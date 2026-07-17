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

<!-- AUDIT-FIX: -->
## Audit reconciliation: normative frame and transport rules

The normative little-endian frame is: sync 2 bytes, version 1, type 1, flags 1, reserved 1, sequence 2, timestamp 4, payload length 2, payload up to the configured maximum, and CRC-32 4 bytes.

Concrete values and CRC parameters are defined in `config/system_limits.yaml`. Tests must cover sync inside payload, sequence and timestamp wrap, maximum-size traffic, corruption, truncation, concatenation, and non-finite values.

For half-duplex RS-485, the host is bus master in Version 1. It transmits a request or state frame, opens a bounded response window, and STM32 returns at most one response. A bandwidth tool must demonstrate at least 30 percent margin at the configured baud rate.
<!-- AUDIT-FIX: -->
