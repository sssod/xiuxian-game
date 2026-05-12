#!/usr/bin/env python3
"""Compatibility wrapper for the current design-doc ChatGPT export script."""

from __future__ import annotations

import sys
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parent))

from sync_design_docs_chatgpt import main  # noqa: E402


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
