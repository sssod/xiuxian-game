# 地图节点与沙盒世界演化

状态：第三批正式定稿
更新日期：2026-05-08
来源主版本：v2.3 calendar_preinput

## 1. 系统定位

S4 负责世界空间、节点状态、路线通行、资源槽、设施、势力影响、风险、可见性、事件窗口、秘境入口和世界演化结果。

地图不是静态菜单，而是承载个人行动、移动、修炼环境、宗门 AI、资源流转、事件压力、秘境窗口、传闻、后手隐藏层和多人间接竞争的状态机。

核心原则：

```text
地图变化按 world_hour 推进；
移动读取节点图、有向路线、通行门槛和风险；
节点资源、风险、设施、影响力和机会窗口通过 S1 结果包回写；
地图 UI 只展示玩家可见的信息；
私人事件归因不通过地图泄露；
宗门 AI、NPC 行动、事件结果和后手触发都可以改变节点状态。
```

## 2. MVP 边界

MVP 保留：

```text
节点图；
有向带权路线；
节点 risk_level；
节点 aura_profile；
节点资源槽；
基础设施 / facility；
势力控制权与影响力；
地图可见性；
秘境 / 机会窗口；
路线发现、封锁和条件通行；
节点事件、传闻和公开变化；
后手与隐藏层挂载点。
```

MVP 不引入：

```text
完整生态模拟；
复杂气候和自然磨损模型；
每回合统一刷新所有地图系统；
玩家逐个节点点击接管；
没有日志原因的后手失效；
地图直接显示其他玩家私人事件来源；
把推荐阶段做成硬锁。
```

## 3. WorldMapState

`WorldMapState` 是地图运行时主状态。

```text
WorldMapState {
  map_id: String
  current_world_day: int
  current_world_hour: int
  current_macro_period_id: String
  node_states: Dictionary
  route_states: Dictionary
  active_region_effects: Array
  resource_budget_refs: Array
  rumor_pool_refs: Array
  visibility_overrides: Dictionary
}
```

实现要求：

1. `current_world_day / current_world_hour` 与 `RoomState` 同步。
2. `current_macro_period_id` 只用于季节、旬月、灾变期、资源再生批次等宏观周期，不作为玩家回合。
3. 地图变化输出 `node_delta`、`route_delta`、`resource_slot_delta`、`world_production_budget_delta`、`visibility_delta`、`event_window_delta` 等结果包字段。
4. 地图系统不得绕过 S1 直接改写角色、宗门或经济状态。

## 4. 节点图与路线

地图采用有向带权节点图。路线可以双向但成本不同，也可以是单向门、权限门、状态门、风险门、隐藏路线或临时通道。

`RouteState`：

```text
RouteState {
  route_id: String
  from_node_id: String
  to_node_id: String
  base_cost_hours: int
  current_cost_hours: int
  route_type: road | mountain_path | river | teleport | hidden | rumor
  passability: open | blocked | conditional | unknown
  requirements: Array
  risk_tags: Array
  discovered_by: Array
  last_updated_world_day: int
  last_updated_world_hour: int
}
```

路线校验读取：

```text
当前位置；
目标节点；
路线是否可见；
passability；
requirements；
risk_tags；
current_cost_hours；
角色状态；
宗门 / NPC / 事件授予的通行许可；
是否存在 route_blocker 或 public_node_event。
```

移动行动属于个人 `Command.command_type=travel`，按 `world_hour` 结算，不使用跨回合延续语义。

## 5. NodeState

`NodeState` 记录节点当前运行状态。

```text
NodeState {
  node_id: String
  node_type: sect | town | wilderness | secret_realm | cave | market | battlefield | special
  display_name: String
  region_id: String
  owner_faction_id: String | null
  controlling_influence: Dictionary
  risk_level: low | medium | high | unknown
  aura_profile: Dictionary
  resource_slots: Array
  facility_refs: Array
  active_events: Array
  active_windows: Array
  visibility_state: Dictionary
  last_updated_world_day: int
  last_updated_world_hour: int
}
```

推荐补充模板字段：

```text
zone_tier；
recommended_stage_range；
danger_profile；
node_state_tags；
cooldown_tags；
hidden_layer_refs；
legacy_layer_refs。
```

说明：

1. `recommended_stage_range` 只用于内容筛选、提示和风险预期，不作为硬锁。
2. `danger_profile` 用于解释风险结构，例如妖兽、匪修、宗门冲突、灾害、秘境波动。
3. `node_state_tags` 记录当前态势，例如 `contested`、`resource_stressed`、`aura_surge`。
4. `cooldown_tags` 用于防止同类事件短期重复爆发。

## 6. MVP 节点类型

MVP 建议至少支持：

```text
宗门山门节点；
城镇 / 坊市节点；
村庄 / 凡人聚落节点；
资源型地理节点；
荒野探索节点；
秘境入口节点；
前世后手节点 / 隐藏层；
禁地 / 高危节点；
道路 / 山道 / 渡口 / 交通设施节点。
```

节点类型决定默认风险、可用行动、设施、资源槽、事件模板、可见性和移动约束。

## 7. 风险等级与兜底

`risk_level` 是行动队列、自动兜底和显式托管的重要输入。

基础映射：

| `risk_level` | 自动兜底 | 显式托管默认 |
| --- | --- | --- |
| `low` | 吐纳 | 托管吐纳 |
| `medium` | 休整 | 托管休整 |
| `high` | 休整 | 托管休整 |
| `unknown` | 休整 | 托管休整 |

实现约束：

```text
FallbackState.action_type 读取节点 risk_level；
FallbackState.force_speed = N1；
FallbackState.f1_eligible = false；
显式托管只有在安全条件满足时才可能参与 F1；
风险等级变化必须写入 result_package 与个人 / 公开可见日志。
```

## 8. 灵气与设施

`aura_profile` 支持修炼与资源输入系统读取。

```text
aura_profile {
  aura_density: number
  aura_quality: String
  element_affinity_tags: Array
  pollution_tags: Array
  stability_tags: Array
  cultivation_modifiers: Dictionary
}
```

灵气影响：

```text
主动吐纳环境输入；
闭关修炼效率；
资源输入兼容性；
经脉压力与心魔风险；
突破准备条件；
事件选项与风险提示。
```

设施使用 `facility_refs` 关联设施状态。设施可提供：

```text
修炼环境修正；
功法研习效率；
行动资源输入相性或稳定性修正；
残余药性收束风险修正；
炼丹、炼器、治疗、护法、合成等固定执行时间行动条件。
```

这些效果必须通过行动模板、设施权限、资源使用日志和结果包进入结算，不得作为无来源全局倍率。

修炼数值读取节点时，应通过 `NodeRealmSupport` 或等价模板表达：

```text
节点支持的境界段标签；
灵气品阶、密度与相性；
兼容角色容量；
兼容小时消耗与再生；
每世界小时风险；
机会窗口修正；
竞争策略。
```

节点灵气只提供当前 `RealmSegment` 的相对效率和压力 / 风险修正，不直接发放 raw 修为。

## 9. 节点资源槽

`NodeResourceSlot` 代表节点自然、半自然或组织控制的产出位置。

```text
NodeResourceSlot {
  slot_id: String
  node_id: String
  resource_template_id: String
  current_amount: number
  max_amount: number
  regen_per_world_hour: number
  visibility_policy: String
  depletion_event_refs: Array
  contest_state: Dictionary
}
```

规则：

1. 资源采集、争夺、消耗和刷新均按 `world_hour` 记录。
2. 自然资源点原则上先产出资源池或资源量，再通过采集、加工、炼制、修复等行动转化为物品或宗门资源。
3. 已控制资源节点的基础产出属于常态结算，不占宗门唯一持续行动槽。
4. 枯竭、再生、污染、异变按节点模板配置，不做统一生态公式。
5. 公开信息通过可见性系统进入地图摘要、日志或传闻。

资源再生可按 `world_hour` 连续累计，也可按 `macro_period_id` 做批量刷新，但记录仍需能追溯到世界时间。

### 9.1 资源投放预算

地图层继承旧设定中的 `WorldResourceBudget`。它控制区域、节点和机会窗口可向世界投放多少资源，不是玩家可见库存，也不替代 `NodeResourceSlot`、`ResourcePool` 或资产容器。

```text
WorldResourceBudget {
  budget_id: String
  world_id: String
  region_id: String | null
  tier_code: String
  budget_type: stable | opportunity | rare | legacy
  max_value: number
  spent_value: number
  reserved_value: number
  refresh_rule: String
}
```

使用口径：

```text
stable：地图骨架保证下限，支持受控节点常态产出；
opportunity：按区域、事件压力和阶段预算生成机会型资源；
rare：必须由事件、秘境、隐藏层、强敌或争夺链路承载；
legacy：正式后手、遗产、密库或封存链路，不混入普通随机奖励池。
```

资源槽出现资源时，应记录其来自哪个 `WorldResourceBudget` 或旧资产容器。高价值物品一旦进入显性库存或事件锁定奖励，按 `BudgetValue / V_world_budget` 扣除；出售、拆解、销毁、上交、损坏或消耗不返还生成预算。

阶段预算投放到地图时，优先进入 `WorldResourceBudget` 的预留、`NodeResourceSlot`、`OpportunityWindow` 或区域效果，不直接改写角色修为。

规则：

```text
WorldStageBudgetState.active_budget_realm 决定当前稳定投放的最高资源阶段；
先锋资源可通过 next_realm_leakage_rate 少量提前泄漏；
新阶段预算打开后，节点资源应在 1-3 个宏观周期内逐渐显现；
预算投放必须产生 world_production_budget_delta / resource_slot_delta / event_window_delta / visible or hidden log；
recommended_stage_range 只做筛选、提示和风险预期，不作为预算硬锁。
```

## 10. 控制权与影响力

节点归属采用：

```text
控制权 + 影响力
```

控制权影响：

```text
主资源收益权；
建设权；
驻守权；
通行管理权；
节点事件优先响应权；
宗门 AI 行动目标选择。
```

影响力影响：

```text
行动耗时与便利；
情报发现率；
任务成功率；
探索与交易便利；
控制权争夺基础；
对控制者收益的轻微竞争；
传闻可信度与可见性。
```

控制权变更采用阈值 + 事件模型。推动因素包括：

```text
玩家探索、驻守、建设、开采；
玩家处理节点事件；
玩家亲自参与宗门相关个人行动；
宗门 AI 持续行动；
外部 AI 宗门压力；
NPC 行动；
后手触发；
节点危机或重大事件链。
```

达到条件后，由事件系统触发控制权变更事件或直接生成受控的 `node_delta`，再由 S1 合并。

## 11. 区域层与宏观效果

区域是地图生成与事件演化的中层容器，不是玩家回合结构。

```text
RegionState {
  region_id: String
  display_name: String
  region_type: String
  zone_tier: String
  base_aura_band: String
  base_danger_band: String
  climate_or_terrain_tags: Array
  dominant_factions: Array
  region_pressure_tags: Array
  major_event_refs: Array
  resource_budget_refs: Array
}
```

MVP 区域至少包含：

```text
新手 / 凡俗边缘区；
宗门腹地区；
边界 / 荒野 / 禁地区。
```

`active_region_effects` 可表达灾变、灵潮、战乱、封山、市场波动等区域层效果。区域效果应按 `world_day / world_hour` 生效，宏观周期只用于内容批次和阶段标记。

## 12. 秘境、入口与机会窗口

`OpportunityWindow` 表达秘境、资源名额、节点危机、短期交易、突破护法机会等时间窗口。

```text
OpportunityWindow {
  window_id: String
  node_id: String
  starts_world_day: int
  starts_world_hour: int
  ends_world_day: int
  ends_world_hour: int
  visibility_policy: String
  entry_requirements: Array
  event_template_refs: Array
  contest_policy: String
}
```

规则：

1. 普通秘境入口作为节点上的机会窗口或入口槽表达。
2. 少数著名秘境可作为长期显示的高危节点。
3. 窗口开启、关闭、被争夺、被后手影响或被宗门 AI 改变时写入 `TimelineReplay`。
4. 进入窗口必须通过个人 `Command`、事件选择或 B1 交锋进入，不允许地图直接改角色状态。
5. 窗口信息按可见性分发：公开地图信息、宗门共享情报、传闻、玩家已探索信息或隐藏世界信息。

临时节点可用于表达秘境内部或短期空间：

```text
TemporaryNode {
  temp_node_id: String
  parent_node_id: String
  created_world_day: int
  created_world_hour: int
  expiry_rule: Dictionary
  access_rules: Dictionary
  event_chain_refs: Array
  cleanup_rules: Dictionary
}
```

## 13. 隐藏层与后手层

隐藏层用于承载：

```text
隐藏资源；
旧洞府；
线索；
秘境入口；
伏笔事件；
前世痕迹；
隐藏路线。
```

后手层用于挂载正式 `ContingencyRecord` 或 `LegacyRecord`。

规则：

1. 后手必须有位置或明确目标引用。
2. 后手创建、触发、失败、争夺必须写入轮回账本、日志和 `TimelineReplay`。
3. 后手风险只在相关节点发生明确变化、竞争者发现、宗门清查、事件结果或宏观条件改变时检定。
4. 不做无原因的每回合随机磨损。
5. 不引入年久失修型低频随机失败作为 MVP 默认规则。

## 14. 可见性

地图可见性分层：

```text
公开地图信息；
玩家已探索信息；
宗门共享情报；
传闻信息；
隐藏路线；
秘境窗口；
个人事件来源；
隐藏世界信息；
Debug 信息。
```

玩家 UI 只显示其可见层级内的节点、路线、风险、资源槽摘要、机会窗口、宗门影响与传闻。

不得显示：

```text
其他玩家私人事件归因；
隐秘局部时停来源；
未公开突破选择；
隐藏后手真实归属；
Debug private_reason_refs。
```

公开地图变化应通过中性描述表达，例如：

```text
黑石岭驻守加强。
云麓山道近日妖兽踪迹增多。
青木谷灵气波动，疑有秘境窗口。
坊市筑基资源短缺。
```

## 15. 世界小时演化

每个世界小时，S4 由 S1 调用并输出结果包。

```text
advance_nodes(world):
  for node in node_states:
    regenerate_resource_slots(node)
    update_facility_effects(node)
    update_risk_level(node)
    update_influence(node)
    check_event_windows(node)
    write_node_result_packages(node)
```

演化来源：

```text
玩家行动；
宗门 AI；
NPC 行动；
资源采集和枯竭；
事件结果；
后手触发；
宏观周期；
世界随机状态。
```

C1 追赶期间只补结算确定性节点影响，不触发新的随机个人事件、普通机缘或软机会事件。若地图变化属于强制公开节点事件、正式交锋或 P0 公共事件，应交给 S1 速度状态机处理。

## 16. 与行动队列的集成

地图系统为 `Command` 校验提供：

```text
location_requirement；
target_node_id；
route availability；
current_cost_hours；
risk_level；
event conflict；
visibility_permission；
facility_requirement；
resource_slot_access；
sect_or_npc_permission。
```

典型集成：

1. `travel` 读取 `RouteState.current_cost_hours` 与通行条件。
2. `cultivate` 读取 `NodeState.aura_profile`、设施和风险。
3. `apply_resource` 读取角色位置、宗门权限、库存来源和设施支持。
4. `breakthrough_open` 读取突破地点、护法、环境稳定性和风险。
5. 行动完成后若角色在中高风险或未知风险节点进入自动兜底，`FallbackState.action_type=rest`。

地图变化不自动修改玩家队列。队列中的移动或节点行动在执行前必须再次校验。

## 17. 结果包与回放

地图系统输出：

```text
node_delta；
route_delta；
resource_slot_delta；
visibility_delta；
rumor_entries；
event_window_delta；
risk_level_delta；
region_effect_delta；
temporary_node_delta；
ledger_entries；
visible_log_entries；
hidden_world_log_entries；
debug_log_entries。
```

必须进入 `TimelineReplay` 的记录：

```text
节点风险变化；
路线发现、封锁、开启或条件变化；
资源槽刷新、枯竭、争夺；
机会窗口开启、关闭、进入、错过或被争夺；
宗门 AI 导致的节点变化；
后手导致的节点、路线或可见性变化；
重大节点事件；
地图相关结果包。
```

所有输出交由 S1 合并。日志和回放必须保留 `world_day / world_hour`。

## 18. UI 与验收约束

主界面地图应作为共享日历行动工作台的第一视野主体，稳定展示：

```text
当前位置；
可见节点；
可见路线；
节点风险；
资源槽摘要；
宗门影响；
秘境 / 机会窗口；
公开传闻；
队列目标路线；
当前节点可用行动入口。
```

地图不得显示其他玩家私人事件来源。隐秘交锋、局部时停和私人突破只通过中性速度、公开后果、传闻或地图变化体现。

验收检查：

1. 地图状态使用 `WorldMapState.current_world_day / current_world_hour`。
2. 移动行动读取 `RouteState.current_cost_hours` 并按 `world_hour` 结算。
3. `risk_level` 正确影响自动兜底和显式托管默认。
4. 节点 `aura_profile` 能被修炼和突破准备读取。
5. 节点资源槽能刷新、消耗、枯竭和生成传闻。
6. 宗门 AI 能改变节点影响、风险、资源槽或机会窗口。
7. 机会窗口有开始、结束、可见性、准入条件和争夺策略。
8. 后手只在有明确世界变化或触发条件时检定，不做无原因随机失效。
9. 地图 UI 不显示其他玩家私人事件归因。
10. 地图变化进入结果包和 `TimelineReplay`。

## 19. Deprecated aliases 与迁移说明

| 旧口径 | 当前处理 | 说明 |
| --- | --- | --- |
| `current_turn_id` | 废弃 | 地图主时间使用 `current_world_day / current_world_hour` |
| `created_turn_id` | 废弃 | 临时节点使用 `created_world_day / created_world_hour` |
| `base_cost_slots` | 废弃 | 路线成本使用 `base_cost_hours / current_cost_hours` |
| 回合刷新地图 | 废弃 | 地图变化按 `hour_tick` 推进，宏观批次用 `macro_period_id` |
| 5 天回合作为世界演化节奏 | 废弃 | 小时、日、宏观周期和特殊窗口分层处理 |
| 推荐阶段硬锁 | 废弃 | `recommended_stage_range` 只做筛选、提示和风险预期 |
| 后手每回合随机磨损 | 废弃 | 后手失败必须有节点变化、竞争、宗门清查、事件或条件变化原因 |

## 20. 来源与裁决

吸收来源：

```text
v2.3 04_地图节点_世界演化
v2.3 01_共享日历_房间推进_权威结算
v2.3 03_个人行动队列_移动通行_托管
v2.3 03_术语表_命名规范_字段统一
v2.3 01_运行时状态_数据模型_结果包
v2.3 05_宗门组织_库存_宗门AI持续行动
v2.3 06_经济物品资产_NPC持久化
v2.3 07_后手遗产_可见性_多人间接竞争
v2.3 01_UIUX需求方案
v2.3 02_MVP开发切片与验收清单
v2.3 05_原始文档映射与来源索引
修为年限、境界收益与阶段预算数值设计
```

参考来源：

```text
v2.2 地图节点_世界演化
旧版地图节点、资源槽与建筑槽设计案
旧版沙盒世界演化与地图节点生成规则草稿
旧版经济系统框架与物品产出草稿
```

裁决：

| 采用方案 | 废弃方案 | 原因与实现影响 |
| --- | --- | --- |
| 地图按 `world_day / world_hour` 和 `hour_tick` 演化 | `current_turn_id`、5 天回合作为地图主节奏 | 地图变化需要与行动、事件、宗门 AI、日志和回放对齐 |
| 有向带权路线使用小时成本 | 行动格或回合槽成本 | 移动是普通持续 `Command`，执行前再次校验 |
| `risk_level` 驱动兜底与托管默认 | 只用文案危险描述 | 自动兜底、显式托管和 UI 风险提示都需要结构字段 |
| 节点资源槽输出资源池 / 资源量并经行动转化 | 节点直接无来源发放任意物品 | 资源进入经济系统时必须可审计、可回放 |
| `WorldResourceBudget` 控制地图资源投放，阶段预算只做境界调度 | 高阶资源无来源全图刷新或把阶段预算当作唯一预算池 | 沙盒随玩家突破开放机会，但每次资源出现仍需预算来源、时间、可见性和资产日志 |
| 控制权 + 影响力模型 | 玩家逐节点经营接管 | 节点变化由行动、宗门 AI、事件和后手共同推动 |
| 后手失败必须有明确原因 | 后手每回合随机磨损或无日志失效 | 轮回体验需要可复盘和可解释 |
| 地图可见性分层 | 地图公开所有节点真相和私人归因 | 多人间接竞争依赖信息边界与传闻系统 |
