# Experiment Protocol

## Experiment identity

Every run must record:

- Experiment ID
- Git commit
- Controller version
- Plant version
- Configuration checksum
- Training or evaluation seed
- Start time and duration
- Execution level: MIL, SIL, PIL, or HIL
- Hardware and firmware version
- Result status

## Required scenarios

| ID | Scenario |
|---|---|
| S01 | No current, nominal plant |
| S02 | Constant current |
| S03 | Current-direction step |
| S04 | Current-magnitude ramp |
| S05 | Gauss-Markov current |
| S06 | Gust disturbance |
| S07 | Sensor noise and bias |
| S08 | Mass and damping uncertainty |
| S09 | Latency sweep |
| S10 | Packet-loss sweep |
| S11 | Degraded thruster |
| S12 | Daughter relative station keeping |
| S13 | Simultaneous mother and daughter hold |
| S14 | RL failure and PID fallback |
| S15 | Emergency stop and restart |

## Metrics

- Position RMSE
- Depth RMSE
- Heading RMSE
- 95th percentile position error
- Maximum position error
- Time within tolerance
- Settling time
- Recovery time after gust
- Total control effort
- Peak thrust
- Saturation duration
- Command variation
- Episode success rate
- Mean, p95, and p99 communication latency
- Jitter and missed deadlines
- STM32 CPU, memory, and worst-case execution time

## Fair-comparison rules

- Controllers use identical evaluation seeds.
- Controllers use identical limits and evaluation windows.
- Training seeds are excluded from final evaluation.
- Failed episodes are not discarded.
- Hyperparameter changes after viewing final seeds invalidate the final evaluation and require a new held-out set.

## Minimum final evaluation

- At least 100 randomized episodes per controller where computationally feasible.
- Confidence intervals for primary metrics.
- Separate nominal, uncertainty, and communication-fault summaries.
- Complete failure count and failure classification.
