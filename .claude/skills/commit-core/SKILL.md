---
name: commit-core
description: Persist repo changes during orchestration `commit` tasks. Use when the job is to review the current worktree with `commit_snapshot` as advisory context, apply only minimal hygiene needed for a safe clean commit, and either create one bounded commit or report a no-op.
---

# Commit Core

## Purpose

Persist the remaining repo changes as one bounded Stage 4 commit finalization pass.

## Read First

- `commit_snapshot` when present
- any explicitly provided diff scope when no snapshot exists
- parent-task linkage in structured task/report fields rather than commit-message body rules

## Decision Unit

- one repository-finalization pass and whether it needs a commit, minimal hygiene cleanup, or a no-op completion

## Procedure

### 1. Establish the starting context

- review `commit_snapshot` when present to understand what triggered the task
- compare that snapshot with the live worktree before deciding what still needs persistence

### 2. Decide whether persistence is still needed

- if the repository is already clean, already committed, or otherwise already resolved, report `done`
- otherwise continue toward one minimal safe commit

### 3. Resolve minimal hygiene before committing

- allow only lint, formatting, or ignore-policy cleanup needed for a clean commit
- keep every cleanup change tightly coupled to the remaining worktree changes being finalized
- do not auto-stage obvious local-only or dangerous paths such as secrets, env files, logs, caches, or transient machine artifacts
- do not delete or ignore screenshots, recordings, comparison outputs, or other
  artifacts when the parent task lists them as required visual evidence; either
  persist them if they are repository-appropriate, or report `blocked` with the
  size/privacy reason and the needed artifact policy
- do not reopen planning, audit, or acceptance from the commit task itself

### 4. Create one bounded commit

- stage only files that are safe and necessary to leave the repository clean
- use a concise `type(scope): summary` subject; task linkage lives in structured task/report fields

### 5. Record the persistence outcome

- report the commit SHA and message when a commit is created
- otherwise report the explicit no-op reason

## Allowed Outputs

- one minimal safe commit that leaves the repository clean
- a no-op `done` report when no commit is needed

## Boundaries

- Do not modify product logic beyond minimal hygiene.
- Do not reopen broad verification or review workflow.
- Do not push or refresh the snapshot from the live worktree.

## Exception Route

- Report `blocked` only when git cannot safely complete the commit, such as conflicts, lock or index failures, permissions issues, hook failures, or repository corruption.
