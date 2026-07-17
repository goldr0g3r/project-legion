# ROS 2 Interfaces

## Namespaces

```text
/mother
/daughter
/ocean
/mission
/experiment
/safety
```

## Topics

### Mother

- `/mother/target_pose`
- `/mother/odometry`
- `/mother/imu`
- `/mother/depth`
- `/mother/wrench_cmd`
- `/mother/thruster_cmd`
- `/mother/controller_state`

### Daughter

- `/daughter/relative_target`
- `/daughter/odometry`
- `/daughter/imu`
- `/daughter/depth`
- `/daughter/pid_wrench`
- `/daughter/rl_residual`
- `/daughter/wrench_cmd`
- `/daughter/thruster_cmd`
- `/daughter/stm32/telemetry`
- `/daughter/stm32/link_status`

### Common

- `/clock`
- `/ocean/current`
- `/mission/state`
- `/experiment/id`
- `/safety/state`
- `/diagnostics`

## QoS policy

- Commands: reliable, keep last 1
- Safety state: reliable, transient local
- High-rate simulated sensors: best effort, small queue
- Mission configuration: reliable
- Experiment events: reliable
- Visualization: best effort

## Frame policy

- Plant and controller calculations use the selected marine frame convention.
- ROS-facing conversion is explicit and tested.
- Every stored result records the frame convention.
- No component infers frame or units from the variable name alone.

<!-- AUDIT-FIX: -->
## Audit reconciliation: control services, QoS, and time

Required services include `/daughter/arm`, `/daughter/disarm`, `/safety/emergency_stop`, `/safety/reset_fault`, `/experiment/select_controller_mode`, and fault-injection configure, enable, and disable operations.

Safety, configuration, controller-mode, and experiment events use reliable QoS. High-rate state and disposable residual streams use best effort with small depth plus timestamp and sequence validation. Low-rate targets use reliable depth 1 with explicit expiry.

`/clock` is enabled only in simulation-time modes. HIL uses monotonic wall time as specified in `docs/architecture/TIME_POLICY.md`.
<!-- AUDIT-FIX: -->
