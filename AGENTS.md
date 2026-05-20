# AI Workspace Governance (AGENTS)

> Runtime: Codex CLI

## Scope

This file applies to the `xiuxian-game` project root. Do not use files outside this project root as authority for this project.

`AGENTS.md` is the core governance file. `CLAUDE.md` is only a compatibility pointer; if the two conflict, follow `AGENTS.md`.

## Current Status

Checked on 2026-05-20.

The current formal design document package is:

- `docs/xiuxian_design_docs`

This package was promoted out of `docs/inbox` and is now the primary basis for design interpretation, MVP planning, and any later implementation work.

Current work mode is design package correction. The MVP development state reached before this date is locked for now: do not continue gameplay, runtime, client, tooling, test, or balance implementation unless the user explicitly unlocks development or requests a narrow maintenance action.

Current focus:

- Review, repair, and tighten `docs/xiuxian_design_docs` as the current design authority.
- Clarify gameplay, numeric, UI, terminology, and worldbuilding decisions.
- Resolve package-internal conflicts, stale-vs-active ambiguity, missing references, and design gates.
- Keep the formal package self-contained. Adopted details from historical materials must be restated in the formal package or directly authorized by the user.
- Surface unresolved non-mechanical choices for user judgment instead of deciding silently.
- Keep implementation mechanics out of the formal package unless the user explicitly promotes them into design authority.

## Technical Stack Direction

The product target remains a Godot desktop game for Steam. Web browser distribution is not a product requirement. While development is frozen, this section is only a future-implementation constraint, not a work queue.

## Source Precedence

When documents conflict, prefer this order:

```text
AGENTS.md
-> docs/xiuxian_design_docs
-> current UI artifact / Figma, only for node-level UI layout and component placement
-> docs/inbox/historical_reference_docs and other docs/inbox materials, reference only
-> CLAUDE.md compatibility notes, reference only
```

Do not treat old `docs/index.md`, old `docs/CHANGELOG.md`, formerly canonical docs under `docs/inbox/historical_reference_docs`, or other non-package inbox files as current authority. They may help recover lost details, identify conflicts, or support manual review, but imported decisions must be restated inside `docs/xiuxian_design_docs` or explicitly confirmed by the user before the active design package or any later implementation depends on them.

## Development Freeze

- Do not implement new MVP slices, runtime systems, Godot scenes, tests, tools, exports, or balance pipelines unless the user explicitly resumes development.
- Treat existing development artifacts as a locked snapshot. Read them only as context for design-package repair or user-requested maintenance.
- If a design-package fix reveals a future implementation issue, record it as a design gap or development note instead of coding around it.

## Documentation Rules

- Codex-side work should default to design-package correction until the user resumes development.
- Update `docs/xiuxian_design_docs` when the change clarifies current design behavior, records a user-accepted gameplay/design decision, resolves a design conflict, or surfaces a future implementation-blocking design gap. When in doubt, ask before editing the formal package.
- Do not backfill implementation mechanics into the formal design package.
- New persisted implementation-facing notes should prefer English. Existing Chinese design documents may remain Chinese when preserving established design terminology.
- The game must support at least Simplified Chinese and English. Formal design documents should remain primarily Chinese. For xiuxian-specific worldbuilding terms that do not yet have a good English localization, use a simple temporary translation first and keep the Chinese source meaning recoverable for later localization review.
- For package structure, templates, terminology, package-internal references, leading-section style, stale-content handling, and historical-material handling, follow `docs/xiuxian_design_docs/00_INDEX/文档模板与包内引用规范.md`.
- Keep `docs/xiuxian_design_docs` self-contained. Package-external materials are references only; adopted details must be restated in the formal package or directly authorized by the user.
- Mark unresolved conflicts, stale-vs-active ambiguity, and non-mechanical design choices for user judgment instead of deciding silently.
- Do not update historical reference documents in `docs/inbox` unless the user explicitly asks for archive maintenance.
- Record only stable UI decisions in the formal package; node-level layout and component placement belong to the current UI artifact / Figma.

## External Resources

### Figma

Checked on 2026-05-07.

- Root file: `XiuxianUI`
- URL: https://www.figma.com/design/5NFYx1eLoNKzLxRMqbSh0l/XiuxianUI?m=auto&t=zZ0MxmVIsFqU5atg-6
- File key: `5NFYx1eLoNKzLxRMqbSh0l`

If the root Figma file moves, update this section with the new title, URL, file key, and checked date.
