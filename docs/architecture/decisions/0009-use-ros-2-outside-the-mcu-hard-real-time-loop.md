# ADR-0009: Use ROS 2 outside the MCU hard real-time loop

- Status: Proposed
- Date: 2026-07-20

## Context

Project Legion requires a documented decision for this topic because it affects multiple components, experimental validity, or the ability to reproduce results.

## Options considered

ROS-controlled loop; MCU timer loop; RT Linux controller.

## Decision

Use ROS 2 for orchestration and data exchange, while the MCU timer drives the fastest loop.

## Rationale

Record the evidence, constraints, and trade-offs that support this decision before changing the status to Accepted.

## Consequences

- Update affected interfaces, tests, and documentation.
- Record limitations introduced by the decision.
- Create follow-up issues for implementation or validation.

## Validation

Define the tests, measurements, or review evidence that will confirm the decision is suitable.
