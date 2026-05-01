---
name: execute-core
description: Core operating behavior for orchestration `execute` tasks. Use when a task must deliver a concrete code, config, docs, or operational change directly. Load before any scenario-specific execute skill such as follow-up-test handoff, failure repair, compatible migration, safe refactor, or batch review.
---

# Execute Core

Treat `execute` as bounded delivery work.

## Workflow

### 1. Fix the live contract

- Read the task brief, required inputs, and any explicit design or change artifacts before editing.
- Let the task's `objective`, `context`, `constraints`, and `acceptance_criteria` define the job.
- Identify the local delta and proof surface before making the change.

### 2. Apply the smallest safe delta

- Change only what is needed to satisfy the declared contract.
- Keep surrounding behavior stable unless the task explicitly changes that contract.
- Prefer local, reviewable edits over broad cleanup or speculative redesign.

### 3. Close the task with proportional proof

- Prefer focused verification that matches the acceptance contract.
- If the task intentionally defers broader proof, keep the local handoff clean and explicit.

### 4. Report the real execution outcome

- Finish with the requested concrete delta or a blocker backed by current evidence.
- Keep the final report aligned to what was actually delivered, repaired, or deferred in this run.

## Boundaries

- Do not widen the task into governance, audit, planning, or standalone design work.
- Do not absorb unrelated cleanup just because it is nearby.

## Scenario Layering

- `execute-core` supplies the shared delivery discipline.
- Let one scenario-specific execute skill add the procedure when the task clearly fits a repeated workflow family.
