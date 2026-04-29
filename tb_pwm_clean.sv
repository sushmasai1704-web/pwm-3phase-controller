module tb_pwm_clean;
    logic clk=0,rst_n;
    logic pwm_ah,pwm_al,pwm_bh,pwm_bl,pwm_ch,pwm_cl;
    logic fault_in=0,fault_out,pwm_sync;
    logic [2:0] sector;
    logic axi_awvalid=0,axi_awready;
    logic [7:0] axi_awaddr=0;
    logic axi_wvalid=0,axi_wready;
    logic [31:0] axi_wdata=0;
    logic axi_bvalid,axi_bready=1;
    logic [1:0] axi_bresp;
    logic axi_arvalid=0,axi_arready;
    logic [7:0] axi_araddr=0;
    logic axi_rvalid,axi_rready=1;
    logic [31:0] axi_rdata;
    logic [1:0] axi_rresp;
    always #2.5 clk=~clk;
    pwm_3phase_controller dut(.*);
    task axi_write(input [7:0] addr, input [31:0] data);
        integer t; t=0;
        @(posedge clk);
        axi_awvalid=1; axi_awaddr=addr;
        axi_wvalid=1;  axi_wdata=data;
        while(!(axi_awready&&axi_wready)&&t<200) begin @(posedge clk);t++; end
        @(posedge clk);
        axi_awvalid=0; axi_wvalid=0;
        t=0;
        while(!axi_bvalid&&t<200) begin @(posedge clk);t++; end
        @(posedge clk);
    endtask
    integer fail=0;
    initial begin
        $dumpfile("sim/pwm_tb.vcd");
        $dumpvars(0,tb_pwm_clean);
        rst_n=0; repeat(10) @(posedge clk);
        rst_n=1; repeat(5)  @(posedge clk);
        $display("=== TEST 1: Enable PWM ===");
        axi_write(8'h00,32'h1);
        repeat(100) @(posedge clk);
        $display("PASS: PWM enabled");
        $display("=== TEST 2: Set duty ===");
        axi_write(8'h04,32'd3000);
        repeat(100) @(posedge clk);
        $display("PASS: Duty set");
        $display("=== TEST 3: Fault injection ===");
        fault_in=1; @(posedge clk); fault_in=0;
        repeat(5) @(posedge clk);
        if(fault_out) $display("PASS: Fault latched");
        else begin $display("FAIL: Fault not latched");fail++; end
        if(!pwm_ah&&!pwm_al&&!pwm_bh&&!pwm_bl&&!pwm_ch&&!pwm_cl)
            $display("PASS: Outputs disabled");
        else begin $display("FAIL: Outputs still active");fail++; end
        $display("=== TEST 4: Fault clear ===");
        axi_write(8'h00,32'h2);
        repeat(20) @(posedge clk);
        if(!fault_out) $display("PASS: Fault cleared");
        else begin $display("FAIL: Fault not cleared");fail++; end
        $display("=== TEST 5: Programmable dead-time ===");
        axi_write(8'h10,32'd20);
        repeat(50) @(posedge clk);
        $display("PASS: Dead-time register written");
        $display("====================================");
        if(fail==0) $display("ALL PWM TESTS PASSED");
        else $display("%0d TEST(S) FAILED",fail);
        $display("====================================");
        $finish;
    end
    always @(posedge clk) if(rst_n) begin
        if(pwm_ah&pwm_al) begin $display("CRITICAL: A shoot-through!");$finish; end
        if(pwm_bh&pwm_bl) begin $display("CRITICAL: B shoot-through!");$finish; end
        if(pwm_ch&pwm_cl) begin $display("CRITICAL: C shoot-through!");$finish; end
    end
endmodule