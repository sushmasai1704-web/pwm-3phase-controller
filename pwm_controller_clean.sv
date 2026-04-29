module pwm_3phase_controller #(
    parameter CLK_FREQ_HZ   = 200_000_000,
    parameter PWM_FREQ_HZ   = 20_000,
    parameter DEADTIME_NS   = 200,
    parameter DUTY_WIDTH    = 16,
    parameter CARRIER_WIDTH = 12
)(
    input  logic        clk, rst_n,
    input  logic        axi_awvalid,
    output logic        axi_awready,
    input  logic [7:0]  axi_awaddr,
    input  logic        axi_wvalid,
    output logic        axi_wready,
    input  logic [31:0] axi_wdata,
    output logic        axi_bvalid,
    input  logic        axi_bready,
    output logic [1:0]  axi_bresp,
    input  logic        axi_arvalid,
    output logic        axi_arready,
    input  logic [7:0]  axi_araddr,
    output logic        axi_rvalid,
    input  logic        axi_rready,
    output logic [31:0] axi_rdata,
    output logic [1:0]  axi_rresp,
    output logic        pwm_ah, pwm_al,
    output logic        pwm_bh, pwm_bl,
    output logic        pwm_ch, pwm_cl,
    input  logic        fault_in,
    output logic        fault_out,
    output logic        pwm_sync,
    output logic [2:0]  sector
);
    localparam CARRIER_MAX  = CLK_FREQ_HZ / (PWM_FREQ_HZ * 2);
    localparam DEADTIME_CYC = 40;
    logic [CARRIER_WIDTH-1:0] carrier_cnt;
    logic carrier_up, pwm_enable, fault_latched, fault_clear;
    logic [DUTY_WIDTH-1:0] duty_a, duty_b, duty_c;
    logic [7:0] deadtime_reg;
    logic raw_ah, raw_bh, raw_ch;
    logic [7:0] aw_addr_reg;
    logic aw_active;
    logic fault_in_sync, fault_in_meta;
    assign sector    = 3'b001;
    assign fault_out = fault_latched;
    assign axi_bresp = 2'b00;
    assign axi_rresp = 2'b00;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin fault_in_meta<=0; fault_in_sync<=0; end
        else        begin fault_in_meta<=fault_in; fault_in_sync<=fault_in_meta; end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            fault_latched <= 1'b0;
        else if (fault_clear)
            fault_latched <= 1'b0;
        else if (fault_in_sync)
            fault_latched <= 1'b1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            carrier_cnt<=0; carrier_up<=1; pwm_sync<=0;
        end else begin
            pwm_sync <= 0;
            if (pwm_enable && !fault_latched) begin
                if (carrier_up) begin
                    if (carrier_cnt >= CARRIER_MAX-1) begin
                        carrier_up<=0; pwm_sync<=1;
                    end else carrier_cnt <= carrier_cnt + 1;
                end else begin
                    if (carrier_cnt == 0) carrier_up <= 1;
                    else carrier_cnt <= carrier_cnt - 1;
                end
            end else carrier_cnt <= 0;
        end
    end

    assign raw_ah = pwm_enable && !fault_latched && (carrier_cnt < duty_a[CARRIER_WIDTH-1:0]);
    assign raw_bh = pwm_enable && !fault_latched && (carrier_cnt < duty_b[CARRIER_WIDTH-1:0]);
    assign raw_ch = pwm_enable && !fault_latched && (carrier_cnt < duty_c[CARRIER_WIDTH-1:0]);

    dead_time_gen #(.DT_CYCLES(DEADTIME_CYC)) dt_a (.clk(clk),.rst_n(rst_n),.en(pwm_enable&~fault_latched),.pwm_in(raw_ah),.pwm_h(pwm_ah),.pwm_l(pwm_al),.dt_cfg(deadtime_reg));
    dead_time_gen #(.DT_CYCLES(DEADTIME_CYC)) dt_b (.clk(clk),.rst_n(rst_n),.en(pwm_enable&~fault_latched),.pwm_in(raw_bh),.pwm_h(pwm_bh),.pwm_l(pwm_bl),.dt_cfg(deadtime_reg));
    dead_time_gen #(.DT_CYCLES(DEADTIME_CYC)) dt_c (.clk(clk),.rst_n(rst_n),.en(pwm_enable&~fault_latched),.pwm_in(raw_ch),.pwm_h(pwm_ch),.pwm_l(pwm_cl),.dt_cfg(deadtime_reg));

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_enable<=0; fault_clear<=0; deadtime_reg<=8'd40;
            duty_a<=DUTY_WIDTH'(CARRIER_MAX/2);
            duty_b<=DUTY_WIDTH'(CARRIER_MAX/2);
            duty_c<=DUTY_WIDTH'(CARRIER_MAX/2);
            axi_awready<=1; axi_wready<=1; axi_bvalid<=0;
            axi_arready<=1; axi_rvalid<=0; axi_rdata<=0;
            aw_active<=0;
        end else begin
            fault_clear <= 0;
            if (axi_awvalid && axi_awready) begin
                aw_addr_reg<=axi_awaddr; aw_active<=1; axi_awready<=0;
            end
            if (axi_wvalid && axi_wready && (aw_active || (axi_awvalid && axi_awready))) begin
                case (axi_awvalid ? axi_awaddr : aw_addr_reg)
                    8'h00: begin pwm_enable<=axi_wdata[0]; if (axi_wdata[1]) fault_clear<=1; end
                    8'h04: duty_a<=axi_wdata[DUTY_WIDTH-1:0];
                    8'h08: duty_b<=axi_wdata[DUTY_WIDTH-1:0];
                    8'h0C: duty_c<=axi_wdata[DUTY_WIDTH-1:0];
                    8'h10: deadtime_reg<=axi_wdata[7:0];
                    default: ;
                endcase
                axi_bvalid<=1; aw_active<=0; axi_awready<=1;
            end
            if (axi_bvalid && axi_bready) axi_bvalid<=0;
            if (axi_arvalid && axi_arready) begin
                axi_rvalid<=1;
                axi_rdata<=(axi_araddr==8'h14) ? {30'b0,fault_latched,pwm_enable} : {30'b0,pwm_enable};
            end
            if (axi_rvalid && axi_rready) axi_rvalid<=0;
        end
    end
endmodule

module dead_time_gen #(parameter DT_CYCLES=40)(
    input  logic clk, rst_n, en, pwm_in,
    input  logic [7:0] dt_cfg,
    output logic pwm_h, pwm_l
);
    logic [7:0] dt_cnt;
    logic prev_in;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin pwm_h<=0;pwm_l<=0;dt_cnt<=0;prev_in<=0; end
        else if (!en) begin pwm_h<=0;pwm_l<=0; end
        else begin
            prev_in<=pwm_in;
            if (pwm_in!=prev_in) begin pwm_h<=0;pwm_l<=0;dt_cnt<=dt_cfg; end
            else if (dt_cnt>0) dt_cnt<=dt_cnt-1;
            else begin pwm_h<=pwm_in; pwm_l<=~pwm_in; end
        end
    end
endmodule
