# 个人行动队列、移动通行与托管

状态：第二批正式定稿
更新日期：2026-05-08
来源主版本：v2.3 calendar_preinput

## 1. 系统定位

S3 负责玩家角色的普通行动输入、短队列执行、移动通行、自动兜底、显式托管和行动资源输入入口。

一句话定义：

```text
玩家给当前角色提交普通行动指令；系统保持当前执行指令 + 最多 3 条预输入指令。
```

队列只保存当前已经合法的普通指令。它用于减少机械补指令，不承担条件脚本、未来资源推导、通用事件预案或自动化排程职责。

## 2. 队列结构

MVP 队列容量：

```text
当前执行指令 + 最多 3 条预输入指令
```

示例：

```text
当前：闭关修炼《青木引气诀》10 日
后续 1：调息 2 日
后续 2：开启筑基突破
后续 3：吐纳 3 日
```

每条指令都需要：

```text
入队时合法性校验
+ 执行前再次合法性校验
```

队列容量由 `TimeConfig.command_queue_max_pending = 3` 控制。

## 3. 数据契约

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

`Command` 最小字段：

```text
Command {
  command_id: String
  command_type: cultivate | meditate | rest | heal | craft | travel | visit | apply_resource | breakthrough_open | minor_breakthrough | managed
  actor_ref: String
  character_id: String
  target_node_id: String | null
  target_ref: String | null
  duration_hours: int | null
  selected_items: Array
  resource_inputs: Array
  location_requirement: String | null
  seclusion_policy: safe | standard | risky | null
  managed_mode: ManagedMode | null
  created_world_day: int
  created_world_hour: int
  submitted_by_player_id: String
  source: explicit_player | timeout_managed | system_fallback
  status: queued | running | completed | skipped | failed
  validation_history: Array
  log_refs: Array
}
```

`CommandValidationResult`：

```text
CommandValidationResult {
  command_id: String
  checked_world_day: int
  checked_world_hour: int
  phase: enqueue | before_execution
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

## 4. 行动经济基础

普通行动仍按世界小时结算：

```text
行动可消耗小时或天；
移动读取节点图、有向边权、权限门和风险门；
炼丹、炼器、仪式、治疗等可为固定执行时间行动；
修炼、吐纳、研习、探索、休整等可为可选投入执行时间行动；
丹药、灵材、符箓作为行动资源输入绑定具体行动或事件选项；
行动资源输入必须通过资产容器、位置、权限、行动标签和叠加限制校验。
```

队列执行不推导前序产出，也不锁定未来资源。资源在行动真正开始或事件选项生效时按规则消耗。

## 5. 可预输入指令

可入队：

```text
闭关修炼
吐纳
休整
养伤
炼丹
炼器
赶路
拜访指定 NPC
申请指定宗门资源
进入指定地图节点
开启当前已满足条件的大境界突破
执行当前已满足条件的小境界突破
显式托管行动
```

不进入普通队列：

```text
未知事件的选项选择
未满足条件的突破
未拥有道具的消耗行为
需要新情报判断的宗门站队
多人直接冲突选择
正式交锋中的轮内策略选择
突破挑战中的轮内选择
临时触发的机缘事件
临时触发的心魔 / 风险抉择
```

这些内容由事件系统、B1 交锋系统或玩家即时处理。

## 6. 入队合法性

入队时必须满足：

```text
当前状态允许；
当前地点允许；
当前资源足够；
当前风险没有阻止；
当前事件状态不冲突；
当前境界 / 功法 / 关系条件满足；
主修功法对应模板可用；
资源输入项可从资产容器合法取得。
```

队列不做：

```text
资源锁定；
未来产出承诺；
队列内资源占用推导；
条件 if-else 链；
跨指令依赖图；
甘特图计划；
通用事件预案策略表。
```

示例裁决：

```text
如果玩家当前没有筑基丹，不能因为前序“炼制筑基丹”可能成功而预输入“开启筑基突破并使用筑基丹”。
```

## 7. 执行前再次校验

每条预输入指令从队列头进入执行前，必须重新校验。

通过：

```text
开始执行该指令。
```

失败：

```text
1. 跳过该指令；
2. 记录个人日志；
3. 进入自动兜底；
4. 世界进入 N1；
5. 等待玩家输入新指令。
```

失败提示只对本人可见，不进入其他玩家 UI。

## 8. 行动完成处理

行动完成点固定流程：

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

行动完成后如果下一条指令合法，且全员仍处于长期低交互行动，F1 可以继续。行动完成后如果进入自动兜底，世界进入 N1。

## 9. 移动通行

移动行动属于普通指令，按 `world_hour` 消耗持续时间。

移动校验读取：

```text
当前 location_node_id；
目标 target_node_id；
路线 edge 权重；
节点权限门；
宗门 / NPC / 事件授予的通行许可；
节点 risk_level；
当前伤势、负重、显形状态或追击状态；
是否存在 route_blocker 或 public_node_event。
```

移动执行期间：

1. 行动进度按小时结算。
2. 路线事件按 `event_time_mode` 处理。
3. 轻遭遇进入本人局部时停。
4. 正式追击、玩家直接冲突或重大资源损失风险进入 B1。
5. 移动完成时更新 `location_node_id`，结果通过 S1 结果包回写。

移动不再使用“跨回合延续”作为 active concept；长途移动只是一个可跨多个 `hour_tick` 的持续行动。

## 10. 行动资源输入

丹药、灵材、符箓和临时 boost 统一作为行动或事件选项的资源输入。

规则：

```text
1. 入队时只校验当前是否拥有和可使用资源。
2. 队列不锁定未来资源。
3. 行动真正开始前再次校验资源。
4. 行动开始后才消耗资源输入。
5. 未用完资源效果生成 ActiveResourceEffect。
6. 局部时停期间该玩家资源变化暂停。
7. C1 追赶时只补结算确定性资源效果。
```

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

## 11. 自动兜底

触发条件：

```text
当前指令完成后队列为空；
下一条指令执行前校验失败；
下一条指令地点不合法；
下一条指令资源不足；
下一条指令被当前风险状态阻止；
玩家未输入任何后续指令。
```

风险选择：

| 当前节点风险 | 自动兜底 |
| --- | --- |
| 低风险 / 宗门 / 城镇 / 安全洞府 / 已控制灵地 | 吐纳 |
| 中风险 / 高风险 / 秘境 / 敌对边境 / 未控制节点 / 战斗后区域 | 休整 |
| 风险等级不明 | 休整 |

`FallbackState` 固定要求：

```text
force_speed = N1
f1_eligible = false
expected_reward_level = very_low | low
```

自动兜底只用于防止角色冻结和提示玩家补指令，不得作为长期 F1 计划依据。

## 12. 显式托管与超时安全默认

三种机制必须分离：

| 类型 | 来源 | 是否等待玩家补指令 | 是否可参与 F1 | 主要用途 |
| --- | --- | --- | --- | --- |
| 自动吐纳 / 自动休整 | 队列空或校验失败 | 是 | 否 | 防止角色冻结 |
| 显式托管行动 | 玩家主动输入 | 否 | 满足条件时可 | 低关注、低收益、安全运行 |
| 超时安全默认 | 局部事件 / B1 / P0 超时或房间规则 | 视事件而定 | 否 | 防止多人时间卡死 |

显式托管默认行为：

```text
低风险节点 → 托管吐纳
中高风险节点 → 托管休整
```

显式托管可自动处理低价值事件：

```text
普通邀约：婉拒；
普通传闻：记录；
低价值机会：忽略；
轻微状态波动：保守处理；
普通资源波动：不冒险。
```

重大事件仍进入通知、局部时停、B1 或 P0：

```text
死亡风险；
正式交锋；
重大心魔；
重大机缘；
不可逆选择；
大境界突破挑战；
多人直接冲突；
宗门重大事件。
```

## 13. 闭关预案

闭关支持有限预案，只处理闭关内部小波动：

```text
药性轻微波动；
经脉轻微负荷；
灵力流速轻微异常；
短暂杂念；
轻度疲劳。
```

三档：

| 档位 | 行为 |
| --- | --- |
| 稳妥闭关 | 小波动自动调息；风险升高即中断闭关转休整 |
| 标准闭关 | 小波动自动压制；中等风险提示玩家 |
| 冒险闭关 | 小波动继续闭关；接近严重风险才提示玩家 |

默认：

```text
标准闭关
```

闭关预案覆盖范围外的事件按 `event_time_mode` 处理。

## 14. 大境界突破与预输入

大境界突破可以作为普通指令入队，但必须当前已经满足条件。

入队前必须满足：

```text
达到突破条件；
拥有开启阶段需要选择的突破专用道具；
当前地点允许突破；
当前状态允许突破；
主修功法突破模板可用。
```

预输入保存：

```text
开启突破；
选择少量突破专用道具；
确认当前主修功法对应突破模板；
必要时选择突破挑战默认预设。
```

突破挑战每轮选择由 B1 交锋轮处理。

执行前再次校验：

```text
仍合法 → 进入突破挑战，世界 B1；
不合法 → 跳过突破指令，不消耗突破道具，记录个人日志，进入自动兜底，世界 N1。
```

## 15. 与 S1 的集成

S3 不直接绕过 S1 改写世界状态。

必须通过 S1 记录：

```text
每次队列变更 → TimelineReplay.submitted_command_changes；
每次入队 / 执行前校验 → command_validation_records；
每次自动兜底 → fallback_records；
每次显式托管 → managed_action_records；
每次行动完成、移动抵达、资源输入消耗 → result_packages；
每次速度变化 → speed_segments；
每次个人日志与公开日志 → 对应 log refs。
```

小时结算中，S3 至少接入：

```text
ensure_current_action_or_fallback(player)
validate_running_action_segment(player)
settle_action_progress(player)
settle_resource_inputs_and_residual_effects(player)
check_action_completion_and_next_command(player)
```

## 16. UI 与验收约束

UI 应强调简单队列，避免呈现为自动化脚本编辑器。

队列面板建议显示：

```text
当前指令
后续 1
后续 2
后续 3
当前兜底规则
显式托管入口
```

入队提示只说明当前是否合法：

```text
可入队：当前已满足筑基突破条件。
不可入队：当前未拥有筑基丹。
不可入队：当前地点不允许突破。
不可入队：当前灵力储备不足。
```

执行失败提示只给本人：

```text
预输入指令未执行：开启筑基突破。
原因：缺少筑基丹。
已自动转入：吐纳。
世界进入常态推进，等待你输入新指令。
```

验收检查：

1. 玩家能新增、删除、调整最多 3 条后续普通指令。
2. 未满足条件的突破不能入队。
3. 队列不会因为前序炼丹可能成功而允许后序使用丹药。
4. 行动完成后下一条合法则自动执行。
5. 下一条不合法时跳过、个人日志记录、自动兜底、降 N1。
6. 自动吐纳 / 自动休整不会触发 F1。
7. 显式托管在安全条件下可参与 F1。
8. 移动行动按节点路线与 `world_hour` 结算。
9. 行动资源输入只在行动开始或事件选项生效时消耗。

## 17. Deprecated aliases 与迁移说明

| 旧口径 | 当前处理 | 说明 |
| --- | --- | --- |
| 1 回合 = 5 游戏天 | 废弃 | 连续日历下使用 `world_day / world_hour` 与 `hour_tick` |
| 回合时间预算 | 废弃 | 普通行动消耗小时或天，但不占用固定回合预算 |
| 跨回合延续 | 迁移为持续行动跨多个 `hour_tick` | 不再以回合作为延续边界 |
| 个人即时行动发生在回合决策阶段 | 废弃 | 普通队列编辑不冻结当前行动；F1 编辑降 N1 |
| 行动格 / `action_slot` | 废弃 | 当前指令 + 最多 3 条预输入取代行动格 |
| 条件脚本 / if-else 行动链 | 废弃 | 队列只保存当前已经合法的普通指令 |
| 通用事件默认策略表 | 废弃 | 只保留闭关预案、显式托管低价值事件处理、超时安全默认 |

## 18. 来源与裁决

吸收来源：

```text
v2.3 03_个人行动队列_移动通行_托管
v2.3 01_共享日历_房间推进_权威结算
v2.3 03_术语表_命名规范_字段统一
v2.3 01_运行时状态_数据模型_结果包
v2.3 08_事件突破战斗时间规则
v2.3 02_MVP开发切片与验收清单
v2.3 05_原始文档映射与来源索引
```

参考来源：

```text
指令预输入机制 v1
自适应流速可暂停日历制 v2
v2.2 个人行动经济_移动通行_托管
v2.2 核心体验_玩家目标_设计基石
v2.1 / v2.2 角色真灵轮回_修炼养成
```

裁决：

| 采用方案 | 废弃方案 | 原因与实现影响 |
| --- | --- | --- |
| `CommandQueue` 当前 + 3 后续 | 每回合 5 天预算、行动格、跨回合计划 | v2.3 将玩家输入改为连续日历短队列；实现按 `hour_tick` 结算 |
| 入队当前合法 + 执行前再次校验 | 未来条件满足后自动执行、前序产出推导后序消耗 | 避免脚本系统和资源锁定复杂度；失败时个人日志 + 自动兜底 |
| 自动兜底固定 N1 且无 F1 资格 | 兜底作为长期高速计划 | 兜底是等待玩家接管的安全缓冲 |
| 显式托管与自动兜底分离 | 离线 / 超时 / 自动兜底混用 | 来源、收益、F1 资格和事件处理权不同，必须分离建模 |
| 大境界突破只预输入开启指令 | 预设完整突破分支或未来达标自动突破 | B1 轮内选择和资源消耗由 `FormalEncounterState` 处理 |
| 行动资源输入绑定行动或事件选项 | 丹药炼化作为 MVP 默认独立行动 | 与 v2.3 资源输入合同一致，残余效果进入 `ActiveResourceEffect` |
