# Reinforcement-Learning Specification

## Observation

Mother-relative position error, daughter velocity error, attitude and rate error, estimated current, previous command, PID wrench, and age/validity flags.

## Action

A finite-checked, clipped six-component residual wrench scaled by authority from `config/system_limits.yaml`.

## Evaluation

Primary metric is held-out position RMSE. Required training arms are residual PPO with domain randomization and a matched no-domain-randomization ablation.

## Reward template

```text
r = -wp*ep^2 - wv*ev^2 - wo*eo^2 - wu*u^2 - wd*du^2 - ws*sat - wf*fault
```

Weights, seeds, training budget, and checkpoint-selection rule must be frozen before final training.
