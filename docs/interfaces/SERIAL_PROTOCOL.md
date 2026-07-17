# STM32 Serial Protocol

## Physical-layer progression

1. ST-Link virtual COM or USB UART
2. External UART adapter
3. Isolated RS-485 transceiver
4. Cable-length and error-injection testing

## Frame

```text
+----------+---------+------+----------+----------+---------+----------+--------+
| SyncWord | Version | Type | Sequence | Time_us  | Length  | Payload  | CRC32  |
+----------+---------+------+----------+----------+---------+----------+--------+
```

## Required messages

- `HEARTBEAT`
- `STATE_UPDATE`
- `PID_SETPOINT`
- `RL_RESIDUAL`
- `THRUSTER_COMMAND`
- `CONTROLLER_STATUS`
- `FAULT_STATUS`
- `TIME_SYNC`
- `PARAMETER_SET`
- `PARAMETER_ACK`
- `E_STOP`
- `RESET_FAULT`

## Receiver requirements

- Streaming parser supports partial and concatenated frames.
- Invalid CRC is rejected.
- Invalid length is rejected.
- Unknown version or message type is rejected safely.
- Old or duplicate sequence numbers are rejected where required.
- Stale commands are never applied.
- Non-finite values are rejected.
- Counters are maintained for every rejection category.

## Timeout behavior

- RL timeout: residual becomes zero.
- Reference timeout with valid state: safe hold according to configuration.
- State timeout: disarm.
- Heartbeat timeout: transition to communication fault.
- Emergency stop: immediate latched safe state.

## Test vectors

Commit binary and human-readable golden vectors for:

- Valid minimum frame
- Valid maximum payload
- CRC failure
- Truncated frame
- Garbage before sync
- Duplicate sequence
- Sequence wrap-around
- Unsupported version
- NaN and infinity payloads
