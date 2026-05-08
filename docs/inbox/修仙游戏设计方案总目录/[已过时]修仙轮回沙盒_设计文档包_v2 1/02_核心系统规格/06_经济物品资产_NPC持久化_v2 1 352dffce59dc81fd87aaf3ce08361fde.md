# 06_经济物品资产_NPC持久化_v2.1

# 经济、物品、资产容器与 NPC 持久化（v2.1）

## 0. 文档定位

本文整理资源、灵石、物品、资产容器、世界生成预算、宗门库存、商店库存、NPC 分层持久化、战斗战利品和遗产分配的统一口径。

本项目经济系统不是完整市场模拟，也不是所有 NPC 都有钱包、背包和消费偏好的社会模拟。它更接近：

> 资源流转与资产可信系统。
> 

新版重点：所有资源请求、预留、消耗日志统一使用 `turn_id / world_hour / consumed_hours` 口径，不再使用旧 `quarter / tick`。

---

## 1. 经济系统一句话定位

经济系统负责让资源、物品、灵石、宗门库存、NPC 资产、市场库存、事件奖励和后手遗产都拥有可信来源、明确位置、可验证消耗、可追踪流转，并最终服务于：

```
个人成长效率
+ 宗门资源平台
+ 沙盒世界演化
```

---

## 2. 核心原则

### 2.1 先问资产容器，再问物品归属

不要先问：

```
这个 NPC 身上有什么？
```

而要先问：

```
这个资产属于哪个容器？
容器在哪里？
谁有权限调用？
它是否显性存在？
它的变化是否需要写入日志？
```

### 2.2 资产变化分五类

```
生成：世界、节点、事件、配方或预算创造新资产。
转移：资产从一个容器移动到另一个容器。
消耗：资产被行动、事件、战斗、突破、建设等用掉。
回收：资产被拆解、修复、出售、上交、再加工，转换成其他资产。
封存：资产进入正式后手、遗产、密库、事件锁定或隐藏层。
```

### 2.3 抽象到足够低成本，具体到足够可信

MVP 不需要所有资源都是具体物品实例。

推荐：

- 宗门大宗资源先用抽象库存数值。
- 节点自然产能先作为 ResourcePool / ResourceSlot。
- 普通材料、丹药、符箓可作为可堆叠物品。
- 法宝、功法载体、正式后手物、高价值突破资源、带独立状态的物品作为实例物品。
- 当抽象资源进入战斗、交易、突破、封存、奖励、遗产等具体语境时，再转换为物品栈或实例。

---

## 3. 资产容器模型

```
AssetContainerRef {
  container_type: String,
  container_id: String
}
```

容器类型：

| 容器 | 用途 |
| --- | --- |
| CharacterInventory | 当前角色随身 / 个人储藏 |
| SectStorage | 宗门库存 |
| NodeStorage | 节点储藏 |
| ShopStock | 店铺库存 |
| MarketListing | 市场挂牌 |
| ResourcePool | 节点资源池 |
| SealedLegacy | 正式后手 / 遗产封存 |
| EventLockedReward | 事件锁定奖励包 |

---

## 4. 货币与高密度灵气资源

### 4.1 灵石

灵石是修行世界核心通货。

```
SpiritStoneStack {
  amount: int,
  owner_container_ref: AssetContainerRef,
  bind_state: String,
  ledger_refs: Array
}
```

规则：

- 灵石不分等级。
- 低阶货币不进入主修行经济循环。
- 灵石可以兑换低阶货币，用于凡人区域消费、伪装、剧情任务等。
- 普通灵石不能无损支持所有高阶灵气用途。

### 4.2 聚灵石

聚灵石是高密度灵气物品，不是灵石面额。

```
CondensedSpiritStoneItem {
  item_id: String,
  tier_code: String,
  quality_code: String,
  energy_density: float,
  owner_container_ref: AssetContainerRef
}
```

MVP 灵石加工只打通：

```
灵石 + 加工设施 + 固定执行时间 / 人力 / 技艺修正
→ 聚灵石
```

---

## 5. 物品类型、等级、堆叠

MVP 核心类型：

1. 货币。
2. 补给。
3. 修炼资源。
4. 突破资源。
5. 材料 / 矿材 / 灵材。
6. 功法 / 术法载体。
7. 法宝。
8. 消耗道具。
9. 后手 / 遗产封存物。
10. 任务 / 权限 / 钥匙类物品。

评级采用：

```
阶级 Tier + 品级 Quality
```

堆叠：

```
ItemStack {
  stack_id: String,
  item_template_id: String,
  tier_code: String,
  quality_code: String,
  amount: int,
  key_state_tags: Array,
  bind_state: String,
  owner_container_ref: AssetContainerRef
}
```

实例：

```
ItemInstance {
  item_id: String,
  item_template_id: String,
  tier_code: String,
  quality_code: String,
  instance_state: Dictionary,
  durability: float,
  charge: float,
  source_log_refs: Array,
  owner_container_ref: AssetContainerRef,
  tags: Array
}
```

不设计半可堆叠物品。

---

## 6. 资源使用接口

所有消耗应通过统一接口：

```
ResourceUseRequest {
  actor_ref: String,
  source_container_ref: AssetContainerRef,
  resource_or_item_ref: String,
  amount: int,
  use_context: String,      # cultivation / breakthrough / combat / building / event / sect_ai
  target_ref: String,
  turn_id: int,
  world_hour: int
}
```

输出：

```
ResourceUseResult {
  accepted: bool,
  consumed_assets: Array,
  failed_reason: String,
  inventory_delta: Dictionary,
  log_entries: Array
}
```

宗门资源预留：

```
ResourceReservation {
  reservation_id: String,
  owner_scope: String,      # sect / character / event
  owner_ref: String,
  resource_type: String,
  amount: int,
  reserved_for_system: String,
  reserved_for_event: String,
  start_turn_id: int,
  expiry_turn_id: int,
  status: String
}
```

---

## 7. 配方制生产

MVP 支持轻量配方制生产，不做完整炼丹炼器大系统。

规则：

- 玩家或宗门 AI 主动生产物品时，优先使用配方制。
- 消耗明确资源。
- 产出明确目标物品。
- 随机性只在配方允许范围内发生。
- 配方作为非战斗类功法 / 技艺的衍生物进入规则。
- 配方可由 NPC 传授或物品学习获得。
- MVP 支持配方经验与少量等级效果。

生产行动时间：

- 炼丹 / 炼器通常属于固定执行时间持续行动。
- 采药 / 挖矿 / 资源处理通常属于可选投入执行时间行动。

---

## 8. 随身资产与无装备栏

本项目不采用传统装备栏 / 换装备 / 换法宝作为核心限制。

规则：

- 随身携带的法宝、道具、已掌握术法 / 神通都可以成为可用来源。
- 被动法宝在满足条件时自动生效。
- 主动型法宝通过战斗交锋格、事件选择或行动入口投入。
- 限制来自时间预算、交锋格、元气 / 神念 / 生机、耐久、充能、消耗品数量、事件条件、标签，而不是固定装备栏位。

MVP 不引入携带容量数值，不设计重量、体积、背包格子或负重上限。携带限制由标签和事件上下文表达。

---

## 9. NPC 持久化与库存

NPC 分层：

```
N1：背景人群 / 抽象劳动力。
N2：普通可交互 NPC，可有轻量状态。
N3：重要 NPC，默认持久化关系、位置、关键资产。
N4：高价值 NPC，拥有宏观意图、事件权重和持久化资产。
```

规则：

- 不在战斗开始时临时初始化 NPC 完整库存。
- 战利品来自持久化随身 / 可调用资产、事件锁定奖励包或预算生成奖励。
- 商店库存属于 ShopStock / MarketListing / SectStorage / NodeStorage，不属于掌柜个人。
- N3 以上默认持久化个人库存。
- N4 宏观行动不应随每回合 5 天全量提频，可按 `macro_period_id`、关键事件或宗门 AI 需要推进。

---

## 10. 商店与市场库存

商店是资产容器，不是 NPC 背包。

```
ShopStock {
  shop_id: String,
  node_id: String,
  owner_faction_ref: String,
  stock_container_ref: AssetContainerRef,
  restock_rule: Dictionary,
  price_rule: Dictionary,
  visibility_rules: Dictionary,
  log_refs: Array
}
```

MVP 不做完整市场模拟。价格、库存和补货通过模板、节点状态、宗门控制、事件压力和宏观周期驱动。

---

## 11. 资产日志

以下必须写日志：

- 高价值物品生成。
- 关键突破物消耗。
- 法宝、功法载体、正式后手物转移。
- 宗门库存资源预留、消耗、释放。
- 战斗战利品分配。
- 后手封存、暴露、回收、失效。
- 商店库存重大变化。

日志应记录：

```
turn_id
world_day
world_hour
source_system
actor_ref
container_from
container_to
asset_refs
action_or_event_ref
visible_state
```