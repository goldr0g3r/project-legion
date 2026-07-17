# ADR-0003: Use a Fossen-based six-DOF plant

- Status: Proposed
- Date: 2026-07-20

## Context

Project Legion requires a documented decision for this topic because it affects multiple components, experimental validity, or the ability to reproduce results.

## Options considered

Simple decoupled model; Fossen-based model; CFD-derived reduced-order model.

## Decision

Use a standard nonlinear marine-craft structure with configurable hydrodynamic coefficients.

## Rationale

Record the evidence, constraints, and trade-offs that support this decision before changing the status to Accepted.

## Consequences

- Update affected interfaces, tests, and documentation.
- Record limitations introduced by the decision.
- Create follow-up issues for implementation or validation.

## Validation

Define the tests, measurements, or review evidence that will confirm the decision is suitable.
