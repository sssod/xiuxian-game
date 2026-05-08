# 角色、真灵、轮回与修炼养成

状态：第二批正式定稿
更新日期：2026-05-08
来源主版本：v2.3 calendar_preinput

## 1. 系统定位

S2 负责当世修为成长、跨世真灵连续性、修炼、功法掌握、资源输入、突破结果、死亡、转世、轮回账本和后手关联。

玩家显性的成长主线是当世角色修为与境界持续攀升。轮回不是终局目标，而是当本世效率不足、路线受限、寿元压力过大或竞争失位时，用于效率修正、路线重构、信息复用和后手兑现的跨世手段。

核心实体：

```text
TrueSpiritState
CharacterState
CultivationState
MethodState
LifeLedger
ReincarnationRecord
ContingencyRecord
```

角色系统不直接绕过 S1 改写世界状态。修炼、伤势、寿元、资源输入、突破、死亡和转世结果必须通过结果包回写，并进入日志、存档和 `TimelineReplay`。

## 2. 分层原则

玩家身份由跨世真灵承接，当世角色是一次生命的载体，也是修为、境界、功法掌握、资源、关系和身份后果的主要承载层。

| 层级 | 负责内容 | 跨世处理 |
| --- | --- | --- |
| 真灵 | 跨世身份锚点、真名、轮回账本、执念容量、因果痕迹、已知后手、后手容量、暴露等级 | 持续存在 |
| 当世角色 | 肉身、年龄、寿元、境界、位置、宗门身份、资产容器、关系、伤势、心魔 | 死亡后结算并大多不默认继承 |
| 修炼状态 | 修为点、瓶颈、小境界、根基质量、经脉压力、资源灵气输入 | 写入本世日志，关键结果进入轮回账本 |
| 功法状态 | 完整功法载体学习、掌握度、解锁效果、兼容境界 | 本世状态；跨世保留取决于后手和轮回规则 |

真灵不是数值外挂，不应默认稳定提高每世修炼效率，也不保存当前修为、当前功法等级、当前背包物品、当前宗门职位或当前普通社会关系。

## 3. 真灵状态

```text
TrueSpiritState {
  true_spirit_id: String
  owner_player_id: String
  current_character_id: String | null
  reincarnation_count: int
  life_ledger_refs: Array
  inherited_memory_tags: Array
  known_contingency_refs: Array
  karmic_trace: Dictionary
  exposure_level: hidden | suspected | exposed
}
```

`exposure_level` 影响：

```text
高阶 NPC 感知；
宿敌追索；
后手争夺；
多人间接竞争；
可见性系统中的传闻与线索。
```

暴露信息进入可见性系统，不直接向所有玩家公开。

## 4. 当世角色状态

```text
CharacterState {
  character_id: String
  true_spirit_id: String
  player_id: String
  name: String
  age: int
  lifespan: int
  realm: String
  minor_stage: String
  cultivation_state: CultivationState
  location_node_id: String
  sect_membership: SectMembership | null
  inventory_container_id: String
  method_states: Array
  active_resource_effects: Array
  injury_state: Dictionary
  mental_state: Dictionary
  relationship_refs: Array
  visibility_state: Dictionary
  current_life_status: alive | dead | reincarnating
}
```

当世角色保存本世实际发生的一切。死亡、转世或重大突破后，系统从当世角色提取必要记录写入 `LifeLedger`、`ReincarnationRecord`、公开传闻和后手索引。

## 5. 修炼状态

```text
CultivationState {
  character_id: String
  realm: String
  minor_stage: String
  cultivation_points: number
  bottleneck_state: none | approaching | reached
  foundation_quality: number
  meridian_pressure: number
  resource_aura_input: number
  last_settled_world_day: int
  last_settled_world_hour: int
}
```

修炼结算读取：

```text
角色资质；
主修功法；
MethodState 掌握度；
节点 aura_profile；
设施修正；
宗门支持；
ActionResourceInputBinding；
ActiveResourceEffect；
伤势、心魔、经脉压力；
实际兼容小时。
```

修炼收益、经脉压力、资源灵气输入和状态变化必须按 `world_hour` 结算。

## 6. 功法与掌握度

功法学习来自完整功法载体。残页、章节和片段用于合成、线索、权限、事件投放或内容收集，不作为运行时学习进度。

```text
MethodState {
  method_state_id: String
  character_id: String
  method_template_id: String
  learned_from_carrier_id: String
  mastery_level: int
  mastery_progress: number
  compatible_realms: Array
  active_tags: Array
  unlocked_effect_refs: Array
  last_practiced_world_day: int
  last_practiced_world_hour: int
}
```

掌握度影响：

```text
修炼效率；
突破模板；
事件选项；
战斗策略；
资源输入兼容；
心魔与走火风险；
宗门评价和 NPC 关系。
```

主修功法决定突破模板匹配和部分资源输入适配，但不允许通过残篇 / 章节直接累加成运行时“学习进度条”。

## 7. 行动资源输入

丹药、灵材、符箓和临时增益资源通过 `ActionResourceInputBinding` 绑定具体行动或事件选项。

规则：

```text
资源输入不作为默认独立行动；
行动入队时校验当前拥有和可用；
行动开始前再次校验；
行动开始或事件选项生效时消耗；
未用完效果生成 ActiveResourceEffect；
局部时停期间角色自身资源变化暂停；
C1 追赶只补确定性资源效果。
```

`ActiveResourceEffect` 用于保存未完全消耗的兼容小时、叠加策略、过期条件和日志引用。

MVP 不把“丹药炼化”作为默认独立持续行动。修为丹药、定心类资源、避瘴类资源、疗伤资源等应作为行动或事件的资源输入，按兼容小时和当前状态结算。

## 8. 小境界与瓶颈

小境界推进由修炼状态、功法、资源、地点和风险共同决定。

小境界选择事件按普通个人事件处理：

```text
本人局部时停；
外部世界 N1；
gap≤1 游戏日；
选择后 C1 追赶。
```

小境界结果进入个人日志和可见性系统，必要时影响宗门传闻。

小境界不等同于大境界突破挑战；只有模板明确升级为正式交锋或高风险挑战时才进入 B1。

## 9. 大境界突破

大境界突破结构：

```text
准备期
→ 开启突破短指令
→ 突破挑战 B1
→ 个人结果报告
→ 后续选择
```

准备期可作为长期低交互行动。开启突破必须当前满足条件。突破挑战使用 `FormalEncounterState`，每轮资源消耗与策略选择进入结果包。

突破结果至少影响：

```text
realm / minor_stage；
foundation_quality；
injury_state；
lifespan；
mental_state；
method_states；
active_resource_effects；
LifeLedger；
宗门传闻 / 世界日志；
下一次修正方向。
```

## 10. 死亡与转世

死亡触发：

```text
寿元耗尽；
战斗失败；
突破失败；
重大事件结果；
资源反噬；
后手或因果冲突。
```

死亡结果写入：

```text
LifeLedger；
ReincarnationRecord；
可继承后手；
可见传闻；
资产去向；
真灵暴露变化；
下一世初始条件。
```

转世流程：

```text
生成 ReincarnationRecord
→ 结算后手与遗产
→ 选择或生成新当世角色入口
→ 绑定 TrueSpiritState
→ 建立新 CharacterState
→ 写入 TimelineReplay
```

转世不是清空进度，也不是玩家追求的主要目标。它应把本世冲击更高境界过程中的失败原因、低效率来源、关键选择、后手、传闻、因果痕迹和可继承线索，转化为下一世可理解、可利用、可修正的信息和开局资本。

转世价值判断应围绕继续修行是否仍然合理：

```text
当前世代效率是否低于境界段基准；
剩余寿元是否足够支撑下一里程碑；
当前路线是否还能获得适配资源、功法、节点和宗门支持；
继续硬冲、降低品质目标、冒险抢窗口、布置后手或轮回，哪一种更服务更高境界追求。
```

## 11. 后手与轮回账本接口

S2 只定义角色与真灵侧接口，后手、遗产、可见性和多人竞争的详细规则由后续 canonical 文档承载。

最低接口要求：

```text
LifeLedger 记录本世关键成果、失败标签、突破报告、死亡原因和公开影响；
ReincarnationRecord 记录转世原因、继承条件、新角色入口和真灵绑定；
ContingencyRecord 记录可感知、可触发或可争夺的后手索引；
TrueSpiritState.known_contingency_refs 只保存当前真灵已知后手，不代表世界中全部后手。
```

## 12. 与 S1 的集成

S2 输出结果包，不直接绕过 S1 改写世界状态。

必须通过 S1 记录：

```text
修炼进度变化 → result_packages / personal logs；
功法掌握变化 → result_packages；
资源输入消耗 → inventory_delta / resource_effect_delta；
ActiveResourceEffect 创建、衰减、过期 → resource_effect_delta；
小境界选择 → event_outcomes / local_time_stop_records / catchup_records；
突破挑战 → formal_encounter_rounds / result_packages；
死亡与转世 → ledger_entries / TimelineReplay / visible or hidden logs；
真灵暴露变化 → visibility_state / hidden_world_log_entries。
```

所有状态变化必须带 `world_day / world_hour`。

## 13. UI 与验收约束

UI 应清楚分辨：

```text
真灵层长期记录；
当世角色当前状态；
修炼与瓶颈进度；
功法掌握度；
行动资源输入与残余效果；
突破准备 / 开启 / B1 挑战 / 结果报告；
死亡与转世后的可继承信息。
```

验收检查：

1. `TrueSpiritState` 与 `CharacterState` 分层保存。
2. 当世角色死亡后真灵仍保留轮回账本和已知后手索引。
3. 修炼收益按 `world_hour` 与实际兼容小时结算。
4. 完整功法载体才能生成 `MethodState`。
5. 残页 / 章节不能作为运行时学习进度。
6. 丹药、灵材、符箓作为 `ActionResourceInputBinding` 进入行动或事件。
7. 未消耗完资源效果进入 `ActiveResourceEffect`。
8. 小境界选择走个人局部时停 + C1。
9. 大境界突破走 `FormalEncounterState` B1。
10. 死亡与转世写入 `LifeLedger`、`ReincarnationRecord` 和 `TimelineReplay`。

## 14. Deprecated aliases 与迁移说明

| 旧口径 | 当前处理 | 说明 |
| --- | --- | --- |
| `started_turn_id` | 废弃 | 改用 `started_world_day / started_world_hour` 或结果包时间字段 |
| 回合修炼预算 | 废弃 | 修炼按 `hour_tick` 与兼容小时结算 |
| 丹药炼化默认独立行动 | 废弃 | 丹药作为行动或事件资源输入 |
| 残篇 / 章节作为学习进度 | 废弃 | 只作为合成、线索、权限或内容投放资产 |
| 真灵强度直接稳定提高修炼效率 | 废弃 | 真灵提供长期身份、轮回账本、执念容量、因果与后手容量，不作为默认效率外挂 |
| 当世角色内容默认跨世继承 | 废弃 | 跨世继承必须经后手、轮回记录或明确规则 |

## 15. 来源与裁决

吸收来源：

```text
v2.3 02_角色真灵轮回_修炼养成
v2.3 02_核心体验_玩家目标_设计基石
v2.3 03_术语表_命名规范_字段统一
v2.3 01_运行时状态_数据模型_结果包
v2.3 03_个人行动队列_移动通行_托管
v2.3 08_事件突破战斗时间规则
v2.3 02_MVP开发切片与验收清单
v2.3 05_原始文档映射与来源索引
```

参考来源：

```text
v2.2 角色真灵轮回_修炼养成
v2.1 角色真灵轮回_修炼养成
v2.2 事件突破战斗
修为修炼公式_资源输入与丹药药性处理补充_v0.2
功法系统_收敛设定汇总_v0.4
核心数值设计方案_境界基准收益模型_v0.1
玩家角色扮演核心体验｜真灵-执念-身躯与灵魂三层模型 0·425
```

裁决：

| 采用方案 | 废弃方案 | 原因与实现影响 |
| --- | --- | --- |
| 当世修为主线与真灵连续性分层 | 玩家控制固定角色、宗门本体，或把轮回本身作为终局目标 | 当世角色承载修为、境界和现实后果；真灵承载账本、执念容量、后手和跨世线索 |
| 修炼按 `world_hour` 与兼容小时结算 | 回合修炼预算 | 连续日历下收益、资源输入和残余效果必须可按小时复盘 |
| 完整功法载体生成 `MethodState` | 残篇 / 章节直接作为学习进度 | 避免内容资产与运行时进度混淆 |
| 丹药等作为 `ActionResourceInputBinding` | 丹药炼化默认独立持续行动 | 与行动队列和资源输入合同一致 |
| 大境界突破走 B1 `FormalEncounterState` | 突破多次 P0 或单次概率按钮 | 突破资源消耗、策略和结果必须可轮内复盘 |
| 死亡转世写入 `LifeLedger` / `ReincarnationRecord` | 死亡后简单重开，或用寿元 / 事件门槛半强迫轮回 | 失败需要转化为下一世信息、后手和修正方向，并继续服务更高境界追求 |
