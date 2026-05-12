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

- Prefer one clear document per topic inside `docs/xiuxian_design_docs`.
- For new documents or structural revisions inside the package, follow `docs/xiuxian_design_docs/00_INDEX/文档模板与包内引用规范.md` for template choice and package-internal reference format.
- Preserve Chinese project terminology in design docs unless a file clearly uses English.
- Keep the formal package self-contained: documents inside the package may reference each other, but should not depend on outside files for interpretation.
- In leading chapters such as “设计定位”, “当前定位”, “当前结论”, and “当前状态”, emphasize current system responsibility, core design conclusions, player-facing purpose, and stable boundaries. Do not turn these chapters into historical convergence notes or lists of deprecated wording.
- Keep leading conclusion chapters concise. They should summarize the stable core in a small number of high-level points, not recreate the later document structure or repeat details that belong in rules, fields, formulas, UI, MVP, acceptance, migration, or maintenance sections.
- Historical convergence notes, old-field migration, deprecated terms, stale-vs-active explanations, and source-material cleanup should be placed in dedicated later sections such as “旧字段迁移”, “待裁决与待补”, or “维护记录”. A leading chapter may include a concise exclusion only when it is necessary to define the current boundary.
- Mark unresolved conflicts, stale-vs-active ambiguity, and non-mechanical design choices for user judgment.
- Record implementation implications as notes, acceptance constraints, risks, open questions, or technical decision gates when they are not immediately handled in the current MVP implementation task.
- Do not reintroduce deprecated terms as active concepts.
- Do not update historical canonical docs or the archived changelog under `docs/inbox/historical_reference_docs` unless the user explicitly asks to maintain historical references.
- Record only stable UI decisions in the formal package; node-level layout and component placement belong to the current UI artifact / Figma.

## External Resources

### Figma

Checked on 2026-05-07.

- Root file: `XiuxianUI`
- URL: https://www.figma.com/design/5NFYx1eLoNKzLxRMqbSh0l/XiuxianUI?m=auto&t=zZ0MxmVIsFqU5atg-6
- File key: `5NFYx1eLoNKzLxRMqbSh0l`

If the root Figma file moves, update this section with the new title, URL, file key, and checked date.
