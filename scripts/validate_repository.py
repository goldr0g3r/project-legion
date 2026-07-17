from pathlib import Path
import yaml
ROOT=Path(__file__).resolve().parents[1]
with (ROOT/'config/system_limits.yaml').open(encoding='utf-8') as f: c=yaml.safe_load(f)
assert c['control']['daughter_pid_rate_hz']==c['control']['state_transport_rate_hz']
assert 0<c['control']['residual_authority_initial']<=c['control']['residual_authority_maximum']<=1
assert c['communication']['heartbeat_timeout_ms']>c['communication']['state_timeout_ms']
print('Repository configuration is internally consistent.')
