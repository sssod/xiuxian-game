# 突破玩法设计收敛结论与待修改项

版本：v0.1  
日期：2026-05-22  
适用范围：`xiuxian_design_docs` 中突破、修为境界、主修道功、功法数值、丹药、持续状态、事件与 UI 相关文档。

## 0. 本轮裁决摘要

本文件沉淀当前对“大境界突破玩法”的最新收敛口径。当前对话中的用户裁决优先于既有 Notion 文档；若旧文档与本文冲突，应以本文为准，并回写到正式文档。

一句话定稿：

> 大境界突破是由 CP 触发、由当前大境界锁定主修道功的突破模板定义难度和收益、由明确角色数值完成事件内验证、由结果包写入成功 / 失败 / 死亡与伤损后果的个人数值验证事件。前期突破不投放雷劫；金丹到元婴及之后的大境界突破可以把雷劫纳入突破事件内挑战；外扰与护法永远不作为突破事件内挑战。

核心收敛点：

1. **突破入口的角色数值门槛只看 CP。**
2. **突破难度和收益由道功突破模板决定。**
3. **事件内直接验证的数值只收敛为：法力、生机、元气、神念、体魄、精力、根骨、悟性。**
4. **心境、心魔、因果、执念等暂未形成明确数值与开发计划的模块，不作为 MVP 独立突破考验，先用神念、悟性、精力等明确数值包装表达。**
5. **伤势、经脉过载等不是直接考验项，而是持续状态 / debuff；它们通过修正上述明确属性间接影响突破事件。**
6. **突破结果不再区分完美突破、正常突破、残缺突破，也不再引入独立突破品质。**
7. **成功、失败、死亡是结果主类型；伤势、元气亏损、神念受创、经脉过载等作为结果包的一部分。**
8. **道功越强，对应突破模板越难，成功收益越高；这已经承担“突破品质”职责，避免道功阶级 / 品级与突破品质两套数值打架。**
9. **雷劫只从金丹到元婴及之后的大境界突破开始，作为突破事件内挑战；炼气到筑基、筑基到金丹等前期大境界突破不投放雷劫。**
10. **外扰 / 护法永远不进入突破事件内挑战。外敌干扰若存在，只能作为突破前或突破后的独立事件。**
11. **经脉压力不直接影响属性；体魄决定经脉压力上限，丹药、突破道具等提供灵气并占用经脉压力，超限后生成 debuff，debuff 再影响属性。**

---

## 1. 突破入口口径

### 1.1 入口只检查 CP 作为角色成长门槛

突破开启时，角色数值层面只检查当前大境界 CP 是否达到突破要求：

```plain text
can_attempt_breakthrough_by_growth =
  current_realm_cp >= required_breakthrough_cp
```

这条规则的含义是：

- 不在开启阶段检查法力。
- 不在开启阶段检查生机、元气、神念、体魄、精力、根骨、悟性。
- 不在开启阶段检查伤势、心境、心魔、因果等模块。
- 不因为当前角色数值偏弱而禁止玩家进入突破。
- 当前角色数值统一在突破事件内部进行验证。

### 1.2 道功模板合法性不是角色数值门槛

大境界突破仍然需要能找到合法的道功突破模板：

```plain text
locked_main_dao_method_record
→ breakthrough_template_ref
→ supported_transition
```

但这属于配置与路线合法性，不应包装成额外角色数值门槛。换言之：

- 当前大境界锁定主修道功决定突破模板。
- 玩家临近突破时不能临时换功规避难度。
- 道功模板缺失时是内容配置缺失或路线不支持，不是“角色属性不足”。

### 1.3 突破道具是事件输入，不是额外属性门槛

筑基丹等突破道具可以由突破模板声明为必需或可选输入。它们的职责不是额外判断角色是否“够格”，而是作为突破事件的资源输入参与结算。

筑基丹一类道具的规则口径：

```plain text
突破道具
= 提供大量辅助突破灵气
+ 占用经脉压力
+ 在突破事件中逐步被吸收或消散
+ 超出经脉压力上限时生成 debuff
```

如果某模板要求必须投入突破道具，则缺少道具时不能创建该模板实例；但这属于资源 / 模板合法性，不属于角色当前数值检查。

---

## 2. 道功突破模板职责

### 2.1 难度与收益均来自道功模板

突破难度不由角色当前属性动态生成，而由当前大境界锁定主修道功的突破模板定义。

道功突破模板至少负责：

```yaml
BreakthroughTemplate:
  template_id: string
  source_dao_method_id: string
  supported_transition: string
  difficulty_profile_ref: string
  reward_profile_ref: string
  stage_sequence: list[BreakthroughStageTemplate]
  required_or_optional_resource_slots: list[ResourceSlot]
  thunder_tribulation_policy: none | enabled_from_this_transition | enabled
  failure_tag_pool_ref: string
  result_report_template_ref: string
```

其中：

- `difficulty_profile_ref`：定义阶段阈值、损伤风险、死亡风险和失败标签池。
- `reward_profile_ref`：定义成功突破后的境界收益、道功路线收益、属性倾向、寿元 / 权限 / 行动入口等。
- `stage_sequence`：定义突破事件内需要经历哪些个人数值验证阶段。
- `thunder_tribulation_policy`：定义是否包含雷劫挑战；仅金丹到元婴及以后可启用。

### 2.2 不再设置独立突破品质

删除独立的突破品质字段与结算：

```plain text
删除：breakthrough_quality
删除：perfect / normal / incomplete breakthrough quality tier
删除：突破品质 S/A/B/C
删除：按突破过程再生成一套永久收益品质
```

理由：

```plain text
道功阶级 / 品级 / 模板强度
已经决定突破难度与成功收益。

如果再引入突破品质，玩家需要同时理解：
1. 道功本身强弱；
2. 本次突破品质强弱。

两套系统容易互相打架，造成困惑。
```

新的收益关系：

```plain text
突破成功收益
= 境界基础收益
+ 道功突破模板收益
```

突破过程中的损伤只影响角色当前状态，不降低本次突破的永久品质。

---

## 3. 突破事件内验证因素

### 3.1 可直接考验的数值白名单

突破事件内可以直接考验的角色数值只包括以下 8 类：

```plain text
法力
生机
元气
神念
体魄
精力
根骨
悟性
```

任何突破阶段都应落到这 8 类数值中的一项或多项。其他概念只能通过文本包装、状态修正或未来扩展进入。

### 3.2 直接考验项说明

| 数值 | 可承载的突破语义 | 常见阶段包装 |
|---|---|---|
| 法力 | 破境冲击、灵力调度、道功输出 | 灵力冲关、破境推演、关隘攻伐 |
| 生机 | 承受反噬、维持生命、濒死边界 | 生机护持、反噬承受、濒死拉回 |
| 元气 | 气机循环、内耗续航、稳定突破态势 | 气机维稳、元气续航、强行调息 |
| 神念 | 识海稳定、心神抗压、心魔叙事包装 | 神念守关、识海定境、心魔幻象 |
| 体魄 | 肉身承载、经脉承压、雷劫承受 | 肉身承载、经脉震荡、雷劫硬抗 |
| 精力 | 长时间维持、连续阶段消耗、疲劳抗性 | 精力续航、久战维持、持续入定 |
| 根骨 | 承道资质、身体底盘、境界容纳 | 根骨承道、道基成形、灵根承载 |
| 悟性 | 理解新境界、道意成形、路线领悟 | 悟道成形、道意归一、破关理解 |

### 3.3 不直接作为考验项的因素

| 因素 | 处理口径 |
|---|---|
| 伤势 | debuff，折算为上述属性修正 |
| 经脉压力 | 资源 / 药性 / 突破道具占用系统；本身不直接影响属性，超限后生成 debuff |
| 心境 | MVP 不独立设计，用神念、悟性、精力等明确数值包装表达 |
| 心魔 | MVP 不独立设计，用神念 / 悟性阶段叙事包装 |
| 因果 | 暂不作为突破事件内直接数值 |
| 执念 | 暂不作为突破事件内直接数值 |
| 前世阴影 | 可作为文本、日志或未来扩展标签，不直接进入 MVP 结算 |
| 外敌干扰 | 永远不作为突破事件内挑战 |
| 护法 | 永远不作为突破事件内挑战 |
| 雷劫 | 金丹到元婴及以后可作为突破事件内挑战；前期不投放 |

---

## 4. 雷劫、外扰与护法的边界

### 4.1 雷劫投放边界

雷劫是后期大境界突破挑战的一部分，但不是前期突破压力来源。

投放规则：

```plain text
炼气 → 筑基：不投放雷劫
筑基 → 金丹：不投放雷劫
金丹 → 元婴：开始允许投放雷劫
元婴 → 化神：允许投放雷劫
化神 → 炼虚及之后：允许投放雷劫或更高阶劫数变体
```

雷劫进入突破事件内挑战时，仍然必须遵守“个人数值验证”的原则。雷劫不是外敌，也不是世界随机怪物攻击，而是境界突破本身的劫数验证。

可考验数值示例：

| 雷劫阶段 | 主考数值 | 辅考数值 | 说明 |
|---|---|---|---|
| 天雷临身 | 体魄 | 生机、元气 | 承受雷劫对肉身与生命的冲击 |
| 雷火炼神 | 神念 | 精力、悟性 | 承受雷劫对识海、心神、道意的淬炼 |
| 劫力贯体 | 法力 | 体魄、元气 | 以法力与气机调度化解劫力 |
| 劫后成形 | 悟性 | 根骨、神念 | 将劫数压力转化为新境界成形 |

### 4.2 外扰永远不加入突破事件内挑战

外扰包括但不限于：

```plain text
外敌袭击
敌对宗门干扰
妖兽闯入
秘境暴动中的敌对实体
行踪暴露导致的追杀
NPC 破坏阵法
玩家直接冲突
```

这些内容不进入突破事件的阶段挑战，不生成“突破中途被打断”的内部阶段。

如果需要表达外扰，只能在突破事件前或突破事件后独立触发：

```plain text
突破前：
  地点暴露、敌人追踪、是否能安全闭关、是否延后突破、是否换地点。

突破后：
  刚突破后状态虚弱被人发现、宗门传闻扩散、敌对势力行动、资源点争夺。
```

这些是独立事件链，不属于突破事件内挑战。

### 4.3 护法永远不加入突破事件内挑战

护法不作为突破阶段，不作为突破内应对项，也不作为“抵挡外扰”的轮内选择。

护法可以存在于世界与叙事层，但不能进入突破事件内挑战：

```plain text
允许：
- 突破前安排护法，降低突破前地点暴露或被袭击概率。
- 突破后护法协助封锁消息、接应、疗伤或处理余波。
- 宗门层面记录某次突破有长老护持，作为传闻或身份表达。

禁止：
- 突破阶段中出现“护法抵御外敌”。
- 护法作为阶段内资源格直接修改突破数值检定。
- 外敌入侵作为突破阶段挑战，然后用护法抵消。
```

---

## 5. 经脉压力系统口径

### 5.1 经脉压力不是直接属性修正

经脉压力本身不直接影响法力、生机、元气、神念、体魄、精力、根骨、悟性。

正确链路是：

```plain text
体魄
→ 经脉压力上限
→ 丹药 / 灵材 / 突破道具占用经脉压力
→ 超限时生成经脉过载 debuff
→ debuff 修正角色属性
→ 属性参与突破事件内验证
```

禁止链路：

```plain text
经脉压力
→ 直接降低属性

经脉压力
→ 直接作为突破阶段考验项
```

### 5.2 体魄决定经脉压力上限

体魄越高，角色能承载的经脉压力上限越高。

建议公式方向：

```plain text
meridian_pressure_cap =
  base_cap_by_realm
  + physique_to_meridian_cap(physique)
  + allowed_state_or_method_bonus
```

当前设计重点：

- 体魄强的角色拥有更高经脉压力空间。
- 体魄弱的角色在使用大剂量丹药、灵液、筑基丹等突破道具时更容易超限。
- 经脉压力上限不是突破阶段直接考验，但会影响资源准备与过载风险。

### 5.3 丹药与突破道具占用持续经脉压力

丹药、灵液、灵材、突破道具等提供灵气输入时，会生成持续经脉压力。

```yaml
InternalAuraPressureState:
  source_instance_id: string
  source_type: medicine | breakthrough_item | spirit_liquid | spirit_material | formation_infusion | other
  aura_payload_total: number
  aura_payload_remaining: number
  meridian_pressure_value: number
  release_mode: absorbed_over_time | breakthrough_stage_consumed | dissipating
  started_world_time: string
  expected_end_world_time: string | null
```

持续经脉压力会在以下情况下下降：

```plain text
灵力被吸收
灵力自然消散
道具效果结束
突破阶段消耗了对应灵气负载
特殊状态或治疗移除
```

### 5.4 突破道具占用大量经脉压力

筑基丹等开启突破的道具，本质上是提供大量灵气辅助突破，因此应占用大量经脉压力。

示例：

```plain text
筑基丹：
  提供大量筑基辅助灵气
  占用较高经脉压力
  在突破事件中逐步释放 / 吸收
  超出经脉压力上限时触发经脉过载 debuff
```

这会形成有意义的准备玩法：

```plain text
体魄强：
  经脉压力上限足够
  可以带着少量药性残余或直接承接突破道具
  经脉压力不影响突破表现

体魄弱：
  经脉压力上限较低
  需要先消化已有药性，腾出经脉压力空间
  若强行使用突破道具超限，会获得经脉过载 debuff
  debuff 影响属性，进而影响突破事件验证
```

### 5.5 经脉过载 debuff

当当前经脉压力与新增压力超过上限时，不是直接改属性，而是生成持续状态：

```plain text
if current_meridian_pressure + incoming_meridian_pressure > meridian_pressure_cap:
  create_meridian_overload_debuff(overload_amount)
```

建议状态结构：

```yaml
MeridianOverloadDebuff:
  debuff_id: string
  source_refs: list[string]
  overload_amount: number
  severity: light | medium | severe | critical
  attribute_modifiers:
    vitality: number | null
    qi: number | null
    physique: number | null
    stamina: number | null
    spirit_sense: number | null
    mana: number | null
  duration_or_recovery_rule: object
  log_key: string
```

说明：

- debuff 可以影响生机、元气、体魄、精力、神念或法力等明确数值。
- debuff 是否影响根骨 / 悟性应谨慎，默认不建议常规临时 debuff 修改根骨与悟性，除非是严重长期损伤或特殊事件。
- debuff 进入突破事件时，只通过属性修正影响阶段检定。

### 5.6 经脉压力与突破流程的关系

突破流程中，经脉压力的推荐处理：

```plain text
1. 玩家 CP 达标，可尝试突破。
2. 系统读取突破模板需要或允许的突破道具。
3. 玩家选择投入突破道具。
4. 突破道具生成 InternalAuraPressureState。
5. 系统计算是否超过 meridian_pressure_cap。
6. 若未超限：无经脉压力惩罚。
7. 若超限：生成 MeridianOverloadDebuff。
8. debuff 修正明确属性。
9. 突破事件阶段读取修正后的法力、生机、元气、神念、体魄、精力、根骨、悟性。
10. 事件输出成功 / 失败 / 死亡与伤损结果包。
```

---

## 6. 突破阶段类型建议

### 6.1 通用个人数值验证阶段

| 阶段类型 | 主考数值 | 辅考数值 | 语义 |
|---|---|---|---|
| 灵力冲关 | 法力 | 元气、精力 | 将 CP 积累与道功运转转化为破境冲击 |
| 气机维稳 | 元气 | 法力、精力 | 稳定突破中的气机循环，避免内耗失控 |
| 肉身承载 | 体魄 | 生机、根骨 | 承受破境反噬、肉身压力与经脉震荡 |
| 生机护持 | 生机 | 体魄、元气 | 防止重伤、濒死或生命崩溃 |
| 神念守关 | 神念 | 悟性、精力 | 处理识海、心神、心魔叙事包装 |
| 悟道成形 | 悟性 | 神念、根骨 | 理解新境界结构，使境界成形 |
| 根骨承道 | 根骨 | 体魄、生机 | 检验角色底层资质与承道能力 |
| 精力续航 | 精力 | 元气、神念 | 长阶段突破中的持续稳定性 |

### 6.2 后期雷劫阶段

雷劫阶段只能在金丹到元婴及之后的突破模板中出现。

| 阶段类型 | 主考数值 | 辅考数值 | 语义 |
|---|---|---|---|
| 天雷临身 | 体魄 | 生机、元气 | 肉身承受雷劫冲击 |
| 雷火炼神 | 神念 | 精力、悟性 | 识海与心神承受雷劫淬炼 |
| 劫力贯体 | 法力 | 体魄、元气 | 以法力和气机化解劫力 |
| 劫后道成 | 悟性 | 根骨、神念 | 将劫数压力转化为新境界成形 |

### 6.3 示例模板方向

#### 速成道功突破模板

```plain text
阶段：灵力冲关 → 气机维稳 → 生机护持
特点：
  CP 推进快，但法力密度可能较虚。
  突破时元气 / 生机压力更明显。
  成功收益按该道功模板给，不另设突破品质。
```

#### 凝实道功突破模板

```plain text
阶段：肉身承载 → 根骨承道 → 悟道成形
特点：
  修炼较慢，但成功收益更高或更稳。
  体魄、根骨、悟性考验更硬。
```

#### 神魂道功突破模板

```plain text
阶段：神念守关 → 悟道成形 → 精力续航
特点：
  神念、悟性、精力是核心考验。
  心魔叙事可以包装在神念守关中，但不独立引入心境系统。
```

#### 元婴及以后雷劫模板

```plain text
阶段：灵力冲关 → 雷火炼神 → 天雷临身 → 劫后道成
特点：
  雷劫进入突破事件内部。
  雷劫仍然是个人数值验证，不是外敌攻击。
  不引入护法抵挡雷劫或外敌入侵阶段。
```

---

## 7. 突破结果收敛

### 7.1 结果主类型

突破结果主类型只保留三类：

```plain text
success
failed_survived
failed_death
```

不再保留：

```plain text
perfect_success
normal_success
incomplete_success
breakthrough_quality_tier
残缺突破
完美突破
普通突破
```

### 7.2 成功结果

成功时：

```plain text
写入新大境界
应用境界基础收益
应用道功突破模板收益
结算突破过程中的伤势 / debuff / 资源消耗
写入日志、传闻、轮回账本必要摘要
```

成功后可能出现两种体验状态：

```plain text
神完气足成功：
  新境界收益立即体现。
  当前战力直接提升。

带伤成功：
  新境界事实已经成立。
  道功模板收益已经写入。
  但伤势、元气亏损、神念受创、经脉过载等 debuff 暂时压制战力。
  恢复后回到该道功成功突破应有的战力水平。
```

重点：带伤成功不是残缺突破，不降低永久突破品质。

### 7.3 失败存活

失败存活时：

```plain text
不写入新大境界
消耗已承诺资源或机会
结算伤势、元气亏损、神念受创、经脉过载等 debuff
写入失败标签
角色进入疗伤、休整、重新准备或后续选择
```

失败存活可以有轻重之分，但轻重体现在伤损与恢复成本，不体现在“失败品质”。

### 7.4 失败死亡

失败死亡时：

```plain text
不写入新大境界
进入死亡 / 转世链
写入轮回账本
记录失败标签、突破模板、主要损伤来源和资源消耗
触发宗门清点、遗产、后手或传闻等后续系统
```

死亡判断来自突破事件阶段结果和损伤累积，不来自单独“死亡概率按钮”。

### 7.5 推荐结果包结构

```yaml
BreakthroughResultPackage:
  breakthrough_instance_id: string
  character_id: string
  transition_id: string
  source_dao_method_id: string
  source_template_id: string

  result_type: success | failed_survived | failed_death
  realm_changed: bool
  old_realm_id: string
  new_realm_id: string | null

  realm_base_reward_applied: bool
  dao_method_reward_profile_applied: bool

  stage_results:
    - stage_id: string
      stage_type: string
      checked_attributes: list[string]
      check_result: pass | partial | fail
      damage_delta_refs: list[string]
      resource_consumed_refs: list[string]
      failure_tags: list[string]

  damage_results:
    injuries: list[object]
    debuffs: list[object]
    attribute_damage_or_modifiers: object
    recovery_requirements: list[object]

  meridian_pressure_results:
    pressure_sources: list[string]
    overload_created: bool
    overload_debuff_refs: list[string]

  consumed_resources: list[object]
  logs: list[object]
  rumor_or_public_effects: list[object]
  reincarnation_record_delta: object | null
```

---

## 8. 旧口径到新口径的替换表

| 旧口径 | 新口径 |
|---|---|
| 突破开启读取法力、伤势、心境、肉身等大量准备维度 | 角色数值入口只看 CP；其他数值在事件内验证 |
| 法力相对推荐法力决定突破质量 | 法力只作为事件内可考验数值；不生成突破品质 |
| 完美突破 / 正常突破 / 残缺突破 | success / failed_survived / failed_death |
| 残缺突破可继续玩 | 删除残缺突破；改为成功但带伤 / 失败但存活 |
| 突破品质影响永久收益 | 删除突破品质；永久收益由道功突破模板决定 |
| 心境 / 心魔独立突破阶段 | MVP 用神念、悟性、精力等明确数值包装表达 |
| 外扰 / 护法作为突破阶段 | 永远移出突破事件内挑战 |
| 护法抵御外敌 | 只能作为突破前 / 后事件，不能进入突破阶段 |
| 雷劫前期出现 | 前期不出现；金丹到元婴及之后可进入突破事件内挑战 |
| 经脉压力直接影响属性或突破 | 经脉压力只作为资源占用；超限生成 debuff，debuff 再影响属性 |
| 筑基丹只作为普通突破资源 | 筑基丹是大量灵气输入，同时占用大量经脉压力 |

---

## 9. 需回写修改的正式文档

### 9.1 `02_系统设计/14_突破玩法设计.md`

需要重点重写。

修改项：

1. 将设计定位改为：突破是“道功模板驱动的个人数值验证事件”。
2. 当前结论中删除“完美突破、正常突破、残缺突破”的结果类型。
3. 当前结论中新增：突破不再存在独立突破品质。
4. 开启条件改为：角色数值门槛只看 CP；道功模板合法与资源输入属于模板 / 资源合法性。
5. 准备维度章节重写：删除将法力、肉身、心境、护法、外扰等列为开启阶段准备评分的写法。
6. 阶段类型章节重写：阶段直接考验白名单限定为法力、生机、元气、神念、体魄、精力、根骨、悟性。
7. 删除“外扰 / 护法”作为突破阶段类型。
8. 新增“雷劫投放边界”：金丹到元婴及以后可出现，前期不出现。
9. 新增“经脉压力与突破道具”章节：筑基丹等道具提供灵气并占用经脉压力，超限生成 debuff。
10. 结果包章节改为 success / failed_survived / failed_death + damage_results。
11. 资源章节中明确：突破道具可在创建实例或阶段开始时生成 `InternalAuraPressureState`。
12. 护法 / 宗门支持从突破内阶段移出，只能影响突破前后的独立事件或叙事 / 日志。

### 9.2 `02_系统设计/02_角色与真灵设计/03_角色修为与境界.md`

修改项：

1. 大境界突破结果列表删除“完美突破、正常突破、残缺突破”。
2. 改成：成功、失败存活、失败死亡。
3. 成功收益改为：境界基础收益 + 道功模板收益。
4. 删除或改写“突破质量收益 / 惩罚”表述。
5. 新增说明：成功后的当前战力可能受伤势 / debuff 暂时压制，但不等于残缺突破。
6. 轮回账本记录保留失败标签、最高境界、死亡原因、主要损伤来源。

### 9.3 `02_系统设计/02_角色与真灵设计/04_角色主修功法.md`

修改项：

1. 大境界突破开启前校验列表中，删除根基、经脉压力、伤势、心魔等作为默认开启门槛的写法。
2. 保留：大境界突破读取当前大境界最终锁定主修道功记录。
3. 强化：主修道功决定突破模板、难度和成功收益。
4. 明确：掌握度不改变突破模板类型；是否作为事件内修正需要模板声明，但不作为默认入口门槛。

### 9.4 `02_系统设计/04_功法设计/01_道功.md`

修改项：

1. 道功职责中补充：道功突破模板定义突破难度与成功收益。
2. 删除可能暗示“突破品质另行结算”的表述。
3. 强调：道功强弱已经体现在突破模板难度与收益中，不再叠加独立突破品质。
4. 补充：高阶或强力道功可以有更高阶段阈值、更高雷劫压力或更高伤损风险。

### 9.5 `03_数值设计/05_功法设计基准建模.md`

修改项：

1. `突破承接`章节中删除“突破质量 / 风险 MVP 可读取法力相对推荐法力”的旧方向，或降级为废弃口径。
2. 新增 `BreakthroughTemplate.difficulty_profile_ref` 与 `reward_profile_ref` 的职责边界。
3. 明确：突破最终永久收益由道功模板决定，不再另设突破品质公式。
4. 新增：金丹到元婴及以后模板可启用雷劫阶段。
5. 明确：事件内属性验证白名单为法力、生机、元气、神念、体魄、精力、根骨、悟性。

### 9.6 `00_INDEX/修炼系统数值投放收敛裁决.md`

修改项：

1. “突破推荐法力”待裁决项需要改写：法力不再作为入口推荐法力或突破品质来源，只是事件内可考验数值。
2. 经脉压力职责需进一步精确：经脉压力不直接影响属性；体魄决定上限，资源占用压力，超限生成 debuff。
3. “不要在 MVP 阶段引入复杂突破评分”继续保留，并扩展为“不引入独立突破品质”。

### 9.7 `02_系统设计/05_物品设计/02_丹药.md`

修改项：

1. 明确丹药和突破道具都会生成持续经脉压力。
2. 修为丹药 / 灵气输入药物的压力随灵力吸收或消散而降低。
3. 筑基丹等突破道具需要特殊标记：`breakthrough_item`、`aura_payload_total`、`meridian_pressure_value`。
4. 超限不直接改属性，而是生成经脉过载 debuff。
5. 丹药不能在突破中回溯改变已结算阶段。

### 9.8 `02_系统设计/02_角色与真灵设计/07_角色持续状态系统.md`

修改项：

1. 新增或完善 `InternalAuraPressureState`。
2. 新增或完善 `MeridianOverloadDebuff`。
3. 明确经脉压力状态与属性 debuff 的分层。
4. 明确 debuff 才能影响属性，并作为突破事件内属性验证的输入。

### 9.9 `02_系统设计/15_随机事件玩法设计.md`

修改项：

1. 保留突破挑战作为 `breakthrough_b1` 或同步处理事件。
2. 新增边界：外扰和护法不作为突破事件内阶段。
3. 外扰只能作为突破前 / 后的独立事件链。
4. 雷劫是突破事件内部挑战，但不是外扰事件，也不走护法抵御逻辑。
5. 事件来源标签中避免把“突破外扰”写成突破链内部模块。

### 9.10 `04_交互设计/04_修为页面设计.md`

修改项：

1. 突破入口 UI 只将 CP 作为明确成长门槛展示。
2. 风险提示展示为突破事件内考验预览，而不是入口阻止条件。
3. 不展示“突破品质预测”。
4. 展示当前道功突破模板名称、主要考验项、可能损伤类型。
5. 展示经脉压力空间与突破道具占用提示。
6. 若将使用筑基丹等突破道具导致经脉过载，应提示“可能获得经脉过载状态，影响突破时属性表现”。
7. 成功结果页区分“已突破”和“当前伤损状态”，不要显示“残缺突破”。

### 9.11 `04_交互设计/05_功法页面设计.md`

修改项：

1. 道功详情展示突破模板收益与主要挑战倾向。
2. 不展示独立突破品质。
3. 强道功的表达应是“收益更高、突破模板更难”，而不是“更容易完美突破”。
4. 可展示后期道功是否包含雷劫阶段。

---

## 10. 推荐实现字段补充

### 10.1 突破实例

```yaml
BreakthroughInstance:
  instance_id: string
  character_id: string
  transition_id: string
  source_dao_method_id: string
  source_template_id: string
  current_stage_index: int
  status: created | active | resolved | failed | cancelled

  cp_requirement_met: bool
  resource_inputs: list[string]
  internal_aura_pressure_state_refs: list[string]
  active_debuff_refs: list[string]

  stage_results: list[object]
  result_package_ref: string | null
```

### 10.2 突破阶段模板

```yaml
BreakthroughStageTemplate:
  stage_id: string
  stage_type: string
  direct_check_attributes:
    primary: list[mana | vitality | qi | spirit_sense | physique | stamina | aptitude_root | aptitude_comprehension]
    secondary: list[mana | vitality | qi | spirit_sense | physique | stamina | aptitude_root | aptitude_comprehension]
  threshold_profile_ref: string
  damage_profile_ref: string
  death_risk_profile_ref: string | null
  resource_interaction_policy: object
  failure_tag_pool_ref: string
```

### 10.3 雷劫策略字段

```yaml
ThunderTribulationPolicy:
  enabled: bool
  earliest_transition: golden_core_to_nascent_soul
  tribulation_stage_pool_ref: string
  thunder_damage_profile_ref: string
  allowed_attributes:
    - physique
    - vitality
    - qi
    - spirit_sense
    - stamina
    - mana
    - aptitude_comprehension
    - aptitude_root
```

### 10.4 经脉压力状态

```yaml
InternalAuraPressureState:
  state_id: string
  character_id: string
  source_instance_id: string
  source_type: medicine | breakthrough_item | spirit_liquid | spirit_material | formation_infusion | other
  aura_payload_total: number
  aura_payload_remaining: number
  meridian_pressure_value: number
  release_mode: absorbed_over_time | breakthrough_stage_consumed | dissipating
  started_world_day: int
  started_world_hour: int
  expected_end_world_day: int | null
  expected_end_world_hour: int | null
```

### 10.5 经脉过载 debuff

```yaml
MeridianOverloadDebuff:
  debuff_id: string
  character_id: string
  source_pressure_state_refs: list[string]
  overload_amount: number
  severity: light | medium | severe | critical
  attribute_modifiers:
    mana: number | null
    vitality: number | null
    qi: number | null
    spirit_sense: number | null
    physique: number | null
    stamina: number | null
  duration_rule: object
  recovery_rule: object
  created_by_breakthrough_instance_id: string | null
```

---

## 11. 待裁决与待补

以下内容尚未定数值或实现细节，需要后续补表或裁决：

1. 各大境界突破所需 CP 表。
2. 各道功突破模板的阶段序列、阈值和奖励表。
3. 法力、生机、元气、神念、体魄、精力、根骨、悟性在突破检定中的标准化方式。
4. 伤势 / debuff 对 8 类明确属性的修正规则。
5. 体魄到经脉压力上限的映射公式。
6. 丹药、灵液、灵材、突破道具的 `meridian_pressure_value` 与释放时长。
7. 筑基丹等关键突破道具是否为某些模板必需，还是强推荐 / 可选输入。
8. 经脉过载 debuff 的轻 / 中 / 重 / 危阈值。
9. 雷劫阶段的数值强度、伤害曲线和死亡阈值。
10. 雷劫是否允许通过法宝、符箓等后期资源降低伤损；若允许，应保持其为个人数值验证辅助，不引入护法或外扰逻辑。
11. 成功但带伤后的恢复路径、时间、资源和 UI 表达。
12. 失败存活后的再次突破冷却、资源重置和伤损保留规则。
13. 死亡后轮回账本需要记录哪些突破失败标签。
14. 普通 UI 中是否展示具体属性阈值，还是只展示“主要考验：法力 / 体魄 / 神念”等方向性信息。

---

## 12. 可直接写入正式文档的结论段

建议在《14_突破玩法设计》的“当前结论”中加入或替换为以下段落：

```plain text
大境界突破是由 CP 触发、由当前大境界锁定主修道功的突破模板定义难度和收益、由明确角色数值完成事件内验证、由结果包写入成功 / 失败 / 死亡与伤损后果的个人数值验证事件。

突破入口的角色数值门槛只看 CP。法力、生机、元气、神念、体魄、精力、根骨、悟性不在开启阶段阻止突破，而是在突破事件内部作为直接考验项。伤势、经脉过载等状态不作为直接考验项，只通过属性修正影响这些明确数值。

突破不再设置独立突破品质，也不再区分完美突破、正常突破和残缺突破。突破成功后的永久收益由境界基础收益与道功突破模板收益决定；突破过程中的损伤只作为当前状态或 debuff 进入结果包。成功但带伤不是残缺突破，恢复后应回到该道功模板成功突破应有的战力水平。

雷劫只从金丹到元婴及之后的大境界突破开始进入突破事件内挑战。雷劫属于境界劫数验证，不是外敌入侵。炼气到筑基、筑基到金丹等前期大境界突破不投放雷劫。

外扰与护法永远不作为突破事件内挑战。外敌干扰如需存在，只能在突破事件开启前或完成后作为独立事件链触发；护法也只能用于突破前后的安全、接应、传闻或宗门支持表达，不能成为突破阶段内的挑战或应对项。

经脉压力本身不直接影响属性。体魄决定经脉压力上限；丹药、灵液、灵材和筑基丹等突破道具会提供灵气并占用持续经脉压力，直到灵力被吸收或消散。若突破道具或药性导致经脉压力超限，则生成经脉过载 debuff；该 debuff 再修正属性，并间接影响突破事件验证。
```
