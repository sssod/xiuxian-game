# 术语表、命名规范与字段统一

状态：首批正式定稿
更新日期：2026-05-08
来源主版本：v2.3 calendar_preinput

## 1. 命名原则

1. 玩家面对的是共享世界日历，主时间字段使用 `world_day / world_hour`。
2. 服务器以 `hour_tick` 推进，行动、事件、资源效果、节点变化和宗门 AI 均应落到绝对世界小时。
3. 普通行动使用 `Command` 与 `CommandQueue`，不使用条件脚本或自动化排程字段。
4. 回放主结构使用 `TimelineReplay`，按连续时间片段记录速度、队列、事件、交锋和结果包。
5. 自动兜底、显式托管、超时安全默认必须分离建模，字段不得混用。
6. 玩家 UI 只展示中性速度原因，不暴露私人事件归因；Debug 字段不得直接进入玩家界面。

## 2. 时间术语

| 中文术语 | 含义 | 推荐字段 |
| --- | --- | --- |
| 世界日历 | 房间共享的连续世界时间 | `world_day / world_hour` |
| 游戏日 | 24 个游戏小时 | `world_day` |
| 游戏年 | 数值换算基准，默认 360 游戏日 | `days_per_game_year` |
| 游戏小时 | 服务器结算最小单位 | `world_hour` |
| 宏观周期 | 季节、旬月、灾变期等内容刷新周期 | `macro_period_id` / `season_id` |
| 服务器小时 tick | S1 推进一个游戏小时的结算步骤 | `hour_tick` |
| 速度状态 | 世界公开推进速度 | `SpeedState.current_speed` |
| 高速推进 | 全员长期低交互时的压缩速度 | `F1` |
| 常态推进 | 多人默认运行速度 | `N1` |
| 交锋慢速 | 正式交锋与突破挑战速度 | `B1` |
| 全局暂停 | 公共决策、同步保护、主机暂停 | `P0` |
| 追赶补结算 | 局部时停结束后的确定性补齐 | `C1` / `CatchupSettlementState` |

必须使用：

```text
current_world_day
current_world_hour
current_macro_period_id
world_day
world_hour
hour_tick
```

## 3. 房间与速度字段

`RoomState` 最小时间结构：

```text
RoomState {
  room_id: String
  world_seed: int
  current_year: int
  current_world_day: int
  current_world_hour: int
  current_macro_period_id: String
  time_config: TimeConfig
  speed_state: SpeedState
  runtime_state: String
  player_slots: Array
  active_players: Array
  active_local_time_stops: Dictionary
  active_catchups: Dictionary
  active_formal_encounters: Dictionary
  active_global_pause: GlobalPauseState | null
  save_version: String
}
```

`runtime_state` 推荐枚举：

```text
room_loading
world_running
local_time_stop_active
catchup_settlement
formal_encounter_b1
global_pause_p0
save_writeback
```

`TimeConfig` 默认值：

```text
server_tick_unit = hour
hours_per_game_day = 24
days_per_game_year = 360
n1_real_seconds_per_game_hour = 15
f1_real_seconds_per_game_day = 2
b1_real_seconds_per_game_hour = 60
local_gap_limit_hours = 24
local_gap_soft_warning_hours = 12
local_gap_hard_warning_hours = 18
catchup_max_real_seconds_per_day = 2
command_queue_max_pending = 3
enable_player_side_future_jump = false
```

`SpeedState` 玩家 UI 只读取：

```text
current_speed
public_reason_key
```

服务端日志与 Debug 面板可读取：

```text
private_reason_refs
blockers
f1_eligible_player_refs
n1_forced_by_refs
b1_encounter_ref
p0_pause_ref
```

## 4. 行动与队列术语

| 中文术语 | 含义 | 推荐字段 |
| --- | --- | --- |
| 指令 | 玩家当前已经合法的普通行动意图 | `Command` |
| 当前执行指令 | 正在执行的队列头或当前行动来源 | `current_command_ref` |
| 预输入指令 | 最多 3 条后续普通指令 | `pending_command_refs` |
| 行动状态 | 执行中的持续状态 | `ContinuousActionState` |
| 自动兜底 | 队列空或校验失败后的系统安全行为 | `FallbackState` |
| 显式托管 | 玩家主动输入的低关注行动 | `ManagedActionState` |
| 超时安全默认 | 事件、B1 或 P0 的安全默认处理 | `timeout_safe_default` / `default_resolution_policy` |
| 闭关预案 | 闭关行动内部小波动处理策略 | `seclusion_policy` |

`CommandQueue`：

```text
CommandQueue {
  queue_id: String
  character_id: String
  current_command_ref: String | null
  pending_command_refs: Array
  max_pending_count: int
  last_edited_world_day: int
  last_edited_world_hour: int
  last_validation_summary: Dictionary
}
```

队列上限：

```text
当前执行指令 + 最多 3 条预输入指令
```

`Command.source` 枚举：

```text
explicit_player
timeout_managed
system_fallback
```

`Command.status` 枚举：

```text
queued
running
completed
skipped
failed
```

## 5. 校验、兜底与托管

`CommandValidationResult.phase`：

```text
enqueue
before_execution
```

新增普通指令必须经过入队校验；从预输入转入执行前必须再次校验。

`FallbackState` 检查点：

```text
FallbackState.force_speed = N1
FallbackState.f1_eligible = false
```

自动兜底只用于防止角色冻结和提示玩家补指令，不得作为长期 F1 计划依据。

`ManagedActionState` 检查点：

```text
source 必须可追溯；
只有玩家主动输入或房间超时规则可生成；
低价值事件可保守处理；
重大事件仍走局部时停 / B1 / P0。
```

## 6. 事件、交锋与突破字段

`event_time_mode`：

```text
info
local_time_stop
light_encounter
formal_encounter_b1
breakthrough_b1
global_pause_p0
```

`LocalTimeStopState` 必须记录：

```text
frozen_world_day
frozen_world_hour
current_gap_hours
gap_limit_hours = 24
warning_stage = none | soft | hard | limit
safe_default_option_ref
p0_required_if_timeout
```

`CatchupSettlementState` 必须满足：

```text
deterministic_only = true
random_events_blocked = true
```

`FormalEncounterState` 检查点：

```text
round_game_hours = 1
round_real_seconds = 60
hard_cap_rounds <= 24
突破挑战使用 encounter_type = breakthrough
突破挑战资源消耗记录到轮内结果包
```

## 7. 资源输入字段

丹药、灵材、符箓和临时 boost 统一作为行动或事件选项的资源输入，不作为默认独立“丹药炼化”行动。

`ActionResourceInputBinding` 必须能追溯：

```text
owner_character_id
source_container_id
item_instance_id
resource_template_id
bound_command_id 或 bound_event_option_id
compatible_hours
consumed_at_world_day
consumed_at_world_hour
residual_policy
active_effect_ref
```

未完全消耗的资源效果进入：

```text
ActiveResourceEffect
```

并记录：

```text
remaining_compatible_hours
stack_policy
expires_when
log_refs
```

## 8. 修炼数值、世界产出预算与阶段预算字段

修炼数值主源为 `docs/systems-design/cultivation-realm-numeric-balance.md`。推荐字段：

| 中文术语 | 含义 | 推荐字段 |
| --- | --- | --- |
| 境界段 | 从一个稳定修炼状态到下一个关键里程碑的最小数值成长段 | `RealmSegment` |
| 境界段平衡表 | 修炼数值根表，定义目标时间、有效小时占比、阈值和效率边界 | `RealmSegmentBalance` |
| 标准化境界段进度 | 当前段调参进度，默认 0.0-1.0+ | `normalized_segment_progress` |
| 当前境界段 ID | 当前角色所处数值成长段 | `current_realm_segment_id` |
| 修为点 | 表现值、阈值和日志映射，不直接线性等于战斗力 | `cultivation_points` |
| 行动修炼效率模板 | 行动相对当前境界段基准的效率和策略字段 | `ActionCultivationProfile` |
| 境界适配矩阵 | 功法、资源、设施、节点灵气和宗门支持的品阶 / 相性适配 | `RealmInputFitMatrix` |
| 资源效果平衡 | 资源按基准兼容小时、贡献上限、压力和突破修正定价 | `ResourceEffectBalance` |
| 状态压力模型 | 高效率修炼带来的经脉压力、伤势和心魔惩罚曲线 | `StatePressureModel` |
| 节点境界支持 | 节点灵气、容量、消耗、再生、风险和机会窗口支持 | `NodeRealmSupport` |
| 宗门支持平衡 | 宗门资源、设施、护法、功法、节点和情报支持 | `SectSupportBalance` |
| 世界产出预算状态 | 世界资源、物品和机会投放的底层预算账本 | `WorldProductionBudgetState` |
| 世界物品预算阶层 | 按阶级维护的物品生成预算帽 | `WorldItemBudgetTier` |
| 世界资源投放预算 | 区域、节点、机会、稀有和后手资源的投放预算 | `WorldResourceBudget` |
| 资源池 | 节点、区域或系统中的潜在产能 / 可采资源量，不是显性库存 | `ResourcePool` |
| 预算价值 | 扣除世界生成预算使用的价值，不等于市场价格 | `BudgetValue` |
| 资产生成请求 | 事件、采集、秘境、任务、交易或 NPC 掉落发起的生成请求 | `AssetGenerationRequest` |
| 资产生成结果 | 资产生成成功 / 失败、预算扣除和目标容器记录 | `AssetGenerationResult` |
| 阶段预算状态 | 当前世界稳定投放的最高资源阶段和预算池 | `WorldStageBudgetState` |
| 境界预算池 | 单个境界阶段对底层世界产出预算的分配切片 | `RealmBudgetPool` |
| 修炼 tick 结果 | 每小时修炼收益、效率、压力、资源消耗和调试公式明细 | `CultivationTickResult` |
| 当前世代效率指数 | 当前世代相对境界段基准的推进效率 | `CEI` |

必须避免：

```text
行动模板直接写死 raw 修为收益；
资源直接无条件给角色修为；
把阶段预算当成唯一预算或覆盖资源流转旧设定；
阶段预算直接赠送修为；
世界生成预算在出售、拆解、销毁、上交、损坏或消耗后返还；
高于当前预算境界的 NPC 无来源晋升；
寿元或事件门槛半强迫轮回。
```

## 9. 回放与结果包字段

回放主结构：

```text
TimelineReplay {
  room_id: String
  replay_segment_id: String
  start_world_day: int
  start_world_hour: int
  end_world_day: int
  end_world_hour: int
  speed_segments: Array
  submitted_command_changes: Array
  command_validation_records: Array
  fallback_records: Array
  managed_action_records: Array
  local_time_stop_records: Array
  catchup_records: Array
  formal_encounter_rounds: Array
  global_pause_records: Array
  sect_ai_steps: Array
  rng_trace: Array
  settlement_steps: Array
  event_outcomes: Array
  result_packages: Array
  player_timeline_summaries: Dictionary
  final_state_hash: String
  debug_notes: Array
}
```

结果包最低要求：

```text
每个 result_package 必须带 world_day / world_hour；
每次速度变化必须写入 speed_segments；
每次队列变更必须写入 submitted_command_changes；
每次校验失败必须写入 command_validation_records 与个人日志；
每次 B1 交锋轮必须写入 formal_encounter_rounds。
```

## 10. 内容模板字段

行动模板：

```text
long_low_interaction: bool
f1_eligible_when_explicit: bool
can_be_auto_fallback: bool
risk_sensitive_fallback: bool
default_duration_hours: int | null
resource_input_slots: Array
```

节点模板：

```text
risk_level: low | medium | high | unknown
safe_fallback_action: meditate | rest
route_edges: Array
resource_slots: Array
visibility_policy: String
```

事件模板：

```text
event_time_mode: info | local_time_stop | light_encounter | formal_encounter_b1 | breakthrough_b1 | global_pause_p0
safe_default_option_ref: String | null
p0_required_if_timeout: bool
visibility_policy: String
result_package_template: String
```

突破模板：

```text
open_requirements
round_templates
default_strategy_options
round_resource_consumption
result_report_template
```

## 11. Deprecated aliases 与迁移说明

| 旧术语 / 字段 | 当前处理 | 说明 |
| --- | --- | --- |
| `quarter` | 废弃玩家回合语义；若表示世界宏观周期，迁为 `macro_period_id` / `season_id` | 不再作为玩家最小推进单位 |
| `current_quarter` | 废弃；改用 `current_world_day / current_world_hour / current_macro_period_id` | 不再保存当前玩家回合 |
| `turn_id` | 不作为 active concept | v2.2 曾作为玩家最小同步回合，v2.3 已被连续日历取代 |
| `action_slot` / `remaining_action_slots` | 废弃 | 不做 6 个朔望行动格，也不做固定行动槽预算 |
| `TurnReplay` / `QuarterReplay` | 废弃；改用 `TimelineReplay` | 回放按连续时间片段记录 |
| `SectDecisionIntent` | 移除 | 玩家不提交宗门主行动意图 |
| 宗门主行动输入 / 主行动建议 / 宗门提案 | 移除 | 宗门 AI 自行维护 `SectContinuousActionState` |
| 玩家侧未来跳转 | 移除 | 不做推进至下一事件、下一关键节点、月末等功能 |

## 12. 新增字段准入规则

新增 schema、接口、存档字段或 UI 状态前，必须满足：

```text
1. 能落到 world_day / world_hour，或明确属于 macro_period_id。
2. 能说明是否需要 SpeedState 记录速度变化。
3. 能说明是否需要进入 TimelineReplay。
4. 能说明玩家可见性层级。
5. 能区分 explicit_player、system_fallback、timeout_managed。
6. 能说明是否需要 CommandValidationResult。
7. 能说明是否会影响 ResultPackage。
8. 能说明是否会暴露私人归因给其他玩家。
```

若字段无法满足以上条件，需要先补充到本术语表或字段检查清单，再进入实现。

## 13. 来源与裁决

吸收来源：

```text
v2.3 03_术语表_命名规范_字段统一
v2.3 04_字段命名与开发检查清单
v2.3 01_运行时状态_数据模型_结果包
v2.3 01_共享日历_房间推进_权威结算
v2.3 08_事件突破战斗时间规则
修为年限、境界收益与阶段预算数值设计
```

参考来源：

```text
v2.1 字段迁移对照表
v2.2 术语表、房间推进与冲突决议
阶段性规则：自适应流速可暂停日历制 v2
阶段性规则：指令预输入机制 v1
```

裁决：

| 采用方案 | 废弃方案 | 原因与影响 |
| --- | --- | --- |
| `world_day / world_hour / hour_tick` | `turn_id`、`quarter`、`current_quarter` | v2.3 将共享连续日历定为唯一运行时间事实 |
| `CommandQueue` 当前 + 3 后续 | `action_slot`、6 个朔望行动格、条件脚本 | 玩家只提交少量线性普通指令 |
| `TimelineReplay` | `TurnReplay` / `QuarterReplay` | 连续日历需要记录速度片段和状态变化，而不是回合报告 |
| `SectContinuousActionState` | `SectDecisionIntent`、宗门主行动输入 | 宗门由 AI 演化，玩家只间接影响 |
| `RealmSegmentBalance` / `normalized_segment_progress` | 所有境界共用一个 raw CP 小时收益 | 境界段目标时间、资源适配和突破准备需要稳定调参单位 |
| `WorldProductionBudgetState` | 资源、物品或机会无预算来源刷新 | 世界产出预算是底层投放账本，必须保留预算扣除、预留和日志 |
| `WorldStageBudgetState` | 无来源高阶资源刷新、直接加修为或替代底层预算 | 阶段预算只做境界调度，实际投放必须落到底层预算、资源池和资产来源 |
