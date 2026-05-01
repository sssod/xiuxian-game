---
name: execute-compatible-migration
description: Land a compatibility-preserving migration, upgrade, or cutover slice during an orchestration `execute` task. Use when the change must move an interface, schema, config, dependency, or runtime path through a staged old/new coexistence boundary instead of a one-step replacement.
---

# Execute Compatible Migration

Use this skill when the task changes a live contract through a staged compatibility seam.

## Workflow

### 1. Fix the migration boundary

- Name the old path, the new path, and the compatibility window this task owns.
- Decide what must keep working during the slice: old readers, new writers, adapters, staged config, or another explicit bridge.

### 2. Land the smallest safe migration slice

- Prefer reversible or staged changes such as adapters, dual read/write, compatibility shims, or additive schema or config steps.
- Keep the task bounded to one migration slice rather than full cutover, backfill, and cleanup at once.

### 3. Prove the live compatibility claim

- Verify both the newly introduced path and the still-supported path when the task claims they coexist.
- If the task owns only preparation work, prove the bridge itself and record any remaining cutover or backfill boundary explicitly.

## Boundaries

- Do not collapse a staged migration into an unsafe one-step replacement just to finish.
- Split follow-up migration slices when the task boundary runs out.
