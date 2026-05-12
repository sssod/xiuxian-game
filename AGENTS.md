# AI Workspace Governance (AGENTS)

> Runtime: Codex CLI

## Scope

This file applies to the `xiuxian-game` project root. Do not use files outside this project root as authority for this project.

`AGENTS.md` is the core governance file. `CLAUDE.md` is only a compatibility pointer; if the two conflict, follow `AGENTS.md`.

## Current Status

Checked on 2026-05-12.

The current formal design document package is:

- `docs/xiuxian_design_docs`

This package was promoted out of `docs/inbox` and is now the primary basis for design interpretation, MVP planning, and MVP implementation work. It can still be revised during development, but changes should support current design clarity and implementation decisions rather than recreate the previous reorganization phase.

Current work mode is MVP development. Codex-side work should prioritize implementing, validating, and tightening the MVP against the formal design package. Documentation updates remain in scope when they clarify MVP behavior, record accepted decisions, or surface implementation-blocking gaps.

Current focus:

- Implement MVP slices against `docs/xiuxian_design_docs`.
- Use the formal package to derive runtime, backend, frontend, data, test, and acceptance work.
- Keep edits scoped to the MVP slice or user-requested task.
- Record or surface design gaps, stale-vs-active ambiguity, and non-mechanical choices instead of deciding silently.
- Treat historical documents as reference material only; accepted details must be restated in the formal package or directly authorized by the user before driving implementation.

## Source Precedence

When documents conflict, prefer this order:

```text
AGENTS.md
-> docs/xiuxian_design_docs
-> current UI artifact / Figma, only for node-level UI layout and component placement
-> docs/inbox/historical_reference_docs and other docs/inbox materials, reference only
-> CLAUDE.md compatibility notes, reference only
```

Do not treat old `docs/index.md`, old `docs/CHANGELOG.md`, formerly canonical docs under `docs/inbox/historical_reference_docs`, or other non-package inbox files as current authority. They may help recover lost details, identify conflicts, or support manual review, but imported decisions must be restated inside `docs/xiuxian_design_docs` or explicitly confirmed by the user before implementation depends on them.

## MVP Development Rules

- Before implementing a slice, identify the relevant formal-package documents and use them as the design contract.
- If the formal package is silent or internally conflicted on a behavior that affects implementation, ask for user judgment or record a narrow design gate before coding around it.
- Prefer small vertical MVP increments with tests or runnable verification over broad infrastructure rewrites.
- Keep implementation notes, acceptance constraints, risks, and design deltas close to the relevant formal-package topic when documentation needs to change.
- Do not update historical reference documents in `docs/inbox` as if they were active docs unless the user explicitly asks for archive maintenance.

## Documentation Rules

- Codex-side work should default to MVP implementation. Update docs only when the change clarifies MVP behavior, records an accepted decision, or surfaces an implementation-blocking gap.
- For package structure, templates, terminology, package-internal references, leading-section style, stale-content handling, and historical-material handling, follow `docs/xiuxian_design_docs/00_INDEX/文档模板与包内引用规范.md`.
- For ChatGPT Web Library upload/download round-trips, follow `docs/xiuxian_design_docs/00_INDEX/ChatGPT_Library同步与扁平导入导出规范.md`.
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
