---
name: execute-dev-with-followup-test
description: Deliver an implementation slice that is intentionally followed by a separate verification task. Use when the current `execute` task should complete the change itself, but full runtime proof belongs to an explicit downstream test or acceptance task.
---

# Execute Dev With Follow-Up Test

Use this skill when the current execute task owns implementation and a later task owns the broader verification pass.

## Workflow

### 1. Deliver the scoped implementation slice

- Keep the code change narrowly aligned to the current task objective.
- Keep interfaces, fixtures, flags, and entrypoints clear enough for the downstream verifier to pick up immediately.

### 2. Leave a clean verification handoff

- Update or add only the local checks needed to avoid obviously broken output.
- Record any remaining verification boundary explicitly in the final report instead of silently assuming it will be fine.

### 3. Stop at the split point

- If the implementation cannot be judged safe without broad verification right now, report that the split is wrong instead of pretending the handoff is clean.
