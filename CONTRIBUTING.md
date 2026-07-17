# Contributing

## Branch naming

```text
feature/<issue>-short-name
test/<issue>-short-name
docs/<issue>-short-name
fix/<issue>-short-name
experiment/<issue>-short-name
```

## Commit convention

```text
feat(model): implement Gauss-Markov current generator
feat(control): add PID anti-windup
test(model): verify free-decay response
docs(adr): select six-DOF plant formulation
fix(serial): recover from malformed frame
```

## Pull-request requirements

- Link the issue with `Closes #<number>`.
- Keep the change focused.
- Add or update tests.
- State frames and units.
- Include evidence and reproduction instructions.
- Update related documentation and ADRs.
- Do not mix generated experiment results with unrelated code changes.

## Definition of done

- Acceptance criteria satisfied
- Tests pass
- Required evidence attached
- Documentation updated
- Safety effect reviewed
- Reproduction command recorded
- Project fields updated
