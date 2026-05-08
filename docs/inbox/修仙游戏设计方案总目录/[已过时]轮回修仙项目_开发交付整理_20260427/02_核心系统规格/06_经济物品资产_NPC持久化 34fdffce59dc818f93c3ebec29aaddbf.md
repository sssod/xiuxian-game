# 06_经济物品资产_NPC持久化

# 经济、物品、资产容器与 NPC 持久化

## 0. 文档定位

本文整理资源、灵石、物品、资产容器、世界生成预算、宗门库存、商店库存、NPC 分层持久化、战斗战利品和遗产分配的统一口径。

本项目经济系统不是完整市场模拟，也不是所有 NPC 都有钱包、背包和消费偏好的社会模拟。它更接近：

> 资源流转与资产可信系统。
> 

## 1. 经济系统一句话定位

经济系统负责让资源、物品、灵石、宗门库存、NPC 资产、市场库存、事件奖励和后手遗产都拥有可信来源、明确位置、可验证消耗、可追踪流转，并最终服务于：

```
个人成长效率
+ 宗门经营取舍
+ 沙盒世界演化
```

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

这五类不能全部用“获得 / 失去物品”表达。

### 2.3 抽象到足够低成本，具体到足够可信

MVP 不需要所有资源都是具体物品实例。

推荐口径：

- 宗门大宗资源先用抽象库存数值。
- 节点自然产能先作为 ResourcePool / ResourceSlot。
- 普通材料、丹药、符箓可作为可堆叠物品。
- 法宝、功法载体、正式后手物、高价值突破资源、带独立状态的物品作为实例物品。
- 当抽象资源进入战斗、交易、突破、封存、奖励、遗产等具体语境时，再转换为物品栈或实例。

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

### 4.2 低阶货币

```
MundaneCurrencyStack {
  currency_type: String,  # coin / silver
  amount: int,
  context_tags: Array
}
```

用于凡人阶段、新手流程和特殊情境。

### 4.3 聚灵石

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
灵石 + 加工设施 + 时间 / 人力 / 技艺修正
→ 聚灵石
```

聚灵石可作为高阶阵法、突破、洞府维护、法宝充能、特殊配方等系统的统一高密度资源接口。

## 5. 物品类型

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

## 6. 物品等级

全游戏可评级对象采用：

```
阶级 Tier + 品级 Quality
```

### 6.1 Tier

```
TierProfile {
  tier_code: String,        # A / B / C
  tier_order: int,
  display_key: String,
  default_stage_range: Array,
  value_multiplier: float,
  access_requirement: Dictionary
}
```

### 6.2 Quality

```
QualityProfile {
  quality_code: String,     # Q1 ~ Q5
  quality_order: int,
  display_key: String,
  value_multiplier: float,
  random_affix_budget: int,
  instability_modifier: float
}
```

五档显示：

```
下品 / 中品 / 上品 / 极品 / 绝品
```

绝品是稀有产出，不作为普通自然随机结果。主要来自高风险秘境、重大事件、制造大成功、稀有配方或其他明确高价值机制。

## 7. 堆叠与实例

不设计半可堆叠物品。

### 7.1 可堆叠物品

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

### 7.2 独立实例物品

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

### 7.3 堆叠键

```
StackKey {
  item_template_id: String,
  tier_code: String,
  quality_code: String,
  key_state_tags: Array,
  bind_state: String,
  owner_restriction: String
}
```

若字段影响战斗、突破、交易、后手、消耗结果，则进入堆叠键。若只是风味，不拆分堆叠。

## 8. 物品生成与预算帽

世界生成物品包括：

- 宝藏。
- 事件奖励。
- NPC 掉落。
- 秘境奖励.
- 世界随机发现。
- 隐性状态实例化物品。

这些属于“凭空生成”范畴，必须受分阶生成预算帽约束。

规则：

- 一旦物品由事件 / 宝藏 / 隐性状态实例化，按完整预算价值扣除生成预算。
- 后续出售、拆解、损坏、销毁、上交、封存，不返还生成预算。
- 生成预算用于控制世界投放，不是玩家可见资源，也不是资产回收池。

## 9. 配方制生产

MVP 支持轻量配方制生产，不做完整炼丹炼器大系统。

规则：

- 玩家或宗门主动生产物品时，优先使用配方制。
- 消耗明确资源。
- 产出明确目标物品。
- 随机性只在配方允许范围内发生。
- 配方作为非战斗类功法 / 技艺的衍生物进入规则。
- 配方可由 NPC 传授或物品学习获得。
- MVP 支持配方经验与少量等级效果。
- 配方改造不进入 MVP，只保留接口。

## 10. 资源使用接口

所有消耗应通过统一接口：

```
ResourceUseRequest {
  actor_ref: String,
  source_container_ref: AssetContainerRef,
  resource_or_item_ref: String,
  amount: int,
  use_context: String,      # cultivation / breakthrough / combat / building / event
  target_ref: String,
  quarter: int,
  tick: int
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

## 11. 随身资产与无装备栏

本项目不采用传统装备栏 / 换装备 / 换法宝作为核心限制。

规则：

- 随身携带的法宝、道具、已掌握术法 / 神通都可以成为可用来源。
- 被动法宝在满足条件时自动生效。
- 主动型法宝通过战斗交锋格、事件选择或行动入口投入。
- 限制来自行动格、交锋格、元气 / 神念 / 生机、耐久、充能、消耗品数量、事件条件、标签，而不是固定装备栏位。

MVP 不引入携带容量数值，不设计重量、体积、背包格子或负重上限。携带限制由标签和事件上下文表达。

常用标签：

```
bulky
fragile
sealed
combat_ready
food
currency
quest_item
legacy_related
```

## 12. 法宝

法宝可以：

- 主动投入。
- 被动触发。
- 损耗。
- 修复。
- 封存。
- 传承。
- 拆解或回收。

```
ArtifactItem {
  item_id: String,
  active_command_refs: Array,
  passive_effect_refs: Array,
  durability: float,
  charge: float,
  spirituality: float,
  repair_requirements: Dictionary,
  bind_state: String
}
```

MVP 不引入法宝自然灵性衰退。法宝损耗主要来自主动使用、被动触发、战斗破坏或事件后果。

## 13. 突破资源

突破资源分层：

```
关键突破物：必需，决定能否开启突破事件链。
辅助突破资源：可选，影响风险、交锋修正或奖励质量。
突破地点 / 护法 / 宗门支持：外部准备，不一定是物品。
```

关键突破物是具体物品实例，不是抽象货币。

```
BreakthroughCatalystItem {
  item_id: String,
  tier_code: String,
  quality_code: String,
  supported_major_transition: String,
  method_tag_affinity: Array,
  catalyst_role: String,
  purity_or_stability_value: float,
  owner_container_ref: AssetContainerRef,
  consumption_rule: String,   # consumed_on_chain_start
  event_flags: Array
}
```

突破事件链正式创建时消耗关键突破物，无论最终成功、失败、中断、残缺突破或身死转世都不返还。

## 14. NPC 分层持久化

NPC 采用分层持久化，不做全 NPC 全量模拟。

| 层级 | 名称 | 身份 | 库存 | 行动 | 世界影响 |
| --- | --- | --- | --- | --- | --- |
| N0 | 抽象人群 / 劳力池 | 否 | 否 | 聚合 | 低 |
| N1 | 轻量身份 NPC | 是 | 否 | 无 / 被动 | 低 |
| N2 | 功能服务 NPC | 是 | 通常否，库存归机构 | 职责刷新 | 中低 |
| N3 | 关键角色 NPC | 是 | 是 | 季度宏观行动 | 中高 |
| N4 | 世界轴心 NPC / 势力代理 | 是 | 是 | 高优先级宏观行动 + 事件链 | 高 |

不设置 N2.5。

## 15. NPC 库存规则

战斗开始时不得临时初始化“完整 NPC 库存”。

战斗可获得资产只来自：

1. NPC 已持久化的随身 / 可调用资产。
2. 事件链在结算前明确锁定的奖励包或掉落包。
3. 由事件预算生成的非个人库存奖励，且必须写入来源日志。

商店库存优先属于：

```
ShopStock / MarketListing / SectStorage / NodeStorage
```

不是掌柜个人背包。

## 16. N4 行动

N4 每季度必须生成个人宏观行动。

行动可包括：

- 闭关。
- 外出。
- 亲自介入宗门主行动。
- 推动重大事件。
- 处理内部危机。
- 争夺资源窗口。
- 稳定宗门局势。

若 N4 行动与玩家、宗门主行动或关键节点交叉，进入事件链精算。若未交叉，用汇总结算写入状态、宗门倾向、传闻候选或隐藏世界日志。

N4 行动不得无条件增加宗门主行动数量。

## 17. 商店与市场

### 17.1 宗门商店

宗门商店需要依赖真实供给状态，由宗门建筑、设施、部门产出决定库存供应。

### 17.2 非宗门商店

非宗门商店按商店常规运营事件处理，属于世界生成的一部分。

### 17.3 玩家出售

玩家出售给商店的物品进入 `ShopStock`：

- 默认保留 1 个季度。
- 不支持原价回购。
- 保留期后，可堆叠物品按回收价折算为灵石进入商店库存。
- 不可堆叠物品继续保留，超出警戒区时按回收价从低到高进入回收系统。
- 带不可回收标签的物品不进入回收。

MVP 不做操控市场和倒卖赚差价玩法。

## 18. 死亡遗产分配

N3 / N4 死亡后：

```
死亡事件链
→ 处理战斗损坏、遗失、封存、遗言、现场控制权
→ 读取剩余资产容器
→ 按遗产分配规则处理
→ 写入资产流水与日志
```

MVP 不细分复杂世界观关系。除当场损失外，其余资产归属权整体移交给一个主体。

顺序：

```
道侣
→ 子嗣
→ 弟子
→ 宗门
→ 家族
→ 世界
```

宗门托管 / 职务资产归宗门，不随个人死亡流失。正式后手资产按 SealedLegacy 规则处理，不因普通死亡自动暴露。

## 19. MVP 验收清单

- 灵石作为核心通货且不分等级。
- 聚灵石作为独立高密度灵气物品。
- 宗门抽象资源和具体物品可区分。
- 资产容器可表达角色、宗门、节点、商店、市场、后手、事件锁定。
- 物品只分可堆叠和独立实例。
- 物品生成扣除生成预算。
- 资源使用写入日志。
- 战斗不会临时生成 NPC 完整库存。
- 商店库存不属于掌柜个人。
- N3 / N4 可持有真实个人库存。
- N4 每季度有宏观行动。
- 玩家出售物品进入 ShopStock。
- 正式后手不凭空产出物品，只封存已存在资产。