---
name: execute-safe-refactor
description: Run a behavior-preserving refactor during an orchestration `execute` task. Use when the task's main objective is structural cleanup, simplification, or reorganization with explicit regression proof requirements.
---

# Execute Safe Refactor

Use this skill when the task must improve structure without changing the accepted behavior.

## Workflow

### 1. Fix the preserved contract

- Read the acceptance criteria and identify what behavior, interfaces, or outputs must remain unchanged.
- Name the concrete proof surface that will show the refactor stayed safe.

### 2. Refactor in reviewable slices

- Prefer mechanical, local transformations over broad simultaneous rewrites.
- Keep external contracts stable unless the task explicitly authorizes a change.
- Remove dead or duplicate code only when the preserved behavior remains demonstrable.

### 3. Prove no intended behavior was lost

- Run the narrowest regression checks that actually cover the preserved contract.
- If no meaningful regression proof exists, say so explicitly instead of claiming the refactor is safe.

## Boundary

- Split feature work or incompatible cleanup into another task instead of smuggling it through the refactor.
