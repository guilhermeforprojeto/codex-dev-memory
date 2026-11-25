# Contributing

Use Python 3.12, UV and PowerShell on Windows x64. From a checkout:

```powershell
uv venv --python 3.12 .venv
uv pip install --python .venv/Scripts/python.exe --require-hashes -r requirements.lock
uv pip install --python .venv/Scripts/python.exe pytest
./install-project.ps1
./.venv/Scripts/python.exe -m pytest tests -q
./tests/integration.ps1
./.venv/Scripts/python.exe tests/mcp_smoke.py .
```

Tests use synthetic data; integration tests create isolated temporary projects under `work/`.
Model assets from the installed project are reused by unit tests. `CDM_TEST_ASSETS` can select another
directory containing `models/` and `tokenizers/`. Headroom's `datetime.utcnow` deprecation warnings
are upstream; do not hide failures or disable Windows safeguards to make tests pass.

Keep the adapter small: memory storage, vector search and data compression belong to Headroom.
Document changes to its API, schema or model assets. Regenerate `requirements.lock` with
`uv pip compile pyproject.toml --python-version 3.12 --generate-hashes -o requirements.lock`.
Run the native Windows/PowerShell matrix before publishing. Test actual model calls separately;
CI does not contain ChatGPT credentials. Follow AGENTS.md and update ESTADO_PROJETO.md.

Português: use dados sintéticos, preserve configurações existentes, não publique memória local,
execute os testes acima e registre limitações reais. Correções e documentação são bem-vindas.
