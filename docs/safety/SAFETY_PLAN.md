# Safety and Fault-Management Plan

## Safety objective

No software component, learning policy, malformed message, stale host command, or single recoverable communication fault may produce unbounded actuator commands.

## State machine

```mermaid
stateDiagram-v2
    [*] --> BOOT
    BOOT --> DISARMED: self-test passed
    BOOT --> FAULT: self-test failed
    DISARMED --> ARMED_IDLE: valid arm request
    ARMED_IDLE --> ACTIVE_PID: valid state and reference
    ACTIVE_PID --> ACTIVE_RL: RL healthy
    ACTIVE_RL --> ACTIVE_PID: RL stale or invalid
    ACTIVE_PID --> SAFE_HOLD: reference stale
    ACTIVE_RL --> SAFE_HOLD: reference stale
    SAFE_HOLD --> ACTIVE_PID: reference restored
    ACTIVE_PID --> DISARMED: state or link timeout
    ACTIVE_RL --> DISARMED: state or link timeout
    SAFE_HOLD --> DISARMED: state timeout
    BOOT --> E_STOP: emergency stop
    DISARMED --> E_STOP: emergency stop
    ARMED_IDLE --> E_STOP: emergency stop
    ACTIVE_PID --> E_STOP: emergency stop
    ACTIVE_RL --> E_STOP: emergency stop
    SAFE_HOLD --> E_STOP: emergency stop
    E_STOP --> DISARMED: manual reset
    FAULT --> DISARMED: fault cleared
```

## Mandatory protections

- Watchdog
- Brownout handling
- Neutral startup
- Explicit arm/disarm
- Emergency stop
- State, reference, heartbeat, and RL timeouts
- CRC and sequence checks
- Saturation and slew limits
- NaN and infinity rejection
- Persistent fault counters
- Latched critical faults
- Controlled fault reset

## Bench safety

- Do not test exposed propellers under power.
- Use simulated loads or disconnected motors for initial HIL.
- Use current-limited supplies when hardware is introduced.
- Isolate RS-485 where ground differences may exist.
- Record every safety bypass and remove it before final evaluation.

## Safety evidence

Each safety requirement must map to:

- implementation issue;
- unit or integration test;
- test evidence;
- final verification status.
