# 3-Phase PWM Controller — RTL to GDSII

Full RTL to GDSII flow using OpenLane on SkyWater SKY130A 130nm process.

## Design
- 3-phase PWM with AXI4-Lite interface
- Dead-time insertion and fault protection
- Clock: 200 MHz, PWM: 20 kHz

## GDSII Results
| Metric | Value |
|--------|-------|
| Die size | 132 x 130 µm |
| Technology | SKY130A 130nm |
| DRC violations | 0 |
| LVS status | Clean (867 nets) |
| Setup violations | 0 |
| Hold violations | 0 |

## Tools Used
- OpenLane v1.0.2 — RTL to GDSII flow
- Yosys — Synthesis
- OpenROAD — Placement & Routing
- Magic VLSI — DRC + GDS streaming
- KLayout — Layout viewing
- Sky130A PDK — SkyWater 130nm

## File Structure
- `src/` — RTL source (SystemVerilog)
- `results/gds/` — Final GDSII layout
- `results/reports/` — DRC, LVS, timing reports
- `screenshots/` — KLayout layout image
