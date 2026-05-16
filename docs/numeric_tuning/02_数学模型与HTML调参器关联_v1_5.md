# 数值设计｜数学模型、公式推导与 HTML 调参器关联 v1.5

适用范围：本文件是从 `数值建模核心修订稿_f_1_术语修正版_canvas草稿_建模版本.md` 拆分出的数学模型与调参器对照稿，用于维护变量分类、公式、调参顺序、HTML 字段映射和已知对齐事项。

本文对应的 HTML 调参器为 `修为时间数学模型_html调参器_v_0_1.html`。HTML 是本轮建模校验工具，不是正式运行时或正式设计权威。

本文位于 `docs/numeric_tuning`，属于开发调参与验算资产。正式数值设计权威仍位于 `docs/xiuxian_design_docs/03_数值设计`；调参器输出若要驱动实现，必须先把稳定结论改写进对应正式数值文档。

## 1. 当前定位

本文负责把 v1.5 数值方案中的输入变量、目标期望值、推导变量、约束项和 HTML 调参器字段集中定义。

正式数值口径以以下文档为准：

| 正式文档 | 关系 |
| --- | --- |
| `../xiuxian_design_docs/03_数值设计/10_时间速度与局部时间域数值设计.md` | 时间速度、F1、现实时间基线、外界年基线、局部时间域和资源年权威口径 |
| `../xiuxian_design_docs/03_数值设计/01_修为境界与期望游玩时间建模.md` | 境界段、玩家现实体验目标、CP 上下界和阶段倍率参考 |
| `../xiuxian_design_docs/03_数值设计/02_修炼公式与数值设计.md` | 正式修炼收益、资源输入、兼容小时和状态压力公式 |
| `../xiuxian_design_docs/03_数值设计/08_数值验算.md` | 验算场景、Debug 输出和调参验收边界 |

历史输入来源仍可参考 `../inbox/design_changed_input/01_标准数值方案_v1_5.md` 与 `../inbox/design_changed_input/03_跨系统数值修改裁定_v1_5.md`，但它们不越过正式包成为当前设计权威。

## 2. 分类定义

| 分类 | 记号 | 定义 | 调整权限 | 示例 |
| --- | --- | --- | --- | --- |
| 外部强约束 | `H` | 来自当前裁决、正式系统口径或跨系统一致性要求；本方案只能服从，不能在内部调参时改写 | 不可在本文内任意修改 | 速度状态只保留 N1 / F1 / B1 / P0；阶段预算按外界时间刷新 |
| 可调输入变量 | `X` | 设计者可以直接调整的模型输入，用于反推体验节奏、时间分配、资源消耗和事件密度 | 可调 | `f1_seconds_per_outer_day`、`local_domain_growth_ratio`、`method_study_ratio` |
| 模型输出的可调期望值 | `T` | 用于校准模型的目标值或验收区间；不是单次运行的结算结果 | 可调，但应通过版本裁决修改 | 32 小时现实参考、约 47.55 外界年、596 局部主观年、50 小时 / 100 年 Debug 边界 |
| 因变量 / 推导变量 | `Y` | 由 `H`、`X`、`T` 与运行时状态经公式推导得到；通常不应被手动直接填写 | 不直接调，随输入变化 | `F1_outer_years`、`local_dao_cultivation_years`、`unsupported_inner_years` |
| 方案内生约束 | `C` | 本方案为了数学一致性设定的等式、不等式、优先级和守恒关系 | 原则上不可破坏；可在新版本中整体重构 | `N1_ratio + F1_ratio + B1_ratio = 1` |

使用顺序：

```text
先固定 H 与 T；
再选择 X；
由公式计算 Y；
最后用 C 检查模型是否自洽。
```

若某个 `Y` 不符合目标，不应直接篡改 `Y`，而应回到对应的 `X` 或 `T` 调整。

## 3. 外部强约束 H

| 编号 | 强约束 | 数学 / 系统含义 | 本方案影响 |
| --- | --- | --- | --- |
| `H01` | 修为时间建模终点为“大乘圆满 -> 突破进入渡劫期” | 终点之后的劫数、飞升、终局结算不进入本模型 | 本文不反推渡劫后的成长时间 |
| `H02` | 玩家可见速度状态只保留 N1 / F1 / B1 / P0 | 不新增独立宏观流年阶段 | F1 承担长期低交互高速推进 |
| `H03` | 速度优先级为 `P0 > B1 > N1 > F1` | 高优先级状态覆盖低优先级状态 | F1 只能在无交锋、无公共暂停、无强交互阻塞时启用 |
| `H04` | F1 内部不得逐小时全量 tick | 不允许全量刷新所有对象 | 必须使用批量结算、断点推进和事件流采样 |
| `H05` | 闭关承诺不吞掉事件 | 事件仍会触发，只是处理方式可能自动化 | EventStream 是 F1 的必要组成 |
| `H06` | 寿元按角色所在时间域扣除 | 洞天内按主观时间；洞天外按共享外界日历 | 不能用房间当前速度直接决定寿元消耗 |
| `H07` | 阶段预算按外界时间刷新 | 洞天内主观百年不等于外界预算百年 | 资源、市场、NPC 宏观成长读取外界时间 |
| `H08` | 洞天 / 时间阵法不等于免费收益 | 局部时间域只提供时间和场地，修炼收益仍受资源年限制 | 必须计算有效修炼年与资源不足年份 |
| `H09` | 短交互行为不承担大规模年份消耗 | 短途移动、交易、互动、现场探索主要吃 N1 / B1 现实预算 | 非修行外界流年主要来自等待、生产、长期游历、宗门职责 |
| `H10` | 高风险不可逆事件不能被普通预设自动处理 | 突破、转世、叛宗、强 PvP、稀有资源消耗等必须人工确认 | 这些事件会硬中断 F1 或进入 B1 / P0 |
| `H11` | 轮回不保证缩短总通关时间 | 轮回提高稳定性、成功率和结局质量，但资源等待可能拉长总时长 | 不得设定 `reincarnation_total_time < single_life_time` 为硬约束 |

## 4. 可调输入变量 X

### 4.1 现实时间与速度分配输入

| 变量 | 默认值 | 单位 | 含义 | HTML 控件 |
| --- | ---: | --- | --- | --- |
| `N1_real_ratio` | 0.66 | 比例 | 现实参考时长中分配给 N1 现场交互的现实时间占比 | `N1 现实占比` |
| `F1_real_ratio` | 0.22 | 比例 | 现实参考时长中分配给 F1 长期低交互推进的现实时间占比 | `F1 现实占比` |
| `B1_real_ratio` | 0.12 | 比例 | 现实参考时长中分配给 B1 关键慢速轮的现实时间占比 | `B1 现实占比` |
| `n1_seconds_per_outer_hour` | 15 | 秒 / 外界小时 | N1 现场状态的外界时间推进速度 | `N1 秒 / 外界小时` |
| `f1_seconds_per_outer_day` | 1.5 | 秒 / 外界日 | F1 长期低交互状态的外界时间推进速度；HTML 调参范围为 1-2 秒 / 外界日 | `F1 秒 / 外界日` |
| `b1_seconds_per_outer_hour` | 60 | 秒 / 外界小时 | B1 慢速交锋状态的外界时间推进速度 | `B1 秒 / 外界小时` |

内生约束：

```text
N1_real_ratio + F1_real_ratio + B1_real_ratio = 1
N1_real_ratio >= 0
F1_real_ratio >= 0
B1_real_ratio >= 0
```

HTML 中 `lockTimeRatio` 勾选时自动保持三项总和为 100%。

### 4.2 分域时间分配输入

| 变量 | 默认值 | 单位 | 含义 | HTML 控件 |
| --- | ---: | --- | --- | --- |
| `local_domain_growth_ratio` | 0.70 | 比例 | 局部时间域主观时间中用于修行成长的比例 | `局部主观年：修行成长占比` |
| `local_domain_support_ratio` | 0.30 | 比例 | 局部时间域主观时间中用于支持行为的比例 | `局部主观年：支持行为占比` |
| `method_study_ratio` | 0.20 | 比例 | 修行成长时间中用于功法研习的比例 | `修行成长：功法研习占比` |
| `dao_cultivation_ratio` | 0.80 | 比例 | 修行成长时间中用于道功修炼的比例 | `修行成长：道功修炼占比` |
| `outer_f1_ordinary_cultivation_ratio` | 0.15 | 比例 | 洞天外 F1 外界流年中用于普通修炼 / 低阶修炼的比例 | `洞天外 F1 普通修炼占比` |

内生约束：

```text
local_domain_growth_ratio + local_domain_support_ratio = 1
method_study_ratio + dao_cultivation_ratio = 1
0 <= outer_f1_ordinary_cultivation_ratio <= 1
```

HTML 中 `lockLocalRatio` 和 `lockMethodRatio` 分别保持成长 / 支持、研习 / 道功比例守恒。

### 4.3 局部时间域与洞天输入

| 变量 | HTML 默认值 | 单位 | 含义 | HTML 控件 |
| --- | ---: | --- | --- | --- |
| `inner_years_per_outer_day` | 2 | 主观年 / 外界日 | 局部时间域相对外界日历的时间倍率；正式数值应按 T0-T5 配置 | `洞天倍率：主观年 / 外界日` |
| `max_inner_years_per_entry` | 80 | 主观年 | 单次进入局部时间域的主观年上限 | `单次进入主观年上限` |
| `resource_year_capacity_multiplier` | 1 | 倍率 | 洞天对资源包可支撑修炼年数的修正 | `资源年承载倍率` |
| `lifespan_pressure_modifier` | 1 | 倍率 | 洞天对寿元压力的修正；HTML 当前只展示，不直接改写寿元安全年 | `寿元压力倍率` |
| `mental_risk_per_inner_year` | 0.015 | 风险 / 主观年 | 心魔风险年增长率 | `心魔风险 / 主观年` |
| `meridian_pressure_per_inner_year` | 0.018 | 压力 / 主观年 | 经脉压力年增长率 | `经脉压力 / 主观年` |
| `fuel_cost_per_inner_year` | 1 | 成本 / 主观年 | 时间阵法或洞天运行燃料消耗 | `阵法燃料成本 / 主观年` |
| `maintenance_cost_per_outer_day` | 3 | 成本 / 外界日 | 局部时间域维持成本 | `洞天维护成本 / 外界日` |

### 4.4 资源年与收益输入

| 变量 | HTML 默认值 | 单位 | 含义 | HTML 控件 |
| --- | ---: | --- | --- | --- |
| `planned_inner_years` | 596 | 主观年 | 玩家计划闭关或修炼的主观年数 | `计划闭关 / 修炼主观年` |
| `resource_supported_inner_years` | 420 | 主观年 | 当前资源可支撑的主观修炼年 | `资源可支撑年数` |
| `method_supported_inner_years` | 596 | 主观年 | 当前功法可支撑的推进年数 | `功法可支撑年数` |
| `lifespan_safe_years` | 700 | 主观年或外界年 | 当前状态下的安全耗寿区间 | `寿元安全年数` |
| `mental_stability_supported_years` | 520 | 主观年 | 当前心神可承受的连续闭关年数 | `心神稳定年数` |
| `unsupported_yield_ratio` | 0.10 | 比例 | 资源不足年份仍保留的基础收益比例 | `资源不足基础收益比例` |
| `base_cultivation_yield` | 1 | CP / 年 | HTML 估算收益上限用；不代表正式修炼公式 | `基础修炼收益` |

### 4.5 F1 批量结算与事件输入

| 变量 | HTML 默认值 | 单位 | 含义 | HTML 控件 |
| --- | ---: | --- | --- | --- |
| `max_f1_batch_horizon_early` | 3 | 外界日 / 批 | 早期 F1 单批最大推进上限 | `早期最大批次` |
| `max_f1_batch_horizon_mid` | 15 | 外界日 / 批 | 中期 F1 单批最大推进上限 | `中期最大批次` |
| `max_f1_batch_horizon_late` | 90 | 外界日 / 批 | 后期 F1 单批最大推进上限 | `后期最大批次` |
| `base_rate_per_outer_day` | 0.02 | 概率 / 外界日 | 读取外界日历的事件流基础危险率 | `外界事件危险率` |
| `base_rate_per_inner_year` | 0.01 | 概率 / 主观年 | 读取局部主观时间的事件流基础危险率 | `主观事件危险率` |
| `max_triggers_per_batch` | 2 | 次 / 批 | 单批最多触发次数 | `单批最大触发次数` |

## 5. 模型输出的可调期望值 T

| 目标值 | 当前口径 | 验收 / 说明 | HTML 字段 |
| --- | --- | --- | --- |
| `target_real_reference_hours` | 默认 32 小时，Debug 最高 50 小时 | 理论直线现实参考时长，不等于实际单局总时长 | `target_real_reference_hours` |
| `target_outer_world_years` | 默认约 47.55 年，Debug 最高 100 年 | HTML 中作为“反推 F1 速度”的目标值；当前约 47.55 年基线已接受 | `target_outer_world_years` |
| `outer_world_year_acceptance_range` | 常规 20-50 年，可 Debug 到 100 年 | 常规验收范围仍以 20-50 年为主；100 年只作为调试极限 | `outer_world_year_min` / `outer_world_year_max` / `outer_world_year_debug_limit` |
| `target_local_domain_inner_years` | 约 596 年 | 局部时间域主观经历目标，不等同完整生涯总年数 | `local_domain_inner_years` |
| `target_local_growth_years` | 约 417 年 | 596 年 x 70%，用于修行成长 | 推导输出 |
| `target_local_method_study_years` | 约 83 年 | 417 年 x 20%，用于功法研习 | 推导输出 |
| `target_local_dao_cultivation_years` | 约 334 年 | 417 年 x 80%，用于道功修炼 | 推导输出 |
| `target_local_support_years` | 约 179 年 | 596 年 x 30%，用于支持行为 | 推导输出 |
| `target_total_outer_years_baseline` | 约 47.55 年 | N1 + F1 + B1 合计外界年基准 | `totalOuterYears` |

期望值使用方式：

```text
若 total_outer_years < 20：外界流年感不足，应提高 F1 占比或加快 F1；
若 total_outer_years > outer_world_year_max 且 <= outer_world_year_debug_limit：超过常规验收上限，只能作为 Debug 样例；
若 total_outer_years > outer_world_year_debug_limit：超过 100 年调试极限，应降低 F1 占比或放慢外界年目标；
若 local_dao_cultivation_years 不足：修为推进年不够，应提高局部主观年或道功修炼比例；
若 local_support_years 不足：闭关风险、恢复、巩固和事件空间不足，应提高支持行为比例或减少连续高压修炼。
```

## 6. 公式与模型

### 6.1 基础常量

HTML 调参器使用：

```text
DAYS_PER_YEAR = 360
HOURS_PER_DAY = 24
```

### 6.2 现实时间分配

```text
N1_real_hours = target_real_reference_hours * N1_real_ratio
F1_real_hours = target_real_reference_hours * F1_real_ratio
B1_real_hours = target_real_reference_hours * B1_real_ratio
```

基准代入：

```text
N1_real_hours = 32 * 0.66 = 21.12
F1_real_hours = 32 * 0.22 = 7.04
B1_real_hours = 32 * 0.12 = 3.84
```

### 6.3 外界世界日历推导

文本简写：

```text
N1_outer_years = N1_real_hours / 36
B1_outer_years = B1_real_hours / 144
F1_outer_years = F1_real_hours * 10 / f1_seconds_per_outer_day

total_outer_world_years =
  N1_outer_years
  + F1_outer_years
  + B1_outer_years
```

HTML 精确式：

```text
n1OuterYears =
  n1RealHours * 3600
  / n1_seconds_per_outer_hour
  / HOURS_PER_DAY
  / DAYS_PER_YEAR

f1OuterYears =
  f1RealHours * 3600
  / f1_seconds_per_outer_day
  / DAYS_PER_YEAR

b1OuterYears =
  b1RealHours * 3600
  / b1_seconds_per_outer_hour
  / HOURS_PER_DAY
  / DAYS_PER_YEAR
```

基准代入：

```text
N1_outer_years = 21.12 / 36 = 0.59
B1_outer_years = 3.84 / 144 = 0.03
F1_outer_years = 7.04 * 10 / 1.5 = 46.93

total_outer_world_years ≈ 47.55
```

### 6.4 按目标外界年反推 F1 速度

HTML 按钮 `按目标外界年反推 F1 速度` 使用：

```text
targetF1Years =
  target_outer_world_years
  - n1OuterYears
  - b1OuterYears

f1_seconds_per_outer_day =
  F1_real_hours * 3600
  / (targetF1Years * DAYS_PER_YEAR)
```

若 `targetF1Years <= 0`，调参器提示目标外界年过低，无法反推 F1 速度。

### 6.5 局部时间域分配

```text
local_growth_years =
  local_domain_inner_years * local_domain_growth_ratio

local_support_years =
  local_domain_inner_years * local_domain_support_ratio

local_method_study_years =
  local_growth_years * method_study_ratio

local_dao_cultivation_years =
  local_growth_years * dao_cultivation_ratio
```

基准代入：

```text
local_growth_years = 596 * 0.70 ≈ 417
local_support_years = 596 * 0.30 ≈ 179
local_method_study_years = 417 * 0.20 ≈ 83
local_dao_cultivation_years = 417 * 0.80 ≈ 334
```

### 6.6 洞天外 F1 分配

```text
outer_ordinary_cultivation_years =
  F1_outer_years * outer_f1_ordinary_cultivation_ratio

outer_non_cultivation_years =
  F1_outer_years - outer_ordinary_cultivation_years
```

其中：

```text
outer_non_cultivation_years
= 世界资源积累 / 大型窗口等待
+ 长耗时生产与准备
+ 长期游历 / 远程行程 / 宗门职责
+ 其它低交互非修行过程
```

### 6.7 总修行成长时间

```text
total_method_study_years =
  local_method_study_years
  + outer_ordinary_cultivation_years * method_study_ratio

total_dao_cultivation_years =
  local_dao_cultivation_years
  + outer_ordinary_cultivation_years * dao_cultivation_ratio

total_cultivation_growth_years =
  total_method_study_years
  + total_dao_cultivation_years
```

### 6.8 有效修炼年与资源不足年

HTML 使用洞天资源年承载倍率：

```text
resource_cap =
  resource_supported_inner_years
  * resource_year_capacity_multiplier

effective_cultivation_inner_years =
  min(
    planned_inner_years,
    resource_cap,
    method_supported_inner_years,
    lifespan_safe_years,
    mental_stability_supported_years
  )

unsupported_inner_years =
  max(0, planned_inner_years - effective_cultivation_inner_years)
```

资源不足时的收益上限：

```text
supported_yield =
  effective_cultivation_inner_years * base_cultivation_yield

unsupported_yield_cap =
  unsupported_inner_years
  * base_cultivation_yield
  * unsupported_yield_ratio

total_yield_cap =
  supported_yield + unsupported_yield_cap
```

说明：`base_cultivation_yield` 是 HTML 估算收益上限用字段，不代表正式修炼公式。正式修炼收益仍应读取《修炼公式与数值设计》中的境界段、兼容小时、资源输入和状态压力模型。

### 6.9 局部时间窗口、进入次数与成本

HTML 用于观察洞天倍率和进入次数：

```text
local_outer_days_needed =
  local_domain_inner_years / inner_years_per_outer_day

local_outer_years_needed =
  local_outer_days_needed / DAYS_PER_YEAR

entries_needed =
  ceil(local_domain_inner_years / max_inner_years_per_entry)

planned_fuel_cost =
  planned_inner_years * fuel_cost_per_inner_year

planned_maintenance_cost =
  local_outer_days_needed * maintenance_cost_per_outer_day
```

### 6.10 事件概率估算

HTML 对每个阶段批次计算：

```text
inner_years =
  batch_outer_days * inner_years_per_outer_day

outer_prob =
  probability_at_least_one(base_rate_per_outer_day, batch_outer_days)

inner_prob =
  probability_at_least_one(base_rate_per_inner_year, inner_years)

combined_prob =
  1 - (1 - outer_prob) * (1 - inner_prob)

expected_total =
  base_rate_per_outer_day * batch_outer_days
  + base_rate_per_inner_year * inner_years
```

HTML 的离散概率函数：

```text
probability_at_least_one(rate, duration):
  if rate <= 0 or duration <= 0: return 0
  return 1 - (1 - rate) ^ duration
```

设计稿中的危险率采样模型：

```text
P(no event in n hours) = (1 - p)^n

u = random(0, 1)
next_event_hour = floor(log(1 - u) / log(1 - p))
```

连续危险率模型：

```text
H(t) = ∫ lambda(t) dt
事件发生条件：H(t) >= -ln(u)
```

### 6.11 生涯耗时

```text
career_elapsed_years =
  local_domain_inner_years
  + outer_years_when_character_outside_local_domain
```

禁止写成：

```text
career_elapsed_years = local_domain_inner_years + total_outer_world_years
```

原因是：角色在洞天内时，外界时间仍会推进，但寿元和主观经历按局部时间域扣除；只有角色位于洞天外的外界年份才进入该角色自身的外界经历时间。

### 6.12 轮回总时长

```text
actual_total_clear_time_with_reincarnation =
  Σ(each_life_career_elapsed_time)
  + reincarnation_transition_time
  + world_resource_accumulation_wait_time
  + major_resource_event_wait_time
  + repeated_route_setup_time
  - route_knowledge_time_saved
  - failure_risk_time_saved
```

其中：

```text
world_resource_accumulation_wait_time >= 0
major_resource_event_wait_time >= 0
```

这两个值可能大于轮回带来的路线节省，因此总通关时间可以更长。

## 7. 方案内生约束 C

| 编号 | 约束 | 表达式 / 规则 | HTML 校验 |
| --- | --- | --- | --- |
| `C01` | 现实时间占比守恒 | `N1_real_ratio + F1_real_ratio + B1_real_ratio = 1` | 有 |
| `C02` | 速度优先级 | `P0 > B1 > N1 > F1` | 摘要展示 |
| `C03` | F1 进入条件 | `can_enter_F1(room) = true` 才能进入 F1 | 无 |
| `C04` | F1 批量推进断点 | `F1_target_time = min(all_safe_stops, max_f1_batch_horizon)` | 无 |
| `C05` | 局部时间域比例守恒 | `local_domain_growth_ratio + local_domain_support_ratio = 1` | 有 |
| `C06` | 修行成长比例守恒 | `method_study_ratio + dao_cultivation_ratio = 1` | 有 |
| `C07` | 外界 F1 普通修炼比例边界 | `0 <= outer_f1_ordinary_cultivation_ratio <= 1`，默认建议 10%-20% | 有 |
| `C08` | 有效修炼年上限 | `effective_cultivation_inner_years <= planned_inner_years` | 有 |
| `C09` | 资源不足年非负 | `unsupported_inner_years >= 0` | 有 |
| `C10` | 世界预算不读洞天主观年 | `world_budget_delta = f(outer_world_time)` | 无 |
| `C11` | 寿元读取角色时间域 | `lifespan_delta = f(character_time_domain)` | 摘要展示 |
| `C12` | 事件不被闭关承诺消除 | `EventStream` 仍按适用时间域采样 | 摘要展示 |
| `C13` | 高风险事件不可普通自动化 | `interrupt_level = hard_interrupt` 或进入 B1 / P0 | 无 |
| `C14` | 轮回总时长无缩短硬约束 | 不设置 `reincarnation_total_time < single_life_time` | 摘要展示 |

HTML 另有提示校验：

| 校验项 | 作用 |
| --- | --- |
| `T_outer` | 检查总外界年是否落在 `outer_world_year_min` 到 `outer_world_year_max` |
| `H08` | 若存在资源不足年，提示洞天闭关资源不足，只能获得低效收益 |
| `F1 占比` | 提示当前模型预期外界流年主要由 F1 承担 |
| `洞天窗口` | 检查按当前洞天倍率，596 主观年所需外界时间是否小于 F1 外界年贡献 |
| `事件密度` | 检查早期单批综合事件概率是否超过 25% |

## 8. 模型依赖关系与调参顺序

推荐调参顺序：

```text
Step 1：确认 H
  固定终点、速度状态、寿元口径、阶段预算口径、F1 事件口径。

Step 2：设定 T
  确认默认 32 小时现实参考、当前约 47.55 外界年、596 局部主观年，以及 50 小时 / 100 年 Debug 边界。

Step 3：选择 X_time
  调整 N1 / F1 / B1 现实占比与速度常量，得到 total_outer_world_years。

Step 4：选择 X_domain
  调整局部时间域倍率、进入上限、修行成长 / 支持行为比例，得到局部研习年与道功修炼年。

Step 5：选择 X_resource
  配置资源包、洞天燃料、寿元安全年、心魔稳定年，得到 effective_cultivation_inner_years。

Step 6：选择 X_event
  配置 F1 批量上限、事件危险率、中断等级和预设范围，验证 F1 可读性与性能。

Step 7：检查 C
  若任何内生约束被破坏，回退到对应输入变量，不直接修正因变量。
```

总依赖图：

```text
外部强约束 H
        ↓
模型目标 T  ->  可调输入 X
        ↓          ↓
      推导变量 Y / 结果包字段
        ↓
    内生约束 C 校验
        ↓
  若不满足目标或约束，回调 X 或重裁 T
```

## 9. HTML 调参器结构

HTML 文件：

```text
docs/numeric_tuning/修为时间数学模型_html调参器_v_0_1.html
```

调参器功能：

1. 编辑 v1.5 基线参数。
2. 锁定 N1 / F1 / B1 总和、局部成长 / 支持总和、研习 / 道功总和。
3. 按目标外界年反推 F1 秒 / 外界日。
4. 展示总外界年、F1 外界年贡献、局部道功修炼年、有效修炼年和早期单批事件概率。
5. 展示现实时间、外界年、分域时间、资源瓶颈和事件风险条。
6. 输出推导字段表、检查项和可复制摘要。
7. 支持参数 JSON 导出 / 导入。
8. 使用 localStorage 键 `xiuxian-time-model-tuner-v01` 保存本地状态。

主要按钮：

| 按钮 / 预设 | 作用 |
| --- | --- |
| `按目标外界年反推 F1 速度` | 根据目标外界年、N1 / B1 外界年和 F1 现实小时反推 `f1_seconds_per_outer_day` |
| `复制摘要` | 复制当前调参摘要 |
| `导出参数 JSON` | 导出当前 state |
| `导入参数 JSON` | 从 JSON 合并参数到默认字段集合 |
| `恢复 v1.5 基线` | 恢复 `defaults` |
| `F1 1 秒快档` | 设置 `f1_seconds_per_outer_day = 1`，用于观察更长外界流年压力 |
| `F1 2 秒慢档` | 设置 `f1_seconds_per_outer_day = 2`，用于观察更短外界流年压力 |
| `50h / 100 年调试` | 设置 `target_real_reference_hours = 50`、`target_outer_world_years = 100`、`outer_world_year_max = 100`，用于压力测试 |
| `高压洞天样例` | 提高局部主观年、心魔 / 经脉压力、洞天倍率并降低资源不足收益 |

## 10. HTML 与文档对齐事项

| 项目 | 当前状态 | 后续处理建议 |
| --- | --- | --- |
| F1 速度 | HTML 默认 1.5 秒 / 外界日，调参范围 1-2 秒 / 外界日 | 正式包已采用默认 1.5 秒，并保留 1 / 1.5 / 2 秒调参档 |
| 现实参考时长 | HTML 默认 `target_real_reference_hours = 32`，上限 50 小时 | 正式包默认 32 小时；50 小时只作为 Debug 上限 |
| 外界年目标 | HTML 默认 `target_outer_world_years = 47.55`，可 Debug 到 100 年 | 正式包接受当前约 47.55 年基线，不改为 30-40 年保守口径；100 年只作为调试极限 |
| 外界年验收上限 | HTML 默认 `outer_world_year_max = 50`，`outer_world_year_debug_limit = 100` | 超过 50 年属于 Debug 样例；超过 100 年应判定为越界 |
| 资源年承载倍率 | HTML 在有效修炼年公式中使用 `resource_supported_inner_years * resource_year_capacity_multiplier` | 文档公式应明确 `resource_cap`，避免只写 `resource_supported_inner_years` 造成漏乘 |
| 寿元压力倍率 | HTML 仅展示 `lifespan_pressure_modifier`，不直接改写 `lifespan_safe_years` | 后续若要模拟寿元压力，应补派生公式 |
| `base_cultivation_yield` | HTML 仅用于估算收益上限 CP | 不应写入正式修炼公式作为权威收益单位 |
| EventStream | HTML 只估算概率与事件密度，不生成事件实例 | 正式事件系统仍需维护事件流、随机种子、触发上限、中断等级和结果包 |
| `max_triggers_per_batch` | HTML 有输入但当前主要用于字段保存，未参与概率表截断 | 后续可增加“期望触发超过上限”的警告或截断展示 |
| 局部时间档位 | HTML 使用单个 `inner_years_per_outer_day` 调试值 | 正式方案应使用 T0-T5 `LocalTimeDomainProfile` 表 |

## 11. 包内关联

| 文档 | 关系 |
| --- | --- |
| `../xiuxian_design_docs/03_数值设计/10_时间速度与局部时间域数值设计.md` | 正式权威；提供默认 32 小时、F1 默认 1.5 秒、47.55 外界年、50 小时 / 100 年 Debug 边界 |
| `../xiuxian_design_docs/03_数值设计/01_修为境界与期望游玩时间建模.md` | 正式权威；提供境界段、现实体验目标和阶段倍率参考 |
| `../xiuxian_design_docs/03_数值设计/02_修炼公式与数值设计.md` | 正式权威；正式修炼收益公式仍由该文档维护 |
| `../xiuxian_design_docs/03_数值设计/08_数值验算.md` | 正式权威；提供验算场景和 Debug 输出边界 |
| `修为时间数学模型_html调参器_v_0_1.html` | 工具关联；用于快速验算本文变量和公式，但不是正式设计权威 |
| `../inbox/design_changed_input/01_标准数值方案_v1_5.md` | 历史输入；不越过正式包成为当前权威 |
| `../inbox/design_changed_input/03_跨系统数值修改裁定_v1_5.md` | 历史输入；不越过正式包成为当前权威 |

## 12. 维护记录

2026-05-15：从原始 v1.5 草稿拆分出数学模型与 HTML 调参器关联稿，补齐 HTML 字段映射、推导公式、约束校验和对齐事项。

2026-05-16：迁移到 `docs/numeric_tuning`，明确调参器只是开发验算工具；同步用户裁决，将现实参考时长调试上限限制为 50 小时、外界年 Debug 极限限制为 100 年，并接受当前约 47.55 外界年基线。
