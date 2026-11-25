import os
from pathlib import Path

import pytest

from cdm.core import Project


@pytest.fixture
def project(tmp_path, monkeypatch):
    # Reuse downloaded PUBLIC model assets, never a real project's memory.
    cache = Path(os.environ.get('CDM_TEST_ASSETS', Path(__file__).parents[1]/'.codex-dev-memory'))
    original = Project.configure
    def configure(self, online=False):
        original(self, online)
        os.environ['HF_HOME'] = str(cache/'models')
        os.environ['TIKTOKEN_CACHE_DIR'] = str(cache/'tokenizers')
    monkeypatch.setattr(Project, 'configure', configure)
    return Project(tmp_path)
