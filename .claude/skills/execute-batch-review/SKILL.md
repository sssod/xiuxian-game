---
name: execute-batch-review
description: Systematically inspect and resolve a repeated class of issues across multiple files during an orchestration `execute` task. Use when the work is a bounded batch wave, not one deep feature or one isolated bug.
---

# Execute Batch Review

Use this skill when one execute task must handle many repeated candidates under one clear rule.

## Workflow

### 1. Fix the batch rule

- Identify the repeated issue class, file set, or candidate list the task owns.
- Keep the boundary explicit so the batch does not become open-ended repo cleanup.

### 2. Triage candidates once

- Separate safe mechanical fixes from ambiguous cases.
- Apply only the fixes that clearly follow the same rule and acceptance logic.

### 3. Prove batch coverage

- Use sampling, focused searches, or targeted commands that prove the repeated issue class was actually addressed.
- Leave risky or unclear cases explicit instead of forcing them into the same batch.

## Boundary

- Split any candidate that needs a different workflow instead of contaminating the whole batch.
