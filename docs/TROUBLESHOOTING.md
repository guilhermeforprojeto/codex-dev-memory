# Troubleshooting / Solução de problemas

| Symptom | Action |
|---|---|
| `python` opens Windows Store | Installer uses UV's interpreter discovery instead of this alias. Keep Python 3.12 available or allow UV's download. |
| Codex not authenticated | Run native `codex login`; do not paste credentials into memory. |
| MCP call requires approval | Use the current launcher/tool definitions and review Codex's project trust/approval UI. Do not disable all safeguards. |
| Hooks do not run | Review hook trust in Codex; project trust alone may be insufficient. Use `checkpoint` explicitly until trusted. |
| Hook warning on exit | 1.0.0 uses Stop/PreCompact only; reinstall to remove obsolete managed SessionEnd entries. |
| Model missing while offline | Re-run installation online to populate public ONNX/tokenizer assets. No paid embedding API is needed. |
| Possible credential detected | Remove the credential, including from quoted logs/checkpoint. Detection intentionally favors rejection. |
| Search result is stale | Verify code and overwrite the stable memory key. Re-read files with `--force` after compaction. |
| Artifact integrity failure | Original artifact was changed; capture the authorized source again. Do not ignore hash mismatches. |
| Install blocked by policy | Follow your organization's approved process; installer does not alter execution policy or antivirus. |
| SQLite/lock timeout | Stop conflicting sessions, then retry once. Avoid synchronized/network folders. Preserve a backup before recovery. |
| No token reduction | Conservative lossless compression can retain the original; unique logs may not benefit. Metrics are payload-only. |
| Moved project / stale absolute paths | Re-run install from the new root to refresh launcher and hooks. |

The first memory load can take several seconds. Headroom selects its safe Python content detector
on Windows; its warning is not a failure. Upstream datetime deprecation warnings do not mean
persistence failed. Do not enable native detection overrides merely to silence warnings.

Português: rode `doctor`, confira o erro concreto e faça uma tentativa direcionada. Não repita
instalações ou comandos indefinidamente. Ao reportar falhas, envie versões e passos sintéticos;
não envie seu banco de memória, credenciais ou logs privados.
