# Third-party components

Original adapter/scripts/docs: MIT, see LICENSE. Dependencies are installed from their own
distributions, not vendored or relicensed. Preserve their included license/notice files when
redistributing an installed environment. The release ZIP contains original project sources and
the dependency lock, not third-party wheels, model weights or private runtime data.

| Component | Version tested | Upstream license |
|---|---|---|
| Headroom | 0.45.0 | Apache-2.0 |
| MCP Python SDK | 2.3.0 | MIT |
| ONNX Runtime | 1.32.0 | MIT |
| sqlite-vec | 0.1.9 | MIT / Apache-2.0 |
| tiktoken | 0.14.0 | MIT |
| filelock | 4.3.1 | MIT |
| NumPy | 2.5.5 | BSD-3-Clause and bundled third-party notices |
| Python | 3.12.10 | PSF |
| SQLite | bundled with Python | Public domain |
| UV | 0.13.9 | MIT / Apache-2.0 |
| Codex CLI | existing 0.171.0-alpha.13.2 | Apache-2.0 upstream |
| Node.js | existing 24.15.0 | MIT and bundled notices |

Package licenses above were checked from installed metadata/source. Transitive dependencies have
their own licenses in each distribution; `requirements.lock` enumerates exact versions and hashes.
Public ONNX model assets are downloaded by Headroom's loader from its configured model repository;
consult that repository's model card/license before redistributing weights. This project does not
ship weights or assert ownership over them. No proprietary Claude implementation was copied.
