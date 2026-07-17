# Project Charter

## Problem statement

Underwater station keeping is difficult because nonlinear vehicle dynamics, uncertain hydrodynamic coefficients, actuator limits, communication delay, sensor error, and time-varying currents act simultaneously. Project Legion investigates whether bounded residual reinforcement learning can improve a deterministic PID baseline while preserving explainability, fallback behavior, and HIL reproducibility.

## Primary research question

Can bounded residual reinforcement learning improve station-keeping accuracy or control effort relative to a tuned PID controller under randomized ocean currents and model uncertainty without increasing the failure rate?

## Secondary research questions

1. How does performance change between MIL, SIL, PIL, and HIL?
2. How sensitive is station keeping to latency, jitter, packet loss, sensor noise, and hydrodynamic uncertainty?
3. Does mother-relative daughter station keeping remain stable when the mother and daughter experience correlated but non-identical currents?
4. Can the STM32 maintain safe daughter control when RL inference or host communications fail?

## Hypotheses

- H1: Residual RL reduces position RMSE or control effort relative to PID in held-out randomized-current scenarios.
- H2: Domain randomization improves performance on unseen plant parameters.
- H3: A faster embedded PID loop with a slower bounded RL residual is more robust to communication jitter than direct host-generated thruster commands.
- H4: Explicit fallback to PID prevents loss of bounded station keeping during RL timeout.

## Deliverables

- Plant model and verification suite
- PID baseline and tuning procedure
- ROS 2 experiment architecture
- STM32 daughter controller
- Framed serial protocol
- PIL and HIL test harnesses
- Residual RL policy and training configuration
- Fault-injection framework
- Statistical comparison
- Dissertation and reproducibility release

## Constraints

- Six-month execution window
- One physical STM32 target
- No complete underwater hardware build in Version 1
- Host-dependent RL inference
- Limited experimental access to real hydrodynamic coefficients

## Decision gates

- Gate 1: Plant verification passes before controller comparison.
- Gate 2: PID meets nominal tolerance before RL development.
- Gate 3: PIL numerical equivalence passes before HIL.
- Gate 4: If residual RL does not improve a preregistered metric by the end of M4, retain PID or evaluate RL gain scheduling.
- Gate 5: Final experiment configurations and seeds are frozen before final evaluation.

<!-- AUDIT-FIX: -->
## Audit reconciliation: hypotheses and measurable gates

`config/system_limits.yaml` is the authoritative source for provisional numeric limits.

### Primary hypothesis

Bounded residual PPO reduces held-out position RMSE relative to the same PID baseline without exceeding the configured failure-rate non-inferiority margin.

### Required ablation

The domain-randomization hypothesis is evaluated using two matched residual-PPO arms: one with domain randomization and one without it. Architecture, reward, training budget, and checkpoint-selection procedure remain identical.

The earlier direct-host-thruster comparison is an optional systems-engineering study rather than a primary dissertation hypothesis.

### Gates

1. Plant sign, equilibrium, decay, and step-size verification pass.
2. PID meets `config/system_limits.yaml` tolerances.
3. PIL equivalence and target timing pass.
4. DR and no-DR policies are frozen before final evaluation.
5. Final configurations, seeds, and analysis scripts are frozen before final runs.
<!-- AUDIT-FIX: -->
