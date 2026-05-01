---
name: execute-test-failure-repair
description: Repair failing tests, build steps, type checks, or focused verification blockers during an orchestration `execute` task. Use when the primary job is restoring an expected contract, not delivering a broad new feature.
---

# Execute Test Failure Repair

Use this skill when the task is fundamentally a repair of an already expected behavior or verification contract.

## Workflow

### 1. Pin down the failing contract

- Prefer the narrowest command or proof surface that demonstrates the break.
- Identify whether the failure is caused by code, config, fixtures, environment assumptions, or stale task context.

### 2. Restore the expected contract

- Change only what is needed to restore the intended behavior.
- Preserve surrounding public behavior unless the task explicitly says the contract changed.

### 3. Re-run the proof surface

- Re-run the command or proof surface that demonstrates the fix.
- If full-suite verification is too expensive for this task, at least rerun the failing path and explain the remaining verification gap.

## Boundaries

- Split the task instead of folding in wide cleanup, redesign, or staged compatibility work.
