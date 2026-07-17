# Underwater Plant Model

## State

```text
eta = [x, y, z, roll, pitch, yaw]^T
nu  = [u, v, w, p, q, r]^T
```

## Dynamics

```text
eta_dot = J(eta) * nu
M * nu_dot + C(nu_r) * nu_r + D(nu_r) * nu_r + g(eta)
    = tau_thruster + tau_tether + tau_external
nu_r = nu - nu_current
```

## Model components

- Rigid-body mass and inertia
- Added mass
- Rigid-body and added-mass Coriolis terms
- Linear and quadratic damping
- Gravity and buoyancy restoring terms
- Thruster force mapping
- Actuator saturation, delay, and rate limits
- Ocean-current disturbance
- Sensor noise, bias, quantization, and delay

## Fidelity progression

1. Four-DOF: surge, sway, heave, yaw.
2. Six-DOF: add roll and pitch with restoring behavior.
3. Uncertainty: randomize mass, added mass, damping, centers, thruster coefficients, delay, and sensor properties.

## Current model

```text
v_current = v_mean + v_gauss_markov + v_gust + v_shear
```

A seeded first-order Gauss-Markov process provides smooth temporally correlated current variation.

## Thruster allocation

```text
tau = B * f
```

Allocation should minimize wrench error and control effort subject to individual thruster limits.

## Model verification

- Zero-input equilibrium
- Gravity and buoyancy sign tests
- Positive-axis impulse tests
- Free-decay tests
- Symmetry tests
- Static-current equilibrium
- Step-size sensitivity
- Simulink versus Python comparison if both are retained
