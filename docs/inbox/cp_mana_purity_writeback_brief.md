# 修炼系统 CP / 法力 / 纯度 / 巩固修为回写指导备忘录

生成日期：2026-05-21  
用途：汇总本次对话中的最新裁决，供后续 agent 将结论回写到 `xiuxian_design_docs` 正式设计文档包。  
状态：**未回写 Notion / 未修改正式文档**。本文件只作为回写指导与冲突清理依据。

---

## 0. 本轮最高优先级裁决

本轮用户明确裁决优先于既有文档口径。后续回写时，应以本文件为准同步修订相关正式文档，并清理旧口径中可能导致误解的表述。

一句话定稿：

```text
CP 概念不变：CP 是外部灵气输入经道功转化后的标准修为点，用于管理境界进展。
法力是玩家直观感知的修为强弱：法力 = CP × 纯度 × 道功放大系数。
纯度是 (0, 1] 的惩罚系数；道功放大系数才是单位 CP 强度。
巩固修为不推进主 CP，只填充当前大境界的巩固 CP 条，用于提高当前大境界纯度。
```

---

## 1. 核心概念定稿

### 1.1 CP：标准修为点

`CP` 概念保持不变。

CP 的主要作用：

1. 将外部灵气输入转化为一个标准化绝对值概念。
2. 管理玩家角色当前境界、小阶段、瓶颈和突破开启门槛。
3. 作为境界进度、日志、数值阈值和系统结算基础。
4. 不再直接等同于战斗出力或玩家感知的“修为强弱”。

建议文档用语：

```text
CP / cultivation_points = 标准修为点 / 修为绝对值进度。
```

### 1.2 外部灵气输入

外部灵气输入分为两类：

```text
环境灵气输入：节点灵气、灵脉、洞府、聚灵阵、宗门设施等。
消耗品资源输入：丹药、灵材、灵液、符箓、宗门配给等。
```

两类输入进入 CP 的方式不同：

1. **环境灵气输入**先受道功吸收灵气上限限制，再按道功转化率转为 CP。
2. **丹药等消耗品输入**主要受药性容量、体魄承载、服用规则和资源释放时长限制，最终同样按道功转化率转为 CP。
3. 节点灵气浓度带来的资源输入也要看道功转化率。

### 1.3 道功吸收上限

道功吸收灵气上限是道功强弱的重要正向指标。

```text
吸收上限越高，说明道功单位时间内可承接的环境灵气越多，道功越强。
```

吸收上限主要用于环境灵气流，不宜和丹药药性流混为同一个限制。

建议字段：

```yaml
aura_absorption_cap_per_hour: number
```

### 1.4 道功转化率

道功转化率表示“已承接灵气转化为 CP 的速度”。

```text
转化率高 = CP 获取速度快。
转化率低 = CP 获取速度慢。
转化率低不等于道功弱。
```

同品级道功中，转化率低的道功通常应拥有更高的道功放大系数，使其单位 CP 的实际法力更强。

建议字段：

```yaml
cp_conversion_rate: number
```

### 1.5 法力

法力是玩家最直观感知的修为强弱概念。

正式公式：

```text
法力 = CP × 纯度 × 道功放大系数
```

按大境界记录时：

```text
major_realm_mana =
  major_realm_cp
  × major_realm_purity
  × dao_method_mana_amplifier
```

角色总法力：

```text
total_mana = Σ major_realm_mana
```

如果未来 CP 不再是跨境界绝对值，而变成每个大境界内部局部值，则需要额外引入境界权重：

```text
total_mana = Σ(cp_i × realm_weight_i × purity_i × amplifier_i)
```

当前建议暂不引入 `realm_weight_i`，保持 CP 作为绝对值。

### 1.6 纯度

纯度是 CP 转化为法力时的惩罚系数。

```text
纯度范围：(0, 1]
纯度越低，说明修为越虚浮。
纯度越高，说明修为越凝实。
纯度不超过 1。
```

纯度不是道功真正强度，**纯度是惩罚项**。  
道功真正的单位 CP 强度由“道功放大系数”表达。

### 1.7 道功放大系数

道功放大系数是道功真正强度的体现。

```text
道功放大系数越高，单位 CP 对应的法力越高。
同品级道功中，转化率低的道功通常放大系数更高。
```

建议字段：

```yaml
mana_amplifier: number
```

### 1.8 每个大境界记录一次纯度

由于当前设计中主修道功通常只在大境界第一小阶段可切换，进入第二小阶段后本大境界主修道功锁定，因此每个大境界天然可以对应一条主修道功记录。

本轮裁决：

```text
纯度和主修道功一样，每个大境界记录一次。
当前大境界的纯度只对应当前大境界的 CP 和法力。
进入下一大境界后，上一大境界记录锁定。
普通巩固修为不能再修改上一大境界纯度。
```

例外预留：稀有事件、特殊消耗品、高阶法门或剧情资源未来可以允许修改历史大境界纯度，但不进入 MVP 默认规则。

---

## 2. 道功数值结构建议

建议为道功增加或明确以下修炼数值字段：

```yaml
DaoMethodCultivationProfile:
  method_id: string

  # 灵气输入与 CP 生成
  aura_absorption_cap_per_hour: number
  cp_conversion_rate: number

  # 法力密度
  mana_amplifier: number

  # 纯度区间
  purity_floor: number
  purity_ceiling: number

  # 巩固修为
  consolidation_cost_factor: number
  consolidation_action_efficiency: number

  # 体验标签，供 UI / 调参 / 投放使用
  cultivation_speed_tag: fast | balanced | slow
  mana_density_tag: loose | balanced | condensed
```

示例方向：

| 道功类型 | CP 转化率 | 法力放大系数 | 默认纯度 | 最高纯度 | 体验定位 |
|---|---:|---:|---:|---:|---|
| 速成道功 | 高 | 低或中 | 0.60 | 0.85 | 境界推进快，但修为虚浮 |
| 均衡道功 | 中 | 中 | 0.75 | 0.92 | 速度、法力、巩固成本均衡 |
| 凝实道功 | 低 | 高 | 0.95 | 1.00 | 修得慢，但单位 CP 法力强 |

重点：

```text
转化率 = 修炼速度。
放大系数 = 单位 CP 强度。
纯度 = 虚浮惩罚。
```

---

## 3. 修炼公式建议

### 3.1 环境灵气流

```text
environment_aura_intake =
  min(
    node_aura_available,
    dao_method_absorption_cap_per_hour × compatible_hours
  )
```

### 3.2 丹药 / 消耗品灵气流

```text
medicine_aura_intake =
  min(
    active_medicine_aura_release,
    medicine_capacity_remaining
  )
```

### 3.3 合流后的 CP 增长

```text
raw_aura_input =
  environment_aura_intake
  + medicine_aura_intake

cp_gain =
  raw_aura_input
  × dao_method_cp_conversion_rate
  × action_efficiency_factor
```

### 3.4 当前大境界法力

```text
major_realm_mana =
  major_realm_cp
  × current_purity
  × mana_amplifier
```

### 3.5 角色总法力

```text
total_mana =
  Σ major_realm_mana
```

---

## 4. 巩固修为定稿

### 4.1 巩固修为的定位

巩固修为不是惩罚流程，而是一个让玩家主动提高法力密度的修炼选择。

本轮裁决：

```text
巩固修为不增加主 CP。
巩固修为不推进境界进度。
巩固修为不增加功法研习度。
巩固修为只修改当前大境界纯度。
巩固修为通过提高纯度来提高当前大境界法力。
```

### 4.2 巩固 CP 条

巩固修为可以理解为“额外 CP 条”。

```text
主 CP 条：推进境界。
巩固 CP 条：不推进境界，只提高当前大境界纯度。
```

当主 CP 条达到一定节点，默认可以根据当前大境界 CP、默认纯度和最高纯度生成巩固 CP 条。

MVP 建议：

```text
主进度达到当前大境界 / 当前阶段要求后，显性提示巩固 CP 条。
未来可以允许中途巩固，但不作为 MVP 必须项。
```

### 4.3 巩固需求计算

```text
purity_gap = purity_ceiling - purity_floor

consolidation_required =
  cp_total_in_current_major_realm
  × purity_gap
  × consolidation_cost_factor
```

如果希望最小化字段，也可以先令：

```text
consolidation_cost_factor = 1
```

### 4.4 巩固填充

巩固修为仍然基于外部输入和道功转化率结算，但写入巩固 CP 条，而不是主 CP 条。

```text
consolidation_gain =
  raw_aura_input
  × dao_method_cp_conversion_rate
  × consolidation_action_efficiency
```

更新：

```text
consolidation_filled =
  min(
    consolidation_filled + consolidation_gain,
    consolidation_required
  )
```

### 4.5 纯度更新

```text
current_purity =
  purity_floor
  + (purity_ceiling - purity_floor)
    × (consolidation_filled / consolidation_required)
```

当 `consolidation_filled == consolidation_required` 时：

```text
current_purity = purity_ceiling
```

### 4.6 不可追回的巩固损失

本轮裁决：

```text
普通巩固修为只能修改当前大境界纯度。
一旦进入下一大境界，上一大境界的纯度和法力记录锁定。
缺少巩固修为导致的上一大境界法力损失，不能通过未来普通巩固修为弥补。
```

可预留例外：

```text
稀有事件；
特殊消耗品；
高阶道功 / 法门；
剧情后手；
宗门秘法。
```

这些例外需要单独模板，不进入普通修炼循环。

---

## 5. 大境界记录结构建议

建议新增或调整角色修为记录结构：

```yaml
MajorRealmCultivationRecord:
  character_id: string
  major_realm_id: string

  # 本大境界主修道功
  main_dao_method_id: string
  main_dao_method_state_id: string

  # 本大境界 CP
  cp_total_in_realm: number

  # 本大境界道功快照
  cp_conversion_rate_snapshot: number
  mana_amplifier_snapshot: number
  purity_floor_snapshot: number
  purity_ceiling_snapshot: number

  # 巩固修为
  consolidation_required: number
  consolidation_filled: number
  current_purity: number

  # 法力结果
  mana_value: number

  # 锁定状态
  locked: bool
  locked_at_stage: string | null
  locked_world_day: number | null
  locked_world_hour: number | null
```

说明：

1. 道功相关数值建议在大境界记录中保存快照，避免后续道功模板调参或角色换功导致历史法力被回溯改写。
2. `mana_value` 可以实时由公式派生，也可以保存缓存值；若保存缓存值，必须保证与 `cp_total_in_realm × current_purity × mana_amplifier_snapshot` 一致。
3. `locked = true` 后，普通巩固修为不再修改该记录。

---

## 6. 功法研习度边界

本轮继续确认：功法研习度不影响最终法力、属性或既往修炼质量。

功法研习度可以影响：

1. 是否学会道功。
2. 当前可修上限。
3. 修炼行动效率。
4. 达到同一 CP 所需总时间。
5. 路线提示、可见信息、稳定操作、部分解锁项。

功法研习度不影响：

1. CP 到法力的纯度系数。
2. 道功放大系数。
3. 已获得 CP 的法力密度。
4. 小阶段奖励质量。
5. 大境界突破后的属性质量。
6. 既往修炼结果。

设计目标：

```text
先研习后修炼、先修炼后研习，不应导致最终战斗力、法力、属性出现不可追回差异。
研习度只影响达到同一结果所需时间和过程效率。
```

---

## 7. 经脉压力边界

本轮裁决：经脉压力暂时收窄，不参与复杂复用。

经脉压力用于：

1. 体魄考验。
2. 药性容量。
3. 丹药 / 外源资源过载风险。

经脉压力暂时不用于：

1. 修为纯度计算。
2. 法力公式。
3. 根基系统。
4. 心境稳定。
5. 普通战斗出力。
6. 复杂突破质量链。

建议边界：

```text
纯度负责“修为是否凝实”。
经脉压力负责“身体能否承受药性和外源输入”。
```

建议字段：

```yaml
medicine_load_current: number
medicine_load_capacity: number
physique_pressure_check: number
```

---

## 8. 战斗与突破 MVP 口径

### 8.1 战斗

战斗出力主要看法力，不直接看 CP。

建议方向：

```text
combat_power =
  base_attribute_score
  × realm_multiplier
  × minor_stage_multiplier
  × mana_factor
  × state_factor
  + equipment_spell_bonus
```

其中：

```text
mana_factor 来自 total_mana 或当前大境界 mana_value。
```

### 8.2 境界推进

境界推进主要看 CP。

```text
current_cp >= required_cp
→ 可以进入下一小阶段，或达到大境界突破门槛。
```

### 8.3 突破 MVP

突破玩法先按最小可用原则简化，不引入过多根基、心境、心魔、复杂纯度惩罚链。

MVP 开启条件建议：

```text
can_start_breakthrough =
  current_realm_cp >= required_cp
  and main_dao_method_supports_next_realm
  and required_breakthrough_resource_available
  and location_allows_breakthrough
```

突破质量或风险可以先由法力表达：

```text
breakthrough_quality_score =
  current_mana / recommended_mana_for_breakthrough
```

或：

```text
breakthrough_quality_score =
  current_purity_adjusted_mana / recommended_mana_for_breakthrough
```

玩家表达：

```text
修为进度够了，可以尝试突破。
但法力偏虚，突破质量较差；建议巩固修为。
```

---

## 9. 主修道功切换：当前状态与未来建议

当前用户裁决：主修道功切换套利问题可以后续解决。暂定方案可先按切换前后道功转化率比值折算已有 CP。

但在本轮新公式下，未来正式折算更建议参考“单位 CP 法力密度”，而不只看转化率。

### 9.1 需要满足的原则

```text
切换主修道功不能凭空增加法力。
切换主修道功不能凭空增加境界 CP。
旧道功已经沉淀出的法力不应按新道功回溯重算。
```

### 9.2 未来建议折算公式

```text
old_effective_density =
  old_purity × old_mana_amplifier

new_effective_density =
  new_default_purity × new_mana_amplifier

new_cp =
  old_cp
  × old_effective_density
  / new_effective_density
  × switch_loss_factor
```

保护：

```text
new_cp = min(new_cp, old_cp)
```

这样：

1. 切到更凝实、更高放大系数的道功时，CP 会折损。
2. 切到更虚浮的速成功法时，CP 不会凭空增加。
3. 法力不凭空上升。

### 9.3 当前回写建议

回写正式文档时不要把主修切换公式写死为定稿。建议标为：

```text
待裁决：主修道功切换时 CP 与法力折算公式。
当前临时方向：可按转化率比值折算 CP；正式版建议按单位 CP 法力密度折算，避免与“法力 = CP × 纯度 × 放大系数”冲突。
```

---

## 10. UI 表达建议

普通玩家界面建议显示：

1. 当前境界 / 小阶段。
2. 主 CP 进度条：用于境界推进。
3. 法力值：用于直观表达修为强弱。
4. 当前大境界纯度：例如 `72%`。
5. 巩固 CP 条：用于说明距离当前大境界纯度上限还有多少。
6. 主修道功摘要：吸收强、修炼快、法力凝实、速成虚浮等标签。

推荐文案：

```text
修为进度已达标，但法力偏虚。巩固修为可提高当前大境界纯度，从而提升法力。
```

```text
本大境界已进入下一阶段，上一大境界修为记录已锁定，普通巩固无法再补足历史纯度。
```

```text
该道功修炼速度较快，但默认纯度较低；建议在突破前巩固修为。
```

```text
该道功转化率较低，但法力放大系数较高，单位 CP 更凝实。
```

---

## 11. 需要同步修改的正式文档清单

以下为后续 agent 回写 `xiuxian_design_docs` 时的建议修改项。

### 11.1 `00_INDEX/修炼系统数值投放收敛裁决.md`

需要新增本轮裁决摘要：

1. CP 概念不变。
2. 法力新增为玩家感知的修为强弱值。
3. 法力公式：`法力 = CP × 纯度 × 道功放大系数`。
4. 纯度按大境界记录。
5. 巩固修为只修改当前大境界纯度。
6. 经脉压力收窄为体魄考验和药性容量。
7. 功法研习度不影响最终法力与历史修炼质量。

### 11.2 `03_数值设计/01_修为境界与期望游玩时间建模.md`

需要修改：

1. 明确 CP 仍是境界进度、阈值、标准修为点。
2. 明确 CP 不直接代表玩家感知强弱，战斗出力主要读取法力。
3. 保持 `cp_lower_bound / cp_upper_bound` 作为阶段阈值，不把法力混入境界进度。
4. 补充：每个大境界可形成独立 `MajorRealmCultivationRecord`。

### 11.3 `03_数值设计/02_修炼公式与数值设计.md`

需要重点修改：

1. 拆分环境灵气流和丹药 / 消耗品灵气流。
2. 环境灵气读取 `aura_absorption_cap_per_hour`。
3. 合流后按 `cp_conversion_rate` 生成 CP。
4. 增加法力公式。
5. 增加纯度、放大系数和巩固 CP 条公式。
6. 新增 `CultivationTickResult` 字段。
7. 新增 `ConsolidationTickResult` 字段。

建议字段：

```yaml
CultivationTickResult:
  cp_gain: number
  raw_aura_input: number
  environment_aura_intake: number
  medicine_aura_intake: number
  cp_conversion_rate_used: number
  major_realm_cp_before: number
  major_realm_cp_after: number
  purity_before: number
  purity_after: number
  mana_before: number
  mana_after: number
  mana_amplifier_used: number
```

```yaml
ConsolidationTickResult:
  consolidation_gain: number
  consolidation_filled_before: number
  consolidation_filled_after: number
  consolidation_required: number
  purity_before: number
  purity_after: number
  mana_before: number
  mana_after: number
```

### 11.4 `02_系统设计/11_修炼玩法设计.md`

需要修改：

1. 修炼行动获得 CP。
2. 巩固修为作为独立行动或修炼相关行动，不获得主 CP。
3. 巩固修为填充当前大境界巩固 CP 条。
4. 巩固修为只提高当前大境界纯度和法力。
5. 普通巩固不能修复历史大境界纯度。
6. 玩家反馈中新增“法力偏虚 / 建议巩固”的提示。

### 11.5 `02_系统设计/02_角色与真灵设计/03_角色修为与境界.md`

需要修改：

1. 在角色修为状态中新增法力和大境界修炼记录。
2. 说明境界推进看 CP，战斗出力看法力。
3. 说明每个大境界记录主修道功、CP、纯度、放大系数和法力。
4. 大境界记录进入下一大境界后锁定。
5. 普通巩固修为只能修改当前大境界记录。

### 11.6 `02_系统设计/04_功法设计/01_道功.md`

需要修改：

1. 道功新增吸收上限、CP 转化率、法力放大系数、纯度区间。
2. 明确转化率高低只代表修炼速度，不直接代表强弱。
3. 明确同品级低转化率道功可拥有更高法力放大系数。
4. 明确速成功法默认纯度低、纯度上限也较低。
5. 明确凝实功法默认纯度高、法力放大系数高、修炼速度慢。

### 11.7 `03_数值设计/05_功法设计基准建模.md`

需要修改：

1. `DaoMethodNumericProfile` 中增加本轮字段。
2. 新增公式：`法力 = CP × 纯度 × mana_amplifier`。
3. 拆分 `cp_conversion_rate` 与 `mana_amplifier` 的职责。
4. 明确功法研习度不影响最终法力和历史纯度。
5. 增加巩固修为相关配置。

### 11.8 `02_系统设计/02_角色与真灵设计/04_角色主修功法.md`

需要修改：

1. 大境界主修道功锁定记录需要附带本大境界 CP、纯度、放大系数、法力快照。
2. 主修道功切换折算标为待裁决。
3. 暂定方案可记录“转化率比值折算 CP”。
4. 正式建议补充“按单位 CP 法力密度折算，避免套利”。

### 11.9 `03_数值设计/03_战斗公式与数值设计.md`

需要修改：

1. 战斗表现主要读取法力，而不是直接读取 CP。
2. 增加 `mana_factor` 或 `total_mana_factor`。
3. 保持生机、元气、神念作为战斗条，但法力作为修为出力基础。
4. 不把纯度、根基、心境等全部塞进战斗公式，MVP 先保持简化。

### 11.10 `02_系统设计/14_突破玩法设计.md`

需要修改：

1. 大境界突破开启门槛仍看 CP。
2. 突破质量 / 风险可先看法力或法力相对推荐值。
3. 不急于引入根基、心境、心魔等复杂质量维度。
4. “修为进度够但法力虚”应成为突破前提示。
5. 稀有事件或特殊资源可作为未来补救历史纯度的例外入口，但不进 MVP。

### 11.11 `02_系统设计/05_物品设计/02_丹药.md`

需要修改：

1. 丹药资源输入最终也按道功转化率转为 CP。
2. 丹药等消耗品主要受药性容量、体魄承载、服用规则、释放时长约束。
3. 经脉压力 / 药性容量与纯度职责分离。
4. 丹药不直接即时涨法力；需进入修炼 / 巩固 / 模板声明的合法流程。

### 11.12 `02_系统设计/02_角色与真灵设计/07_角色持续状态系统.md`

需要修改：

1. 经脉压力边界收窄。
2. 药性容量字段与体魄考验字段明确。
3. 不再让经脉压力默认参与纯度、法力、心境、复杂突破质量链。

### 11.13 `04_交互设计/04_修为页面设计.md`

需要修改：

1. 新增法力显示。
2. 新增纯度显示。
3. 新增巩固 CP 条显示。
4. 新增“修为进度已满但法力偏虚”的提示状态。
5. 新增当前大境界记录锁定提示。

### 11.14 `04_交互设计/05_功法页面设计.md`

需要修改：

1. 道功详情展示吸收上限、转化率、法力放大系数、纯度区间。
2. 用体验标签解释：速成、均衡、凝实。
3. 避免直接暴露过多 Debug 公式，普通 UI 用描述和摘要。

### 11.15 `03_数值设计/08_数值验算.md`

需要新增验算用例：

1. 同 CP 下，速成功法与凝实功法的法力差异。
2. 同资源输入下，高转化率道功更快获得 CP。
3. 巩固修为只提高法力，不推进境界。
4. 当前大境界未巩固进入下一大境界后，普通巩固不能补救历史损失。
5. 主修道功切换不能凭空增加 CP 或法力。
6. 功法研习度先后顺序不影响最终法力。
7. 经脉压力只影响药性容量和体魄承载，不影响纯度公式。

---

## 12. 旧口径清理清单

回写时需要避免或清理以下旧表述：

1. 不要把 CP 直接写成战斗力。
2. 不要把转化率写成道功绝对强弱。
3. 不要把纯度写成超过 1 的正向倍率。
4. 不要让功法研习度影响最终法力、历史纯度或历史小阶段奖励。
5. 不要让巩固修为增加主 CP 或推进境界。
6. 不要让普通巩固修为修补上一大境界纯度。
7. 不要让经脉压力同时承担纯度、根基、心境、突破、战斗等多重职责。
8. 不要在 MVP 阶段引入过多根基、心境、心魔、复杂突破评分。
9. 不要让切换主修道功按新道功回溯重算法力。
10. 不要让丹药即时涨法力或绕过修炼 / 巩固流程。

---

## 13. 待裁决问题

以下项目本轮尚未完全定稿，回写时应标为待裁决或待补，不要静默写成定论。

1. 巩固 CP 条是否只能在当前阶段主 CP 满后显性开启，还是允许任意时点中途巩固。
2. `consolidation_cost_factor` 的默认值和不同道功差异。
3. 稀有事件 / 特殊消耗品修改历史大境界纯度的规则和代价。
4. 主修道功切换时的正式 CP / 法力折算公式。
5. 法力是否按 `Σ major_realm_mana` 直接求和，还是未来需要境界权重。
6. 战斗公式中 `mana_factor` 的具体曲线。
7. 突破质量中 `current_mana / recommended_mana` 的阈值表。
8. 不同品级道功的 `mana_amplifier` 数值范围。
9. 巩固修为是否消耗同类修炼资源，还是需要专门的凝实类资源。
10. UI 是否对普通玩家展示具体纯度百分比，还是用“虚浮 / 稳固 / 凝实”等包装词。

---

## 14. 推荐回写顺序

建议后续 agent 按以下顺序回写正式文档，降低冲突：

1. `00_INDEX/修炼系统数值投放收敛裁决.md`：先新增本轮裁决摘要。
2. `03_数值设计/02_修炼公式与数值设计.md`：先落公式和字段。
3. `03_数值设计/05_功法设计基准建模.md`：落道功数值模板。
4. `02_系统设计/04_功法设计/01_道功.md`：落系统定义与道功体验差异。
5. `02_系统设计/11_修炼玩法设计.md`：落巩固修为行动。
6. `02_系统设计/02_角色与真灵设计/03_角色修为与境界.md`：落大境界记录和法力。
7. `02_系统设计/02_角色与真灵设计/04_角色主修功法.md`：落主修锁定记录扩展与切换待裁决。
8. `03_数值设计/03_战斗公式与数值设计.md`：落法力参与战斗。
9. `02_系统设计/14_突破玩法设计.md`：落 MVP 简化突破读取。
10. `02_系统设计/05_物品设计/02_丹药.md` 与 `07_角色持续状态系统.md`：落药性容量和经脉压力边界。
11. UI 文档：最后统一补显示与提示。
12. `03_数值设计/08_数值验算.md`：补测试用例。

---

## 15. 示例验算

### 15.1 同 CP 下不同道功法力差异

假设当前大境界 CP 为 10,000。

速成道功：

```text
mana_amplifier = 1.00
purity_floor = 0.60
purity_ceiling = 0.85

未巩固法力 = 10,000 × 0.60 × 1.00 = 6,000
巩固满法力 = 10,000 × 0.85 × 1.00 = 8,500
```

凝实道功：

```text
mana_amplifier = 1.60
purity_floor = 0.95
purity_ceiling = 1.00

未巩固法力 = 10,000 × 0.95 × 1.60 = 15,200
巩固满法力 = 10,000 × 1.00 × 1.60 = 16,000
```

解释：

```text
速成道功更快获得 CP，但同 CP 下法力低。
凝实道功更慢获得 CP，但同 CP 下法力高。
速成道功巩固空间大，凝实道功巩固空间小。
```

### 15.2 巩固修为不推进境界

假设：

```text
cp_total = 10,000
purity_floor = 0.60
purity_ceiling = 0.85
consolidation_cost_factor = 1
```

则：

```text
consolidation_required =
  10,000 × (0.85 - 0.60) × 1
  = 2,500
```

巩固填充 1,250：

```text
current_purity =
  0.60 + (0.85 - 0.60) × (1,250 / 2,500)
  = 0.725
```

此时：

```text
主 CP 仍为 10,000
境界进度不变
纯度从 0.60 提高到 0.725
法力提高
```

---

## 16. 给未来 agent 的执行提醒

1. 不要直接修改 Notion，除非用户明确要求“写入 Notion / 更新 Notion 页面 / 回写到 Notion”。
2. 真正回写前应先读取目标页面现有结构。
3. 涉及删除、替换、大规模覆盖时，应先说明影响范围并等待确认。
4. 本文件是回写指导，不是正式文档包本身。
5. 回写时优先保留文档现有章节结构，只在对应章节内替换旧口径并新增字段。
6. 若发现旧文档仍有“CP 直接战斗力”“研习度影响最终法力”“巩固补历史纯度”等表述，应标记为冲突并修正。
