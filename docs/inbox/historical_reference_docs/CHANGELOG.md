# Canonical 文档变更日志

状态：正式 docs 维护文档
更新日期：2026-05-08
适用范围：`docs` 正式目录，不含 `docs/inbox` 原始档案

本文记录 canonical 文档集的新增、删除、改名、拆分、合并，以及重要设计口径修订。具体设计口径仍以 `docs/index.md` 中列出的 canonical 文档及各文档的“来源与裁决”段为准。

## 维护规则

1. 新记录按日期倒序追加。
2. 新增、删除、改名、拆分或合并 canonical 文档时，必须同步更新本文与 `docs/index.md`。
3. “删除”指退出正式 canonical 文档集，不代表从 `docs/inbox` 物理删除原始档案。
4. 若一个 inbox 原文档被吸收到多个正式文档，记录为“合并 / 拆分”，不再保留平行文档。
5. 重要设计口径修订即使不新增或改名文档，也必须记录到本文；是否需要同步 `docs/index.md` 取决于 canonical 文档集是否变化。
6. 目录 README、迁移计划、索引和本文属于维护文档；除非 `docs/index.md` 明确列入“当前 canonical 文档”，否则不作为设计口径主源。

---

## 2026-05-08

### 世界产出预算与资源流转旧设定恢复

本次为 canonical 文档设计口径修订，不新增或改名文档。修订背景：旧版经济、地图、物品产出和 NPC 库存文档中的世界产出预算、资源流转、物品预算帽、资源投放预算、资源池、预算价值和非返还规则在数值文档整合时被阶段预算表述覆盖得过窄；本次恢复为“底层世界产出预算 + 阶段预算境界调度”的统一口径。

补充来源：

```text
docs/inbox/修仙游戏设计方案总目录/[已过时]修仙游戏0424/核心体验｜设计基石/物品产出与获得的核心体验草稿 0426｜人工参与编辑 34edffce59dc81318c81c9a7a6027fd6.md
docs/inbox/修仙游戏设计方案总目录/[已过时]修仙游戏0424/修仙轮回沙盒｜项目总览与顶层设计定案 0424/S8｜地图节点、资源槽与建筑槽子系统设计案 0425｜未人工审核/沙盒世界演化与地图节点生成规则草稿 0427｜人工参与编辑 34fdffce59dc815d91d1d3d145b92e03.md
docs/inbox/修仙游戏设计方案总目录/[已过时]修仙游戏0424/核心体验｜设计基石/经济系统框架性设计草稿 0427｜人工参与编辑 34fdffce59dc816abe2ed699d8a6d447.md
docs/inbox/修仙游戏设计方案总目录/[已过时]修仙游戏0424/核心体验｜设计基石/NPC持久化、库存与经济定位框架草稿 0426｜人工参与编辑 34edffce59dc818cb57ac7248e6e14d9.md
```

| 修订文档 | 变更说明 |
| --- | --- |
| `docs/systems-design/cultivation-realm-numeric-balance.md` | 将阶段预算修订为世界产出预算的境界调度层；恢复 `WorldProductionBudgetState`、`WorldItemBudgetTier`、`WorldResourceBudget`、`BudgetValue`、预算扣除时机和非返还规则。 |
| `docs/systems-design/map-nodes-world-evolution.md` | 恢复 `WorldResourceBudget` 的地图层口径，明确 stable / opportunity / rare / legacy 四类资源投放预算与资源槽、机会窗口的关系。 |
| `docs/systems-design/economy-items-assets-npc-persistence.md` | 补回 `ResourcePool`、`AssetGenerationRequest`、`AssetGenerationResult`、预算价值、隐性候选不扣预算、显性入库扣预算、NPC 掉落来源链路。 |
| `docs/systems-design/sect-organization-inventory-ai.md` | 将宗门库存预算表述修订为世界产出预算的宗门出口，阶段预算只控制境界可得性与扩散节奏。 |
| `docs/systems-design/runtime-state-data-model-result-packages.md` | 增加 `world_production_budget_state`、`world_production_budget_delta`、`asset_generation_records`、`budget_ledger_entries` 和 `resource_pools`，区分底层预算账本与阶段调度 delta。 |
| `docs/references/glossary-and-field-naming.md` | 新增世界产出预算、物品预算阶层、资源投放预算、资源池、预算价值、资产生成请求 / 结果字段，并记录禁止把阶段预算当成唯一预算。 |
| `docs/index.md`、`docs/systems-design/README.md` | 同步核心设计合同和文档入口描述。 |
| `docs/production/risk-register-technical-decision-gates.md`、`docs/production/mvp-delivery-slices-and-acceptance.md`、`docs/ui-design/uiux-stable-requirements.md`、`docs/systems-design/shared-calendar-room-settlement.md` | 同步风险、验收、Debug 展示和时间换算中的预算口径。 |

### 数值设计 canonical 文档新增与系统口径补充

本次新增正式 canonical 数值设计文档，并将两个 inbox 数值稿中影响系统设定的部分同步到相关 canonical 文档。`docs/index.md` 已同步新增文档入口。

基准来源：

```text
docs/inbox/修仙游戏设计方案总目录/数值设计/修为年限_现实时间_阶段预算数值方案_v0 1 35adffce59dc8036907fde811054d5c6.md
docs/inbox/修仙游戏设计方案总目录/数值设计/核心数值设计方案_境界基准收益模型_v0 1 359dffce59dc80bf856ad8241dfdee39.md
```

| 修订文档 | 变更说明 |
| --- | --- |
| `docs/systems-design/cultivation-realm-numeric-balance.md` | 新增 canonical 数值主源；以修为年限、现实时间、阶段预算方案为基准，吸收境界段模型、基准收益反推、适配矩阵、资源效果定价、状态压力、突破承接和轮回效率判断。 |
| `docs/index.md` | 新增数值设计 canonical 入口，并将 `RealmSegmentBalance`、`normalized_segment_progress`、`WorldStageBudgetState`、`RealmBudgetPool`、`CultivationTickResult` 纳入核心设计合同。 |
| `docs/systems-design/README.md` | 新增数值设计文档目录入口。 |
| `docs/references/glossary-and-field-naming.md` | 新增游戏年换算、修炼数值与阶段预算字段术语，记录新增字段裁决。 |
| `docs/systems-design/shared-calendar-room-settlement.md` | 补充 `1 游戏年 = 360 游戏日` 为数值换算基准，不改变 `hour_tick` 运行时事实。 |
| `docs/systems-design/runtime-state-data-model-result-packages.md` | 补充预算、游戏年、修炼结果、结果包、存档和回放接口；预算口径后续修订为 `WorldProductionBudgetState` 底层账本 + `WorldStageBudgetState` 阶段调度。 |
| `docs/systems-design/character-true-spirit-reincarnation-cultivation.md` | 补充 `current_realm_segment_id`、`normalized_segment_progress`、`CultivationTickResult`、CEI 和境界段收益结算接口。 |
| `docs/systems-design/personal-command-queue-movement-managed-actions.md` | 补充 `ActionCultivationProfile`，明确行动只提供相对效率，不写死 raw 修为收益。 |
| `docs/systems-design/events-breakthrough-combat-time-rules.md` | 补充突破开启条件与 `BreakthroughScoreBalance` 初始分承接，保持最终结果由 B1 轮内结算。 |
| `docs/systems-design/map-nodes-world-evolution.md` | 补充 `NodeRealmSupport`、阶段预算对资源槽和机会窗口的投放规则。 |
| `docs/systems-design/economy-items-assets-npc-persistence.md` | 补充 `ResourceEffectBalance` 和预算作为资产与机会来源的审计要求；预算口径后续修订为世界产出预算底层账本 + 阶段调度。 |
| `docs/systems-design/sect-organization-inventory-ai.md` | 补充阶段预算对宗门库存、任务、护法和功法载体可得性的影响，保持资源申请审批和审计合同。 |
| `docs/production/risk-register-technical-decision-gates.md` | 更新 D02 / D03，并新增 D12 与 R10，跟踪阶段预算和 NPC 成长调参风险。 |
| `docs/production/mvp-delivery-slices-and-acceptance.md` | 补充 VS3、VS4、VS6 对数值模型、阶段预算和突破初始分的验收要求。 |
| `docs/ui-design/uiux-stable-requirements.md` | 补充修炼行动预览默认展示时间、有效收益和风险估算，高级详情 / Debug 才展示完整数值公式。 |

### 核心体验目标口径修订

本次为 canonical 文档设计口径修订，不涉及正式文档新增、删除、改名、拆分或合并，因此不需要同步更新 `docs/index.md`。

修订背景：将玩家核心体验从“为跨世真灵争取更好的下一世命运”纠正为“以当世修炼、资源、突破与风险经营推动个人修为和境界持续攀升；轮回作为低效率修正、路线重构、信息复用和后手兑现的跨世手段”。轮回不是显性终极目标，玩家显性终极目标是个人修为与境界成长到当前设计定义的最高层级。

| 修订文档 | 变更说明 |
| --- | --- |
| `docs/concept/core-experience-player-goals-pillars.md` | 重写核心体验句、显性终极目标、玩家身份、MVP 玩家目标、设计基石、修炼 / 突破体验、失败 / 转世体验和裁决表；新增 `核心数值设计方案_境界基准收益模型_v0.1` 与 `玩家角色扮演核心体验｜真灵-执念-身躯与灵魂三层模型 0425` 为参考来源。 |
| `docs/concept/project-overview-mvp-scope.md` | 将项目定位中的核心体验由“控制跨世延续的真灵”同步为“经营当世修炼、资源、突破与风险，推动个人修为和境界持续攀升；真灵承接跨世身份”。 |
| `docs/systems-design/character-true-spirit-reincarnation-cultivation.md` | 明确 S2 的显性成长主线是当世修为与境界攀升；轮回不是终局目标，而是效率修正、路线重构、信息复用和后手兑现手段；补充真灵不保存当前修为、功法等级、背包、宗门职位或普通社会关系。 |
| `docs/production/mvp-delivery-slices-and-acceptance.md` | 将 VS1 补充为包含当世角色与修炼成长；将 VS8 交付重点从“轮回与多人差异”收敛为“跨世后手与多人差异”。 |

### 建立 formal docs canonical 基线

**基准来源**

```text
docs/inbox/修仙游戏设计方案总目录/修仙轮回沙盒_设计文档包_v2 3/
docs/index.md
docs/references/document-consolidation-plan.md
```

本次记录以 v2.3 文档包为 raw source baseline，对照当前正式 `docs` 文档集生成。v2.3 原始包继续作为 provenance、冲突比对和恢复材料保留在 `docs/inbox`。

### 新增 canonical 文档

| 当前正式文档 | 来源 / 差异说明 |
| --- | --- |
| `docs/concept/project-overview-mvp-scope.md` | 吸收 v2.3 `01_项目总览_MVP边界_系统依赖`，作为项目总览、MVP 边界和系统依赖主源。 |
| `docs/concept/core-experience-player-goals-pillars.md` | 吸收 v2.3 `02_核心体验_玩家目标_设计基石`，作为核心体验、玩家目标和设计基石主源。 |
| `docs/references/glossary-and-field-naming.md` | 吸收 v2.3 `03_术语表_命名规范_字段统一` 与 `04_字段命名与开发检查清单`，作为 active / deprecated 术语和字段命名主源。 |
| `docs/systems-design/shared-calendar-room-settlement.md` | 吸收 v2.3 `01_共享日历_房间推进_权威结算`，保留 `world_day / world_hour / hour_tick`、`F1 / N1 / B1 / P0`、`C1` 和 S1 权威结算口径。 |
| `docs/systems-design/personal-command-queue-movement-managed-actions.md` | 吸收 v2.3 `03_个人行动队列_移动通行_托管`，作为 `Command / CommandQueue`、移动、显式托管和自动兜底主源。 |
| `docs/systems-design/events-breakthrough-combat-time-rules.md` | 吸收 v2.3 `08_事件突破战斗时间规则`，作为局部时停、C1、B1、突破和正式交锋主源。 |
| `docs/systems-design/character-true-spirit-reincarnation-cultivation.md` | 吸收 v2.3 `02_角色真灵轮回_修炼养成`，并参考修为公式与功法补充资料，作为真灵、当世角色、修炼、功法和转世主源。 |
| `docs/systems-design/sect-organization-inventory-ai.md` | 吸收 v2.3 `05_宗门组织_库存_宗门AI持续行动`，作为宗门组织、库存、权限和 `SectContinuousActionState` 主源。 |
| `docs/systems-design/map-nodes-world-evolution.md` | 吸收 v2.3 `04_地图节点_世界演化`，作为地图节点、资源槽、机会窗口和世界演化主源。 |
| `docs/systems-design/economy-items-assets-npc-persistence.md` | 吸收 v2.3 `06_经济物品资产_NPC持久化`，并参考资源输入与功法补充资料，作为资产容器、物品、资源输入、商店和 NPC 持久化主源。 |
| `docs/systems-design/contingency-legacy-visibility-indirect-competition.md` | 吸收 v2.3 `07_后手遗产_可见性_多人间接竞争`，作为后手、遗产、可见性和多人间接竞争主源。 |
| `docs/systems-design/runtime-state-data-model-result-packages.md` | 吸收 v2.3 `01_运行时状态_数据模型_结果包` 与 `09_数据驱动_存档_服务端调试`，作为运行时状态、数据模型、结果包、日志、回放、存档和数据驱动主源。 |
| `docs/production/mvp-delivery-slices-and-acceptance.md` | 吸收 v2.3 `02_MVP开发切片与验收清单`，作为 MVP 切片、验收和开发交付顺序主源。 |
| `docs/ui-design/uiux-stable-requirements.md` | 吸收 v2.3 `01_UIUX需求方案`，作为稳定 UI 行为、屏幕责任、队列控件、速度展示和隐私展示主源。 |
| `docs/production/risk-register-technical-decision-gates.md` | 吸收 v2.3 `03_待确认问题_风险登记`，作为风险登记、滚动落地事项和技术决策门主源。 |

### 新增维护文档与目录入口

| 文档 | 作用 |
| --- | --- |
| `docs/index.md` | 正式 docs 总入口和 canonical 文档地图，替代 v2.3 包内 README / MANIFEST 作为当前阅读入口。 |
| `docs/CHANGELOG.md` | 本文件，维护 canonical 文档集的增删、改名、拆分和合并历史。 |
| `docs/references/document-consolidation-plan.md` | 迁移完成记录、正式目录职责、迁移批次和来源记录。 |
| `docs/concept/README.md` | `concept` 目录入口。 |
| `docs/systems-design/README.md` | `systems-design` 目录入口。 |
| `docs/production/README.md` | `production` 目录入口。 |
| `docs/ui-design/README.md` | `ui-design` 目录入口。 |
| `docs/references/README.md` | `references` 目录入口。 |
| `docs/game-design/README.md` | `game-design` 目录入口；当前不承载独立 canonical 文档。 |
| `docs/worldbuilding/README.md` | `worldbuilding` 目录入口；当前不承载独立 canonical 文档。 |
| `docs/research/README.md` | `research` 目录入口；当前不承载最终设计承诺。 |
| `docs/playtest/README.md` | `playtest` 目录入口；当前不承载独立 canonical 文档。 |

### 删除 / 退出独立 canonical 文档集

以下文档未从 `docs/inbox` 物理删除；它们只是不再作为正式 canonical 文档的独立入口。

| v2.3 原文档 / 包内文件 | 当前处理 |
| --- | --- |
| `README.md` | 由 `docs/index.md` 承担正式阅读入口；v2.3 README 保留为 raw package provenance。 |
| `MANIFEST.md` | 由 `docs/index.md` 和各目录 README 承担正式文档清单；v2.3 manifest 保留为 raw package 文件清单。 |
| `CHANGELOG.md` | v2.3 changelog 保留为原包内部变更记录；正式 docs 的文档结构变更改由 `docs/CHANGELOG.md` 维护。 |
| `QA_自动检查报告.md` | 不进入 canonical 文档集；相关验收约束吸收到 MVP 验收、风险登记和各系统文档。 |
| `03_实现交付/04_字段命名与开发检查清单_v2.3.md` | 不保留独立文档；字段命名主口径吸收到 `docs/references/glossary-and-field-naming.md`，开发检查项进入运行时、风险和验收文档。 |
| `03_实现交付/05_原始文档映射与来源索引_v2.3.md` | 不保留独立 canonical 文档；来源索引分散记录到各正式文档的“来源与裁决”段，并由 `docs/references/document-consolidation-plan.md` 汇总。 |
| `02_核心系统规格/09_数据驱动_存档_服务端调试_v2.3.md` | 不保留独立文档；数据驱动、存档、服务端和调试口径合并进 `docs/systems-design/runtime-state-data-model-result-packages.md` 与 `docs/production/risk-register-technical-decision-gates.md`。 |
| v2.3 包级目录页与 Notion wrapper 页 | 不进入 canonical 文档集；正式目录结构由 `docs/index.md` 和目录 README 表达。 |

### 主题级改名与合并说明

| v2.3 主题 | 当前 canonical 处理 |
| --- | --- |
| `01_基础与总览` | 拆分到 `docs/concept` 与 `docs/references`。 |
| `02_核心系统规格` | 拆分到 `docs/systems-design`，其中数据驱动与存档主题合并进运行时数据模型文档。 |
| `03_实现交付` | 拆分到 `docs/production`、`docs/references` 与 `docs/systems-design`。 |
| `04_UIUX与界面规范` | 收敛为 `docs/ui-design/uiux-stable-requirements.md`；节点级布局仍以后续当前 UI artifact / Figma 为准。 |
| v2.3 原包级 README / MANIFEST / CHANGELOG / QA 报告 | 保留为 `docs/inbox` provenance；正式 docs 使用新的索引、本文和验收 / 风险文档维护。 |

### 当前未建立 canonical 内容的正式目录

| 目录 | 当前状态 |
| --- | --- |
| `docs/game-design` | 仅有目录 README；玩家侧流程、失败、死亡、轮回体验解读仍待后续迁移或新写。 |
| `docs/worldbuilding` | 仅有目录 README；世界观、宗门 lore、地域和器物叙事仍待后续迁移或新写。 |
| `docs/research` | 仅有目录 README；调研内容不自动构成最终设计承诺。 |
| `docs/playtest` | 仅有目录 README；测试计划、反馈和调参记录仍待后续创建。 |
