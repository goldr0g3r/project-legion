# ADR-0006: Use bounded residual reinforcement learning

- Status: Proposed
- Date: 2026-07-20

## Context

Project Legion requires a documented decision for this topic because it affects multiple components, experimental validity, or the ability to reproduce results.

## Options considered

End-to-end RL; gain scheduling; residual RL.

## Decision

Apply learning as a limited correction to PID rather than unrestricted direct actuation.

## Rationale

Record the evidence, constraints, and trade-offs that support this decision before changing the status to Accepted.

## Consequences

- Update affected interfaces, tests, and documentation.
- Record limitations introduced by the decision.
- Create follow-up issues for implementation or validation.

## Validation

Define the tests, measurements, or review evidence that will confirm the decision is suitable.
