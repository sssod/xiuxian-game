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

### Demo Development Exception

When the user explicitly asks for demo development, treat the demo as a design-validation prototype used to test and refine the v2.2 plan, interaction flow, data contracts, and settlement assumptions. Demo code does not mean the overall project has entered the formal production implementation phase.

Demo work should stay clearly scoped and separated from production assumptions:

- Keep demo runtime code, content fixtures, saves, replays, and debugging tools under an explicit demo directory.
- Prefer reversible Godot 4 / JSON prototypes that preserve v2.2 field names and settlement boundaries.
- Do not use demo shortcuts as authority to rewrite source-of-truth design docs unless the user explicitly requests a documentation update.
- Record implementation implications as demo findings, follow-up notes, or open questions instead of treating them as finalized architecture.

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

Use the v2.2 document package in `docs/inbox` as the current local source of truth:

```text
docs/inbox/修仙轮回沙盒_设计文档包_v2.2/
```

Start with:

1. `README.md`
2. `01_基础与总览/01_项目总览_MVP边界_系统依赖_v2.2.md`
3. `01_基础与总览/03_术语表_命名规范_字段统一_v2.2.md`
4. `03_实现交付/02_MVP开发切片与验收清单_v2.2.md`
5. `04_UIUX与效果图/01_UIUX需求方案_v2.2.md`
6. `04_UIUX与效果图/02_UI效果图生成Prompt速查_v2.2.md`

During high-frequency Figma UI iteration, do not maintain per-iteration "精修规格" document series unless explicitly requested. Use the current Figma artifact for node-level layout and component placement, and record only stable UI decisions in the v2.2 UI/UX documents.

When documents conflict, prefer this order:

```text
AGENTS.md
-> current Figma UI artifact, for node-level main UI layout / component placement
-> v2.2 UI/UX requirement document, for stable UI decisions
-> v2.2 terminology / field-unification document
-> v2.2 room turn / action economy / sect AI documents
-> v2.2 runtime state / migration table
-> other v2.2 system documents
-> older Notion or imported historical documents
-> CLAUDE.md compatibility notes
```

Before changing product, design, UI, data, or implementation-facing docs, read the package `README.md` and the relevant v2.2 document for the subsystem being touched.

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
- Learned methods come from complete method carriers; fragments / chapters are assets for synthesis, clues, permissions, or content delivery, not runtime learning progress.
- Dan pills, spiritual materials, talismans, and temporary boost resources enter settlement as action resource inputs such as `ActionResourceInputBinding`, not as a default standalone "丹药炼化" action.
- Unused consumed resource effects are represented by `ActiveResourceEffect` and can persist across turns according to residual policy.

## External Resource Index

Resource check dates are recorded per section.

### Notion

Checked on 2026-05-06.

Latest checked Notion package entry:

- `修仙轮回沙盒_设计文档包_v2.2`
- https://www.notion.so/358dffce59dc801790b1d4f6009d2a9e
- Contains mounted entries for `01_基础与总览`, `02_核心系统规格`, `03_实现交付`, `04_UIUX与效果图`, `README`, `MANIFEST`, and `QA_自动检查报告`.

Note: the v2.2 Notion parent page was repaired on 2026-05-06 from the `修仙轮回沙盒_设计文档包_v2.2 Import May 6, 2026` wrapper page. The blank original imported folder root is retained only under the zip import record as `修仙轮回沙盒_设计文档包_v2.2（原导入根，已归并）`.

Zip import / page mapping record:

- `Zip Import - 修仙轮回沙盒_设计文档包_v2.2.zip - May 6, 2026`
- https://www.notion.so/358dffce59dc818b9096fa160cb7933b
- Records the v2.2 zip import and source-file-to-Notion-page mappings.

Historical references:

- `[已过时]修仙轮回沙盒_设计文档包_v2.1`: https://www.notion.so/352dffce59dc81659844f34177712f05
- `Zip Import - 修仙轮回沙盒_设计文档包_v2.1.zip - Apr 30, 2026`: https://app.notion.com/p/352dffce59dc81489e33c21f3c5beb42
- `修仙轮回沙盒｜项目总览与顶层设计定案 0424`: https://app.notion.com/p/0c9dffce59dc83d49a4c8147a47b6b36
- `修仙轮回沙盒_UIUX需求最终方案_v1.1`: https://app.notion.com/p/351dffce59dc8062802cd14ff328e743

Treat historical Notion pages as traceability only when v2.2 is silent.

### Figma

Checked on 2026-05-04.

Current Figma UI file:

- `XiuxianUI`
- https://www.figma.com/design/5NFYx1eLoNKzLxRMqbSh0l/XiuxianUI?m=auto&t=zZ0MxmVIsFqU5atg-6
- File key: `5NFYx1eLoNKzLxRMqbSh0l`

Located page and frames:

- Current main UI page: `UI_MainFrame_Rebuild_v0.9`, node `89:2`
- State frame: `State_01_Prepare_InfoProcessing_1920x1080`, node `89:3`
- State frame: `State_02_Planning_WithContinuation_1920x1080`, node `89:124`
- State frame: `State_03_Planning_ContinuationCancelled_1920x1080`, node `89:288`
- State frame: `State_04_LockedWaiting_Readonly_1920x1080`, node `89:452`
- State frame: `State_05_AutopilotPreview_1920x1080`, node `89:583`
- State frame: `State_06_SidePanelsCollapsed_1920x1080`, node `89:725`
- Component page: `UI_MainFrame_Components_v0.9`, node `89:822`
- Component library frame: `ComponentLibrary_FilledSpec_v0.9`, node `93:2`
- Flow page: `UI_MainFrame_Flows_v0.9`, node `89:937`
- Flow detail frame: `Flow_DetailFill_v0.9`, node `96:2`
- Archived old page: `[archived]UI_TurnStart_InfoProcessing_v0.1`, node `1:2`

The current Figma artifact is the v0.9 rebuild of the large-world-map-driven turn action workbench. It contains six main UI state frames covering preparation, planning with continuation, planning after continuation cancellation, locked waiting, autopilot preview, and side-panel-collapsed layouts. Each state frame uses `MapViewport_FullWidth` for the map surface; node-level map connectivity is represented by `Map_RouteConnectivity_Essential_v0.9`, keeping only known passable routes, selected plan routes, and rumor / hidden routes as visible connection types.

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
      修仙轮回沙盒_设计文档包_v2.2/
```

The repo is currently documentation-first. Do not invent engine, backend, database, or deployment implementation details beyond the current documents.

## Working Conventions

- Keep edits scoped to the user request and the current v2.2 design package.
- Preserve the existing document language. Current project design documents are primarily Chinese.
- Preserve Chinese project terminology in design docs unless a specific file clearly uses English.
- Prefer v2.2 field names such as `turn_id`, `world_day`, `world_hour`, `hour_tick`, `macro_period_id`, `TurnReplay`, `SectContinuousActionState`, `ActionResourceInputBinding`, and `ActiveResourceEffect`.
- Avoid reintroducing old terms as active implementation concepts: `quarter`, `action_slot`, `current_quarter`, `QuarterReplay`, `SectDecisionIntent`, sect main-action input, or six lunar action slots.
- Keep design changes traceable to the v2.2 package or explicitly mark them as new decisions.
- If moving files out of `docs/inbox`, preserve source provenance and update this governance file.
- When updating governance, keep resource links, checked dates, and source precedence current.
- If Notion or Figma resources move, update the External Resource Index with the new URL, title, and checked date.

## Demo Test Notes

- Checked on 2026-05-06: Godot headless self-tests may need permission to write `user://logs` outside the workspace sandbox. A first sandboxed run can fail or crash while opening a Godot log file such as `user://logs/godot2026-05-06T21.10.09.log`; rerun the same headless command with approved escalation before treating it as a test failure.
- On 2026-05-06, after rerunning Godot headless with approved escalation, Phase A-E demo self-tests all passed.

## Useful Commands

```bash
ls docs
find docs/inbox -maxdepth 3 -type f
rg "turn_id|world_hour|SectContinuousActionState" docs/inbox
```
