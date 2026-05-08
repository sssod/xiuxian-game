# 修仙轮回沙盒文档索引

状态：正式 docs 入口
更新日期：2026-05-08

本目录承载面向开发交付的定稿文档。`docs/inbox` 是原始资料档案，后续实现、验收、UI、数据契约和制作管理应优先从正式 docs 读取。

## 当前主源

最新原始设计源为 v2.3 包：

```text
docs/inbox/修仙游戏设计方案总目录/修仙轮回沙盒_设计文档包_v2 3/
```

正式文档已开始从 v2.3 主源迁移。旧版本和 `[已过时]` 文件仅用于冲突比对、来源追溯和背景补充。

## 当前 canonical 文档

| 主题 | 文档 |
| --- | --- |
| 文档架构与迁移计划 | [references/document-consolidation-plan.md](references/document-consolidation-plan.md) |
| 项目总览、MVP 边界与系统依赖 | [concept/project-overview-mvp-scope.md](concept/project-overview-mvp-scope.md) |
| 核心体验、玩家目标与设计基石 | [concept/core-experience-player-goals-pillars.md](concept/core-experience-player-goals-pillars.md) |
| 术语表、命名规范与字段统一 | [references/glossary-and-field-naming.md](references/glossary-and-field-naming.md) |
| 共享日历、房间推进与权威结算 | [systems-design/shared-calendar-room-settlement.md](systems-design/shared-calendar-room-settlement.md) |
| 个人行动队列、移动通行与托管 | [systems-design/personal-command-queue-movement-managed-actions.md](systems-design/personal-command-queue-movement-managed-actions.md) |
| 事件、突破与战斗时间规则 | [systems-design/events-breakthrough-combat-time-rules.md](systems-design/events-breakthrough-combat-time-rules.md) |
| 角色、真灵、轮回与修炼养成 | [systems-design/character-true-spirit-reincarnation-cultivation.md](systems-design/character-true-spirit-reincarnation-cultivation.md) |
| 宗门组织、库存与宗门 AI 持续行动 | [systems-design/sect-organization-inventory-ai.md](systems-design/sect-organization-inventory-ai.md) |
| 地图节点与沙盒世界演化 | [systems-design/map-nodes-world-evolution.md](systems-design/map-nodes-world-evolution.md) |
| 经济、物品、资产容器与 NPC 持久化 | [systems-design/economy-items-assets-npc-persistence.md](systems-design/economy-items-assets-npc-persistence.md) |
| 后手、遗产、可见性与多人间接竞争 | [systems-design/contingency-legacy-visibility-indirect-competition.md](systems-design/contingency-legacy-visibility-indirect-competition.md) |
| 运行时状态、数据模型与结果包 | [systems-design/runtime-state-data-model-result-packages.md](systems-design/runtime-state-data-model-result-packages.md) |
| MVP 开发切片与验收清单 | [production/mvp-delivery-slices-and-acceptance.md](production/mvp-delivery-slices-and-acceptance.md) |
| UI/UX 稳定需求 | [ui-design/uiux-stable-requirements.md](ui-design/uiux-stable-requirements.md) |
| 风险登记与技术决策门 | [production/risk-register-technical-decision-gates.md](production/risk-register-technical-decision-gates.md) |

## 正式目录

| 目录 | 用途 |
| --- | --- |
| `concept` | 项目定位、玩家承诺、设计基石、MVP 边界 |
| `game-design` | 玩家循环、行动规则、房间流程、失败、轮回 |
| `systems-design` | 时间系统、结算总线、模拟系统、数据契约 |
| `ui-design` | 屏幕清单、交互状态、UI 流程、Figma 参考 |
| `worldbuilding` | 世界观、宗门、地点、势力、lore 术语 |
| `production` | MVP 切片、验收、风险登记、技术决策门 |
| `references` | 术语、字段索引、来源映射、冲突裁决 |
| `research` | 调研与非最终设计承诺 |
| `playtest` | 测试计划、反馈、观察和调参记录 |

## 核心设计合同

```text
共享连续世界日历
world_day / world_hour
hour_tick
F1 / N1 / B1 / P0
C1
Command / CommandQueue
TimelineReplay
FormalEncounterState
SectContinuousActionState
ActionResourceInputBinding
ActiveResourceEffect
```

Deprecated active concepts:

```text
turn_id
quarter
action_slot
current_quarter
TurnReplay
QuarterReplay
SectDecisionIntent
宗门主行动输入
每季度 6 个朔望行动格
```
