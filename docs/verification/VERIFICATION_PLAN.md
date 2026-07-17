# Verification and Validation Plan

## Verification levels

| Level | Controller execution | Plant execution | Purpose |
|---|---|---|---|
| MIL | Model | Model | Validate equations and control design |
| SIL | Host-generated code | Host model | Validate generated software behavior |
| PIL | STM32 | Host test harness | Verify target numerical behavior and timing |
| HIL | STM32 | Real-time host plant | Verify closed-loop timing and communication |
| External simulation | Selected controller | Independent simulator | Cross-check model assumptions |

## Unit tests

- Coordinate transforms
- Quaternion normalization
- Plant matrices
- Restoring-force signs
- Current generator determinism
- Thruster allocation
- Saturation and slew limits
- PID reset and anti-windup
- Packet encoding and parsing
- CRC and sequence handling
- State machine transitions
- Reward and termination logic

## Integration tests

- Host plant with host PID
- Two-vehicle ROS 2 launch
- ROS 2 serial bridge loopback
- STM32 PIL
- Closed-loop daughter HIL
- RL timeout fallback
- Emergency stop
- Experiment recording and replay

## Entry criteria for final evaluation

- No open critical safety defects
- Plant verification complete
- Baseline PID frozen
- RL checkpoint frozen
- Scenario and seed lists frozen
- Metrics scripts reviewed
- HIL timing within configured bounds
- Reproduction command tested on a clean environment

## Exit criteria

- All preregistered scenarios executed
- Failures retained in the dataset
- Confidence intervals calculated
- Result artifacts checksummed
- Figures generated from scripts
- Final release tagged

<!-- AUDIT-FIX: -->
## Audit reconciliation: language-independent verification levels

- MIL: model controller and plant execute in one model process.
- SIL: production host processes execute against the simulated plant.
- PIL: production controller code executes on STM32 against host vectors or plant.
- HIL: STM32 executes in the real-time bidirectional loop using the production serial protocol.

Required gates include plant sign/equilibrium/decay/step-size tests, PID numeric tolerance, host and STM32 serial golden vectors, PIL equivalence and WCET, HIL timing instrumentation, and RL-timeout fallback.
<!-- AUDIT-FIX: -->
