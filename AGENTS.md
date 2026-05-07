# AI Workspace Governance (AGENTS)

> Runtime: Codex CLI

## Scope

This file applies to the `xiuxian-game` project root.

## Governance Precedence

`AGENTS.md` is the core governance file for this project.

`CLAUDE.md` is a compatibility follower for Claude Code and other agents that look for that filename. If `CLAUDE.md` and `AGENTS.md` conflict, follow `AGENTS.md`.

Do not use files outside this project root as authority for this project.

## Current Work Mode

The current project focus is design documentation iteration and UI control refinement.

Default assumption: requests in this stage are documentation and design tasks, not engineering execution tasks, unless they explicitly mention coding, tests, runtime behavior, or source files.

Unless the user explicitly asks for implementation:

- Do not modify gameplay, runtime, backend, frontend, database, deployment, or other source code.
- Do not propose feature implementation as the default next step.
- Treat docs, UI artifacts, terminology, interaction specs, data contracts, and UI component behavior as the primary work surface.
- Keep responses concise and avoid broad codebase exploration unless it is needed to update an implementation-facing document.
- If implementation implications appear, record them as implementation notes or open questions instead of editing code.

## Project Purpose

`xiuxian-game` is a design-stage independent game project for a room-based multiplayer xiuxian reincarnation sandbox.

Current MVP target:

```text
local single-player testing
privately deployable server
3-player room co-op / indirect competition
save, pause, resume, and continue rooms
M0 -> M3 vertical gameplay loop
```

The player controls a cross-life true-spirit identity, not a sect, nation, or fixed character. Each life can cultivate, join a sect, move across a shared node map, compete for resources, attempt breakthroughs, die, reincarnate, leave legacies, and influence sect and world-node evolution.

## Current Source Of Truth

Use the v2.3 document package in `docs/inbox` as the current latest local source of truth:

```text
docs/inbox/修仙轮回沙盒_设计文档包_v2.3/
```

Start with:

1. `README.md`
2. `01_基础与总览/01_项目总览_MVP边界_系统依赖_v2.3.md`
3. `01_基础与总览/03_术语表_命名规范_字段统一_v2.3.md`
4. `02_核心系统规格/01_共享日历_房间推进_权威结算_v2.3.md`
5. `03_实现交付/02_MVP开发切片与验收清单_v2.3.md`
6. `04_UIUX与界面规范/01_UIUX需求方案_v2.3.md`
7. `02_核心系统规格/08_事件突破战斗时间规则_v2.3.md`

During high-frequency UI iteration, do not maintain per-iteration "精修规格" document series unless explicitly requested. Use the current UI artifact for node-level layout and component placement, and record only stable UI decisions in the v2.3 UI/UX documents.

When documents conflict, prefer this order:

```text
AGENTS.md
-> current UI artifact, for node-level main UI layout / component placement
-> v2.3 UI/UX requirement document, for stable UI decisions
-> v2.3 terminology / field-unification document
-> v2.3 shared calendar / command queue / event breakthrough combat / sect AI documents
-> v2.3 runtime state / data model / result package documents
-> other v2.3 system documents
-> older imported historical documents
-> CLAUDE.md compatibility notes
```

Before changing product, design, UI, data, or implementation-facing docs, read the package `README.md` and the relevant v2.3 document for the subsystem being touched.

## Current Design Contract

- The player-facing time surface is a shared continuous world calendar, not `turn_id`, `quarter`, or fixed action slots.
- Primary time fields are `world_day / world_hour`; 1 game day = 24 game hours.
- Server settlement uses 1-hour ticks through `hour_tick`.
- Public speed states are `F1 / N1 / B1 / P0`; internal catch-up uses `C1`.
- Players submit a small linear list of personal action instructions, not an hour-by-hour schedule.
- Ordinary actions use `Command` and `CommandQueue`: current command plus up to 3 pending preinput commands.
- Client submits intent; authoritative validation, settlement, state mutation, logs, and replay data belong to the server-side settlement path.
- S1 / room authoritative settlement is the integration bus. Subsystems should output result packages and should not directly bypass the settlement bus to mutate world state.
- Replays use `TimelineReplay`, recording speed segments, queue changes, events, formal encounter rounds, result packages, and settlement steps.
- Sect gameplay is an organizational resource platform, not direct player control.
- MVP removes player sect instant commands, sect main-action suggestions, sect proposals, and sect decision phases.
- Each sect may have at most one active `SectContinuousActionState` at the same time, maintained by sect AI.
- Multiplayer competition is mainly indirect through sects, nodes, resources, rumors, visibility, and opportunity windows.
- Learned methods come from complete method carriers; fragments / chapters are assets for synthesis, clues, permissions, or content delivery, not runtime learning progress.
- Dan pills, spiritual materials, talismans, and temporary boost resources enter settlement as action resource inputs such as `ActionResourceInputBinding`, not as a default standalone "丹药炼化" action.
- Unused consumed resource effects are represented by `ActiveResourceEffect` and can persist across turns according to residual policy.
- Formal combat and breakthrough challenges use `FormalEncounterState` in B1. One B1 round equals 1 game hour.

## External Resource Index

### Figma

Checked on 2026-05-07.

Root Figma file:

- `XiuxianUI`
- https://www.figma.com/design/5NFYx1eLoNKzLxRMqbSh0l/XiuxianUI?m=auto&t=zZ0MxmVIsFqU5atg-6
- File key: `5NFYx1eLoNKzLxRMqbSh0l`

## Repository Layout

```text
xiuxian-game/
  AGENTS.md
  CLAUDE.md
  README.md
  docs/
    inbox/
      README.md
      修仙轮回沙盒_设计文档包_v2.3/
```

The repo is currently documentation-first. Do not invent engine, backend, database, or deployment implementation details beyond the current documents.

## Working Conventions

- Keep edits scoped to the user request and the current v2.3 design package.
- Preserve the existing document language. Current project design documents are primarily Chinese.
- Preserve Chinese project terminology in design docs unless a specific file clearly uses English.
- Prefer v2.3 field names such as `world_day`, `world_hour`, `hour_tick`, `macro_period_id`, `Command`, `CommandQueue`, `TimelineReplay`, `FormalEncounterState`, `SectContinuousActionState`, `ActionResourceInputBinding`, and `ActiveResourceEffect`.
- Avoid reintroducing old terms as active implementation concepts: `turn_id`, `quarter`, `action_slot`, `current_quarter`, `TurnReplay`, `QuarterReplay`, `SectDecisionIntent`, sect main-action input, or six lunar action slots.
- Keep design changes traceable to the v2.3 package or explicitly mark them as new decisions.
- If moving files out of `docs/inbox`, preserve source provenance and update this governance file.
- When updating governance, keep resource links, checked dates, and source precedence current.
- If the root Figma file moves, update the External Resource Index with the new URL, title, file key, and checked date.

## Useful Commands

```bash
ls docs
find docs/inbox -maxdepth 3 -type f
rg "world_day|world_hour|TimelineReplay|SectContinuousActionState" docs/inbox
```
