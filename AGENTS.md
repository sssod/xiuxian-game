# AI Workspace Governance (AGENTS)

> Runtime: Codex CLI

## Scope

This file applies to the `xiuxian-game` project root. Do not use files outside this project root as authority for this project.

`AGENTS.md` is the core governance file. `CLAUDE.md` is only a compatibility pointer; if the two conflict, follow `AGENTS.md`.

## Current Status

Checked on 2026-05-12.

The current formal design document package is:

- `docs/xiuxian_design_docs`

This package was promoted out of `docs/inbox` and is now the primary basis for design interpretation, MVP planning, and MVP implementation work. It can still be revised during development, but changes should support current design clarity and accepted gameplay decisions rather than recreate the previous reorganization phase or record implementation mechanics.

Current work mode is MVP development. Codex-side work should prioritize implementing, validating, and tightening the MVP against the formal design package. Documentation updates remain in scope when they clarify MVP behavior, record accepted design decisions, or surface implementation-blocking design gaps. Development details, technical implementation notes, smoke-test results, local tool decisions, and transient recovery strategies should stay outside the formal design package unless the user explicitly approves promoting them into design authority.

Current focus:

- Implement MVP slices against `docs/xiuxian_design_docs`.
- Use the formal package to derive runtime, Godot client, data, test, tooling, and acceptance work.
- Keep edits scoped to the MVP slice or user-requested task.
- Record or surface design gaps, stale-vs-active ambiguity, and non-mechanical choices instead of deciding silently.
- Treat historical documents as reference material only; accepted gameplay, numeric, UI, or worldbuilding details must be restated in the formal package or directly authorized by the user before driving implementation. Implementation details should instead be kept in development docs, code comments, tests, or commit/PR notes.

## Technical Stack Direction

The project is a Godot game project. MVP development and final production should use Godot as the primary playable client and runtime target, rather than building a separate Web application as the main MVP.

Target distribution is a desktop Steam release. Web browser distribution is not a product requirement, and technical choices should not be optimized around Godot Web export, browser compatibility, or Web-first deployment unless the user explicitly changes the target.

MVP UI may be low fidelity and should prioritize playable workflows, debug visibility, validation speed, and implementation clarity over final visual polish, animation quality, or high-fidelity layout matching.

Prefer a Godot-first architecture:

- Keep core gameplay rules, room state, time progression, command queues, settlement, result packages, save/load, and replay/debug records in testable runtime modules.
- Keep UI scenes thin; they should submit player intent, display authoritative state, and show result summaries rather than own settlement logic.
- Use local developer tooling where it improves validation, such as command-line runners, debug scenes, structured logs, replay viewers, or numeric simulation scripts.
- Local Godot environment checked on 2026-05-12: `/Applications/Godot.app/Contents/MacOS/Godot`, version `4.6.2.stable.official.71f334935`. `scripts/run_godot_smoke.sh` should prefer `GODOT_BIN`, then `godot4`, then `godot`, then this macOS app-bundle path.
- Godot may crash inside the Codex filesystem sandbox when it cannot write its normal `user://logs` files. If a Godot smoke or headless run fails with `user://logs` write errors under sandboxing, rerun the project smoke command outside the sandbox with `sh scripts/run_godot_smoke.sh`; this is the normal local verification path.
- Do not introduce a Web frontend solely for MVP speed. Web or script-based tools may be used only as local developer utilities, such as viewing exported JSON logs or balance reports, when they do not become the authoritative runtime.

Configuration and balance data should be data-driven. It is acceptable to edit configuration tables in local Excel workbooks during design and balancing, then export them into structured project formats such as CSV, JSON, TOML, or another Godot-friendly format chosen during implementation. The exported structured files, not the spreadsheet UI state, should be treated as runtime inputs.

Godot version, scripting language, test framework, data format, build pipeline, and local tooling should be chosen by implementation best practice for a desktop Steam Godot game, with decisions recorded when they affect maintainability, testing, save compatibility, or production workflow.

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
- Keep implementation notes, acceptance constraints, technical risks, and local validation records in `docs/development`, code-adjacent technical notes, tests, or tooling docs. Do not write implementation mechanics back into `docs/xiuxian_design_docs`.
- Update `docs/xiuxian_design_docs` only for stable gameplay, numeric, UI, terminology, or worldbuilding decisions that are design authority, preferably after explicit user confirmation.
- Do not update historical reference documents in `docs/inbox` as if they were active docs unless the user explicitly asks for archive maintenance.

## Documentation Rules

- Codex-side work should default to MVP implementation. Update development docs when tracking implementation progress, technical decisions, verification results, or local workflow details.
- Do not backfill development details into the formal design package. Examples that should not be written to `docs/xiuxian_design_docs` by default include class/module names, save/load implementation mechanics, smoke-runner behavior, local Godot paths, recovery implementation strategies, test outputs, and temporary scaffolding choices.
- Update `docs/xiuxian_design_docs` only when the change clarifies current design behavior, records a user-accepted gameplay/design decision, resolves a design conflict, or surfaces an implementation-blocking design gap. When in doubt, ask before editing the formal package.
- New persisted implementation documents, technical notes, schemas, configuration comments, and code comments should prefer English. Existing Chinese design documents may remain Chinese when preserving established design terminology, but implementation-facing documentation should default to English unless the user asks otherwise.
- The game must support at least Simplified Chinese and English. Formal design documents should remain primarily Chinese. For xiuxian-specific worldbuilding terms that do not yet have a good English localization, use a simple temporary translation first and keep the Chinese source meaning recoverable for later localization review.
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
