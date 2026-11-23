# ADR-009: uv for Python packages and environments

**Status:** Accepted — 18 Nov 2026

## Context

The project needs reproducible Python environments on the Mac and in CI, with pinned dependencies that reviewers can reproduce.

## Decision

Use `uv` for Python installation, project setup, dependencies, environment synchronization, and execution. Declare dependencies in `pyproject.toml` and commit `uv.lock`. CI builds Lambda deployment packages from the lockfile, exports requirements, installs into a target directory, and packages the result before AWS credentials are assumed.

## Alternatives

- **pip and venv:** Works, but lacks a lockfile by default.
- **Poetry:** Provides a lockfile, but is heavier and has a less suitable Lambda export path.
- **pip-tools:** Provides locking, but requires separate tools for work that `uv` combines.

## Consequences

Environments are reproducible from one lockfile and installs are faster. `uv` is an additional Phase 0 tool to learn, replacing rather than adding to the venv lesson. If `uv export` fails deployment, use a maintained `requirements.txt` checked against the lockfile.

**Guide deviation:** The guide targets Python 3.13, rather than the plan's Python 3.12 reference.
