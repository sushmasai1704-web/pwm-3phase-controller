module pwm_assertions #(
    parameter CLK_FREQ_HZ   = 200_000_000,
    parameter PWM_FREQ_HZ   = 20_000,
    parameter DUTY_WIDTH    = 16,
    parameter CARRIER_WIDTH = 12
)(
    input logic clk, rst_n,
    input logic pwm_ah, pwm_al,
    input logic pwm_bh, pwm_bl,
    input logic pwm_ch, pwm_cl,
    input logic fault_in,
    input logic fault_out,
    input logic pwm_enable,
    input logic fault_latched,
    input logic [CARRIER_WIDTH-1:0] carrier_cnt
);
    localparam CARRIER_MAX = CLK_FREQ_HZ / (PWM_FREQ_HZ * 2);

    // P1: Dead time
    A_DEADTIME_A: assert property (!(pwm_ah && pwm_al));
    A_DEADTIME_B: assert property (!(pwm_bh && pwm_bl));
    A_DEADTIME_C: assert property (!(pwm_ch && pwm_cl));

    // P2: fault_out equals fault_latched
    A_FAULT_OUT: assert property (fault_out == fault_latched);

    // P3-P7: Sequential checks in always block
    always @(posedge clk) begin
        if (rst_n) begin
            // P3: PWM disabled = all outputs LOW
            if (!pwm_enable) begin
                A_PWM_DISABLED_AH: assert (!pwm_ah);
                A_PWM_DISABLED_AL: assert (!pwm_al);
                A_PWM_DISABLED_BH: assert (!pwm_bh);
                A_PWM_DISABLED_BL: assert (!pwm_bl);
                A_PWM_DISABLED_CH: assert (!pwm_ch);
                A_PWM_DISABLED_CL: assert (!pwm_cl);
            end
            // P4: Fault = all outputs LOW
            if (fault_latched) begin
                A_FAULT_AH: assert (!pwm_ah);
                A_FAULT_AL: assert (!pwm_al);
                A_FAULT_BH: assert (!pwm_bh);
                A_FAULT_BL: assert (!pwm_bl);
                A_FAULT_CH: assert (!pwm_ch);
                A_FAULT_CL: assert (!pwm_cl);
            end
            // P5: Carrier bounded
            A_CARRIER: assert (carrier_cnt <= CARRIER_MAX);
            // P6: Fault latches after 2 cycles
            if ($past(fault_in,2) && $past(rst_n,2) && $past(rst_n))
                A_FAULT_LATCH: assert (fault_out);
        end else begin
            // P7: Reset clears outputs
            A_RST_AH: assert (!pwm_ah);
            A_RST_AL: assert (!pwm_al);
            A_RST_BH: assert (!pwm_bh);
            A_RST_BL: assert (!pwm_bl);
            A_RST_CH: assert (!pwm_ch);
            A_RST_CL: assert (!pwm_cl);
        end
    end

endmodule
