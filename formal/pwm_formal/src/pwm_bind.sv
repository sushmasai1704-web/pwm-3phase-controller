bind pwm_3phase_controller pwm_assertions #(
    .CLK_FREQ_HZ  (CLK_FREQ_HZ),
    .PWM_FREQ_HZ  (PWM_FREQ_HZ),
    .DUTY_WIDTH   (DUTY_WIDTH),
    .CARRIER_WIDTH(CARRIER_WIDTH)
) u_assertions (
    .clk          (clk),
    .rst_n        (rst_n),
    .pwm_ah       (pwm_ah),
    .pwm_al       (pwm_al),
    .pwm_bh       (pwm_bh),
    .pwm_bl       (pwm_bl),
    .pwm_ch       (pwm_ch),
    .pwm_cl       (pwm_cl),
    .fault_in     (fault_in),
    .fault_out    (fault_out),
    .pwm_enable   (pwm_enable),
    .fault_latched(fault_latched),
    .carrier_cnt  (carrier_cnt)
);
