# 风险登记与技术决策门

状态：第三批正式定稿
更新日期：2026-05-08
来源主版本：v2.3 calendar_preinput

## 1. 文档定位

本文承载开发交付准备阶段的风险登记、数值 / 内容 / 模板滚动落地事项、技术决策门和验收关注点。

当前结论：

```text
没有阻塞开发启动的设定待决项。
```

已经定稿的开发口径包括：

```text
共享世界日历
服务器 1 游戏小时 tick
F1 / N1 / B1 / P0 速度状态机
当前执行指令 + 最多 3 条预输入指令
自动兜底强制 N1
显式托管由玩家主动输入
个人非交锋事件局部时停
局部时停 gap 上限 1 游戏日
C1 追赶只补确定性内容
正式交锋与突破挑战进入 B1
个人突破主要消耗发生在突破挑战轮内
回放使用 TimelineReplay
```

本文不选择具体引擎、数据库、部署方案或最终 UI 组件实现。尚未定型的工程选型记录为技术决策门；数值、事件、功法、物品和模板样例记录为滚动落地事项。

## 2. 当前决议基线

| 范围 | 当前口径 |
| --- | --- |
| 时间事实 | `world_day / world_hour` 是唯一运行时间事实 |
| 结算单位 | 服务端按 `hour_tick` 做 1 游戏小时权威结算 |
| 公开速度 | `F1 / N1 / B1 / P0`，优先级为 P0 > B1 > N1 > F1 |
| 内部追赶 | `C1` 只用于局部时停后的确定性补结算 |
| 行动输入 | `CommandQueue` 保存当前执行指令 + 最多 3 条预输入 |
| 自动兜底 | `FallbackState.force_speed=N1` 且 `f1_eligible=false` |
| 显式托管 | 玩家主动输入或房间规则生成，不等同于自动兜底 |
| 局部时停 | 个人非交锋事件冻结本人时间，外部世界 N1 |
| 正式交锋 | 战斗、突破挑战和玩家直接冲突进入 `FormalEncounterState` B1 |
| 回放 | `TimelineReplay` 记录速度片段、队列变化、局部时停、C1、B1、P0 和结果包 |
| 资源输入 | 丹药、灵材、符箓通过 `ActionResourceInputBinding` 绑定行动或事件选项 |
| 残余效果 | 未消耗完的资源效果进入 `ActiveResourceEffect` |
| 宗门 | 宗门 AI 维护 `SectContinuousActionState`，玩家通过身份、贡献、申请、事件和亲自参与间接影响 |
| UI 隐私 | 普通玩家 UI 只展示中性速度原因，不暴露私人归因或 Debug 字段 |

## 3. 数值 / 内容 / 模板滚动落地事项

以下事项不是阻塞开发启动的设定待决项，但属于当前数值设计与系统设计互校的持续工作面。每次确定公式、曲线、模板或样例数值后，应更新对应 canonical 系统文档，并记录到后续 changelog / 变更记录。

| 编号 | 事项 | 落地位置 | 检查点 |
| --- | --- | --- | --- |
| D01 | 行动模板基础字段 | 行动队列、运行时数据模型、MVP 验收 | 实际耗时、收益、风险曲线、`long_low_interaction`、`f1_eligible_when_explicit`、`can_be_auto_fallback`、`risk_sensitive_fallback` |
| D02 | 修炼成长模型 | 角色真灵轮回与修炼养成 | 修为曲线、根骨承载、境界阈值、寿元影响、突破条件 |
| D03 | 资源输入模板 | 经济物品、角色修炼、运行时数据模型 | `ActionResourceInputBinding` 样例、兼容小时、残余策略、`ActiveResourceEffect` |
| D04 | 节点风险与资源刷新 | 地图节点与世界演化 | `risk_level` 判定、默认兜底行动、资源槽刷新 |
| D05 | 闭关三档预案 | 角色修炼、事件突破战斗 | 风险阈值、收益修正、事件触发、局部时停 / B1 升级边界 |
| D06 | 显式托管事件边界 | 行动队列、UI/UX 稳定需求 | 低价值事件白名单、重大事件通知规则、默认选项策略 |
| D07 | B1 交锋模板 | 事件突破战斗 | 普通 / 复杂 / 硬上限模板、默认策略、模板结局 |
| D08 | 突破挑战模板 | 角色修炼、事件突破战斗 | 轮内资源消耗、轮内选项、失败代价、结果报告样例 |
| D09 | 24 小时 gap 处理 | 共享日历、事件突破战斗 | 默认选项清单、P0 同步保护事件清单 |
| D10 | C1 确定性白名单 | 共享日历、运行时数据模型 | 可补结算字段、禁止随机事件、结果包记录 |
| D11 | UI 速度与隐私文案 | UI/UX 稳定需求 | 中性速度提示、私人归因屏蔽、Debug 分层文案 |

## 4. 技术决策门

技术决策门用于开发启动前后集中评估，不在本文直接拍板。任何选择都必须保持 v2.3 字段命名、权威结算、结果包、存档和回放合同不变。

| 编号 | 决策门 | 候选 / 约束 | 触发时机 | 必须回答 |
| --- | --- | --- | --- | --- |
| T01 | 存档格式 | SQLite / Godot Resource / JSON / 混合方案 | VS0 技术底座前 | 如何保存 `RoomState`、`SaveGame`、`TimelineReplay` index、版本迁移、备份和损坏恢复 |
| T02 | 模板数据承载 | JSON / Godot Resource / 其他可审计模板格式 | 内容模板进入批量制作前 | 如何保证稳定 id、字段校验、结果包模板引用、本地化文本分离 |
| T03 | Figma 与客户端组件拆分 | 当前 UI artifact / Figma 仅作布局和视觉依据，规则以正式 docs 为准 | UI 原型和 Godot UI 组件拆分前 | 哪些是稳定交互规则，哪些是可迭代视觉与节点级布局 |
| T04 | Debug / QA 工具范围 | Debug 面板、QA 脚本、回放检查 | VS0 与 VS9 验收前 | 哪些隐藏字段可进 Debug，如何防止 Debug 字段进入普通玩家 UI |
| T05 | 私人服务器保存与恢复流程 | 本地单测、私人部署、3 人房间恢复 | 首个可保存房间前 | 存档写入点、恢复后速度状态、未完成局部时停 / B1 / P0 的恢复策略 |

## 5. 风险登记

| 编号 | 风险 | 描述 | 缓解 | 相关验收 |
| --- | --- | --- | --- | --- |
| R01 | F1 被误解为跳时 | 高速推进可能被实现为跳到下一关键点 | F1 仅走 `SpeedState`，每小时仍结算并检查事件、交锋、队列完成和 P0 | VS0、VS9、T02 |
| R02 | 自动兜底被滥用 | 玩家可能依赖低收益兜底长期挂机 | `FallbackState.force_speed=N1` 且 `f1_eligible=false` | VS2、T04 |
| R03 | 显式托管吞掉关键事件 | 托管可能被误做成复杂 AI 或自动处理重大事件 | 托管只覆盖低价值事件，重大事件走局部时停 / B1 / P0 | VS2、VS9、D06 |
| R04 | 突破预输入边界不清 | 开启突破与挑战轮内策略可能被混用 | `breakthrough_open` 只保存开启指令，挑战轮使用 `FormalEncounterState` | VS6、D08 |
| R05 | 局部时停信息泄露 | 其他玩家可能从速度变化推测私人事件 | 玩家 UI 只显示中性 `public_reason_key` | VS9、U09、T04 |
| R06 | C1 追赶触发循环事件 | 追赶期间再次触发随机事件会导致循环或重入 | `CatchupSettlementState.deterministic_only=true`，禁止新随机事件 | VS0、VS2、D10 |
| R07 | B1 拖慢非参战玩家 | 正式交锋会使全世界进入慢速 | 控制轮数、默认策略、硬上限与模板结局 | VS6、VS9、D07 |
| R08 | 字段口径漂移 | 开发中容易出现多套时间、回放或行动字段 | 以术语表、字段检查清单和 QA 脚本为 schema 入口 | T01、T02、T04 |
| R09 | UI 过度暴露调试信息 | Debug 字段进入玩家界面会影响多人体验 | 玩家 UI 与 Debug 面板数据源分层 | U09、T04 |

## 6. 验收关注点

开发验收时优先检查：

```text
world_day / world_hour 是否是唯一运行时间事实
CommandQueue 是否限制为当前 + 3 后续
入队与执行前校验是否都有日志
FallbackState 是否总是 force_speed=N1
ManagedActionState 是否只能来自玩家主动输入或房间规则
LocalTimeStopState gap 是否按 12/18/24h 提示
C1 是否只结算确定性内容
FormalEncounterState 是否复用给突破挑战
TimelineReplay 是否记录速度片段和关键状态
UI 是否屏蔽私人归因
```

QA 脚本和人工验收应覆盖：

| 范围 | 检查 |
| --- | --- |
| 时间 | `world_day / world_hour / hour_tick` 一致；P0 下世界时间不推进 |
| 速度 | `P0 > B1 > N1 > F1`；F1 不跳过小时结算 |
| 队列 | `CommandQueue.pending_command_refs` 不超过 3；执行前再次校验 |
| 兜底 / 托管 | 自动兜底不参与 F1；显式托管来源可追溯 |
| 局部时停 | 12/18/24h gap 提示和默认 / P0 处理可验证 |
| C1 | 只补确定性字段，不触发随机事件 |
| B1 | 每轮 1 游戏小时、60 秒窗口、默认策略和硬上限 |
| 结果包 | 每个 `ResultPackage` 带 `world_day / world_hour` 和 `source_system` |
| 回放 | `TimelineReplay.speed_segments`、队列变化、局部时停、C1、B1、P0 和结果包可复盘 |
| UI | 普通玩家 UI 不读取 `private_reason_refs`、隐藏日志或完整 `rng_trace` |

## 7. Deprecated aliases 与迁移说明

| 旧待决 / 风险口径 | 当前处理 | 说明 |
| --- | --- | --- |
| 季度 / 回合作为玩家最小推进单位 | 废弃 | 迁移为共享连续世界日历与 `world_day / world_hour` |
| 每季度 6 个朔望行动格 / 行动格成本 | 废弃 | 迁移为 `CommandQueue` 当前 + 3 后续，行动耗时按小时结算 |
| `TurnTimeBudgetBar` 作为主 UI 规则 | 废弃 | UI 使用简单队列面板，节点级布局以后续 UI artifact 为准 |
| 宗门主行动输入 / 宗门提案 / `SectDecisionIntent` | 移除 | 宗门 AI 维护 `SectContinuousActionState` |
| 功法等级结构待决 | 已收敛 | 完整功法载体学习，`MethodState` 使用掌握度成长；残页 / 篇章不作为运行时学习进度 |
| 行动资源输入与丹药药性待决 | 已收敛 | 使用 `ActionResourceInputBinding` 与 `ActiveResourceEffect` |
| 存档格式待决 | 保留为技术决策门 | 不阻塞设计定稿，但会影响 VS0 工程选型 |
| 寿元 MVP 最小实现待决 | 并入滚动落地 | 由角色修炼文档和数值模型继续验证，不改变当前时间 / 队列合同 |
| 行动模板耗时表、宗门 AI 权重、战斗数值 | 并入滚动落地 | 不作为设定冲突，作为 D01 / D07 / D08 等持续工作面 |
| 2 分钟回合决策风险 | 旧口径废弃 | 连续日历和局部时停取代回合决策阶段；保留“信息阅读拖慢体验”作为 UI 提醒与日志优先级问题 |

## 8. 来源与裁决

吸收来源：

```text
v2.3 README
v2.3 03_待确认问题_风险登记
v2.3 02_MVP开发切片与验收清单
v2.3 04_字段命名与开发检查清单
docs/references/glossary-and-field-naming.md
docs/production/mvp-delivery-slices-and-acceptance.md
docs/systems-design/runtime-state-data-model-result-packages.md
docs/ui-design/uiux-stable-requirements.md
```

冲突比对来源：

```text
v2.2 03_冲突决议_待确认问题_风险登记
v2.1 03_冲突决议_待确认问题_风险登记
20260427 03_冲突决议_待确认问题_风险登记
```

裁决：

| 采用方案 | 废弃 / 降级方案 | 原因与影响 |
| --- | --- | --- |
| 无阻塞开发启动的设定待决项 | 将行动模板、战斗数值、宗门 AI 权重等作为统一前置阻塞 | v2.3 已完成核心时间、队列、事件、回放和宗门口径统一；数值和模板进入滚动落地 |
| 技术决策门记录工程选型，不在设计文档内拍板 | 在文档阶段定死 SQLite / Godot Resource / JSON 任一方案 | 当前仍是 development handoff preparation，需保留工程评估空间 |
| 风险登记围绕 F1、兜底、托管、突破、局部时停、C1、B1、字段和 UI 隐私 | 旧版 2 分钟回合决策、时间预算条、回合报告风险 | v2.3 已改为共享日历、自适应速度和短队列 |
| 存档与数据模板必须服从 `RoomState`、`SaveGame`、`ResultPackage`、`TimelineReplay` 合同 | 存 UI 临时态、只存回合报告或子系统直接写状态 | 私人服务器、恢复、调试和 QA 都需要权威状态与可复盘记录 |
| 旧待决项按“已收敛 / 滚动落地 / 技术门”分类 | 保持旧版大列表作为 active 待决项 | 避免重新引入 v2.1 / v2.2 的回合、行动格和宗门主行动旧口径 |
