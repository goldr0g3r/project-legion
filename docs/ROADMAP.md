# Six-Month Roadmap

## Milestones

| Milestone | Period | Exit result |
|---|---|---|
| M1: Foundation and four-DOF baseline | 2026-07-20 to 2026-08-19 | Scope, metrics, four-DOF model, initial PID |
| M2: Six-DOF modeling and ROS 2 | 2026-08-20 to 2026-09-19 | Verified six-DOF model and integrated two-vehicle simulation |
| M3: STM32 and PIL | 2026-09-20 to 2026-10-19 | Embedded daughter controller and PIL evidence |
| M4: Reinforcement learning | 2026-10-20 to 2026-11-19 | Frozen residual-RL candidate and held-out evaluation |
| M5: HIL and evaluation | 2026-11-20 to 2026-12-19 | Fault injection and final controller comparison |
| M6: Dissertation and demonstration | 2026-12-20 to 2027-01-19 | Tagged release, dissertation, and demonstration |

## Work-in-progress policy

- Maximum three active issues.
- Maximum one major unresolved architectural decision.
- Do not start M4 final training while M2 plant verification is incomplete.
- Begin dissertation writing during M2, not after experimentation.

## Weekly cadence

### Monday

- Review milestone and blockers.
- Select up to three ready items.
- Confirm acceptance criteria and expected evidence.

### During the week

- Use one branch per issue.
- Keep pull requests focused.
- Attach plots, logs, and reproduction commands.
- Record unexpected results and failed experiments.

### Friday

- Close completed issues.
- Update risks and milestone status.
- Archive experiment results.
- Record next-week priorities.
