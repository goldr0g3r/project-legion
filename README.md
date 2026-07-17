# Project Legion

## Reinforcement Learning-Assisted Station Keeping for a Mother-Daughter ROV System

Project Legion is an MTech AIML dissertation project that develops a reproducible ROS 2-based SIL, PIL, and HIL platform for station keeping of a heterogeneous mother-daughter underwater vehicle system in randomized ocean currents.

## Version 1 scope

Version 1 focuses on control architecture, simulation, embedded execution, communication, verification, and experimental reproducibility.

- The mother ROV plant and controller run on the host PC.
- The daughter ROV plant runs on the host PC.
- The daughter PID, allocation, protocol, and safety logic run on an STM32 Nucleo.
- Reinforcement-learning training and inference run on the PC.
- ROS 2 provides orchestration, telemetry, configuration, logging, and experiment management.
- UART is used first; isolated RS-485 may be introduced after protocol validation.
- PID is the mandatory baseline.
- Bounded residual RL is the primary learning-based controller.

## Deferred work

The following are outside Version 1 unless schedule margin remains:

- Pressure-rated vehicle fabrication
- Deep-sea deployment
- Multi-daughter formation control
- Visual or sonar SLAM
- Autonomous docking
- Real tether-shape control
- Acoustic networking
- Full mapping and exploration autonomy
- On-MCU neural-network inference
- Real-time CFD

## Definition of success

1. Verified four-DOF and six-DOF plant models.
2. Stable mother and daughter PID station keeping.
3. Daughter control executing on STM32.
4. Closed-loop serial HIL operation.
5. Reproducible randomized-current experiments.
6. Residual RL compared fairly against PID.
7. Automatic RL-to-PID fallback.
8. Versioned results, configurations, and random seeds.
9. Reproducible dissertation release.

## Repository layout

```text
project-legion/
├── .github/
├── config/
├── docs/
│   ├── architecture/
│   ├── experiments/
│   ├── interfaces/
│   ├── research/
│   ├── safety/
│   └── verification/
├── experiments/
├── firmware/stm32/
├── models/matlab/
├── models/python/
├── rl/
├── ros2_ws/src/
├── scripts/
└── tests/
```

## Development order

1. Freeze conventions, scope, metrics, and safety boundaries.
2. Implement and verify the plant model.
3. Implement and benchmark PID.
4. Establish ROS 2 orchestration and deterministic replay.
5. Deploy the daughter controller to STM32 and complete PIL.
6. Close the HIL loop.
7. Train residual RL only after the baseline is stable.
8. Execute the final held-out evaluation.
9. Freeze results and complete the dissertation.

## Core rule

Do not begin final RL training until the plant, coordinate frames, PID baseline, metrics, and deterministic experiment replay are verified.
