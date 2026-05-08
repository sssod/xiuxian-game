# AI Workspace Governance (AGENTS)

> Runtime: Codex CLI

## Scope

This file applies to the `xiuxian-game` project root.

## Governance Precedence

`AGENTS.md` is the core governance file for this project.

`CLAUDE.md` is a compatibility follower for Claude Code and other agents that look for that filename. If `CLAUDE.md` and `AGENTS.md` conflict, follow `AGENTS.md`.

Do not use files outside this project root as authority for this project.

## Current Work Mode

The current project focus is design finalization, document consolidation, and development handoff preparation.

The project is transitioning from multiple historical design drafts in `docs/inbox` into a curated, implementation-facing documentation set under the formal `docs` sections.

Default assumption: requests in this stage are documentation and design tasks, not engineering execution tasks, unless they explicitly mention coding, tests, runtime behavior, or source files.

Unless the user explicitly asks for implementation:

- Do not modify gameplay, runtime, backend, frontend, database, deployment, or other source code.
- Do not propose feature implementation as the default next step; prepare design, data, UI, and delivery documents for implementation instead.
- Treat document extraction, deduplication, conflict resolution, terminology cleanup, interaction specs, data contracts, acceptance criteria, and source provenance as the primary work surface.
- Prefer editing or creating curated documents under `docs/concept`, `docs/game-design`, `docs/systems-design`, `docs/ui-design`, `docs/worldbuilding`, `docs/production`, `docs/references`, `docs/research`, and `docs/playtest` instead of rewriting raw inbox exports.
- Keep responses concise and avoid broad codebase exploration unless it is needed to consolidate or update an implementation-facing document.
- If implementation implications appear, record them as implementation notes, acceptance constraints, risks, or open questions instead of editing code.

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

## Current Source Management

`docs/inbox` is the raw source archive. It contains multiple historical drafts, imported Notion exports, supplemental notes, and obsolete packages. Use it as evidence and source material, not as the long-term destination for finalized documents.

The current latest raw design source is the v2.3 document package exported under:

```text
docs/inbox/修仙游戏设计方案总目录/修仙轮回沙盒_设计文档包_v2 3/
```

The exported filenames include Notion-style spaces and IDs. Locate files by document title when needed. Start with:

1. `README.md`
2. `01_基础与总览/01_项目总览_MVP边界_系统依赖_v2.3.md`
3. `01_基础与总览/03_术语表_命名规范_字段统一_v2.3.md`
4. `02_核心系统规格/01_共享日历_房间推进_权威结算_v2.3.md`
5. `03_实现交付/02_MVP开发切片与验收清单_v2.3.md`
6. `04_UIUX与界面规范/01_UIUX需求方案_v2.3.md`
7. `02_核心系统规格/08_事件突破战斗时间规则_v2.3.md`

During consolidation, extract stable decisions from inbox sources, remove duplicate and obsolete text, resolve conflicts explicitly, and place the cleaned result in the appropriate formal `docs` section. Preserve source provenance either in the document itself or in a nearby index / source note.

Do not treat older inbox packages, archived historical drafts, or files marked `[已过时]` as active authority. Use them only for comparison, recovery of missing rationale, or conflict analysis.

During high-frequency UI iteration, do not maintain per-iteration "精修规格" document series unless explicitly requested. Use the current UI artifact for node-level layout and component placement, and record only stable UI decisions in the formal UI docs or, before promotion, the v2.3 UI/UX source document.

When documents conflict, prefer this order:

```text
AGENTS.md
-> finalized docs outside docs/inbox, for subsystems that have already been consolidated
-> current UI artifact, for node-level main UI layout / component placement
-> v2.3 UI/UX requirement document, for stable UI decisions not yet promoted
-> v2.3 terminology / field-unification document
-> v2.3 shared calendar / command queue / event breakthrough combat / sect AI documents
-> v2.3 runtime state / data model / result package documents
-> other v2.3 system documents
-> supplemental inbox notes explicitly aligned with v2.3
-> older imported historical documents and files marked [已过时]
-> CLAUDE.md compatibility notes
```

Before changing product, design, UI, data, or implementation-facing docs, read the v2.3 package README and the relevant v2.3 document for the subsystem being touched. If a formal document already exists outside `docs/inbox` for that subsystem, read it first and update it instead of creating a parallel document.

## Documentation Consolidation Rules

- Keep `docs/inbox` as an archive of source inputs unless the user explicitly asks to reorganize the archive itself.
- Move finalized, deduplicated content into the formal `docs` sections according to document purpose:
  - `docs/concept`: project pitch, pillars, fantasy, player promise, high-level experience.
  - `docs/game-design`: player loops, room flow, progression, action rules, failure, reincarnation.
  - `docs/systems-design`: simulation systems, economy, cultivation, character state, room state, multiplayer contracts, data-facing system rules.
  - `docs/ui-design`: screen inventory, interaction states, UI flows, Figma references, component behavior.
  - `docs/worldbuilding`: setting, sects, locations, factions, lore-facing terminology.
  - `docs/production`: MVP scope, milestones, acceptance checklists, delivery plans, risk register, technical decision gates.
  - `docs/references`: source maps, glossary snapshots, field indexes, external references, provenance records.
  - `docs/research`: research notes and comparative analysis that are not final design commitments.
  - `docs/playtest`: playtest plans, feedback, observations, tuning notes.
- Prefer one canonical document per topic in the formal docs. If a new document overlaps an existing one, merge or update the existing document instead of duplicating it.
- When resolving conflicts, state the chosen rule, the rejected / deprecated alternatives, and the reason if it matters for implementation.
- Keep obsolete terms visible only as deprecated aliases, migration notes, or conflict history. Do not reintroduce them as active design concepts.
- When a subsystem is promoted out of `docs/inbox`, update relevant indexes or README files so future work starts from the formal document, not the raw export.

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
    concept/
    game-design/
    inbox/
      README.md
      修仙游戏设计方案总目录/
        修仙轮回沙盒_设计文档包_v2 3/
    playtest/
    production/
    references/
    research/
    systems-design/
    ui-design/
    worldbuilding/
```

The repo is currently documentation-first and entering development handoff. Do not invent engine, backend, database, or deployment implementation details beyond the current documents; record unresolved choices as technical decision gates.

## Working Conventions

- Keep edits scoped to the user request and the current v2.3 design package.
- Preserve the existing document language. Current project design documents are primarily Chinese.
- Preserve Chinese project terminology in design docs unless a specific file clearly uses English.
- Prefer clear canonical document titles without Notion export IDs for new formal docs.
- Prefer v2.3 field names such as `world_day`, `world_hour`, `hour_tick`, `macro_period_id`, `Command`, `CommandQueue`, `TimelineReplay`, `FormalEncounterState`, `SectContinuousActionState`, `ActionResourceInputBinding`, and `ActiveResourceEffect`.
- Avoid reintroducing old terms as active implementation concepts: `turn_id`, `quarter`, `action_slot`, `current_quarter`, `TurnReplay`, `QuarterReplay`, `SectDecisionIntent`, sect main-action input, or six lunar action slots.
- Keep design changes traceable to the v2.3 package or explicitly mark them as new decisions.
- If moving or extracting files out of `docs/inbox`, preserve source provenance and update relevant docs indexes. Update this governance file only when source precedence, repository layout, or work mode changes.
- When updating governance, keep resource links, checked dates, and source precedence current.
- If the root Figma file moves, update the External Resource Index with the new URL, title, file key, and checked date.

## Useful Commands

```bash
ls docs
find docs/inbox -maxdepth 3 -type f
rg --files docs
rg "world_day|world_hour|TimelineReplay|SectContinuousActionState" docs/inbox
```
