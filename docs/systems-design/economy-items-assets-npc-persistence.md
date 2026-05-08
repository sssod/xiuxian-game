# 经济、物品、资产容器与 NPC 持久化

状态：第三批正式定稿
更新日期：2026-05-08
来源主版本：v2.3 calendar_preinput

## 1. 系统定位

S6 负责资源来源可信、物品持久化、资产容器权限、行动资源输入、残余效果、交易与 NPC 状态记录。

经济系统不是完整市场模拟，也不是所有 NPC 都拥有钱包、背包、消费偏好和独立日程的社会模拟。MVP 中它更接近：

```text
资源流转与资产可信系统。
```

核心目标：

```text
资源、物品、灵石、宗门库存、节点资源、NPC 资产、市场库存、事件奖励和后手遗产
都拥有可信来源、明确位置、可验证消耗、可追踪流转，并最终服务于角色成长、宗门资源平台和沙盒世界演化。
```

所有资源请求、预留、转移、消耗、残余效果、交易和 NPC 变化都必须使用：

```text
world_day
world_hour
consumed_hours
result_package_refs
```

## 2. MVP 边界

MVP 保留：

```text
资产容器；
资源池 / ResourcePool；
世界产出预算账本；
资产生成请求与预算扣除记录；
物品实例 / 可堆叠数量；
灵石与货币余额；
丹药、灵材、符箓、法器、功法载体等物品类型；
ActionResourceInputBinding；
ActiveResourceEffect；
ResourceUseRequest；
交易 / 转移记录；
宗门库存、节点资源库、NPC 持有物、商店库存；
NPC 分层持久化；
来源可信与审计日志；
结果包与 TimelineReplay 记录。
```

MVP 不引入：

```text
完整市场供需模拟；
所有 NPC 的完整钱包 / 背包 / 消费偏好；
重量、体积、背包格子或负重上限；
传统装备栏作为核心限制；
半可堆叠物品；
即时服丹涨修为；
残页 / 章节作为运行时学习进度；
无来源倍率、无日志资源发放或无容器资产转移。
```

## 3. 资产容器原则

先问资产容器，再问物品归属。

不要先问：

```text
这个 NPC 身上有什么？
```

而要先问：

```text
这个资产属于哪个容器？
容器在哪里？
谁有权限调用？
它是否显性存在？
它的变化是否需要写入日志？
```

资产变化分五类：

| 类型 | 含义 |
| --- | --- |
| 生成 | 世界、节点、事件、配方、宗门 AI 或预算创造新资产 |
| 转移 | 资产从一个容器移动到另一个容器 |
| 消耗 | 资产被行动、事件、战斗、突破、建设等用掉 |
| 回收 | 资产被拆解、修复、出售、上交、再加工，转换成其他资产 |
| 封存 | 资产进入正式后手、遗产、密库、事件锁定或隐藏层 |

所有高价值资产变化必须可审计、可复盘，并进入结果包。

### 3.1 世界产出预算与资源流转

预算相关设定继承旧版资源流转框架。`WorldStageBudgetState / RealmBudgetPool` 只负责境界阶段的解锁与分配，不覆盖 `WorldProductionBudgetState`、`WorldItemBudgetTier`、`WorldResourceBudget`、`ResourcePool` 和资产容器链路。

资源和资产生成应按以下顺序理解：

```text
世界产出预算：控制该阶级 / 区域 / 类型还能投放多少；
ResourcePool：节点、区域或系统中的潜在产能 / 可采资源量；
AssetGenerationRequest：事件、采集、秘境、任务、交易或 NPC 掉落提出生成请求；
AssetContainer：生成成功后的明确资产位置；
ledger / logs：记录来源、预算扣除、可见性和后续流转。
```

推荐结构：

```text
ResourcePool {
  pool_id: String
  owner_type: world | region | node | sect | event | system
  owner_id: String
  resource_template_id: String
  current_amount: number
  max_amount: number
  regen_rule: String
  budget_ref: String | null
  visibility_policy: String
}

AssetGenerationRequest {
  request_id: String
  source_system: String
  generation_context: Dictionary
  tier_budget_ref: String | null
  resource_budget_ref: String | null
  reward_profile_ref: String
  target_container_ref: String | null
  event_locked_first: bool
  visibility_policy: String
}

AssetGenerationResult {
  success: bool
  generated_asset_refs: Array
  budget_value_spent: number
  source_budget_refs: Array
  target_container_ref: String | null
  ledger_entry_ref: String
  failure_reason: String | null
}
```

预算价值使用世界生成预算价值，不等于交易价格：

```text
BudgetValue = V_world_budget
```

规则：

1. 世界生成预算不在隐性候选生成时扣除，而在资产进入玩家、宗门、NPC、市场、节点显性库存或事件锁定奖励时扣除。
2. `BudgetValue` 不受市场通胀、买卖折扣或临时行情影响；它用于消耗对应阶级 / 类型的世界产出预算。
3. 出售、拆解、销毁、上交、损坏或消耗不返还世界生成预算。
4. 预算不足时，可降品级、降阶级、替换为资源 / 线索 / 副产物、延迟刷新、生成“发现但暂不可取”的事件状态，或触发守护 / 争夺事件。
5. 高于当前阶段预算境界的资源只能来自先锋泄漏、剧情、后手、宗门重大事件、强敌真实资产、事件锁定奖励或专属资源池。
6. 每次预算投放必须记录 realm / tier、budget_ref、macro_period_id、source_system、world_day / world_hour、visibility_policy 和 ledger_entry_ref。

NPC 掉落、秘境奖励、商店刷新、宗门任务奖励和节点采集都必须走同一来源链路。轻量 NPC 不得在战斗开始时临时生成完整库存；可获得资产只能来自持久化随身 / 可调用资产、事件锁定奖励包，或有预算来源的奖励包。

## 4. AssetContainer

`AssetContainer` 是资产位置、权限和审计的基本单位。

```text
AssetContainer {
  container_id: String
  owner_type: character | sect | node | npc | system
  owner_id: String
  location_node_id: String | null
  item_instance_refs: Array
  currency_balances: Dictionary
  access_policy: Dictionary
  audit_log_refs: Array
}
```

资产容器用于：

```text
角色背包；
角色储藏；
宗门库存；
节点资源库；
NPC 持有物；
商店库存；
市场挂牌；
交易缓存；
事件临时容器；
事件锁定奖励；
正式后手 / 遗产封存；
系统预算或生成池。
```

容器权限至少应能表达：

```text
owner；
可见性；
可转移性；
可消耗性；
可被宗门申请；
可被事件锁定；
是否需要位置一致；
是否需要权限 / 贡献 / NPC 关系；
审计日志级别。
```

## 5. ItemInstance

`ItemInstance` 表示可追踪物品或可堆叠物品栈。`quantity` 大于 1 时表示同模板、同关键状态、同容器内的可堆叠数量。

```text
ItemInstance {
  item_instance_id: String
  item_template_id: String
  container_id: String
  quantity: int
  quality: String
  tags: Array
  created_world_day: int
  created_world_hour: int
  source_ref: String
  visibility_policy: String
  bound_effect_refs: Array
}
```

物品类型：

```text
丹药；
灵材；
符箓；
法器；
功法载体；
残页 / 章节；
任务物；
后手凭据；
货币与资源包；
配方；
设施组件；
突破专用资源。
```

抽象到足够低成本，具体到足够可信：

1. 宗门大宗资源可以先用库存数值或资源包表达。
2. 节点自然产能可以先作为 `NodeResourceSlot` 或资源量。
3. 普通材料、丹药、符箓可作为可堆叠物品。
4. 法宝、高价值完整功法载体、正式后手物、高价值突破资源、带独立状态的物品应作为实例物品。
5. 当抽象资源进入战斗、交易、突破、封存、奖励或遗产语境时，再转换为物品栈或实例。

## 6. 灵石与货币

灵石是修行世界核心通货。MVP 可用 `AssetContainer.currency_balances` 表达灵石和低阶货币。

规则：

```text
灵石不分等级；
低阶货币不进入主修行经济循环；
灵石可以兑换低阶货币，用于凡人区域消费、伪装或剧情任务；
普通灵石不能无损支持所有高阶灵气用途；
高密度灵气资源应作为独立资源或物品，而不是灵石面额。
```

若需要表达聚灵石、破境灵晶等高密度资源，应作为 `ItemInstance` 或资源输入模板处理，并记录来源、质量、兼容小时和消耗日志。

## 7. 功法载体与残页

功法学习来自完整功法载体。

```text
完整功法载体 → 可学习并生成 MethodState；
残页 / 章节 → 合成、线索、权限、任务推进或内容投放资产；
导师 / 设施 → 行动模板修正、研习效率或权限入口。
```

残页 / 章节不得作为运行时学习进度，也不得让 UI 表达为“已学会一部分功法”。

残页 / 章节合成为完整功法载体可以使用轻量配方制：

```text
残页 / 章节 + 设施 / 导师 / 权限 + 固定执行时间
→ MethodCarrier ItemInstance
```

产物是完整功法载体，不是 `MethodState`。只有角色学习完整载体后才生成或更新 `MethodState`。

## 8. 行动资源输入

丹药、灵材、符箓和临时增益资源通过 `ActionResourceInputBinding` 绑定具体行动或事件选项。

```text
ActionResourceInputBinding {
  binding_id: String
  owner_character_id: String
  source_container_id: String
  item_instance_id: String
  resource_template_id: String
  bound_command_id: String | null
  bound_event_option_id: String | null
  compatible_hours: int
  consumed_at_world_day: int
  consumed_at_world_hour: int
  residual_policy: String
  active_effect_ref: String | null
}
```

规则：

1. 资源输入绑定具体行动或事件选项。
2. 入队时只校验当前拥有和可用。
3. 队列不锁定未来资源，不推导前序产出。
4. 行动开始或事件选项生效前再次校验。
5. 行动开始或事件选项生效时消耗。
6. 消耗后写入资产流水和结果包。
7. 未完全用完时生成 `ActiveResourceEffect`。
8. C1 追赶只补确定性资源效果。

MVP 不把“丹药炼化”作为默认独立持续行动。修为丹药、定心类资源、避瘴类资源、疗伤资源等应作为行动或事件的资源输入，按兼容小时和当前状态结算。

资源效果按 `ResourceEffectBalance` 或等价模板定价，不写成固定 raw 修为收益。资源模板至少应能表达：

```text
benchmark_hours_saved；
normalized_progress_bonus；
rate_multiplier；
compatible_hours；
contribution_cap_ratio；
meridian_pressure_delta；
mental_risk_delta；
foundation_delta；
breakthrough_success_delta；
breakthrough_quality_delta；
residual_policy；
stack_policy。
```

资源价值必须通过当前境界段的 `RealmInputFitMatrix` 校验品阶、相性、贡献上限、浪费和反噬风险。

## 9. ActiveResourceEffect

`ActiveResourceEffect` 保存资源输入未完全消耗的残余效果。

```text
ActiveResourceEffect {
  effect_id: String
  character_id: String
  source_binding_id: String
  effect_tags: Array
  started_world_day: int
  started_world_hour: int
  remaining_compatible_hours: int
  stack_policy: String
  expires_when: String
  log_refs: Array
}
```

适用：

```text
药性残余；
符箓持续效果；
灵材辅助；
临时护身；
经脉压力；
资源相性影响；
突破准备残留；
疗伤或稳定状态。
```

残余效果要求：

1. 必须能追溯到 `source_binding_id`。
2. 必须记录剩余兼容小时。
3. 必须记录叠加策略。
4. 必须记录过期条件。
5. 局部时停期间该玩家自身资源变化暂停。
6. C1 追赶只补确定性衰减或效果。

## 10. ResourceUseRequest

`ResourceUseRequest` 是资源调用、消耗、退款和失败校验的统一入口。

```text
ResourceUseRequest {
  request_id: String
  character_id: String
  source_container_id: String
  item_instance_id: String
  target_command_id: String | null
  target_event_option_id: String | null
  submitted_world_day: int
  submitted_world_hour: int
  status: pending | approved | rejected | consumed | refunded
  validation_result_ref: String
}
```

校验项：

```text
容器权限；
物品存在；
数量充足；
地点允许；
行动标签兼容；
角色状态允许；
叠加规则；
事件状态；
宗门预留或 NPC 授权；
可见性与绑定限制。
```

资源请求失败只应消耗玩家明确已经消耗的成本；行动未开始、事件选项未生效或 B1 轮未结算前，不得提前消耗关键资源。

## 11. 交易、转移与来源可信

每次物品转移必须写入：

```text
source_container_id
target_container_id
item_instance_id
quantity
world_day
world_hour
reason
visible_log_refs
hidden_debug_refs
```

建议记录结构：

```text
AssetTransferRecord {
  transfer_id: String
  source_container_id: String
  target_container_id: String
  item_instance_id: String
  quantity: int
  world_day: int
  world_hour: int
  reason: String
  source_system: String
  action_or_event_ref: String | null
  visible_log_refs: Array
  hidden_world_log_refs: Array
  debug_log_refs: Array
}
```

来源可信用于：

```text
防作弊；
回放；
任务验证；
后手争夺；
宗门审计；
NPC 关系；
多人争议处理；
突破资源复盘；
战斗战利品分配。
```

## 12. 配方制生产

MVP 支持轻量配方制生产，不做完整炼丹炼器大系统。

规则：

1. 玩家或宗门 AI 主动生产物品时，优先使用配方制。
2. 消耗明确资源。
3. 产出明确目标物品。
4. 随机性只在配方允许范围内发生。
5. 配方可由 NPC、功法、事件、宗门权限或物品获得。
6. 炼丹、炼器通常属于固定执行时间持续行动。
7. 采药、挖矿、资源处理通常属于可选投入执行时间行动。
8. 所有生产消耗和产出都写入资产流水和结果包。

配方制不绕过 `CommandQueue`、行动校验、资产容器和 S1 结果包。

## 13. 随身资产与无装备栏

MVP 不采用传统装备栏 / 换装备 / 换法宝作为核心限制。

规则：

```text
随身携带的法宝、道具、已掌握术法 / 神通可以成为可用来源；
被动法宝在满足条件时自动生效；
主动型法宝通过 B1 交锋轮、事件选择或行动入口投入；
限制来自时间、交锋轮、元气、神念、生机、耐久、充能、消耗品数量、事件条件和标签；
不使用固定装备栏位作为主要限制；
MVP 不引入携带容量数值、重量、体积、背包格子或负重上限。
```

高价值法宝和后手物必须作为实例资产追踪来源、状态和日志。

## 14. 商店与市场库存

商店是资产容器，不是 NPC 背包。

```text
ShopStock {
  shop_id: String
  node_id: String
  owner_faction_ref: String
  stock_container_id: String
  restock_rule: Dictionary
  price_rule: Dictionary
  visibility_rules: Dictionary
  log_refs: Array
}
```

MVP 不做完整市场模拟。价格、库存和补货通过以下因素驱动：

```text
模板；
节点状态；
宗门控制；
事件压力；
宏观周期；
NPC 或宗门 AI 行动；
资源槽枯竭或补给；
公开传闻。
```

市场变化必须写入可见日志或隐藏世界日志，不应作为无来源 UI 数值跳变。

## 15. NPC 持久化

`NpcState` 记录重要 NPC 的位置、关系、库存和事件状态。

```text
NpcState {
  npc_id: String
  display_name: String
  location_node_id: String
  sect_id: String | null
  realm: String
  relationship_map: Dictionary
  inventory_container_id: String
  schedule_state: Dictionary
  active_event_refs: Array
  rumor_refs: Array
  last_updated_world_day: int
  last_updated_world_hour: int
}
```

NPC 分层：

| 层级 | 处理 |
| --- | --- |
| N1 背景人群 / 抽象劳动力 | 不持久化个人库存；可作为宗门或节点抽象输入 |
| N2 普通可交互 NPC | 轻量状态，必要时有关系和事件引用 |
| N3 重要 NPC | 默认持久化关系、位置、关键资产和事件状态 |
| N4 高价值 NPC | 拥有宏观意图、事件权重、持久化资产和世界影响 |

规则：

1. 不在战斗开始时临时初始化 NPC 完整库存。
2. 战利品来自持久化随身 / 可调用资产、事件锁定奖励包或预算生成奖励。
3. 商店库存属于 `ShopStock`、`MarketListing`、`SectStorage` 或 `NodeStorage`，不属于掌柜个人。
4. N3 以上默认持久化个人库存。
5. N4 行动按 `world_hour`、`macro_period_id`、关键事件或宗门 AI 需要推进，不使用每回合全量提频。

NPC 变化来源：

```text
玩家拜访；
宗门 AI；
节点事件；
交易；
战斗；
突破传闻；
后手触发；
世界演化；
资源申请或护法请求；
可见性变化。
```

## 16. 资产日志

以下必须写日志：

```text
高价值物品生成；
关键突破物消耗；
法宝、功法载体、正式后手物转移；
宗门库存资源预留、消耗、释放；
战斗战利品分配；
后手封存、暴露、回收、失效；
商店库存重大变化；
NPC 关键资产变化；
资源输入生成 ActiveResourceEffect；
资产容器权限变化。
```

日志至少记录：

```text
world_day；
world_hour；
source_system；
actor_ref；
container_from；
container_to；
asset_refs；
action_or_event_ref；
visible_state；
result_package_ref。
```

不使用 `turn_id` 作为资产日志主时间字段。

## 17. 与 S1 / S3 / S4 / S5 的集成

经济系统不直接绕过 S1 改写世界状态。

与 S1：

```text
所有 inventory_delta、currency_delta、resource_effect_delta、trade_records、npc_delta 进入 ResultPackage；
所有高价值资产变化进入 TimelineReplay.result_packages；
Debug 日志与玩家可见日志分层。
```

与 S3：

```text
Command 入队时校验资源当前可用；
执行前再次校验资源；
行动开始或事件选项生效时才消耗；
行动资源输入生成 ActionResourceInputBinding；
未完全消耗生成 ActiveResourceEffect。
```

与 S4：

```text
节点资源槽转换为可采集资源或物品；
商店库存读取 node_id、市场状态和可见性；
NPC 位置绑定 location_node_id；
路线、风险和设施影响资源可用性。
```

与 S5：

```text
宗门库存底层使用资产容器；
宗门资源申请生成预留或拒绝；
宗门库存可作为 ActionResourceInputBinding 来源；
宗门审计记录消耗、释放、发放和回收。
```

## 18. 结果包与回放

经济系统输出：

```text
inventory_delta；
currency_delta；
resource_effect_delta；
resource_use_records；
trade_records；
npc_delta；
asset_transfer_records；
reservation_records；
ledger_entries；
visible_log_entries；
hidden_world_log_entries；
debug_log_entries。
```

必须进入 `TimelineReplay` 的记录：

```text
关键资源请求、批准、拒绝、消耗、退款；
ActionResourceInputBinding 创建；
ActiveResourceEffect 创建、衰减、过期；
高价值物品生成、转移、封存、消耗；
宗门库存审计；
NPC 关键位置、关系、资产变化；
市场或商店重大库存变化；
战利品与遗产分配；
后手资产封存和回收。
```

## 19. UI 与验收约束

UI 应按上下文展示资产，而不是展示底层所有容器。

稳定 UI 要求：

```text
行动编辑卡展示可投入资源；
资源输入显示来源容器、兼容小时、预期残余和风险提示；
宗门资源申请显示权限、库存摘要、申请状态和来源；
角色资产界面区分随身、储藏、宗门可申请、事件锁定、后手封存；
NPC 资产不默认完全公开，只显示可见交易、奖励、关系或传闻信息；
Debug 面板可查看容器、转移记录和结果包引用。
```

验收检查：

1. 角色、宗门、节点、NPC、商店和事件奖励都通过 `AssetContainer` 持有资产。
2. 资源输入必须生成 `ActionResourceInputBinding`。
3. 未消耗完资源效果必须生成 `ActiveResourceEffect`。
4. 行动未开始或事件选项未生效前，不提前消耗关键资源。
5. 宗门库存可作为行动资源输入来源，并保留审计日志。
6. 节点资源槽产出进入资产容器或物品实例时有来源记录。
7. 高价值物品和后手物有生成、转移、封存、消耗日志。
8. NPC 战利品来自持久化资产或事件锁定奖励，不临时凭空生成完整库存。
9. 商店库存不等于掌柜个人背包。
10. 经济系统输出进入 S1 结果包和 `TimelineReplay`。

## 20. Deprecated aliases 与迁移说明

| 旧口径 | 当前处理 | 说明 |
| --- | --- | --- |
| `turn_id` 资产日志 | 废弃 | 改用 `world_day / world_hour` |
| `start_turn_id` / `expiry_turn_id` 资源预留 | 废弃 | 改用 `created_world_day / created_world_hour / expires_world_day / expires_world_hour` |
| `quarter / tick` 经济时间 | 废弃 | 经济变化使用连续日历和 `hour_tick` |
| 即时服丹涨修为 | 废弃 | 丹药作为行动或事件资源输入，按兼容小时结算 |
| 丹药炼化默认独立行动 | 废弃 | MVP 默认通过 `ActionResourceInputBinding` 处理 |
| 残页 / 章节作为学习进度 | 废弃 | 只作为合成、线索、权限和内容投放资产 |
| 掌柜个人背包等于商店库存 | 废弃 | 商店库存是独立资产容器 |
| 战斗时临时生成 NPC 完整库存 | 废弃 | 战利品来自持久化资产、事件锁定奖励或预算奖励 |
| 传统装备栏作为核心限制 | 暂不引入 | 限制来自资源、标签、交锋轮、事件条件和状态 |

## 21. 来源与裁决

吸收来源：

```text
v2.3 06_经济物品资产_NPC持久化
v2.3 03_术语表_命名规范_字段统一
v2.3 01_运行时状态_数据模型_结果包
v2.3 03_个人行动队列_移动通行_托管
v2.3 02_角色真灵轮回_修炼养成
v2.3 04_地图节点_世界演化
v2.3 05_宗门组织_库存_宗门AI持续行动
v2.3 07_后手遗产_可见性_多人间接竞争
v2.3 02_MVP开发切片与验收清单
v2.3 05_原始文档映射与来源索引
```

参考来源：

```text
v2.2 经济物品资产_NPC持久化
修为修炼公式_资源输入与丹药药性处理补充_v0.2
功法系统_收敛设定汇总_v0.4
旧版经济系统框架、物品产出、NPC 持久化与库存草稿
旧版沙盒世界演化与地图节点生成规则草稿
修为年限、境界收益与阶段预算数值设计
```

裁决：

| 采用方案 | 废弃方案 | 原因与实现影响 |
| --- | --- | --- |
| 经济系统定位为资源流转与资产可信系统 | 完整市场模拟或全 NPC 社会模拟 | MVP 重点是来源、权限、消耗、日志和回放可信 |
| `AssetContainer` 作为资产持有基础 | 直接把资产挂在 NPC、宗门或节点文案上 | 容器模型能统一角色背包、宗门库存、节点资源、商店和后手封存 |
| 丹药等通过 `ActionResourceInputBinding` 绑定行动 / 事件 | 即时服丹涨修为、默认丹药炼化行动 | 与短队列、资源输入、残余效果和突破 B1 合同一致 |
| 资源效果按 `ResourceEffectBalance` 定价 | 资源模板写死 raw 修为收益 | 资源价值需要随境界适配、贡献上限、压力和突破相关性变化 |
| 世界产出预算控制资产与机会投放，阶段预算只做境界调度 | 高阶资源无来源刷新、直接给角色修为或把阶段预算当成唯一预算 | 预算打开提供世界机会，不自动赠送成长；资源流转、预算扣除和资产变化都必须可审计 |
| `ActiveResourceEffect` 记录残余效果 | 消耗后丢失未用完药性 / 符效 | 残余效果需要按兼容小时、叠加和过期规则复盘 |
| 完整功法载体生成 `MethodState` | 残页 / 章节直接作为学习进度 | 避免内容资产与运行时掌握度混淆 |
| 商店库存是资产容器 | 掌柜个人背包即商店库存 | 支持商店、市场、宗门、节点库存分层 |
| NPC 分层持久化 | 所有 NPC 完整模拟或战斗时临时生成全部库存 | N3/N4 重点持久化，低价值 NPC 轻量处理 |
| 日志使用 `world_day / world_hour` | `turn_id / quarter / tick` 混用 | 连续日历下资产变化必须与 S1、结果包和 `TimelineReplay` 对齐 |
