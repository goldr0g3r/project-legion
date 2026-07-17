# Time-Source Policy

| Level | Time source |
|---|---|
| MIL | Simulation time |
| SIL | Controlled host or simulation time |
| PIL | Host test time plus MCU timestamps |
| HIL | Monotonic wall time |
| Replay | Recorded timestamps |

`/clock` is disabled in HIL. Timeouts use monotonic clocks. Host and MCU timestamps are logged and wrap-safe age calculations are required.
