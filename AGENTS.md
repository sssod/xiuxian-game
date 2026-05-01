# AI Workspace Governance (AGENTS)

> Runtime: Codex CLI

## Scope

This file applies to the `xiuxian-game` project root.

## Primary Guidance

Use `CLAUDE.md` as the project governance source for purpose, current design contract, source-of-truth rules, and external resource locations.

Do not use files outside this project root as authority for this project.

## Current Project Inputs

Current local design package:

```text
docs/inbox/修仙轮回沙盒_设计文档包_v2.1/
```

Before changing product, design, UI, data, or implementation-facing docs, read the package `README.md` and the relevant v2.1 document for the subsystem being touched.

## External Resources

Notion current package entry:

- https://app.notion.com/p/352dffce59dc81659844f34177712f05

Figma current UI file:

- https://www.figma.com/design/5NFYx1eLoNKzLxRMqbSh0l/XiuxianUI?m=auto&t=zZ0MxmVIsFqU5atg-6

Known Figma nodes:

- Page `UI_TurnStart_InfoProcessing_v0.1`: `1:2`
- Frame `MainFrame_1920x1080_TurnStart_InfoProcessing`: `1:3`
- Frame `ComponentLibrary_TurnStart`: `1:4`

Use the Notion and Figma connectors to re-check these resources when a task depends on external context. If access fails, record that the external resource was not verified instead of guessing.

## Agent Conventions

- Keep edits scoped to the user request and the current v2.1 design package.
- Preserve Chinese project terminology in design docs unless a specific file clearly uses English.
- Prefer current v2.1 terms: `turn_id`, `world_day`, `world_hour`, `TurnReplay`, `SectContinuousActionState`.
- Do not reintroduce old active concepts such as `quarter`, `action_slot`, `QuarterReplay`, `SectDecisionIntent`, six lunar action slots, or player-submitted sect main actions unless explicitly documenting migration from old material.
- When updating governance, keep resource links, checked dates, and source precedence current.
