# 宗门组织、库存与宗门 AI 持续行动

状态：第三批正式定稿
更新日期：2026-05-08
来源主版本：v2.3 calendar_preinput

## 1. 系统定位

S5 负责宗门组织身份、宗门库存、资源申请、关键 NPC 支持、宗门 AI 持续行动、宗门日志与传闻，以及宗门对地图节点、事件窗口、经济和多人间接竞争的影响。

宗门是组织资源平台与世界演化实体，不是玩家本体，也不是玩家直接经营的城市建设面板。

当前核心口径：

```text
玩家通过身份、贡献、职位、资源申请、NPC 支持、个人行动和事件结果影响宗门；
宗门 AI 自行选择、维护和结算持续行动；
每个宗门同一时间最多一个 active SectContinuousActionState；
宗门结果必须通过 S1 / room authoritative settlement 回写；
宗门 AI 步骤必须进入 TimelineReplay.sect_ai_steps。
```

## 2. MVP 边界

MVP 保留：

```text
宗门身份与权限；
贡献与门内声望；
宗门库存与资源申请；
宗门库存作为 ActionResourceInputBinding 来源；
宗门 AI 每小时推进唯一持续行动；
宗门节点影响、传闻、公开日志与隐藏日志；
玩家通过个人 Command、事件结果、NPC 关系和后手间接影响宗门。
```

MVP 不引入：

```text
玩家宗门即时指令；
宗门主行动建议；
宗门提案；
宗门决策阶段；
SectDecisionIntent；
同宗多人宗门输入冲突解析；
复杂内部派系 / 山头系统；
玩家担任宗主并直接调度宗门全部资源。
```

如果未来恢复玩家主动宗门管理，应作为后续大型模块重新设计，不在 MVP 中预留半成品交互。

## 3. SectState

`SectState` 是宗门运行时主状态。

```text
SectState {
  sect_id: String
  display_name: String
  headquarters_node_id: String
  influence_nodes: Array
  reputation: Dictionary
  inventory: SectInventory
  member_refs: Array
  key_npc_refs: Array
  current_continuous_action: SectContinuousActionState | null
  ai_policy_ref: String
  visible_rumor_refs: Array
  last_settled_world_day: int
  last_settled_world_hour: int
}
```

实现要求：

1. `current_continuous_action` 同一时间最多一个处于 `active`。
2. `last_settled_world_day / last_settled_world_hour` 必须随宗门小时结算更新。
3. 宗门状态变化只输出 `sect_delta`、`node_delta`、`inventory_delta`、日志与传闻，不直接绕过 S1 改世界状态。
4. 宗门公开摘要不得泄露私人事件归因。

## 4. 成员关系与权限

`SectMembership` 记录当世角色在宗门内的身份、贡献、声望、权限和关键关系。

```text
SectMembership {
  character_id: String
  sect_id: String
  rank: String
  contribution: number
  reputation: number
  role_tags: Array
  resource_access_level: String
  mentor_refs: Array
  faction_relation_tags: Array
}
```

MVP 身份层级采用轻量固定序列：

```text
外门弟子
→ 内门弟子
→ 真传弟子
→ 执事
→ 长老
```

MVP 不开放宗主职位。M3 或等价第三大境界起点后，可允许玩家进入长老序列或等价高层影响体验。

权限不做复杂树状官僚系统，使用可检查标签与访问等级表达：

```text
request_resources
use_training_site
request_breakthrough_support
lead_task
access_inner_archive
manage_node_affairs
assign_guard_or_support
view_sect_ai_summary
influence_sect_ai_weight
```

明确移除：

```text
propose_sect_action
decide_sect_action
sect_decision_phase
```

贡献是历史凭证，不是可直接兑换货币。门内声望是宗门内部对可靠性、潜力与影响力的综合评价。资源申请可读取贡献与声望，但最终仍必须校验真实库存、权限、地点与宗门当前状态。

## 5. SectInventory 与资产容器

`SectInventory` 是宗门库存的宗门侧摘要；底层物品持久化应由资产容器与物品系统承载。

```text
SectInventory {
  sect_id: String
  container_id: String
  spirit_stones: number
  material_items: Array
  method_carriers: Array
  pills: Array
  talismans: Array
  reserved_resources: Array
  public_access_policy: Dictionary
  audit_log_refs: Array
}
```

宗门库存可以包含：

```text
灵石；
丹药；
灵材；
符箓；
法器；
完整功法载体；
残页 / 章节；
任务物；
节点产出资源；
后手回收物；
突破支持资源。
```

宗门库存可接收世界产出预算的宗门出口；阶段预算只决定当前境界阶段的宗门资源可得性上限和扩散节奏。预算投放必须进入宗门资产容器、库存审计和可见性规则：

```text
RealmBudgetPool.sect_inventory_budget 需要映射到底层 WorldProductionBudgetState / WorldResourceBudget / WorldItemBudgetTier；
宗门出口可转化为宗门库存、任务奖励、护法名额、功法载体或突破支持资源；
世界产出预算 / 阶段调度只提高资源可得性，不自动批准玩家申请；
资源申请仍需校验身份、贡献、声望、库存、预留、NPC 支持、地点和宗门当前状态；
高于当前预算境界的宗门资源默认不稳定生成，除非来自先锋泄漏、宗门重大事件、后手或专属资源池。
出售、拆解、销毁、上交、损坏或消耗不返还世界生成预算。
```

宗门提供功法时必须区分：

```text
完整功法载体：可学习并生成 MethodState；
残页 / 章节：用于合成、线索、权限、事件投放或内容收集；
导师 / 设施支持：进入行动模板修正，不直接发放无来源倍率。
```

残页 / 章节不得被 UI 或规则层表达为“已学会一部分功法”。

## 6. 资源预留与申请

资源申请可以作为 `Command.command_type=apply_resource`，也可以作为事件选项进入系统。

```text
SectResourceRequest {
  request_id: String
  character_id: String
  sect_id: String
  requested_resource_refs: Array
  purpose_command_ref: String | null
  submitted_world_day: int
  submitted_world_hour: int
  status: pending | approved | rejected | partial | expired
  result_package_refs: Array
}
```

资源预留用于避免宗门库存被多系统重复使用。

```text
SectResourceReservation {
  reservation_id: String
  sect_id: String
  source_container_id: String
  reserved_resource_refs: Array
  reserved_for_character_id: String | null
  reserved_for_system: String
  bound_request_id: String | null
  bound_command_id: String | null
  created_world_day: int
  created_world_hour: int
  expires_world_day: int | null
  expires_world_hour: int | null
  status: active | consumed | released | expired | failed
  log_refs: Array
}
```

审批依据：

```text
身份与职位；
贡献；
门内声望；
库存与预留状态；
宗门当前持续行动；
关键 NPC 支持；
节点压力；
事件状态；
请求用途；
公开影响；
宗门 AI 策略。
```

资源申请通过后：

1. 高价值资源应生成 `SectResourceReservation`。
2. 丹药、灵材、符箓等在进入个人行动或事件选项时，必须作为 `ActionResourceInputBinding` 消耗。
3. 设施时段、导师指点、护法支持进入行动、事件或突破模板修正，并记录来源。
4. 行动开始或事件选项生效前仍需执行前校验。
5. 消耗、释放、过期和拒绝都必须写入宗门审计日志与结果包。

## 7. SectContinuousActionState

`SectContinuousActionState` 是宗门 AI 当前组织重点。它可以跨多个 `hour_tick` 推进，但同一宗门同一时间最多一个 active。

```text
SectContinuousActionState {
  action_id: String
  sect_id: String
  action_type: recruit | patrol | gather_resource | expand_influence | defend_node | research_method | support_member | trade | recover
  target_node_id: String | null
  started_world_day: int
  started_world_hour: int
  expected_duration_hours: int | null
  progress_hours: int
  resource_inputs: Array
  ai_reason_tags: Array
  status: active | completed | interrupted | failed
  result_package_refs: Array
}
```

常态运营不占用唯一持续行动槽：

```text
已控制矿场 / 药田的基础产出；
已建成基础设施的稳定效果；
已建立驻守状态的持续安全修正；
宗门俸禄或基础供给；
宗门库存维护；
已完成培养体系的基础弟子成长。
```

这些内容仍可按 `world_hour` 常态结算，但不得被计为第二个 `SectContinuousActionState`。

## 8. 宗门 AI 小时循环

宗门 AI 每个世界小时进入 S1 主循环，由 S1 合并结果包。

```text
advance_sect_ai(world):
  for sect in sect_states:
    settle_current_sect_action(sect)
    if current action completed / interrupted / failed:
      close_action_and_write_result_package(sect)
      choose_next_sect_action_if_needed(sect)
    write_sect_ai_step_to_timeline_replay(sect)
```

AI 输入：

```text
宗门库存；
WorldStageBudgetState；
成员状态；
玩家贡献、申请和近期行动；
关键 NPC 意图；
节点影响；
外部威胁；
资源缺口；
秘境窗口；
近期事件；
宗门性格；
后手触发或争夺；
世界宏观周期。
```

AI 输出：

```text
SectContinuousActionState；
宗门库存变更；
节点影响变更；
NPC 行动；
任务与传闻；
资源申请结果；
公开日志；
隐藏世界日志；
Debug 日志。
```

玩家不需要看到宗门 AI 的完整推理。玩家界面可以展示与其可见性匹配的宗门摘要、当前重点、进度、风险和可亲自介入入口。

## 9. 玩家影响宗门的方式

玩家不能直接替宗门排持续行动。玩家个人行动可以改变宗门 AI 的输入和宗门结果：

```text
提升贡献；
提高门内声望；
获得职位或权限；
申请资源；
拜访关键 NPC；
贡献物资；
完成宗门任务；
亲自支援战斗或驻守；
公开或隐瞒突破；
发现、占领或影响节点；
处理宗门事件；
布置、触发或回收后手。
```

亲自介入宗门事务时，仍使用个人 `Command`、事件选择、B1 交锋或 P0 公共事件，并通过 S1 结果包影响宗门。

高地位体验应表现为：

```text
看到更多宗门情报；
拥有更高资源申请权限；
更容易触发议事、委派或护法事件；
更容易影响宗门 AI 权重；
能访问更高价值功法载体、突破支持、节点事务和 NPC 关系入口。
```

这些影响是权重、权限、事件入口和可见性差异，不是玩家直接提交宗门主行动。

## 10. 地图、经济、后手与多人接口

宗门对地图节点的影响包括：

```text
控制或争夺节点；
改变 NodeState.controlling_influence；
改变 route passability 或风险标签；
开启、关闭或推迟 OpportunityWindow；
改变节点资源槽采集、刷新或争夺状态；
生成宗门传闻和公开地图变化。
```

宗门对经济与 NPC 的影响包括：

```text
库存收入与支出；
资源申请、预留、消耗和审计；
功法载体发放；
NPC 位置、关系、任务和库存变化；
交易、护法、导师指点和设施支持来源记录。
```

宗门与后手 / 多人间接竞争接口：

```text
后手可消耗宗门贡献或宗门关系；
后手可被宗门清查、触发、发现或争夺；
宗门库存被申请会影响其他玩家机会；
宗门传闻会改变其他玩家判断；
宗门 AI 影响节点、资源和秘境窗口；
公开突破会改变宗门评价、NPC 关系和世界态势。
```

直接玩家冲突不由宗门 AI 私下结算；满足正式交锋条件时进入 B1 `FormalEncounterState`。

## 11. 日志、可见性与回放

宗门输出日志分层：

```text
本人可见；
宗门成员可见；
公开传闻；
隐藏世界日志；
Debug 日志。
```

可见性要求：

1. 宗门传闻不得泄露不具备可见性的私人事件归因。
2. 资源申请结果默认只对本人、相关宗门权限层和 Debug 可见。
3. 宗门当前持续行动摘要可以按权限层级显示不同细节。
4. 隐秘后手、私人突破选择和个人事件来源只进入本人日志、隐藏世界日志或 Debug。

`TimelineReplay` 必须记录：

```text
sect_ai_steps；
result_packages；
visible_log_entries；
hidden_world_log_entries；
debug_log_entries；
resource request / reservation changes；
node_delta caused by sect action；
inventory_delta caused by sect action。
```

## 12. UI 与验收约束

宗门面板不提供“宗门经营命令 / 宗门主行动输入”。

建议页签：

```text
宗门概览；
当前持续行动；
库存与权限；
资源申请；
身份 / 贡献 / 门内声望；
宗门日志与传闻。
```

当前持续行动显示应保持摘要化：

```text
宗门当前重点：强化黑石岭驻守
进度：40%
预计仍需：约 3 日
投入：人力中、材料低、灵石低
风险：边境冲突升温
可亲自介入：前往黑石岭驻守 / 协助调查
```

验收检查：

1. 每个宗门同一时间最多一个 active `SectContinuousActionState`。
2. 宗门 AI 能在没有玩家直接命令时按 `world_hour` 推进。
3. 宗门当前行动完成、失败或中断后能选择下一项。
4. 宗门常态运营不占用唯一持续行动槽。
5. 玩家资源申请能进入校验、预留、结果包和日志。
6. 宗门库存可作为 `ActionResourceInputBinding` 来源。
7. 玩家只能通过个人行动、贡献、职位、NPC 关系、事件结果和后手间接影响宗门。
8. 宗门节点影响能改变地图节点、事件窗口、资源槽或传闻。
9. 宗门 AI 步骤进入 `TimelineReplay.sect_ai_steps`。
10. 玩家 UI 不出现宗门主行动输入、宗门提案或 `SectDecisionIntent`。

## 13. Deprecated aliases 与迁移说明

| 旧口径 | 当前处理 | 说明 |
| --- | --- | --- |
| 宗门主行动输入 | 废弃 | 玩家不直接选择宗门组织行动 |
| 宗门经营命令 | 废弃 | 宗门不是玩家直接经营界面 |
| 宗门提案 / 主行动建议 | 废弃 | 玩家影响宗门 AI 输入，不提交提案 |
| `SectDecisionIntent` | 废弃 | 不进入 MVP schema |
| 宗门决策阶段 | 废弃 | 共享连续日历下没有独立宗门输入阶段 |
| 每季度一个宗门主行动 | 迁移 | 改为同一时间最多一个 `SectContinuousActionState`，按 `world_hour` 推进 |
| `started_turn_id` / `expiry_turn_id` | 废弃 | 预留和行动时间字段改用 `world_day / world_hour` |
| 内部派系 / 山头系统 | 暂不引入 | MVP 用身份、职位、贡献、声望、关键 NPC 支持和事件授权表达影响 |

## 14. 来源与裁决

吸收来源：

```text
v2.3 05_宗门组织_库存_宗门AI持续行动
v2.3 01_共享日历_房间推进_权威结算
v2.3 03_术语表_命名规范_字段统一
v2.3 01_运行时状态_数据模型_结果包
v2.3 02_MVP开发切片与验收清单
v2.3 04_地图节点_世界演化
v2.3 06_经济物品资产_NPC持久化
v2.3 07_后手遗产_可见性_多人间接竞争
v2.3 05_原始文档映射与来源索引
修为年限、境界收益与阶段预算数值设计
```

参考来源：

```text
v2.2 宗门组织_库存_宗门AI持续行动
v2.2 冲突决议与字段迁移记录
旧版宗门组织、库存和宗门行动文档
旧版经济系统框架、物品产出与地图资源预算草稿
```

裁决：

| 采用方案 | 废弃方案 | 原因与实现影响 |
| --- | --- | --- |
| 宗门作为组织资源平台与世界演化实体 | 玩家控制宗门、国家或宗门经营面板 | 与项目核心身份一致：玩家控制跨世真灵和当世角色 |
| 每宗门同一时间最多一个 active `SectContinuousActionState` | 每季度宗门主行动、多个并行宗门主行动 | 连续日历下宗门行动按 `hour_tick` 推进，避免重新引入回合阶段 |
| 宗门 AI 自行选择持续行动 | 玩家宗门即时指令、提案、主行动建议、`SectDecisionIntent` | 玩家通过身份、贡献、资源申请、NPC 和事件间接影响宗门 |
| 宗门库存通过资产容器和预留机制输出资源 | 抽象资源被即时无来源发放 | 资源必须可审计、可回放，并能作为 `ActionResourceInputBinding` 来源 |
| 世界产出预算通过宗门出口提高资源可得性，阶段预算只做境界调度 | 预算打开后宗门无条件发放资源或给角色加修为 | 宗门仍是组织资源平台，资源调用必须经过底层预算、权限、库存、审计和结果包 |
| 宗门常态运营不占唯一持续行动槽 | 将矿场基础产出、俸禄、设施稳定效果也计入主行动槽 | 保留组织背景运转，同时让唯一持续行动代表当前重点 |
| 可见性分层日志与传闻 | 宗门公开日志暴露私人事件归因 | 多人间接竞争依赖信息边界，Debug 字段不得进入玩家 UI |
