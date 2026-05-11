# AI Workspace Governance (AGENTS)

> Runtime: Codex CLI

## Scope

This file applies to the `xiuxian-game` project root. Do not use files outside this project root as authority for this project.

`AGENTS.md` is the core governance file. `CLAUDE.md` is only a compatibility pointer; if the two conflict, follow `AGENTS.md`.

## Current Status

Checked on 2026-05-11.

The current document baseline is the reorganized package:

- `docs/inbox/xiuxian_design_reorganized_md`

This package is now the primary basis for design-document work, but it is not final. It still needs further human-led review, correction, trimming, deduplication, detail expansion, and internal cross-reference cleanup.

Current work mode is documentation revision and design calibration. Unless the user explicitly asks for implementation, do not modify gameplay, runtime, backend, frontend, database, deployment, or other source code.

Current focus:

- Refine documents in `docs/inbox/xiuxian_design_reorganized_md`.
- Fill missing details only when the basis is clear.
- Remove duplicated, stale, or low-value material under human direction.
- Improve naming consistency, topic boundaries, and internal references.
- Surface unresolved conflicts or design choices to the user instead of deciding silently.

## Source Precedence

When documents conflict, prefer this order:

```text
AGENTS.md
-> docs/inbox/xiuxian_design_reorganized_md
-> current UI artifact / Figma, only for node-level UI layout and component placement
-> docs/inbox materials outside docs/inbox/xiuxian_design_reorganized_md, reference only
-> docs other directories, including docs/index.md and formal docs, reference only
-> CLAUDE.md compatibility notes, reference only
```

Do not treat `docs/index.md`, formal docs under other `docs` directories, or non-package inbox files as current authority during this revision phase. They may help recover lost details, identify conflicts, or support manual review, but imported decisions must be restated inside `docs/inbox/xiuxian_design_reorganized_md`.

## Documentation Rules

- Prefer one clear document per topic inside `docs/inbox/xiuxian_design_reorganized_md`.
- For new documents or structural revisions inside the package, follow `docs/inbox/xiuxian_design_reorganized_md/00_INDEX/文档模板与包内引用规范.md` for template choice and package-internal reference format.
- Preserve Chinese project terminology in design docs unless a file clearly uses English.
- Keep the reorganized package self-contained: documents inside the package may reference each other, but should not depend on outside files for interpretation.
- In leading chapters such as “设计定位”, “当前定位”, “当前结论”, and “当前状态”, emphasize current system responsibility, core design conclusions, player-facing purpose, and stable boundaries. Do not turn these chapters into historical convergence notes or lists of deprecated wording.
- Historical convergence notes, old-field migration, deprecated terms, stale-vs-active explanations, and source-material cleanup should be placed in dedicated later sections such as “旧字段迁移”, “待裁决与待补”, or “维护记录”. A leading chapter may include a concise exclusion only when it is necessary to define the current boundary.
- Mark unresolved conflicts, stale-vs-active ambiguity, and non-mechanical design choices for user judgment.
- Record implementation implications as notes, acceptance constraints, risks, open questions, or technical decision gates unless implementation is explicitly requested.
- Do not reintroduce deprecated terms as active concepts.
- Do not update formal canonical docs or `docs/CHANGELOG.md` unless the user explicitly asks to resume formal-doc maintenance.
- Record only stable UI decisions in the reorganized package; node-level layout and component placement belong to the current UI artifact / Figma.

## External Resources

### Figma

Checked on 2026-05-07.

- Root file: `XiuxianUI`
- URL: https://www.figma.com/design/5NFYx1eLoNKzLxRMqbSh0l/XiuxianUI?m=auto&t=zZ0MxmVIsFqU5atg-6
- File key: `5NFYx1eLoNKzLxRMqbSh0l`

If the root Figma file moves, update this section with the new title, URL, file key, and checked date.
