# ADR-0002: Use NED as the primary model frame

- Status: Proposed
- Date: 2026-07-20

## Context

Project Legion requires a documented decision for this topic because it affects multiple components, experimental validity, or the ability to reproduce results.

## Options considered

NED; ENU; internal NED with boundary conversion.

## Decision

Use NED internally for marine dynamics and perform explicit ROS-facing conversion where needed.

## Rationale

Record the evidence, constraints, and trade-offs that support this decision before changing the status to Accepted.

## Consequences

- Update affected interfaces, tests, and documentation.
- Record limitations introduced by the decision.
- Create follow-up issues for implementation or validation.

## Validation

Define the tests, measurements, or review evidence that will confirm the decision is suitable.
