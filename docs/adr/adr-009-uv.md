# ADR-009 — uv as the Python package and environment manager

**Status:** Accepted — 18 Nov 2026

## Context

The project needs reproducible Python environments on the Mac and in CI, with pinned dependencies a reviewer can reproduce exactly. Phase 0 needs to name one tool for this, not leave it to chance.

## Decision

Use uv (Astral) for everything Python: `uv python install 3.12` for the interpreter, `uv init` / `uv add` for dependencies, `uv sync` to build the environment, `uv run` to execute. Dependencies are declared in `pyproject.toml` and pinned in the committed `uv.lock` lockfile.

## The one wrinkle, and how it is handled

Lambda deployment packages are built from the lockfile, not by hand: CI runs `uv export --format requirements-txt`, installs into a target directory, zips it, uploads the zip to S3, and passes the S3 location to CloudFormation as a parameter (see ADR-010). Local development and tests run under `uv run`; the packaged zip is what gets deployed. No other ADR changes.

## Alternatives considered

- **pip + venv (original plan)** — works, but no lockfile, so "works on my machine" is a real risk for a portfolio repo.
- **Poetry** — lockfile and good UX, but slower, heavier, and its Lambda story is worse than uv's export path.
- **pip-tools** — lockfile via `pip-compile`, but it is two tools doing what uv does in one.

## Consequences

Reproducible environments from one lockfile; faster installs; one tool instead of three. Cost: uv is a new tool to learn in Phase 0 — budgeted there, about 30 minutes, and it replaces the venv lesson rather than adding to it. Revisit if: `uv export` output ever fails a CloudFormation deploy, in which case the fallback is a hand-maintained `requirements.txt` checked by CI against the lockfile.
