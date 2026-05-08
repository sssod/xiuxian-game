# AI Workspace Governance (AGENTS)

> Runtime: Codex CLI

## Scope

This file applies to the `xiuxian-game` project root. Do not use files outside this project root as authority for this project.

`AGENTS.md` is the core governance file. `CLAUDE.md` is only a compatibility pointer; if the two conflict, follow `AGENTS.md`.

## Current Status

Checked on 2026-05-08.

The v2.3 document migration into formal `docs` sections is complete. `docs/references/document-consolidation-plan.md` records “第三批迁移完成” and “第三批剩余建议迁移：无”.

Default entry points:

1. `docs/index.md` for the canonical document map.
2. Formal docs outside `docs/inbox` for active design, UI, systems, production, and reference decisions.
3. `docs/inbox` only as raw source archive, provenance evidence, conflict history, or recovery material.

Current work mode remains design finalization, documentation maintenance, and development handoff preparation. Unless the user explicitly asks for implementation, do not modify gameplay, runtime, backend, frontend, database, deployment, or other source code.

## Project Purpose

`xiuxian-game` is a design-stage independent game project for a room-based multiplayer xiuxian reincarnation sandbox. The player controls a cross-life true-spirit identity, not a sect, nation, or fixed character.

```text
MVP target: local single-player testing, privately deployable server,
3-player room co-op / indirect competition, save / pause / resume,
M0 -> M3 vertical gameplay loop.
```

## Source Precedence

When documents conflict, prefer this order:

```text
AGENTS.md
-> docs/index.md and formal docs outside docs/inbox
-> current UI artifact / Figma, for node-level UI layout and component placement
-> v2.3 raw package, for provenance checks or gaps not yet covered by formal docs
-> supplemental inbox notes explicitly aligned with v2.3
-> older imported historical documents and files marked [已过时]
-> CLAUDE.md compatibility notes
```

Latest raw design source:

```text
docs/inbox/修仙游戏设计方案总目录/修仙轮回沙盒_设计文档包_v2 3/
```

If a formal document exists for a topic, update it instead of creating a parallel document or editing the inbox export. Read the v2.3 README and relevant raw source when resolving conflicts, checking provenance, or filling a gap not already covered by the formal docs.

## Documentation Rules

- Keep `docs/inbox` as an archive unless the user explicitly asks to reorganize it.
- Prefer one canonical document per topic in the formal docs.
- Preserve Chinese project terminology in design docs unless a file clearly uses English.
- Keep design changes traceable to the v2.3 package or explicitly mark them as new decisions.
- Record implementation implications as notes, acceptance constraints, risks, open questions, or technical decision gates unless implementation is explicitly requested.
- Do not reintroduce deprecated terms as active concepts.
- Record only stable UI decisions in formal docs; node-level layout and component placement belong to the current UI artifact / Figma.

## Current Design Contract

Active implementation-facing terms and rules:

```text
shared continuous world calendar
world_day / world_hour
hour_tick
F1 / N1 / B1 / P0
C1
Command / CommandQueue
TimelineReplay
FormalEncounterState
SectContinuousActionState
ActionResourceInputBinding
ActiveResourceEffect
```

Key commitments:

- Server settlement uses 1-hour `hour_tick` through the authoritative settlement path.
- Players submit a small linear `CommandQueue`, not an hour-by-hour schedule.
- Client submits intent; authoritative validation, mutation, logs, result packages, and replay data belong to server settlement.
- S1 / room authoritative settlement is the integration bus; subsystems output result packages instead of bypassing it.
- Sect gameplay is an organizational resource platform, not direct sect control by the player.
- Multiplayer competition is mainly indirect through sects, nodes, resources, rumors, visibility, and opportunity windows.
- Formal combat and breakthrough challenges use `FormalEncounterState` in B1; one B1 round equals 1 game hour.

Deprecated active concepts:

```text
turn_id
quarter
action_slot
current_quarter
TurnReplay
QuarterReplay
SectDecisionIntent
sect main-action input
six lunar action slots
```

## External Resources

### Figma

Checked on 2026-05-07.

- Root file: `XiuxianUI`
- URL: https://www.figma.com/design/5NFYx1eLoNKzLxRMqbSh0l/XiuxianUI?m=auto&t=zZ0MxmVIsFqU5atg-6
- File key: `5NFYx1eLoNKzLxRMqbSh0l`

If the root Figma file moves, update this section with the new title, URL, file key, and checked date.
