# 共享日历、房间推进与权威结算

状态：首批正式定稿
更新日期：2026-05-08
来源主版本：v2.3 calendar_preinput

## 1. 系统定位

S1 是共享世界日历与权威结算总线，负责维护绝对世界时间、速度状态、服务器小时 tick、行动结算、事件处理、宗门 AI 推进、节点演化、结果包合并、日志与回放。

S1 职责：

1. 维护 `world_day / world_hour`。
2. 根据全体玩家和世界状态决定公开速度 F1 / N1 / B1 / P0。
3. 在 `hour_tick` 上推进角色行动、宗门 AI、节点状态、事件触发、资源效果和日志。
4. 处理个人局部时停、gap 上限与 C1 追赶补结算。
5. 处理 B1 正式交锋轮与 P0 全局暂停。
6. 合并行动、事件、交锋、突破、资产、宗门、节点结果包。

## 2. 房间运行目标

MVP 房间必须支持：

1. 本地单人测试。
2. 私人服务器部署。
3. 至少 3 名玩家共玩。
4. 保存、暂停、恢复、续开。
5. 无人在线时世界保持静止，除非房间规则显式允许离线托管时间推进。
6. 普通行动在世界运行中持续结算。
7. P0 全局事件、B1 交锋轮和局部时停均可被日志、回放和调试复盘。
8. 速度切换不泄露私人事件归因。
9. 行动完成、队列为空、预输入校验失败时不会冻结角色，而是触发风险兜底。

## 3. 世界时间与速度档位

基础时间单位：

```text
1 游戏日 = 24 游戏小时
1 游戏年 = 360 游戏日
服务器最小结算单位 = 1 游戏小时
```

`1 游戏年 = 360 游戏日` 是数值换算基准，用于修为年限、寿元压力和世界产出预算的阶段调度表。它不改变 S1 的最小结算单位；所有系统仍以 `world_day / world_hour` 和 `hour_tick` 作为运行时事实。

公开速度档位：

| 档位 | 名称 | 现实时间 : 游戏时间 | 使用场景 |
| --- | --- | --- | --- |
| F1 | 高速推进 | 2 秒 = 1 游戏日 | 全员明确处于长期低交互行动 |
| N1 | 常态推进 | 15 秒 = 1 游戏小时 | 默认多人运行；个人局部时停期间外部世界速度 |
| B1 | 交锋慢速 | 60 秒 = 1 游戏小时 | 正式战斗、突破挑战、秘境关键交锋、玩家直接交锋 |
| P0 | 全局暂停 | 游戏时间不流动 | 全局阶段事件、公共决策、同步保护、主机暂停规则 |

内部机制：

| 机制 | 名称 | 作用 |
| --- | --- | --- |
| C1 | 追赶补结算 | 局部时停结束后，将滞后玩家补结算到世界当前时间 |

C1 只补齐已经产生的本地滞后，不作为玩家可选速度。

## 4. 速度状态机

速度优先级固定为：

```text
P0 > B1 > N1 > F1
```

状态选择：

```text
如果存在 active_global_pause → P0
否则如果存在 active_formal_encounter → B1
否则如果任一玩家处于 local_time_stop → N1
否则如果全员满足 F1 条件 → F1
否则 → N1
```

F1 必须同时满足：

```text
所有玩家都有当前行动；
所有玩家处于显式长期低交互行动；
没有玩家处于自动兜底；
没有玩家处于局部时停；
没有玩家处于 C1 追赶；
没有正式交锋；
没有全局暂停事件；
没有 1 游戏日内到期待决事项；
没有全局阶段闸门；
没有强制公开节点事件。
```

自动兜底行动 `FallbackState` 固定：

```text
f1_eligible = false
force_speed = N1
```

## 5. 房间主循环

```text
房间加载 / 恢复
→ 世界日历运行
→ 玩家在允许状态下编辑普通短队列
→ 服务器按当前速度推进 hour_tick
→ 行动完成点 / 小时 tick 执行校验、结算、事件判定
→ 个人事件进入局部时停 + 外部 N1
→ 正式交锋 / 突破挑战进入 B1
→ 全局公共事件进入 P0
→ 事件结束后 C1 追赶或恢复速度判定
→ 持续写入日志、摘要、存档与回放片段
```

`runtime_state`：

```text
room_loading
world_running
local_time_stop_active
catchup_settlement
formal_encounter_b1
global_pause_p0
save_writeback
```

## 6. 普通队列编辑规则

玩家主动编辑普通指令队列时：

```text
1. 角色当前行动继续结算。
2. 其他玩家与世界继续推进。
3. F1 中打开普通队列编辑界面时，世界进入 N1。
4. B1 或 P0 中可编辑普通队列，但普通队列不替代交锋轮选择或全局选择。
5. 外部 UI 只显示中性速度状态。
```

UI 中性提示示例：

```text
当前速度：常态推进
进入常态推进
```

## 7. 个人局部时停

局部时停用于非交锋类个人选择，例如同门邀约、个人机缘、资源申请反馈、轻度探索遭遇、丹药副作用、小境界突破选择和突破前简短道具确认。

规则：

```text
事件玩家角色时间冻结在触发 world_hour；
事件玩家当前行动、资源变化、风险变化暂停；
其他玩家、宗门与世界继续 N1；
gap = 世界当前时间 - 玩家冻结时间；
gap 最大 1 游戏日。
```

gap 阶段：

| gap | 系统行为 |
| --- | --- |
| 0～12 游戏小时 | 正常局部时停 |
| 12～18 游戏小时 | 仅事件玩家本人轻提示 |
| 18～24 游戏小时 | 事件玩家本人强提示 |
| 24 游戏小时 | 安全默认或 P0 同步保护 |

有安全默认选项时自动执行默认选项；无安全默认选项时进入 P0 同步保护。

## 8. C1 追赶补结算

局部时停结束后，事件玩家进行 C1 追赶补结算：

```text
1. 从冻结 world_hour 回填事件选择后果。
2. 补结算确定性行动进度、修炼收益、资源消耗、药性衰减、伤势恢复、队列切换。
3. 追赶期间不触发随机个人事件、普通机缘、普通战斗、软机会事件、普通心魔或普通资源反馈。
4. 最多 2 秒补完 1 游戏日。
5. 补结算完成后重新检查 F1 条件。
```

## 9. B1 正式交锋

正式交锋包括：

```text
正式战斗
秘境关键交锋
玩家直接交锋
多人组队战斗
宗门任务战斗
可能导致重伤 / 死亡 / 重大资源损失的战斗
突破挑战
```

规则：

```text
世界进入 B1；
1 交锋轮 = 1 游戏小时；
1 交锋轮现实窗口 = 60 秒；
未提交者执行预设策略；
每轮结算后世界时间同步推进 1 游戏小时；
非参战玩家也按 B1 世界时间推进。
```

## 10. P0 全局暂停

P0 适用：

```text
全局阶段闸门；
宗门大会 / 全员议事 / 世界级灾变选择；
所有玩家共同参与的公共决策；
局部时停达到 1 日 gap 且事件不可默认；
服务器同步保护；
房间规则允许的主机暂停。
```

P0 必须有 `GlobalPauseState`，并记录公开原因、私人引用、参与要求、默认处理策略和状态。

## 11. 权威服务器原则

```text
客户端只提交意图。
服务器校验行动、资源、位置、权限、事件触发。
所有结果包交给 S1 统一回写。
宗门 AI、节点变化、事件结果不得绕过 S1。
本地单人测试也走同一规则模型。
```

新增必须校验：

```text
当前世界速度状态；
玩家是否处于局部时停；
玩家 gap 是否接近上限；
玩家是否处于 C1 追赶；
行动来源是显式队列、显式托管、超时默认还是自动兜底；
自动兜底是否错误参与 F1；
B1 轮窗口是否到期；
P0 是否具有合法全局原因。
```

## 12. 小时结算主循环

每个世界小时：

```text
settle_world_hour(world):
  for player in active_players:
    if player.local_time_stop.active:
      update_gap_warning(player)
      continue

    if player.catchup.active:
      process_catchup(player)
      continue

    ensure_current_action_or_fallback(player)
    validate_running_action_segment(player)
    settle_action_progress(player)
    settle_resource_inputs_and_residual_effects(player)
    check_action_completion_and_next_command(player)
    check_personal_events(player)

  advance_sect_ai_continuous_actions(world)
  advance_nodes_resources_rumors(world)
  collect_and_write_result_packages(world)
```

行动完成点：

```text
on_action_complete(player):
  next_command = player.command_queue.pop_next()

  if next_command.exists:
    validation = validate_command_before_execution(next_command, player.current_state)
    if validation.passed:
      start_command(player, next_command)
      return

    mark_command_skipped(next_command, validation.failed_reason)
    log_to_player(player, validation.failed_reason)
    start_auto_fallback(player, reason='validation_failed')
    force_world_speed(N1)
    return

  log_to_player(player, '队列已空')
  start_auto_fallback(player, reason='queue_empty')
  force_world_speed(N1)
```

## 13. 日志与回放

`TimelineReplay` 至少记录：

```text
speed_segments
submitted_command_changes
command_validation_records
fallback_records
managed_action_records
local_time_stop_records
catchup_records
formal_encounter_rounds
global_pause_records
sect_ai_steps
rng_trace
settlement_steps
event_outcomes
result_packages
player_timeline_summaries
final_state_hash
```

阶段摘要生成时机：

```text
玩家队列发生跳过 / 中断 / 失败；
玩家完成一串显式行动；
局部时停事件结束并完成 C1；
B1 交锋或突破挑战结束；
P0 全局事件结束；
存档 / 离线前周期摘要。
```

## 14. 来源与裁决

吸收来源：

```text
v2.3 01_共享日历_房间推进_权威结算
v2.3 03_术语表_命名规范_字段统一
v2.3 01_运行时状态_数据模型_结果包
v2.3 08_事件突破战斗时间规则
v2.3 01_UIUX需求方案
修为年限、境界收益与阶段预算数值设计
```

参考来源：

```text
自适应流速可暂停日历制 v2
指令预输入机制 v1
v2.2 房间回合推进与冲突决议
v2.1 字段迁移对照表
```

裁决：

| 采用方案 | 废弃方案 | 原因与影响 |
| --- | --- | --- |
| 连续日历 + `hour_tick` | 5 天回合、季度推进、行动格推进 | 多人房间与事件追赶需要绝对小时对齐 |
| 数值换算使用 360 日游戏年 | 把游戏年作为独立 tick 或行动排期单位 | 年只用于修为年限、寿元和世界产出预算阶段调度换算，运行时仍按小时结算 |
| F1 / N1 / B1 / P0 + C1 | 玩家侧跳转到未来关键点 | F1 是连续压缩推进，不跳过服务端结算 |
| 局部时停 + gap≤1 日 + C1 | 普通个人事件全局暂停 | 保留个人选择权，同时避免拖慢其他玩家 |
| B1 正式交锋轮 | 正式战斗或突破多次 P0 | 交锋消耗与世界时间同步推进 |
| S1 统一结果包回写 | 子系统直接改世界状态 | 便于日志、存档、回放和调试一致 |
