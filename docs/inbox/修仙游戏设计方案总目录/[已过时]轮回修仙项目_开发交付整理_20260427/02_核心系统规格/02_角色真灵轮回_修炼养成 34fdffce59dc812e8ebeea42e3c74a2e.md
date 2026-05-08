# 02_角色真灵轮回_修炼养成

# 角色、真灵、轮回与修炼养成

## 0. 文档定位

本文整理玩家主体、当世角色、真灵、执念、修为、功法、寿元、突破前置、死亡与转世的开发口径。

本文不展开完整数值公式，但明确数据结构、系统边界和冲突消解。

## 1. 三层角色模型

玩家主体分为三层：

```
真灵：跨世延续的玩家主体。
执念：转世初始化时可携带的少量遗留包。
身躯与灵魂：当前世实际行动、成长、承受后果的角色实例。
```

判断标准：

- 必须永久跨世存在 → 真灵。
- 只用于下一世初始化选择 → 执念。
- 只在当前生命中存在并承担行动后果 → 身躯与灵魂。

## 2. 真灵

### 2.1 定位

真灵提供长期身份感、执念容量、正式后手容量和轮回履历。真灵不是数值外挂，不应直接稳定提高每世修炼效率。

### 2.2 最小数据

```
TrueSpirit {
  spirit_id: String,
  true_name: String,
  spirit_strength: int,
  true_name_visibility: String,  # hidden / declared / exposed
  incarnation_count: int,
  highest_stage_reached: String,
  dao_rhyme_tags: Array,
  obsession_capacity: int,
  formal_contingency_slots: int,
  reincarnation_ledger_refs: Array
}
```

### 2.3 真名可见性

```
hidden：默认隐藏，只有玩家自己可见。
declared：玩家主动归本溯源，宣告真名。
exposed：因重大事件、突破、旧怨、后手争夺等被动暴露。
```

真名暴露会带来优势与风险：

- 优势：可调用真名层面的深层力量或高阶事件入口。
- 风险：更容易被高阶存在、旧怨、其他玩家、后手争夺链识别。

## 3. 执念

### 3.1 定位

执念是下一世初始化遗留包，不等于完整前世记忆或完整人格继承。

执念可携带：

- 天赋标签。
- 出生背景倾向。
- 少量开局资源或线索。
- 特殊开局条件。
- 某些前世失败标签的修正方向。

### 3.2 容量规则

已定口径：执念容量采用权重制。

```
ObsessionLoadout {
  spirit_id: String,
  capacity_limit: int,
  selected_entries: Array,
  used_weight: int
}
```

玩家选择的遗留总权重不得超过容量上限。

## 4. 当世角色

### 4.1 最小数据

```
Incarnation {
  character_id: String,
  spirit_id: String,
  current_name: String,
  age: int,
  lifespan_limit: int,
  sex_or_body_template: String,
  current_stage_code: String,
  cultivation_progress: float,
  bottleneck_state: String,
  base_attributes: Dictionary,
  aptitude_profile: Dictionary,
  derived_bars: Dictionary,
  talent_tags: Array,
  special_traits: Array,
  current_location: String,
  known_info_refs: Array,
  inventory_refs: Array,
  sect_identity: Dictionary,
  social_relations: Array,
  injuries_and_conditions: Array,
  death_state: String
}
```

当世角色保存本世实际发生的一切，但默认不跨世继承。

## 5. 属性与状态条

### 5.1 基础属性

| 显示名 | 内部字段 | 作用 |
| --- | --- | --- |
| 体魄 | `base_physique` | 生机上限、负伤承受、肉身类突破准备 |
| 精力 | `base_vigor` | 元气底子、持续行动承受、疲劳恢复 |

基础属性只保留当世身躯 / 状态底子的基础字段，不包含可评级资质子项。

### 5.2 资质子项

“资质”不是独立系统，不设置总资质等级参与核心判定。

可评级子项：

- 根骨：`aptitude_bone`，身体承载、修炼基础、部分突破准备。
- 悟性：`aptitude_comprehension`，功法理解、配方学习、技艺成长。
- 灵根：`aptitude_root`，灵气亲和、路线适配、功法门槛。

`base_comprehension` 弃用，开发实现不得将“悟性”放入 `BaseAttributes` 或使用 `base_` 前缀表达。

根骨、悟性允许后天改善；灵根在 MVP 中不支持后天修改。

### 5.3 派生状态条

| 显示名 | 内部字段 | 含义 |
| --- | --- | --- |
| 生机 | `bar_vitality` | 健康、伤病、肉身完整度 |
| 元气 | `bar_qi` | 法力 / 气力 / 可支配能量 |
| 神念 | `bar_mind` | 神识、心神、灵魂稳定 |

生机、元气、神念是持久状态，不是战斗内临时资源。战斗结束后不自动回满。

## 6. 修为状态

```
CultivationState {
  current_stage_code: String,       # A-1 / A-2 / B-1
  cultivation_progress: float,
  cultivation_purity: float,
  purity_visibility_state: String,  # hidden / visible_at_major_bottleneck
  bottleneck_state: String,         # none / soft_cap / breakthrough_required
  main_dao_method_ref: String,
  major_method_record_refs: Dictionary,
  progress_cap_context: Dictionary
}
```

### 6.1 修为纯度

- 数据层保留。
- 平时默认隐藏。
- 到达大阶段瓶颈、进入突破准备语境后显示。
- 显示时必须提示提纯 / 巩固路径。

## 7. 道功与法门

### 7.1 道功

道功是可推动修为增长的功法，可设为主修。

```
DaoMethod {
  method_id: String,
  tier_code: String,
  quality_code: String,
  method_tags: Array,
  stage_support_range: Array,
  level_cap_profile: Dictionary,
  absorption_profile: Dictionary,
  conversion_profile: Dictionary,
  passive_effect_refs: Array,
  breakthrough_support_profile: Dictionary,
  compatibility_requirements: Dictionary
}
```

### 7.2 法门

法门不直接推动修为进度。它提供：

- 战斗指令。
- 非战斗能力。
- 采集、炼丹、炼器、阵法、医术、卜算等技艺。
- 事件选项。
- 资源获取效率修正。

### 7.3 主修道功

规则：

- 同一时间只能有一个主修道功。
- 只有道功能被设为主修。
- 主修道功决定被动吸收、主动吐纳、丹药炼化、修为上限和突破模板匹配。
- 主修道功只允许在大境界第一小阶段内无行动格替换，例如 A-1 / B-1 / C-1。
- 离开第一小阶段后，本大境界主修路线锁定。
- 每个大境界记录最终主修道功，用于突破模板、奖励结构和失败标签池。

## 8. 修炼收益来源

### 8.1 自动运转

自动运转用于表现修士日常吐纳，但不能替代主动修炼行动。

规则：

- 按 tick 结算。
- 主动吐纳期间不额外生效。
- 突破、昏迷、重伤、封印等状态下不生效。
- 合法状态下可提供少量被动修为收益。
- 可触发小境界升级。
- 不可跨越大境界瓶颈。
- 不自动消耗高价值丹药或突破资源。

### 8.2 主动吐纳

主动吐纳是核心修为增长持续行动。

读取：

- 行动格投入。
- 当前节点灵气。
- 主修道功吸收速度。
- 主修道功转化效率。
- 角色资质。
- 当前状态和伤势。
- 修为阶段与瓶颈。
- 丹药、灵液、宗门配给、洞府、聚灵阵等修炼资源。

输出：

- 修为进度。
- 主修道功经验。
- 可能的纯度变化。
- 使用资源日志。

### 8.3 研习功法

研习功法消耗行动格，只增加目标功法经验，不直接增加修为。

取舍：

```
吐纳：修为 + 主修道功经验
研习：目标功法经验更高，但没有修为收益
```

### 8.4 丹药与修炼资源

丹药、灵液、灵米、修炼配给等不直接加修为数字，而是生成可转化的输入包。

MVP 不引入丹毒 / 杂质累计系统。不适配主要表现为：

- 转化率低。
- 药力浪费。
- 短期疲劳。
- 短期经脉压力。
- 短期心神扰动。

## 9. 小境界与大境界

### 9.1 小境界升级

小境界升级不是高风险核心玩法。

条件：

```
当前小境界进度达到上限
+ 主修道功等级支持下一小境界
+ 主修道功支持范围覆盖下一小境界
+ 角色不处于禁止升级状态
→ 自动或常规升级到下一小境界
```

小境界不进入突破事件链，不消耗关键突破物，不触发死亡 / 转世风险。

### 9.2 大境界突破

大境界突破是核心玩法节点。

条件：

```
大境界瓶颈成立
+ 主修道功支持目标大境界
+ 主修道功等级达到门槛
+ 至少一个合法关键突破物可用
+ 当前状态允许突破
→ 玩家可选择大境界突破持续行动
```

大境界突破必须由玩家主动发起，自动运转和托管不得主动执行高风险突破。

## 10. 寿元

寿元是当前世角色的最大时间预算，不只是死亡倒计时。

```
LifespanState {
  age: int,
  lifespan_limit: int,
  aging_phase: String,
  lifespan_pressure_state: String,  # safe / pressured / urgent / exhausted
  lifespan_extension_sources: Array,
  lifespan_risk_tags: Array
}
```

MVP 至少支持：

1. 突破延寿。
2. 资源延寿接口。
3. 损耗折寿接口。

寿元压力应显式提示，避免玩家无感知突然死亡。

## 11. 死亡与转世

死亡触发来源：

- 战斗死战。
- 突破严重失败。
- 寿元耗尽。
- 重大事件链。
- 特殊因果或神魂失败。

死亡后流程：

```
死亡事件链
→ 结算当世随身资产和状态
→ 处理普通遗产和正式后手
→ 写入轮回账本
→ 生成失败 / 死亡原因标签
→ 进入转世初始化
→ 玩家用执念容量选择下一世遗留
```

## 12. 轮回账本

轮回账本记录：

- 前世数量。
- 最高境界。
- 重大突破。
- 突破失败原因。
- 死亡原因。
- 正式后手记录。
- 重要地点感应。
- 重要宗门 / NPC / 事件线索。

轮回账本不是完整前世记忆回放，而是跨世优化工具。

## 13. MVP 验收清单

- 可以创建真灵。
- 可以生成初次当世角色。
- 角色有基础属性、资质子项和三条状态条。
- 角色可拥有当前阶段与修为进度。
- 可设置主修道功。
- 自动运转可按 tick 提供少量收益。
- 主动吐纳可消耗行动格并增加修为。
- 小境界可在合法条件下升级。
- 大境界突破不会自动触发，必须玩家主动发起。
- 死亡后可写入账本并转世。
- 执念容量以权重制选择下一世遗留。