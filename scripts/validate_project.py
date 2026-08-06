"""Dependency-free repository structure and syntax checks."""

from __future__ import annotations

import ast
import json
import pathlib
import tomllib

ROOT = pathlib.Path(__file__).resolve().parents[1]
REQUIRED = [
    "README.md", ".env.example", ".env.prod.example", "Dockerfile",
    "docker-compose.yml", "docker-compose.prod.yml", "app/main.py",
    "deploy/init.sql", "deploy/nginx.conf", "deploy/certs/README.md",
]


def main() -> None:
    missing = [path for path in REQUIRED if not (ROOT / path).exists()]
    if missing:
        raise SystemExit(f"Missing required files: {', '.join(missing)}")
    for path in ROOT.rglob("*.py"):
        ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    tomllib.loads((ROOT / "pyproject.toml").read_text(encoding="utf-8"))
    json.loads((ROOT / "eval/eval_set.json").read_text(encoding="utf-8"))
    leaked = [name for name in (".env", ".env.prod") if (ROOT / name).exists()]
    if leaked:
        raise SystemExit(f"Local secrets found: {', '.join(leaked)}")
    print("Repository validation passed")


if __name__ == "__main__":
    main()
