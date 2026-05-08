# Canonical 文档变更日志

状态：正式 docs 维护文档
更新日期：2026-05-08
适用范围：`docs` 正式目录，不含 `docs/inbox` 原始档案

本文记录 canonical 文档集的新增、删除、改名、拆分与合并。它只维护“正式文档结构”的变化；具体设计口径仍以 `docs/index.md` 中列出的 canonical 文档及各文档的“来源与裁决”段为准。

## 维护规则

1. 新记录按日期倒序追加。
2. 新增、删除、改名、拆分或合并 canonical 文档时，必须同步更新本文与 `docs/index.md`。
3. “删除”指退出正式 canonical 文档集，不代表从 `docs/inbox` 物理删除原始档案。
4. 若一个 inbox 原文档被吸收到多个正式文档，记录为“合并 / 拆分”，不再保留平行文档。
5. 目录 README、迁移计划、索引和本文属于维护文档；除非 `docs/index.md` 明确列入“当前 canonical 文档”，否则不作为设计口径主源。

---

## 2026-05-08

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
