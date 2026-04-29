# 3-Phase PWM Controller with AXI4-Lite Interface

Synthesizable SystemVerilog 3-phase PWM controller for motor drive applications.
 
## Features
- Triangle carrier PWM with configurable frequency
- Independent duty cycle control for all 3 phases
- Programmable dead-time insertion via AXI register
- Hardware fault input with 2-FF synchronizer for CDC safety
- Fault latch with AXI-controlled clear
- Shoot-through protection on all 6 gate outputs

## Register Map
| Address | Name     | Description                       |
|---------|----------|-----------------------------------|
| 0x00    | CTRL     | Bit0=PWM enable, Bit1=Fault clear |
| 0x04    | DUTY_A   | Phase A duty cycle                |
| 0x08    | DUTY_B   | Phase B duty cycle                |
| 0x0C    | DUTY_C   | Phase C duty cycle                |
| 0x10    | DEADTIME | Dead-time in clock cycles         |
| 0x14    | STATUS   | Bit0=PWM enable, Bit1=Fault       |

## Simulation
    iverilog -g2012 -o sim/pwm.vvp pwm_controller_clean.sv tb_pwm_clean.sv
    vvp sim/pwm.vvp
    gtkwave sim/pwm_tb.vcd

## Tools
- Icarus Verilog, GTKWave
- SystemVerilog IEEE 1800-2012
