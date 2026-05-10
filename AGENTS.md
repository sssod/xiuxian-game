# AI Workspace Governance (AGENTS)

> Runtime: Codex CLI

## Scope

This file applies to the `xiuxian-game` project root. Do not use files outside this project root as authority for this project.

`AGENTS.md` is the core governance file. `CLAUDE.md` is only a compatibility pointer; if the two conflict, follow `AGENTS.md`.

## Current Status

Checked on 2026-05-10.

The v2.3 document migration into formal `docs` sections is complete. 

Default entry points:

1. `docs/index.md` for the canonical document map.
2. Canonical docs listed by `docs/index.md` for active design, UI, systems, production, and reference decisions.
3. `docs/CHANGELOG.md` for canonical document change records.

Current work mode remains design finalization, documentation maintenance, and development handoff preparation. Unless the user explicitly asks for implementation, do not modify gameplay, runtime, backend, frontend, database, deployment, or other source code.

Current near-term focus is inbox design calibration: use `docs/inbox`, including `docs/inbox/xiuxian_design_reorganized_md`, and the extracted canonical design documents listed by `docs/index.md` to supplement and complete missing details, unify field names and design, and prepare the most accurate and up-to-date design baseline.

Source handling for the inbox calibration work:

- Canonical docs listed by `docs/index.md` have higher trust as extracted active design documents, but they may have lost details during extraction. Treat missing details, ambiguity, or uncertainty as expected calibration work, not as proof that the detail is invalid.
- Fill missing or ambiguous details from user-provided clarification and from `docs/inbox` when the source material does not create an unresolved conflict.
- `docs/inbox/xiuxian_design_reorganized_md` contains the documents previously targeted for calibration. Their information has value and should be treated as similar in trust level to other inbox files, while still checking for duplicated, stale, or conflicting statements.
- Special rule for calibrating `docs/inbox/xiuxian_design_reorganized_md`: this rule overrides the general source-handling bullets above only for the final written form of documents in this directory. During calibration, canonical docs, other inbox files, Figma, and external material may be consulted according to the normal source-handling rules. The calibrated documents in `docs/inbox/xiuxian_design_reorganized_md` must be self-contained after editing: any imported decision or detail must be restated directly in the document, and the document must not leave external source lists, citations, unresolved cross-document dependencies, or references that require material outside this directory to interpret.
- Pay special attention to `docs/inbox/修仙游戏设计方案总目录/[已过时]修仙游戏0424` and the four root-level inbox setting documents:
  - `docs/inbox/功法系统_收敛设定汇总_v0.4.md`
  - `docs/inbox/自适应流速可暂停日历制 v2：阶段性时间规则.md`
  - `docs/inbox/指令预输入机制 v1：阶段性规则文档.md`
  - `docs/inbox/修为修炼公式_资源输入与丹药药性处理补充_v0.2.md`
- These priority inbox sources were heavily edited with user involvement and should be treated as relatively high-trust detail sources, while still checking for outdated content.
- Across all files, any source conflict, conflicting duplicate statement, unresolved stale-vs-active distinction, or design choice that cannot be mechanically derived must be returned to the user for judgment and decision.

## Source Precedence

When documents conflict, prefer this order:

```text
AGENTS.md
-> docs/index.md and canonical docs listed there
-> current UI artifact / Figma, for node-level UI layout and component placement
-> CLAUDE.md compatibility notes
```

If a canonical document exists for a topic, update it instead of creating a parallel document. When canonical documents conflict, resolve the conflict in the relevant canonical document and record the decision in that document's source /裁决 section when appropriate.

## Documentation Rules

- Prefer one canonical document per topic in the formal docs.
- Preserve Chinese project terminology in design docs unless a file clearly uses English.
- Keep design changes traceable in the edited canonical document; explicitly mark new decisions when they are not simple restatements of existing canonical policy.
- Every change to canonical docs must be recorded in `docs/CHANGELOG.md` in the same work session, including design that do not add, delete, rename, split, or merge documents.
- Record implementation implications as notes, acceptance constraints, risks, open questions, or technical decision gates unless implementation is explicitly requested.
- Do not reintroduce deprecated terms as active concepts.
- Record only stable UI decisions in formal docs; node-level layout and component placement belong to the current UI artifact / Figma.

## External Resources

### Figma

Checked on 2026-05-07.

- Root file: `XiuxianUI`
- URL: https://www.figma.com/design/5NFYx1eLoNKzLxRMqbSh0l/XiuxianUI?m=auto&t=zZ0MxmVIsFqU5atg-6
- File key: `5NFYx1eLoNKzLxRMqbSh0l`

If the root Figma file moves, update this section with the new title, URL, file key, and checked date.
