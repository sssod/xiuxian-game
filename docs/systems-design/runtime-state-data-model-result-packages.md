# 运行时状态、数据模型与结果包

状态：第三批正式定稿
更新日期：2026-05-08
来源主版本：v2.3 calendar_preinput

## 1. 系统定位

本文定义运行时状态、数据模型、结果包、存档、回放、调试与 QA 检查的开发交付合同。

它不是最终数据库 schema，也不指定 Godot Resource、JSON、SQLite 或混合存储的最终工程实现。它用于约束：

```text
哪些状态必须存在；
主时间字段如何统一；
子系统如何输出结果包；
存档必须保存哪些状态；
TimelineReplay 如何复盘；
Debug 面板与 QA 脚本应检查什么；
旧字段如何迁移。
```

核心原则：

```text
客户端提交 intent；
服务器权威校验；
子系统输出 ResultPackage；
S1 合并结果包并回写状态；
所有高价值变化写日志；
存档保存权威状态，不保存临时 UI；
文案与规则分离；
回放记录连续时间片段；
Debug 信息不进入普通玩家 UI。
```

## 2. 总体原则

运行时状态以连续世界日历为主事实：

```text
world_day / world_hour 是主时间字段；
TimeConfig 配置速度和 tick；
SpeedState 表达公开速度与调试阻塞项；
CommandQueue 保存当前指令与最多 3 条预输入；
TimelineReplay 记录连续时间片段；
SpeedState / LocalTimeStopState / CatchupSettlementState / FormalEncounterState / GlobalPauseState 是时间系统核心状态。
```

角色、真灵、宗门、地图、资产容器、物品、功法、资源输入、残余效果、后手、结果包基础结构是开发底座。任何新增状态必须能说明：

```text
主时间；
可见性；
结果包输出；
日志层级；
回放记录；
存档位置；
Debug / QA 检查方式。
```

## 3. 运行时根状态

`RuntimeWorldState` 是建议的内存聚合边界，用于表达一个房间加载后的权威世界快照。

```text
RuntimeWorldState {
  room_state: RoomState
  player_runtime_states: Dictionary
  true_spirit_states: Dictionary
  character_states: Dictionary
  cultivation_states: Dictionary
  method_states: Dictionary
  sect_states: Dictionary
  world_map_state: WorldMapState
  npc_states: Dictionary
  asset_containers: Dictionary
  item_instances: Dictionary
  active_resource_effects: Dictionary
  contingency_records: Dictionary
  legacy_records: Dictionary
  event_states: Dictionary
  formal_encounters: Dictionary
  visibility_states: Dictionary
  rng_state: Dictionary
  log_state: LogState
  timeline_replay_index: Array
}
```

说明：

1. `RuntimeWorldState` 是开发整理用的聚合视图，不要求最终数据库有同名表。
2. 子系统内部可拆分存储，但对 S1 合并结果包时必须能提供一致快照。
3. 临时 UI 状态、悬停、筛选、面板展开状态不进入权威运行时状态。
4. 可重建缓存可以保存，但必须标记为缓存，并能从权威状态重建。

## 4. RoomState

`RoomState` 是房间级主状态。

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
  ai_controlled_factions: Array

  world_state_version: int
  pending_decisions: Dictionary
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

规则：

1. `current_world_day / current_world_hour` 是房间权威时间。
2. `current_macro_period_id` 只表达季节、旬月、灾变期、资源再生批次等宏观周期。
3. `pending_decisions` 用于 P0、同步保护、未解决公共事件和必要默认策略。
4. `world_state_version` 每次权威写回递增，用于存档、回放和客户端同步。

## 5. TimeConfig

```text
TimeConfig {
  server_tick_unit: String
  hours_per_game_day: int

  speed_profiles: Dictionary
  n1_real_seconds_per_game_hour: int
  f1_real_seconds_per_game_day: int
  b1_real_seconds_per_game_hour: int

  local_gap_limit_hours: int
  local_gap_soft_warning_hours: int
  local_gap_hard_warning_hours: int
  catchup_max_real_seconds_per_day: int

  command_queue_max_pending: int
  enable_player_side_future_jump: bool
  allow_host_pause: bool
}
```

默认合同：

```text
server_tick_unit = hour
hours_per_game_day = 24
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

实现不得把公开速度配置转换成客户端未来跳转能力。F1 仍是服务端连续 `hour_tick` 压缩推进。

## 6. SpeedState

```text
SpeedState {
  current_speed: String
  previous_speed: String
  changed_at_world_day: int
  changed_at_world_hour: int
  public_reason_key: String
  private_reason_refs: Array
  blockers: Array
  f1_eligible_player_refs: Array
  n1_forced_by_refs: Array
  b1_encounter_ref: String | null
  p0_pause_ref: String | null
}
```

`current_speed` 仅允许：

```text
F1
N1
B1
P0
```

客户端普通 UI 只读取：

```text
current_speed
public_reason_key
```

服务端日志和 Debug 面板可读取：

```text
private_reason_refs
blockers
f1_eligible_player_refs
n1_forced_by_refs
b1_encounter_ref
p0_pause_ref
```

速度变化必须写入 `TimelineReplay.speed_segments`，并带 `changed_at_world_day / changed_at_world_hour`。

## 7. PlayerRuntimeTimeState

`PlayerRuntimeTimeState` 聚合单个玩家在时间系统中的运行状态。

```text
PlayerRuntimeTimeState {
  player_id: String
  character_id: String

  command_queue: CommandQueue
  current_action_state_ref: String | null

  local_time_stop: LocalTimeStopState | null
  catchup_state: CatchupSettlementState | null
  fallback_state: FallbackState | null
  managed_state: ManagedActionState | null

  last_synced_world_day: int
  last_synced_world_hour: int
  personal_log_refs: Array
}
```

规则：

1. `last_synced_world_day / last_synced_world_hour` 用于客户端同步和个人摘要，不替代房间权威时间。
2. 玩家处于 `local_time_stop` 时，角色自身行动和资源变化冻结在 `frozen_world_day / frozen_world_hour`。
3. 玩家处于 `catchup_state` 时，只执行确定性补结算。
4. `fallback_state` 和 `managed_state` 不得混用来源。

## 8. CommandQueue 与 Command

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

`Command`：

```text
Command {
  command_id: String
  command_type: String
  actor_ref: String
  character_id: String

  target_node_id: String | null
  target_ref: String | null
  duration_hours: int | null

  selected_items: Array
  resource_inputs: Array
  location_requirement: String | null

  seclusion_policy: String | null
  managed_mode: ManagedMode | null

  created_world_day: int
  created_world_hour: int
  submitted_by_player_id: String
  source: String
  status: String

  validation_history: Array
  log_refs: Array
}
```

`Command.source`：

```text
explicit_player
timeout_managed
system_fallback
```

`Command.status`：

```text
queued
running
completed
skipped
failed
```

常用 `command_type`：

```text
cultivate
meditate
rest
heal
craft
travel
visit
apply_resource
breakthrough_open
minor_breakthrough
managed
```

新增 `command_type` 必须先说明行动模板、校验项、资源输入、结果包输出、可见性和回放字段。

## 9. CommandValidationResult

```text
CommandValidationResult {
  command_id: String
  checked_world_day: int
  checked_world_hour: int
  phase: String
  passed: bool
  failed_reason: String | null
  failed_reason_tags: Array
  resource_check: Dictionary
  location_check: Dictionary
  state_check: Dictionary
  event_conflict_check: Dictionary
  log_ref: String | null
}
```

`phase`：

```text
enqueue
before_execution
```

规则：

1. 入队时只校验当前已知合法性。
2. 从预输入转执行前必须再次校验。
3. 校验失败必须写入 `command_validation_records` 和个人日志。
4. 校验失败不得提前消耗关键资源。
5. 若队列因此为空或无法继续，进入 `FallbackState`。

## 10. FallbackState 与 ManagedActionState

`FallbackState`：

```text
FallbackState {
  fallback_id: String
  character_id: String
  started_world_day: int
  started_world_hour: int
  reason: String
  node_risk: String
  action_type: String
  expected_reward_level: String
  f1_eligible: bool
  force_speed: String
  replaced_by_command_ref: String | null
  log_refs: Array
}
```

约束：

```text
f1_eligible = false
force_speed = N1
expected_reward_level = very_low | low
```

`FallbackState.reason`：

```text
queue_empty
validation_failed
invalid_location
insufficient_resource
blocked_by_state
```

`ManagedActionState`：

```text
ManagedActionState {
  managed_id: String
  character_id: String
  source: String
  started_world_day: int
  started_world_hour: int
  duration_hours: int | null
  low_risk_action: String
  mid_high_risk_action: String
  low_value_event_policy: String
  major_event_policy: String
  f1_eligible_if_safe: bool
  log_refs: Array
}
```

`ManagedActionState.source`：

```text
explicit_player
room_timeout_policy
```

自动兜底用于防止角色冻结；显式托管是玩家主动设置或房间超时策略。二者不能混成同一来源。

## 11. LocalTimeStopState 与 CatchupSettlementState

`LocalTimeStopState`：

```text
LocalTimeStopState {
  stop_id: String
  character_id: String
  event_id: String
  frozen_world_day: int
  frozen_world_hour: int
  current_gap_hours: int
  gap_limit_hours: int
  warning_stage: String
  safe_default_option_ref: String | null
  p0_required_if_timeout: bool
  started_real_time: String
  status: String
  log_refs: Array
}
```

`warning_stage`：

```text
none
soft
hard
limit
```

`status`：

```text
active
resolved_by_player
resolved_by_default
escalated_to_p0
```

`CatchupSettlementState`：

```text
CatchupSettlementState {
  catchup_id: String
  character_id: String
  from_world_day: int
  from_world_hour: int
  to_world_day: int
  to_world_hour: int
  deterministic_only: bool
  random_events_blocked: bool
  settled_hours: int
  max_real_seconds: int
  status: String
  result_package_refs: Array
  log_refs: Array
}
```

约束：

```text
deterministic_only = true
random_events_blocked = true
```

C1 追赶必须记录补结算区间和结果包引用。

## 12. FormalEncounterState 与 GlobalPauseState

`FormalEncounterState`：

```text
FormalEncounterState {
  encounter_id: String
  encounter_type: String
  participants: Array
  started_world_day: int
  started_world_hour: int
  current_round_index: int
  round_game_hours: int
  round_real_seconds: int
  max_rounds: int
  hard_cap_rounds: int
  public_visibility: String
  default_strategy_refs: Dictionary
  submitted_round_actions: Dictionary
  status: String
  result_package_refs: Array
  log_refs: Array
}
```

`encounter_type`：

```text
combat
breakthrough
secret_realm
player_conflict
```

约束：

```text
round_game_hours = 1
round_real_seconds = 60
hard_cap_rounds <= 24
突破挑战使用 encounter_type = breakthrough
```

`GlobalPauseState`：

```text
GlobalPauseState {
  pause_id: String
  pause_type: String
  started_world_day: int
  started_world_hour: int
  participants_required: Array
  default_resolution_policy: String | null
  status: String
  public_reason_key: String
  private_reason_refs: Array
  log_refs: Array
}
```

`pause_type`：

```text
global_gate
public_decision
sync_protection
host_pause
```

P0 必须有合法公开原因和必要的私人引用。主机暂停是房间规则能力，不是玩法事件。

## 13. ResultPackage

`ResultPackage` 是子系统向 S1 提交状态变化的唯一交付单位。

```text
ResultPackage {
  package_id: String
  source_system: String
  world_day: int
  world_hour: int

  time_mode: String
  speed_before: String
  speed_after: String
  consumed_hours: int

  character_delta: Dictionary
  inventory_delta: Dictionary
  resource_effect_delta: Dictionary
  node_delta: Dictionary
  sect_delta: Dictionary
  route_delta: Dictionary

  command_delta: Dictionary
  fallback_delta: Dictionary
  local_time_stop_delta: Dictionary
  catchup_delta: Dictionary
  formal_encounter_delta: Dictionary
  global_pause_delta: Dictionary

  triggered_child_events: Array
  ledger_entries: Array
  visible_log_entries: Array
  hidden_world_log_entries: Array
  debug_log_entries: Array
}
```

`time_mode`：

```text
normal_tick
local_stop_choice
catchup
b1_round
p0_resolution
fallback
```

扩展 delta 命名建议：

```text
visibility_delta
rumor_entries
relationship_delta
npc_delta
event_window_delta
risk_level_delta
asset_transfer_records
resource_use_records
reservation_records
contingency_delta
legacy_delta
trade_records
```

规则：

1. 每个结果包必须带 `world_day / world_hour`。
2. 每个结果包必须声明 `source_system`。
3. 消耗世界时间的结果包必须记录 `consumed_hours`。
4. 速度变化必须记录 `speed_before / speed_after`。
5. 私人信息和 Debug 信息必须进入对应日志层，不得混入公开日志。
6. 子系统不得直接写其他系统权威状态，只能提交 delta。

## 14. 子系统输出合同

各 canonical 系统至少输出以下结果包字段。

| 系统 | 主要输出 |
| --- | --- |
| S1 共享日历 / 房间结算 | `speed_segments`、`settlement_steps`、`result_packages`、`global_pause_delta` |
| S2 角色 / 真灵 / 修炼 | `character_delta`、`resource_effect_delta`、`ledger_entries`、`visibility_delta` |
| S3 行动队列 / 移动 / 托管 | `command_delta`、`fallback_delta`、`route_delta`、`visible_log_entries` |
| S4 地图 / 世界演化 | `node_delta`、`route_delta`、`resource_slot_delta`、`event_window_delta`、`rumor_entries` |
| S5 宗门 / 库存 / AI | `sect_delta`、`inventory_delta`、`reservation_records`、`node_delta`、`rumor_entries` |
| S6 经济 / 物品 / NPC | `inventory_delta`、`currency_delta`、`resource_effect_delta`、`asset_transfer_records`、`npc_delta` |
| S7 后手 / 遗产 / 可见性 | `contingency_delta`、`legacy_delta`、`visibility_delta`、`rumor_entries` |
| S8 事件 / 突破 / 战斗 | `event_outcomes`、`formal_encounter_delta`、`character_delta`、`triggered_child_events` |

若一个系统需要多个 delta，应拆成可审计的结果包或在同一结果包中明确每个 delta 的来源引用。

## 15. TimelineReplay

`TimelineReplay` 是唯一回放主结构。

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

回放验收：

```text
同一随机种子和输入记录可复现关键结果；
速度片段可解释每次 F1/N1/B1/P0 变化；
队列变更和校验失败可追溯；
局部时停、C1、B1、P0 均可定位到 world_hour；
final_state_hash 可用于回归测试；
玩家可见回放必须按 visibility_policy 过滤。
```

必须进入 `TimelineReplay`：

```text
速度变化；
队列编辑；
指令校验；
自动兜底；
显式托管；
局部时停；
C1 追赶；
B1 交锋轮；
P0 全局暂停；
宗门 AI 步骤；
节点和资源关键变化；
资产高价值变化；
后手和遗产变化；
事件结果；
所有 ResultPackage；
最终状态 hash。
```

## 16. SaveGame

`SaveGame` 是存档根结构建议。

```text
SaveGame {
  save_version: String
  room_state: RoomState
  player_states: Dictionary
  true_spirit_states: Dictionary
  character_states: Dictionary
  world_map_state: WorldMapState
  sect_states: Dictionary
  npc_states: Dictionary
  asset_containers: Dictionary
  active_resource_effects: Dictionary
  contingency_records: Dictionary
  timeline_replay_index: Array
  rng_state: Dictionary
  visible_logs: Array
  hidden_world_logs: Array
  debug_logs: Array
}
```

建议补充：

```text
method_states
item_instances
legacy_records
visibility_states
event_states
formal_encounter_states
save_metadata
```

存档必须保存：

```text
TimeConfig
SpeedState
CommandQueue
Command validation history
FallbackState
ManagedActionState
LocalTimeStopState
CatchupSettlementState
FormalEncounterState
GlobalPauseState
TimelineReplay index
world_day / world_hour / macro_period_id
角色与真灵
宗门 AI 当前持续行动
地图节点、资源槽、秘境窗口
ActiveResourceEffect
资产容器与物品
后手与遗产
可见性与传闻
日志与随机状态
```

存档写入点：

```text
手动保存；
P0 开始与结束；
B1 交锋开始与结束；
局部时停开始、默认处理和结束；
C1 追赶完成；
角色死亡与转世；
重要节点窗口变化；
正式后手创建、触发、失败、争夺；
服务器关闭或房间暂停。
```

## 17. SaveMetadata 与迁移

```text
SaveMetadata {
  save_version: String
  ruleset_version: String
  content_version: String
  created_at: String
  last_loaded_at: String
  migration_history: Array
}
```

迁移记录必须说明：

```text
从哪个版本迁移到哪个版本；
哪些字段新增、删除、重命名；
哪些数据被默认补齐；
哪些旧存档无法兼容；
迁移后 final_state_hash 是否重算；
迁移脚本或人工修复记录。
```

存档格式技术选型是技术决策门。MVP 原型可使用最容易调试的格式，但多人长期房间必须评估查询、迁移、备份和损坏恢复能力。

## 18. 数据模板范围

MVP 至少需要：

```text
character_origin_templates
realm_templates
method_templates
method_carrier_templates
action_templates
resource_effect_templates
item_templates
node_templates
route_templates
sect_templates
sect_ai_policy_templates
event_templates
formal_encounter_templates
breakthrough_templates
contingency_templates
ui_text_templates
```

模板文件最低字段：

```text
template_id
version
display_name
tags
requirements
effects
result_package_template_ref
debug_notes
```

文案与规则分离：

```text
规则模板使用稳定 id、tags、requirements、effects；
中文名、修仙包装、描述和 UI 文案进入 ui_text_templates 或本地化表；
规则代码不得写死具体世界观名称；
模板必须能指向结果包模板或明确输出规则。
```

MVP 推荐使用 JSON 或 Godot Resource 承载模板数据。底层格式不影响字段命名合同。

## 19. 关键模板结构

`ActionTemplate`：

```text
ActionTemplate {
  action_template_id: String
  command_type: String
  default_duration_hours: int | null
  min_duration_hours: int | null
  max_duration_hours: int | null
  long_low_interaction: bool
  f1_eligible_when_explicit: bool
  can_be_auto_fallback: bool
  risk_sensitive_fallback: bool
  resource_input_slots: Array
  event_trigger_profile: Dictionary
  result_package_template_ref: String
}
```

`EventTemplate`：

```text
EventTemplate {
  event_template_id: String
  event_time_mode: info | local_time_stop | light_encounter | formal_encounter_b1 | breakthrough_b1 | global_pause_p0
  trigger_conditions: Dictionary
  visibility_policy: String
  safe_default_option_ref: String | null
  p0_required_if_timeout: bool
  option_templates: Array
  result_package_template_ref: String
}
```

`BreakthroughTemplate`：

```text
BreakthroughTemplate {
  breakthrough_template_id: String
  realm_from: String
  realm_to: String
  open_requirements: Dictionary
  round_templates: Array
  default_strategy_options: Array
  round_resource_consumption: Dictionary
  success_result_templates: Array
  failure_result_templates: Array
  result_report_template: String
}
```

`BreakthroughRoundTemplate`：

```text
BreakthroughRoundTemplate {
  round_index: int
  situation_text_ref: String
  strategy_options: Array
  resource_input_options: Array
  risk_tags: Array
  result_modifiers: Dictionary
}
```

模板必须引用 v2.3 字段。不得恢复 `action_slot`、`quarter`、宗门主行动建议或直接服丹涨修为模板。

## 20. 日志分层

日志层级：

```text
personal_log
party_log
sect_log
public_world_log
rumor_log
hidden_world_log
debug_log
```

日志写入必须记录：

```text
world_day
world_hour
source_system
visibility_policy
result_package_ref
related_replay_segment_id
```

必须能追踪：

```text
个人 Command 提交与服务端校验；
托管和兜底生成原因；
资源预留、消耗、释放；
ActionResourceInputBinding 创建和消耗；
ActiveResourceEffect 生成、衰减、过期；
库存转移；
宗门 AI 当前持续行动计划、推进和结果；
节点控制权变化；
资源槽枯竭、污染、再生、异变；
秘境开启、关闭、坍缩；
突破关键资源消耗；
事件选项临时追加资源输入；
突破失败标签；
B1 轮指令与结果；
死亡、转世、遗产分配；
正式后手创建、暴露、受损、回收、失效；
多人可见性和传闻生成。
```

私人归因不得进入公开日志。公开日志可以记录中性后果。

## 21. Debug 面板

Debug 面板最小显示：

```text
world_day / world_hour
current_speed
speed blockers
f1 eligibility per player
players in auto fallback
players in explicit managed action
local time stop gap
catchup queue
formal encounter round timer
global pause reason
last command validation result
fallback reason
TimelineReplay current segment
rng state hash
last result packages
```

Debug 面板可扩展：

```text
current RoomState hash
last ResultPackage diff
pending decisions
active SectContinuousActionState
node risk and event windows
asset transfer trace
contingency and legacy trace
visibility filter preview
save writeback status
migration history
```

普通玩家 UI 不得显示 `private_reason_refs`、`hidden_world_log_entries`、`debug_log_entries`、完整 `rng_trace` 或其他玩家私人归因。

## 22. QA 自动检查

QA 脚本应检查：

```text
所有结果包含 world_day / world_hour；
CommandQueue.pending_command_refs 数量不超过 3；
FallbackState.f1_eligible=false；
FallbackState.force_speed=N1；
CatchupSettlementState.deterministic_only=true；
CatchupSettlementState.random_events_blocked=true；
FormalEncounterState.round_game_hours=1；
FormalEncounterState.round_real_seconds=60；
TimelineReplay.speed_segments 非空；
私人归因字段没有进入公开日志；
事件模板均有 event_time_mode；
ActionTemplate 不含 action_slot；
ResultPackage.source_system 非空；
ResultPackage.package_id 唯一；
存档包含 rng_state 或可复盘 rng_trace；
final_state_hash 可生成；
Debug 字段不进入普通玩家 UI。
```

失败项应能定位到：

```text
数据文件；
模板 id；
结果包 id；
回放 segment；
世界时间；
source_system；
相关日志引用。
```

## 23. UI 与开发交付约束

UI 读取原则：

```text
普通玩家 UI 读可见状态和公开摘要；
Debug UI 可读隐藏世界和调试状态；
UI 不自行推演权威结算；
UI 不把本地编辑态写入存档主状态；
UI 不显示其他玩家私人事件归因；
UI 必须能从 ResultPackage 生成个人摘要和公开摘要。
```

开发交付约束：

1. 新状态字段必须先通过术语与字段检查。
2. 新系统必须声明 `source_system`。
3. 新 delta 必须说明合并顺序和冲突策略。
4. 新模板必须引用 `result_package_template_ref` 或明确结果输出。
5. 存档字段必须有版本迁移策略。
6. Debug 面板不得成为玩家 UI 的数据来源。

## 24. Deprecated aliases 与迁移说明

| 旧口径 | 当前处理 | 说明 |
| --- | --- | --- |
| `turn_id` 作为主同步单位 | 废弃 | 主时间为 `world_day / world_hour` |
| `current_turn_id` | 废弃 | `RoomState` 使用 `current_world_day / current_world_hour / current_macro_period_id` |
| `turn_config` | 废弃 | 改为 `TimeConfig` |
| `current_phase` 回合阶段 | 废弃 | 改为 `runtime_state` 和具体时间状态 |
| `PersonalActionInstruction` | 迁移为 `Command` | 玩家输入为短线性指令队列 |
| `created_turn_id` | 废弃 | 改为 `created_world_day / created_world_hour` |
| `started_turn_id` | 废弃 | 改为 `started_world_day / started_world_hour` |
| `expected_duration_turns` | 废弃 | 改为 `expected_duration_hours` |
| `action_slot / remaining_action_slots` | 废弃 | 不做固定行动格预算 |
| `consumed_ticks` | 废弃 | 改为 `consumed_hours` |
| `TurnReplay` / `QuarterReplay` | 废弃 | 改为 `TimelineReplay` |
| `SectDecisionIntent` | 移除 | 玩家不提交宗门主行动意图 |
| 宗门主行动输入 / 建议 / 提案 | 移除 | 宗门 AI 维护 `SectContinuousActionState` |
| 玩家侧未来跳转 | 移除 | F1 是服务端连续压缩推进 |
| `learned_sections / missing_sections` | 移除出 `MethodState` | 残页 / 章节是资产、线索或合成材料 |
| 丹药炼化默认独立行动 | 废弃 | 使用 `ActionResourceInputBinding` 与 `ActiveResourceEffect` |

## 25. 来源与裁决

吸收来源：

```text
v2.3 01_运行时状态_数据模型_结果包
v2.3 09_数据驱动_存档_服务端调试
v2.3 03_术语表_命名规范_字段统一
v2.3 01_共享日历_房间推进_权威结算
v2.3 03_个人行动队列_移动通行_托管
v2.3 08_事件突破战斗时间规则
v2.3 05_宗门组织_库存_宗门AI持续行动
v2.3 04_地图节点_世界演化
v2.3 06_经济物品资产_NPC持久化
v2.3 07_后手遗产_可见性_多人间接竞争
v2.3 02_MVP开发切片与验收清单
v2.3 05_原始文档映射与来源索引
```

参考来源：

```text
v2.2 运行时状态_数据模型_结果包
v2.2 数据驱动_存档_服务端调试
旧版 S14 数据驱动、存档、服务端与调试子系统设计案
旧版 20260427 运行时状态_数据模型_结果包
旧版 20260427 数据驱动、存档、服务端与调试
```

裁决：

| 采用方案 | 废弃方案 | 原因与实现影响 |
| --- | --- | --- |
| `RoomState` + 时间状态对象作为运行时核心 | `current_turn_id` + 回合阶段机 | 连续日历需要按小时、速度状态和局部时停复盘 |
| `TimeConfig` / `SpeedState` | `TurnConfig` / 旧回合倒计时 | 速度档位、gap、C1 和 B1 轮都需要统一配置 |
| `Command` / `CommandQueue` | `PersonalActionInstruction`、行动格队列 | 玩家只提交当前 + 最多 3 条预输入 |
| `ResultPackage` 作为子系统输出单位 | 子系统直接写世界状态 | S1 统一合并，便于日志、存档、回放和调试 |
| `TimelineReplay` | `TurnReplay` / `QuarterReplay` | 回放按连续时间片段和速度变化记录 |
| `SaveGame` 保存权威状态与 replay index | 存 UI 临时态或只存回合报告 | 私人服务器和本地单测都需要可恢复、可复盘 |
| 日志按可见性分层 | 世界日志全量公开 | 多人间接竞争依赖私人归因隔离 |
| 数据模板引用结果包模板 | 规则代码写死世界观名称和效果 | 数据驱动、QA 和后续内容生产需要稳定 id 与可审计输出 |
| 存档格式作为技术决策门 | 立即定死数据库或文件格式 | 当前是文档交付阶段，保留实现评估空间 |
