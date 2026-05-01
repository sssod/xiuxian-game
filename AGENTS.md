# AI Workspace Governance (AGENTS)

> Runtime: Codex CLI

## Scope

This file applies to the `xiuxian-game` project root.

## Governance Precedence

`AGENTS.md` is the core governance file for this project.

`CLAUDE.md` is a compatibility follower for Claude Code and other agents that look for that filename. If `CLAUDE.md` and `AGENTS.md` conflict, follow `AGENTS.md`.

Do not use files outside this project root as authority for this project.

## Current Work Mode

The current project focus is design documentation iteration and Figma UI control refinement.

Default assumption: requests in this stage are documentation and design tasks, not engineering execution tasks, unless they explicitly mention coding, tests, runtime behavior, or source files.

Unless the user explicitly asks for implementation:

- Do not modify gameplay, runtime, backend, frontend, database, deployment, or other source code.
- Do not propose feature implementation as the default next step.
- Treat docs, Notion, Figma, terminology, interaction specs, data contracts, and UI component behavior as the primary work surface.
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

Use the v2.1 document package in `docs/inbox` as the current local source of truth:

```text
docs/inbox/修仙轮回沙盒_设计文档包_v2.1/
```

Start with:

1. `README.md`
2. `01_基础与总览/01_项目总览_MVP边界_系统依赖_v2.1.md`
3. `01_基础与总览/03_术语表_命名规范_字段统一_v2.1.md`
4. `03_实现交付/02_MVP开发切片与验收清单_v2.1.md`
5. `04_UIUX与效果图/01_UIUX需求方案_v2.1.md`

When documents conflict, prefer this order:

```text
AGENTS.md
-> v2.1 terminology / field-unification document
-> v2.1 room turn / action economy / sect AI documents
-> v2.1 runtime state / migration table
-> other v2.1 system documents
-> older Notion or imported historical documents
-> CLAUDE.md compatibility notes
```

Before changing product, design, UI, data, or implementation-facing docs, read the package `README.md` and the relevant v2.1 document for the subsystem being touched.

## Current Design Contract

- The player-facing minimum progression unit is `turn_id`, not `quarter`.
- Each turn has configurable duration; current default is 5 game days.
- UI presents a day-level turn time budget bar.
- Server settlement uses hour-level internal ticks such as `world_hour` / `hour_tick`.
- Players submit a small linear list of personal action instructions, not an hour-by-hour schedule.
- Client submits intent; authoritative validation, settlement, state mutation, logs, and replay data belong to the server-side settlement path.
- S1 / room authoritative settlement is the integration bus. Subsystems should output result packages and should not directly bypass the settlement bus to mutate world state.
- Sect gameplay is an organizational resource platform, not direct player control.
- MVP removes player sect instant commands, sect main-action suggestions, sect proposals, and sect decision phases.
- Each sect may have at most one active `SectContinuousActionState` at the same time, maintained by sect AI.
- Multiplayer competition is mainly indirect through sects, nodes, resources, rumors, visibility, and opportunity windows.

## External Resource Index

Checked on 2026-05-01.

### Notion

Current v2.1 package entry:

- `修仙轮回沙盒_设计文档包_v2.1`
- https://app.notion.com/p/352dffce59dc81659844f34177712f05
- Contains mounted entries for `01_基础与总览`, `02_核心系统规格`, `03_实现交付`, `04_UIUX与效果图`, `README`, `MANIFEST`, and `QA_自动检查报告`.

Zip import / page mapping record:

- `Zip Import - 修仙轮回沙盒_设计文档包_v2.1.zip - Apr 30, 2026`
- https://app.notion.com/p/352dffce59dc81489e33c21f3c5beb42
- Records the original zip import and source-file-to-Notion-page mappings.

Historical references:

- `修仙轮回沙盒｜项目总览与顶层设计定案 0424`: https://app.notion.com/p/0c9dffce59dc83d49a4c8147a47b6b36
- `修仙轮回沙盒_UIUX需求最终方案_v1.1`: https://app.notion.com/p/351dffce59dc8062802cd14ff328e743

Treat historical Notion pages as traceability only when v2.1 is silent.

### Figma

Current Figma UI file:

- `XiuxianUI`
- https://www.figma.com/design/5NFYx1eLoNKzLxRMqbSh0l/XiuxianUI?m=auto&t=zZ0MxmVIsFqU5atg-6
- File key: `5NFYx1eLoNKzLxRMqbSh0l`

Located page and frames:

- Page: `UI_TurnStart_InfoProcessing_v0.1`, node `1:2`
- Main UI frame: `MainFrame_1920x1080_TurnStart_InfoProcessing`, node `1:3`
- Component frame: `ComponentLibrary_TurnStart`, node `1:4`

The current Figma artifact represents the turn-start / information-processing state of the large-world-map-driven turn action workbench. It includes the top phase bar, left pending changes center, central world map canvas, right context and goal panel, bottom turn time budget bar, and a local component library for stage chips, node markers, info cards, buttons, day budget segments, layer toggles, status pills, and tags.

Subscribed libraries observed in the file include Material 3 Design Kit, Simple Design System, and Apple platform UI kits. Do not assume these are the project's own design system unless a specific Figma node uses them.

Use the Notion and Figma connectors to re-check these resources when a task depends on external context. If access fails, record that the external resource was not verified instead of guessing.

## Repository Layout

```text
xiuxian-game/
  AGENTS.md
  CLAUDE.md
  README.md
  docs/
    inbox/
      README.md
      修仙轮回沙盒_设计文档包_v2.1/
```

The repo is currently documentation-first. Do not invent engine, backend, database, or deployment implementation details beyond the current documents.

## Working Conventions

- Keep edits scoped to the user request and the current v2.1 design package.
- Preserve the existing document language. Current project design documents are primarily Chinese.
- Preserve Chinese project terminology in design docs unless a specific file clearly uses English.
- Prefer v2.1 field names such as `turn_id`, `world_day`, `world_hour`, `hour_tick`, `macro_period_id`, `TurnReplay`, and `SectContinuousActionState`.
- Avoid reintroducing old terms as active implementation concepts: `quarter`, `action_slot`, `current_quarter`, `QuarterReplay`, `SectDecisionIntent`, sect main-action input, or six lunar action slots.
- Keep design changes traceable to the v2.1 package or explicitly mark them as new decisions.
- If moving files out of `docs/inbox`, preserve source provenance and update this governance file.
- When updating governance, keep resource links, checked dates, and source precedence current.
- If Notion or Figma resources move, update the External Resource Index with the new URL, title, and checked date.

## Useful Commands

```bash
ls docs
find docs/inbox -maxdepth 3 -type f
rg "turn_id|world_hour|SectContinuousActionState" docs/inbox
```
