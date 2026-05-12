# MVP Development Plan

Status date: 2026-05-12  
Primary scope: single-player Godot MVP  
Document location: `docs/development`  
Design authority: `docs/xiuxian_design_docs`

This is an implementation planning document, not a formal design-package document. It intentionally does not follow the design-package document template, and it must stay outside `docs/xiuxian_design_docs` so formal design exports do not include development planning material.

The plan may reference the formal design package, but it is not a gameplay authority. If implementation work creates a stable gameplay, numeric, UI, save-format, or production-workflow decision, record that accepted decision in the relevant formal design document.

## Current Decision

The first MVP phase is single-player only.

This means MVP-1 includes:

1. Local single-player room creation, save, load, and recovery.
2. One player-controlled true-spirit / current-life character.
3. Local world time progression, command queue, settlement, logs, replay, and debug output.
4. Cultivation, movement, resources, events, combat, breakthrough, reincarnation, and lightweight sect support where those systems are needed for the single-player loop.
5. Low-fidelity Godot UI focused on playability, state visibility, validation, and debugging.

MVP-1 excludes:

1. Multiplayer room creation, player slots, network transport, reconnect, host migration, lobby flow, and cross-player visibility filtering.
2. Direct PvP, player trading, co-op breakthrough support, co-op exploration, and same-sect multiplayer governance.
3. Steam networking, relay service integration, matchmaking, or public/private online room deployment.
4. Web-first client work.
5. Final art, final UI layout fidelity, animation polish, and broad content volume.

Multiplayer remains a later phase. MVP-1 should still keep deterministic settlement, replay records, save boundaries, and authority separation clean enough that a later multiplayer layer can be added without rewriting core gameplay rules.

## Target Outcome

MVP-1 is complete when a local player can:

1. Start a Godot desktop build, create a new single-player room, and initialize a true spirit and current-life character.
2. Advance world time through a short command queue with at most three queued future commands.
3. Move between map nodes, consume time and vital resources, and receive result logs.
4. Cultivate from early progression into at least two major-breakthrough chains, with success, failure-survival, and death-reincarnation outcomes represented.
5. Encounter at least one route event, one node/resource event, one formal combat, and one breakthrough challenge.
6. Use a minimal inventory/resource flow for cultivation inputs, basic materials, and sect support.
7. Save, quit, reload, and recover all authoritative state needed to continue.
8. Review personal logs, public-style summaries, debug traces, and replay records from deterministic test seeds.

## Timeline

The schedule starts on 2026-05-12 and assumes focused part-time-to-full-time development by one primary implementer. Dates are planning targets, not release commitments. If a milestone slips by more than three working days, update this table and the progress tracker.

| Milestone | Calendar Window | Duration | Target Status |
| --- | --- | ---: | --- |
| P0 Planning Reset | 2026-05-12 to 2026-05-15 | 4 days | In progress |
| P1 Godot Foundation | 2026-05-16 to 2026-05-29 | 2 weeks | Not started |
| P2 Single-Player Room, Time, Save | 2026-05-30 to 2026-06-12 | 2 weeks | Not started |
| P3 Character, Realm, Command, Cultivation | 2026-06-13 to 2026-07-03 | 3 weeks | Not started |
| P4 Map, Movement, Resources, Inventory | 2026-07-04 to 2026-07-17 | 2 weeks | Not started |
| P5 Events, Combat, Breakthrough, Reincarnation | 2026-07-18 to 2026-08-07 | 3 weeks | Not started |
| P6 Sect-Lite, UI Integration, Validation | 2026-08-08 to 2026-08-21 | 2 weeks | Not started |
| P7 MVP-1 Stabilization | 2026-08-22 to 2026-09-04 | 2 weeks | Not started |
| MVP-1 Review Gate | 2026-09-05 to 2026-09-08 | 4 days | Not started |

## Execution Progress

Progress is tracked by runnable output, not by document completion.

| Track | Status | Progress | Done | Next Action | Blocking Issues |
| --- | --- | ---: | --- | --- | --- |
| Planning reset | In progress | 40% | MVP plan moved outside design package; first phase narrowed to single-player | Confirm Godot version, scripting language, test runner, and config format | Technical decisions not recorded yet |
| Godot project foundation | Not started | 0% | No Godot project exists in the repo | Create project skeleton and debug boot scene | Need engine/version decision |
| Runtime architecture | Not started | 0% | Target runtime modules identified | Implement room/time/result package smoke runner | Needs project foundation |
| Single-player room/save | Not started | 0% | Design references identified | Implement local room creation, save, load, recovery | Needs runtime skeleton |
| Character/realm/cultivation | Not started | 0% | Design references identified | Implement true-spirit/current-life initialization and CP progression | Needs room/save skeleton |
| Map/movement/resources | Not started | 0% | Design references identified | Implement node graph, travel command, and minimal resource slot | Needs command settlement |
| Events/combat/breakthrough | Not started | 0% | Design references identified | Implement deterministic event trigger and one B1 combat path | Needs character bars and command settlement |
| UI integration | Not started | 0% | Low-fidelity UI direction accepted | Build title/debug/main/cultivation/command views | Needs runtime state APIs |
| Validation/replay | Not started | 0% | Replay/debug requirement accepted | Add fixed-seed test scenarios | Needs core loop |
| Multiplayer | Deferred | 0% | Explicitly moved out of MVP-1 | Revisit after single-player MVP review | Out of current scope |

## Milestone Details

### P0. Planning Reset

Window: 2026-05-12 to 2026-05-15  
Goal: make the implementation plan actionable and single-player focused.

Deliverables:

1. This English-first development plan.
2. Single-player MVP boundary recorded clearly.
3. Open technical choices listed as decision gates.
4. First implementation slice selected.

Exit criteria:

1. The plan no longer lives inside `docs/xiuxian_design_docs`.
2. The plan no longer depends on the formal design document template.
3. MVP-1 scope explicitly excludes multiplayer.
4. The first coding task is ready to start without additional design restructuring.

### P1. Godot Foundation

Window: 2026-05-16 to 2026-05-29  
Goal: create a runnable Godot project with a testable runtime shell.

Deliverables:

1. Godot project files and a minimal desktop startup scene.
2. Debug boot screen showing build/version, config load status, and fixed seed.
3. Runtime module skeletons for room, world time, character, command, settlement, data, save, replay, and UI adapters.
4. A command-line or headless smoke runner that creates an empty local room, advances one world hour, and emits a result package.
5. Project technical decisions recorded in a development note or the top of this plan.

Exit criteria:

1. One local command runs the smoke test.
2. Godot can launch into a debug scene.
3. Config loading, fixed-seed random, structured logging, and result-package creation have working stubs.

Design references:

1. `../xiuxian_design_docs/02_系统设计/01_流程设计/01_单人游戏与多人共玩流程.md`
2. `../xiuxian_design_docs/04_交互设计/01_游戏启动首页设计.md`
3. `../xiuxian_design_docs/04_交互设计/02_游戏主界面设计.md`

### P2. Single-Player Room, Time, Save

Window: 2026-05-30 to 2026-06-12  
Goal: make a local single-player room authoritative and recoverable.

Deliverables:

1. Local single-player room model with room id, world seed, current world day/hour, save version, and active state.
2. N1 and F1 time progression for deterministic settlement.
3. Result package, visible log, debug trace, and replay segment structures.
4. Save, load, version check, and recovery for interrupted settlement states.
5. Low-fidelity title/debug/main screen flow for new room, continue, and diagnostic load failure.

Exit criteria:

1. A new local room can be created, advanced, saved, loaded, and advanced again.
2. F1 uses repeated tick settlement and does not skip log or replay creation.
3. Save/load preserves world time, seed, room mode, and result history.

Scope note:

MVP-1 room mode is local single-player only. Multiplayer player-slot rules are not implemented in this milestone.

### P3. Character, Realm, Command, Cultivation

Window: 2026-06-13 to 2026-07-03  
Goal: make a character playable through the basic cultivation loop.

Deliverables:

1. True-spirit and current-life character initialization.
2. Character attributes, lifespan, age, innate spiritual root result, life/qi/spirit bars, current values, and reserve constraints.
3. Realm and segment progress from Qi Refining through the MVP target range, backed by configurable CP thresholds.
4. Current command plus three queued commands, enqueue validation, execution validation, failure fallback, and explicit low-value auto fallback.
5. Active breathing/cultivation, seclusion, auto-circulation, method study, foundation consolidation, and recovery as minimal command templates.
6. Cultivation tick result, resource input binding, residual effect records, personal logs, and replay output.
7. Low-fidelity character, cultivation, and command management views.

Exit criteria:

1. The player can initialize a character and see state in UI.
2. The player can queue cultivation commands and advance CP.
3. Command failure produces a fallback result and does not silently mutate state.
4. Cultivation pills or resources only work through explicit command resource input, not instant-use shortcuts.
5. Major breakthrough is not automatically completed by reaching a CP threshold.

Design references:

1. `../xiuxian_design_docs/02_系统设计/01_流程设计/02_真灵初始化与角色初始化流程.md`
2. `../xiuxian_design_docs/02_系统设计/02_角色与真灵设计/02_角色属性.md`
3. `../xiuxian_design_docs/02_系统设计/02_角色与真灵设计/03_角色修为与境界.md`
4. `../xiuxian_design_docs/02_系统设计/09_行动指令设计.md`
5. `../xiuxian_design_docs/02_系统设计/11_修炼玩法设计.md`
6. `../xiuxian_design_docs/03_数值设计/01_修为境界与期望游玩时间建模.md`
7. `../xiuxian_design_docs/03_数值设计/02_修炼公式与数值设计.md`
8. `../xiuxian_design_docs/03_数值设计/09_角色属性与派生状态数值设计.md`
9. `../xiuxian_design_docs/04_交互设计/03_角色页面设计.md`
10. `../xiuxian_design_docs/04_交互设计/04_修为页面设计.md`
11. `../xiuxian_design_docs/04_交互设计/06_指令管理页面设计.md`

### P4. Map, Movement, Resources, Inventory

Window: 2026-07-04 to 2026-07-17  
Goal: make world space and resource flow playable.

Deliverables:

1. Minimal world map state, node state, node level, risk, aura profile, visibility, and control summary.
2. Directed weighted routes and a `travel` command with preview, validation, qi cost, arrival, delay, interruption, and result logs.
3. Minimal resource slot model with consumption, regeneration, depletion, ownership/contest state, and replay output.
4. Basic player inventory and stackable material/resource entries.
5. Minimal gathering or processing command that turns node resources into inventory or abstract resource records.
6. Low-fidelity map and inventory views.

Exit criteria:

1. The player can move between two nodes through the command system.
2. Movement consumes time and qi without bypassing command validation.
3. Resource changes can be traced to a node, command, event, or config source.
4. Inventory survives save/load and is visible in UI.

Design references:

1. `../xiuxian_design_docs/02_系统设计/07_地图节点设计/01_地图节点通用设定.md`
2. `../xiuxian_design_docs/02_系统设计/07_地图节点设计/02_资源槽详细设定.md`
3. `../xiuxian_design_docs/02_系统设计/07_地图节点设计/03_节点路线详细设定.md`
4. `../xiuxian_design_docs/02_系统设计/10_移动玩法设计.md`
5. `../xiuxian_design_docs/02_系统设计/05_物品设计/06_资源与材料.md`
6. `../xiuxian_design_docs/02_系统设计/05_物品设计/05_灵石及聚灵石.md`
7. `../xiuxian_design_docs/04_交互设计/07_储物空间页面设计.md`

### P5. Events, Combat, Breakthrough, Reincarnation

Window: 2026-07-18 to 2026-08-07  
Goal: add the risk and milestone systems needed for the single-player loop.

Deliverables:

1. Deterministic event candidate, throttle, trigger, choice, and result pipeline.
2. At least one travel event and one node/resource/risk event.
3. Local pause or focused event handling for player decisions; no multiplayer gap logic required for MVP-1.
4. Formal B1-style combat state for single-player combat, including five tactical slots, fallback actions, and result logs.
5. Life/qi/spirit read/write in combat and a minimal attack/defense/buff counter model.
6. Manual major breakthrough start, precondition check, stage choice, default strategy, result report, failure labels, and reincarnation ledger entry.
7. Two breakthrough chains for MVP validation: M1 -> M2 and M2 -> M3.
8. Death and reincarnation flow back into current-life initialization.

Exit criteria:

1. A deterministic seed can produce a known event, combat, and breakthrough chain.
2. Combat reads and writes persistent character bars and does not auto-refill after battle.
3. Breakthrough can succeed, fail with survival, or fail with death/reincarnation.
4. Result packages explain what happened, why it happened, what changed, and what the player can do next.

Design references:

1. `../xiuxian_design_docs/02_系统设计/15_随机事件玩法设计.md`
2. `../xiuxian_design_docs/02_系统设计/12_战斗指令设计.md`
3. `../xiuxian_design_docs/02_系统设计/13_战斗玩法设计.md`
4. `../xiuxian_design_docs/02_系统设计/14_突破玩法设计.md`
5. `../xiuxian_design_docs/03_数值设计/03_战斗公式与数值设计.md`
6. `../xiuxian_design_docs/03_数值设计/06_事件设计基准建模.md`

### P6. Sect-Lite, UI Integration, Validation

Window: 2026-08-08 to 2026-08-21  
Goal: add the minimum sect support needed for single-player progression and integrate the playable UI.

Deliverables:

1. Single-player sect identity and permission summary.
2. Five abstract sect resource categories and a minimal sect storage reference.
3. Resource request, approval/refusal, reservation, consumption, release, expiration, and audit logs.
4. One active sect continuous action per sect as a local simulation feature.
5. Sect support for cultivation or breakthrough where needed by the single-player loop.
6. Low-fidelity sect page and integrated main navigation.
7. Fixed-seed validation scenarios for cultivation, movement, resources, events, combat, breakthrough, save/load, and reincarnation.

Exit criteria:

1. Sect resources cannot be consumed without inventory/storage, reservation, and permission checks.
2. Sect support can help a single-player breakthrough or resource path without requiring multiplayer governance.
3. The player can complete the MVP-1 loop from title screen through reincarnation using UI only.

Scope note:

This is sect-lite for a local single-player room. Multiplayer visibility, same-sect player conflict, voting, direct player-to-player opportunity contention, and player slot behavior are deferred.

Design references:

1. `../xiuxian_design_docs/02_系统设计/17_宗门系统设计.md`
2. `../xiuxian_design_docs/02_系统设计/03_经济系统设计/01_地图资源产出.md`
3. `../xiuxian_design_docs/02_系统设计/03_经济系统设计/02_世界凭空产出.md`
4. `../xiuxian_design_docs/02_系统设计/03_经济系统设计/03_物品流转.md`
5. `../xiuxian_design_docs/04_交互设计/08_宗门页面设计.md`
6. `../xiuxian_design_docs/03_数值设计/08_数值验算.md`

### P7. MVP-1 Stabilization

Window: 2026-08-22 to 2026-09-04  
Goal: stabilize the single-player MVP into a reviewable build.

Deliverables:

1. Full single-player smoke route from new game to reincarnation.
2. Config validation for required IDs, references, numeric ranges, and localization keys.
3. Save/load migration check for the current save schema.
4. Replay viewer or debug replay dump for fixed-seed runs.
5. Low-fidelity UI pass for title, main, character, cultivation, command, map, inventory, event, combat/breakthrough report, and sect views.
6. Simplified Chinese and English localization key coverage for MVP UI strings.
7. Known issues list, out-of-scope list, and next-phase backlog.

Exit criteria:

1. A reviewer can run the build locally and complete the single-player MVP loop without developer intervention.
2. Automated or scripted fixed-seed checks cover the major gameplay routes.
3. Save/load, replay, and debug traces are good enough to diagnose incorrect settlement.
4. Multiplayer remains explicitly deferred and is not partially implemented as an unstable hidden path.

## MVP-1 Review Gate

Window: 2026-09-05 to 2026-09-08

The MVP-1 review should answer:

1. Is the single-player loop understandable without reading debug logs?
2. Does the authoritative runtime own settlement rather than UI scenes?
3. Can a failed cultivation, combat, breakthrough, or save/load state be debugged from logs and replay?
4. Is the first reincarnation loop compelling enough to justify adding more content?
5. Which multiplayer assumptions survived the single-player implementation, and which need redesign before MVP-2?

Review outputs:

1. MVP-1 accepted / accepted with fixes / not accepted.
2. Required fixes before content expansion.
3. Formal design updates needed because implementation clarified stable behavior.
4. MVP-2 candidate scope, including whether multiplayer should start next.

## Decision Gates

| Gate | Needed By | Current Plan | Decision Needed |
| --- | --- | --- | --- |
| Godot version | P1 start | Use Godot 4 stable line | Exact version and whether to commit editor/export settings |
| Scripting language | P1 start | Prefer GDScript for runtime and UI | Whether C# is allowed for runtime modules |
| Test runner | P1 start | Headless runner required | GUT, native Godot test pattern, or custom runner |
| Config format | P1/P2 | Structured text files | JSON, CSV, TOML, Godot Resource, or mixed approach |
| Save format | P2 | Versioned local save file | JSON/resource/binary and migration policy |
| Localization | P3/P7 | zh-CN and en keys from MVP | Key naming and fallback behavior |
| Realm sample data | P3 | Minimal Qi Refining through early breakthrough chain | Exact segment thresholds and target hours |
| Combat formula | P5 | Minimal counter model | Whether to use deterministic threshold, light randomization, or template-only resolution |
| Breakthrough templates | P5 | M1 -> M2 and M2 -> M3 | Stage count, required resource samples, failure labels |
| Sect-lite approval | P6 | Local single-player resource request | Approval formula, delay, and expiration defaults |

## Validation Matrix

| Scenario | Required By | Validation Type |
| --- | --- | --- |
| Create local room, advance one hour, save, load | P2 | Automated smoke runner |
| Initialize true spirit and current-life character | P3 | Automated + UI check |
| Queue valid and invalid commands | P3 | Automated |
| Active cultivation with resource input and residual effect | P3 | Automated + debug trace |
| Travel between nodes with qi cost | P4 | Automated + UI check |
| Gather resource and persist inventory | P4 | Automated |
| Trigger deterministic event | P5 | Fixed-seed scenario |
| Resolve 1v1 combat | P5 | Fixed-seed scenario |
| Complete breakthrough success | P5 | Fixed-seed scenario |
| Complete breakthrough failure-survival | P5 | Fixed-seed scenario |
| Complete breakthrough death-reincarnation | P5 | Fixed-seed scenario |
| Request and consume sect support resource | P6 | Automated |
| Complete full single-player loop from title screen | P7 | Manual review + scripted smoke route |

## Deferred Multiplayer Backlog

These items are intentionally outside MVP-1:

1. Private multiplayer lobby and player-slot preparation.
2. Post-start join prevention and reconnect-to-original-slot behavior.
3. Network authority, transport, serialization protocol, host rules, and latency handling.
4. Per-player private log visibility and cross-player public summaries.
5. Multiplayer F1/B1/P0/C1 gap handling.
6. Same-sect multiplayer resource contention and privacy boundaries.
7. PvP, player trading, shared expeditions, direct assistance, and direct retaliation loops.
8. Steam-specific networking or distribution integration.

## Change Log

| Date | Change |
| --- | --- |
| 2026-05-12 | Created the MVP development plan outside the formal design package. |
| 2026-05-12 | Revised the plan to be English-first, execution-oriented, schedule-based, progress-tracked, and single-player-only for MVP-1. |
