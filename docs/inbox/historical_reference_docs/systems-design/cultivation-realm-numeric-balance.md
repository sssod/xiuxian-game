# 修为年限、境界收益与阶段预算数值设计

状态：正式 canonical
更新日期：2026-05-08
来源主版本：数值设计 v0.1 consolidation

## 1. 系统定位

本文是修炼成长、境界推进、现实体验时间、世界产出预算的阶段调度、NPC 成长和突破准备数值的 canonical 主源。

本文采用以下基准口径：

```text
标准修士修炼年限 = 世界观背景墙 / NPC 默认成长尺度 / 寿元压力参考 / 数值底表
玩家现实体验时间 = 线性增长目标
玩家实际成长速度 = 世界产出预算的阶段调度、资源集中、灵地、丹药、宗门支持、功法掌握和主动决策共同压缩
```

关键结论：

1. 标准修士年限保留为背景墙，不直接换算成玩家现实等待时间。
2. 玩家主线推进现实耗时按境界线性增长，而不是指数增长。
3. 玩家资源充足路径与标准修士的倍率差距随境界提升而拉大。
4. 修炼数值以 `RealmSegmentBalance` 为根表，以目标达成时间反推基准兼容小时收益。
5. `cultivation_points` 继续作为稳定表现值和阈值字段，但调参核心使用标准化境界段进度。
6. 资源、功法、设施、节点灵气和宗门支持必须通过境界适配矩阵接入，不得提供无来源全局倍率。
7. 沙盒世界产出采用底层世界产出预算 + 阶段调度机制；预算打开提供机会，不自动赠送修为。
8. 高于当前预算境界的 NPC 默认只按背景速度成长，不发生明显修为提升或突破。
9. 大境界突破由准备质量和 B1 轮内决策共同决定，不是概率按钮。
10. 轮回价值围绕当前世代效率是否低于境界段基准判断，不由寿元或事件门槛半强迫触发。

## 2. 适用范围与边界

本文约束：

```text
境界结构；
标准背景年限；
玩家现实体验目标；
CP 阈值和标准化进度；
修炼收益反推公式；
行动、资源、功法、节点和宗门支持的相对效率；
状态压力；
世界产出预算的阶段调度；
NPC 与其他玩家成长分层；
突破准备初始分；
轮回效率判断；
数值表目录与验收指标。
```

本文不直接定义：

```text
最终数据库 schema；
最终战斗系统公式；
全部资源模板具体数值；
所有境界的完整事件库；
化神之后的完整内容平衡；
渡劫 / 飞升终局规则。
```

若本文与 S1 时间、S3 队列、S6 资源输入、S8 突破 B1 或运行时结果包合同冲突，优先保留现有运行时合同，并在本文中调整数值表达。

## 3. 时间换算基准

当前数值设计采用：

```text
1 游戏日 = 24 游戏小时
1 游戏年 = 360 游戏日
服务器最小结算单位 = 1 游戏小时
```

公开速度只影响现实等待，不改变数值单位：

| 速度 | 现实换算 | 数值含义 |
| --- | --- | --- |
| N1 | 15 秒 = 1 游戏小时 | 常规世界推进 |
| F1 | 2 秒 = 1 游戏日 | 长期低交互行动的压缩推进 |
| B1 | 60 秒 = 1 游戏小时 | 正式交锋、突破挑战、关键慢速轮 |
| P0 | 游戏时间不流动 | 全局同步保护或公共决策 |

按当前换算：

| 速度 | 1 游戏日 | 1 游戏年 |
| --- | --- | --- |
| N1 | 6 分钟 | 36 小时 |
| F1 | 2 秒 | 12 分钟 |
| B1 | 24 分钟 | 不用于长期修炼 |

裁决：

```text
N1 不是年级修炼的主承载速度。
F1 不是玩法目标，只是压缩低交互等待的手段。
玩家核心玩法是在 N1、事件、宗门、地图、市场、NPC 和风险选择中创造高价值闭关条件，再用 F1 快速消化。
```

## 4. 境界体系与 MVP 范围

MVP 建议重点平衡到化神，后续境界先保留表结构。

| 阶段编号 | 境界 | 小阶段建议 | MVP 状态 | 设计作用 |
| --- | --- | --- | --- | --- |
| 0 | 凡人 / 锻体 | 可选 | 可弱化 | 出身、教学、低阶 NPC |
| 1 | 炼气 | 1-9 层 | 必做 | 新手阶段，快速建立修炼反馈 |
| 2 | 筑基 | 初 / 中 / 后 / 圆满 | 必做 | 第一次大境界质变 |
| 3 | 金丹 | 初 / 中 / 后 / 圆满 | 必做 | 宗门骨干、资源经营成型 |
| 4 | 元婴 | 初 / 中 / 后 / 圆满 | 必做或后期 MVP | 区域强者、宗门高层 |
| 5 | 化神 | 初 / 中 / 后 / 圆满 | 第一阶段终局 | 世界层级跃迁前顶点 |
| 6 | 炼虚 | 初 / 中 / 后 / 圆满 | 扩展 | 中后期资料片 / 灵界层 |
| 7 | 合体 | 初 / 中 / 后 / 圆满 | 扩展 | 大世界强者 |
| 8 | 大乘 | 初 / 中 / 后 / 圆满 | 扩展 | 飞升前顶点 |
| 9 | 渡劫 / 飞升准备 | 劫数阶段 | 终局 | 不建议设计为纯经验条 |

## 5. 标准修士背景年限

标准修士年限用于世界背景、NPC 默认成长、寿元压力和数值底表，不直接决定玩家等待时间。

| 阶段 | 标准修士背景年限 | 用途 |
| --- | --- | --- |
| 炼气 -> 筑基 | 8 年 | 新手阶段背景尺度 |
| 筑基 -> 金丹 | 30 年 | 普通宗门弟子与精英分层 |
| 金丹 -> 元婴 | 80 年 | 宗门骨干到高层的分水岭 |
| 元婴 -> 化神 | 180 年 | 老祖级别成长尺度 |
| 化神 -> 炼虚 | 360 年 | 世界层级跃迁尺度 |
| 炼虚 -> 合体 | 600 年 | 高阶世界长期尺度 |
| 合体 -> 大乘 | 900 年 | 顶级势力尺度 |
| 大乘 -> 渡劫 | 1200 年 | 终局背景尺度 |
| 渡劫 / 飞升 | 不建议纯年限 | 应以劫数、因果、世界事件和终局挑战为主 |

## 6. 修为表现值 CP

继续使用 `cultivation_points` 作为内部累计稳定修为表现值。CP 主要用于：

```text
小境界 / 大境界阈值判断；
修炼收益、资源收益和闭关收益结算的表现映射；
NPC 成长速度与世界背景年限校准；
突破开启条件；
调试面板和高级详情展示。
```

CP 不直接线性换算成战斗力。

推荐 CP 阈值采用每个大境界圆满约 x5 的递增结构：

| 境界 | CP 范围 | 圆满阈值 | 标准背景年限 |
| --- | --- | --- | --- |
| 炼气 | 0-1,000 | 1,000 | 8 年 |
| 筑基 | 1,000-5,000 | 5,000 | 30 年 |
| 金丹 | 5,000-25,000 | 25,000 | 80 年 |
| 元婴 | 25,000-125,000 | 125,000 | 180 年 |
| 化神 | 125,000-625,000 | 625,000 | 360 年 |
| 炼虚 | 625,000-3,125,000 | 3,125,000 | 600 年 |
| 合体 | 3,125,000-15,625,000 | 15,625,000 | 900 年 |
| 大乘 | 15,625,000-78,125,000 | 78,125,000 | 1200 年 |
| 渡劫 / 飞升准备 | 78,125,000 以上 | 视终局规则 | 不建议纯 CP |

## 7. 玩家现实体验目标

玩家主线成长体验按境界线性增长。

| 阶段 | 标准背景年限 | 玩家现实目标 | 主动经营 / 选择 | F1 闭关消化 | 设计定位 |
| --- | --- | --- | --- | --- | --- |
| 炼气 -> 筑基 | 8 年 | 1-1.5 小时 | 35-60 分钟 | 20-40 分钟 | 新手阶段，快速给第一次质变 |
| 筑基 -> 金丹 | 30 年 | 2 小时左右 | 60-75 分钟 | 45-60 分钟 | 第一次完整资源循环 |
| 金丹 -> 元婴 | 80 年 | 3 小时左右 | 75-100 分钟 | 75-90 分钟 | 中期核心循环 |
| 元婴 -> 化神 | 180 年 | 4 小时左右 | 100-130 分钟 | 100-120 分钟 | 第一阶段大后期 |
| 化神 -> 炼虚 | 360 年 | 5 小时左右 | 120-160 分钟 | 120-150 分钟 | 世界层跃迁 |
| 炼虚 -> 合体 | 600 年 | 6 小时左右 | 150-190 分钟 | 150-180 分钟 | 高阶资源竞争 |
| 合体 -> 大乘 | 900 年 | 7 小时左右 | 180-230 分钟 | 170-210 分钟 | 顶级宗门 / 世界竞争 |
| 大乘 -> 渡劫 | 1200 年 | 8 小时左右 | 210-260 分钟 | 190-230 分钟 | 终局准备 |
| 渡劫 / 飞升 | 不建议纯年限 | 6-10 小时专题终局 | 事件、因果、劫数为主 | 少量闭关 | 终局挑战 |

MVP 优先目标：

```text
炼气 -> 筑基：1-1.5 小时
筑基 -> 金丹：约 2 小时
金丹 -> 元婴：约 3 小时
元婴 -> 化神：约 4 小时
```

## 8. 玩家有效修炼倍率

按 F1 换算，1 游戏年约等于 12 分钟现实时间。若玩家每阶段只进行有限 F1 闭关，则实际游戏年远低于标准背景年限。

| 阶段 | 标准背景年限 | 玩家 F1 闭关现实时间 | 对应实际游戏年 | 需要的有效修炼倍率 |
| --- | --- | --- | --- | --- |
| 炼气 -> 筑基 | 8 年 | 20-40 分钟 | 1.7-3.3 年 | x2.4-x4.8 |
| 筑基 -> 金丹 | 30 年 | 45-60 分钟 | 3.75-5 年 | x6-x8 |
| 金丹 -> 元婴 | 80 年 | 75-90 分钟 | 6.25-7.5 年 | x10.7-x12.8 |
| 元婴 -> 化神 | 180 年 | 100-120 分钟 | 8.3-10 年 | x18-x21.6 |
| 化神 -> 炼虚 | 360 年 | 120-150 分钟 | 10-12.5 年 | x28.8-x36 |
| 炼虚 -> 合体 | 600 年 | 150-180 分钟 | 12.5-15 年 | x40-x48 |
| 合体 -> 大乘 | 900 年 | 170-210 分钟 | 14.2-17.5 年 | x51-x63 |
| 大乘 -> 渡劫 | 1200 年 | 190-230 分钟 | 15.8-19.2 年 | x62-x76 |

推荐阶段倍率方向：

| 阶段 | 标准修士倍率 | 普通 NPC 预算后 | 重点 NPC / 竞争者 | 正常玩家 | 资源充足玩家 |
| --- | --- | --- | --- | --- | --- |
| 炼气 | x1 | x1.2-x1.8 | x2-x4 | x2-x4 | x3-x5 |
| 筑基 | x1 | x1.5-x2.5 | x3-x6 | x4-x7 | x6-x8 |
| 金丹 | x1 | x1.5-x3 | x4-x8 | x7-x10 | x10-x13 |
| 元婴 | x1 | x2-x4 | x5-x10 | x12-x16 | x18-x22 |
| 化神 | x1 | x2-x4 | x6-x12 | x20-x28 | x29-x36 |
| 炼虚 | x1 | x2-x5 | x8-x15 | x30-x40 | x40-x48 |
| 合体 | x1 | x2-x5 | x10-x18 | x40-x55 | x51-x63 |
| 大乘 | x1 | x2-x5 | x12-x20 | x50-x65 | x62-x76 |

这些倍率不是角色坐着吐纳时的无来源加成，而是资源、灵地、宗门支持、功法、机会窗口和风险承受的综合结果。

## 9. 核心对象：RealmSegment

`RealmSegment` 是从一个稳定修炼状态推进到下一个关键里程碑的最小数值成长段。

示例：

```text
炼气一层 -> 炼气二层
炼气九层 -> 炼气圆满
炼气圆满 -> 筑基开启资格
筑基准备期 -> 筑基成功并完成初步巩固
```

每个 `RealmSegment` 都有自己的：

```text
目标达成时间；
有效修炼小时占比；
标准化进度需求；
原始修为表现值；
功法掌握要求；
根基要求；
经脉压力上限；
伤势上限；
心魔风险上限；
突破模板；
轮回效率阈值。
```

不得用一条全局经验曲线覆盖全部境界。

## 10. 根表：RealmSegmentBalance

`RealmSegmentBalance` 是修炼数值模型根表。

```text
RealmSegmentBalance {
  segment_id: String
  realm_from: String
  minor_stage_from: String
  realm_to: String
  minor_stage_to: String
  segment_type: minor_progress | bottleneck | major_breakthrough | consolidation
  target_elapsed_hours_standard: number
  target_elapsed_hours_safe: number
  target_elapsed_hours_risk: number
  target_elapsed_hours_resource: number
  target_elapsed_hours_sect: number
  expected_cultivation_hour_ratio: number
  required_normalized_progress: number
  raw_cultivation_required: number
  required_method_mastery_norm: number
  required_foundation_min: number
  allowed_meridian_pressure_max: number
  allowed_injury_max: number
  allowed_mental_risk_max: number
  expected_breakthrough_rounds: int | null
  breakthrough_template_id: String | null
  min_efficiency_ratio: number
  max_efficiency_ratio: number
  low_efficiency_threshold: number
  high_efficiency_threshold: number
  reincarnation_hint_policy: String
}
```

字段裁决：

1. `target_elapsed_hours_standard` 是段基准，不是 `hour_tick` 本身。
2. `expected_cultivation_hour_ratio` 表示日历小时中有多少小时是真正有效修炼兼容小时。
3. `raw_cultivation_required` 只负责 CP 表现和日志映射。
4. `min_efficiency_ratio / max_efficiency_ratio` 是防止倍率爆炸的段级边界。
5. 轮回效率阈值跟随段配置，不做全局固定值。

## 11. 标准化进度与 CP 映射

`CultivationState` 应增加或派生：

```text
current_realm_segment_id: String
normalized_segment_progress: number
```

建议范围：

```text
0.0 = 当前境界段刚开始
1.0 = 达到该境界段推进目标，具备进入下一阶段或开启突破资格
>1.0 = 超额准备，可转化为突破初始优势、品质修正或稳定性修正
```

CP 映射：

```text
cultivation_points_gain = normalized_gain * raw_cultivation_required_s
```

因此炼气、筑基、金丹可以拥有不同量级 CP，但调参始终看 `normalized_segment_progress`。

## 12. 基准收益反推

设：

```text
s = 当前 RealmSegment
T_s = target_elapsed_hours_standard
U_s = expected_cultivation_hour_ratio
P_s = required_normalized_progress，默认 1.0
```

日历基准推进率：

```text
calendar_benchmark_rate_s = P_s / T_s
```

有效修炼小时基准收益：

```text
compatible_hour_benchmark_rate_s = P_s / (T_s * U_s)
```

若某境界段目标 30 游戏日完成：

```text
T_s = 720 小时
U_s = 0.60
P_s = 1.0
calendar_benchmark_rate_s = 1 / 720
compatible_hour_benchmark_rate_s = 1 / 432
```

含义：

```text
标准路径 720 个日历小时完成该段；
其中约 432 个小时是真正有效修炼小时；
每个有效修炼小时获得 1/432 的标准化进度。
```

## 13. 每小时修炼结算

每个兼容小时的核心公式：

```text
normalized_gain_per_compatible_hour =
  B_s
  * A_action
  * Q_aptitude
  * M_method
  * K_mastery
  * N_node_aura
  * F_facility
  * R_resource
  * S_sect_support
  * P_state_penalty
  * C_competition_or_window
```

其中：

```text
B_s = compatible_hour_benchmark_rate_s
```

修正项：

| 项 | 含义 |
| --- | --- |
| `A_action` | 当前行动类型效率，例如闭关、吐纳、显式托管、自动兜底 |
| `Q_aptitude` | 资质修正 |
| `M_method` | 主修功法对当前境界段的适配度 |
| `K_mastery` | 功法掌握度修正 |
| `N_node_aura` | 地图节点灵气对当前境界段的适配度 |
| `F_facility` | 洞府、静室、阵法等设施支持 |
| `R_resource` | 丹药、灵材、符箓、`ActiveResourceEffect` 等资源效果 |
| `S_sect_support` | 宗门资源、护法、权限、库存支持 |
| `P_state_penalty` | 伤势、心魔、经脉压力、寿元压力等惩罚 |
| `C_competition_or_window` | 秘境窗口、节点争夺、资源枯竭等动态影响 |

所有修正项先计算原始效率倍率，再按当前段边界裁剪：

```text
efficiency_ratio_raw =
  A_action
  * Q_aptitude
  * M_method
  * K_mastery
  * N_node_aura
  * F_facility
  * R_resource
  * S_sect_support
  * P_state_penalty
  * C_competition_or_window

efficiency_ratio = clamp(
  efficiency_ratio_raw,
  min_efficiency_ratio_s,
  max_efficiency_ratio_s
)

normalized_gain = B_s * efficiency_ratio * compatible_hours
```

## 14. 行动相对效率

行动类型不直接写死 raw 修为收益，只提供相对当前境界段基准的效率倍率。

```text
ActionCultivationProfile {
  action_type: String
  source: explicit_player | timeout_managed | system_fallback
  valid_segment_tags: Array
  compatible_hour_policy: full | partial | none
  base_efficiency_ratio: number
  f1_eligible: bool
  event_interrupt_policy: String
  pressure_gain_ratio: number
  risk_exposure_ratio: number
  resource_slot_count: int
  min_duration_hours: number
  max_duration_hours: number | null
}
```

初始方向：

| 路径 / 行动 | 相对基准效率方向 |
| --- | --- |
| 标准主动路径 | 约 1.00 |
| 安全低风险路径 | 0.65-0.90 |
| 资源投入路径 | 1.20-1.70 |
| 高风险节点路径 | 1.30-2.20 |
| 宗门支持路径 | 1.10-1.60 |
| 显式托管 | 0.20-0.50 |
| 自动兜底 | 0.05-0.20 |

裁决：

```text
闭关修炼可参与 F1，并可接资源输入。
普通吐纳风险低但效率低于标准主动路径。
显式托管安全、低关注、低收益，满足条件时可参与 F1。
自动兜底极低收益，不消耗关键资源，force_speed=N1，f1_eligible=false。
休整主要恢复伤势、心魔、经脉压力，不作为成长主路径。
```

## 15. 境界适配矩阵

功法、资源、设施、节点灵气和宗门支持共用境界适配矩阵。

```text
RealmInputFitMatrix {
  input_type: method | resource | facility | node_aura | sect_support
  input_grade: int
  segment_realm_grade: int
  tag_match_policy: String
  efficiency_multiplier: number
  contribution_cap_ratio: number
  waste_ratio: number
  pressure_modifier: number
  side_effect_risk: number
  breakthrough_relevance: number
}
```

初始方向：

| 输入品阶 vs 境界段 | 效率 | 贡献上限 | 浪费 | 压力 / 反噬 |
| --- | --- | --- | --- | --- |
| 低 2 阶 | 极低 | 极低 | 高 | 低 |
| 低 1 阶 | 低 | 低 | 中 | 低 |
| 同阶 | 标准 | 高 | 低 | 低 |
| 高 1 阶 | 高 | 高 | 中 | 中 |
| 高 2 阶以上 | 较高但不稳定 | 中 | 高 | 高 |

高阶资源不应简单碾压。它可以提高效率，但应通过浪费、经脉压力、相性风险、突破副作用限制。

## 16. 资源效果定价

资源不写成固定 raw 修为加成，而应折算为：

```text
在适配境界段内，节省多少基准兼容小时；
最多贡献当前境界段进度的多少比例；
增加或降低多少经脉压力；
是否影响突破 success_score 或 quality_score。
```

```text
ResourceEffectBalance {
  resource_template_id: String
  resource_grade: int
  valid_segment_tags: Array
  effect_mode: progress_bonus | rate_multiplier | breakthrough_modifier | pressure_control | injury_recovery | aura_stabilizer
  benchmark_hours_saved: number | null
  normalized_progress_bonus: number | null
  rate_multiplier: number | null
  compatible_hours: int
  contribution_cap_ratio: number
  meridian_pressure_delta: number
  mental_risk_delta: number
  foundation_delta: number
  breakthrough_success_delta: number
  breakthrough_quality_delta: number
  residual_policy: String
  stack_policy: String
}
```

若资源定义为：

```text
benchmark_hours_saved = H
```

则：

```text
normalized_progress_bonus = H * compatible_hour_benchmark_rate_s
```

资源包不直接给等级，而是提供：

```text
effective_cultivation_years
compatible_hours
risk_modifier
meridian_pressure_delta
method_mastery_delta
breakthrough_quality_modifier
```

## 17. 状态压力

经脉压力是高效率的代价，不是单纯惩罚。

```text
StatePressureModel {
  segment_id: String
  pressure_from_overbenchmark_rate: number
  pressure_from_resource_grade_gap: number
  pressure_from_risky_node: number
  pressure_decay_rest_per_hour: number
  pressure_decay_facility_per_hour: number
  pressure_penalty_curve_id: String
  breakthrough_risk_curve_id: String
}
```

压力生成：

```text
over_rate = max(0, efficiency_ratio - 1.0)

meridian_pressure_gain =
  over_rate * pressure_from_overbenchmark_rate
  + resource_pressure
  + node_pressure
  + method_mismatch_pressure
```

状态惩罚：

```text
P_state_penalty =
  1 / (1 + lambda1 * meridian_pressure + lambda2 * injury + lambda3 * mental_risk)
```

设计取舍：

```text
低效安全修炼：压力低，但时间慢。
高效资源冲刺：时间快，但压力高。
高风险灵地：效率高，但事件和伤势风险高。
宗门设施：不一定大幅加速，但能降低压力或提高上限。
```

## 18. 地图节点支持

地图节点不是简单收益加成点，而是境界段支持环境。

```text
NodeRealmSupport {
  node_id: String
  segment_tags_supported: Array
  aura_grade: int
  aura_density: number
  aura_affinity_tags: Array
  base_node_aura_ratio: number
  capacity_compatible_characters: int
  depletion_per_compatible_hour: number
  regen_per_world_hour: number
  risk_per_world_hour: number
  event_density_per_world_hour: number
  opportunity_window_modifier: number
  competition_policy: String
}
```

节点收益：

```text
N_node_aura =
  fit(node.aura_grade, segment.realm_grade, node.aura_tags, method.tags)
  * capacity_modifier
  * depletion_modifier
  * visibility_or_control_modifier
```

多人竞争通过节点资源被采集、节点被封锁、机会窗口提前触发、后手改变节点状态、宗门控制权变化和资源再生速率变化改变实际收益率。

## 19. 宗门支持

宗门支持不应是免费全局倍率，而应影响资源供给、环境供给、风险控制、突破支持、节点访问和情报可见性。

```text
SectSupportBalance {
  support_id: String
  support_type: resource_access | facility_access | protector | method_access | node_access | intelligence
  required_rank: String
  required_contribution: number
  inventory_cost: Dictionary
  npc_support_required: Array
  valid_segment_tags: Array
  efficiency_cap_increase: number
  pressure_reduction: number
  breakthrough_success_delta: number
  breakthrough_quality_delta: number
  benchmark_hours_saved: number
  public_visibility_risk: number
}
```

宗门支持必须能追溯到宗门库存、设施权限、NPC 支持、宗门 AI 结果或事件结果，不得作为无来源角色光环。

## 20. 世界产出预算与阶段预算机制

预算设定继承旧版经济、地图和物品产出文档中的世界产出预算。阶段预算不是新预算体系，也不覆盖资源流转旧设定；它只是把底层世界产出预算按玩家境界推进进行解锁、分配和节奏调度。

底层口径：

```text
世界产出预算控制“世界凭空投放多少资源、物品和机会”；
资源池 / 节点产能控制“资源从哪里来”；
资产容器和日志控制“资源现在在哪里、被谁获得、如何消耗”；
阶段预算控制“哪个境界阶段的资源机会开始稳定进入世界”。
```

建议运行时保留一个底层预算账本：

```text
WorldProductionBudgetState {
  item_budget_tiers: Dictionary<RealmOrTier, WorldItemBudgetTier>
  resource_budgets: Dictionary<String, WorldResourceBudget>
  current_macro_period_id: String
  generation_ledger_refs: Array
}
```

物品预算帽按阶级独立维护：

```text
WorldItemBudgetTier {
  tier_code: String
  accumulated_value: number
  max_accumulated_value: number
  generation_rate_by_reach_state: Dictionary
  reserved_value: number
  last_update_world_day: int
  last_update_world_hour: int
}
```

地图和资源系统使用资源投放预算：

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

阶段预算状态只记录当前世界按境界稳定开放到哪里，以及如何把境界预算切片映射到底层资源、物品和机会预算。

```text
WorldStageBudgetState {
  active_budget_realm: Realm
  unlocked_realm_history: Array
  unlocked_by_character_refs: Array
  current_macro_period_id: String
  budget_pools: Dictionary<Realm, RealmBudgetPool>
  next_realm_leakage_rate: number
  catchup_policy: Dictionary
  high_realm_npc_progress_policy: Dictionary
}
```

每个境界对应一个预算池：

```text
RealmBudgetPool {
  realm: Realm
  total_budget_points_per_macro_period: number
  production_budget_refs: Array
  node_resource_budget: number
  sect_inventory_budget: number
  market_trade_budget: number
  opportunity_window_budget: number
  npc_personal_budget: number
  method_carrier_budget: number
  breakthrough_material_budget: number
  active: bool
}
```

预算激活规则：

```text
on_major_breakthrough_success(character, new_realm):
  if character.is_player_controlled
     and new_realm > WorldStageBudgetState.active_budget_realm:
      WorldStageBudgetState.active_budget_realm = new_realm
      activate_budget_pool(new_realm)
      schedule_budget_distribution(next_macro_period)
```

裁决：

```text
世界产出预算是底层资源流转和物品生成预算帽。
阶段预算是世界产出预算的境界调度层，不是替代机制。
预算激活是系统事实，不等于公开传闻。
是否公开某玩家突破，由可见性、宗门传闻、玩家选择和事件结果决定。
预算打开提供资源机会，不自动发放修为。
预算投放必须进入资源池、资源槽、机会窗口、资产容器或事件锁定奖励，不得绕开资产日志。
```

## 21. 阶段预算投放

推荐每个阶段预算按以下方向投放。表中比例是境界调度建议；实际投放必须从 `WorldProductionBudgetState` 中对应的 `WorldResourceBudget` 或 `WorldItemBudgetTier` 预留 / 扣除，并通过地图、经济或事件系统落地。

| 预算出口 | 建议占比 | 作用 |
| --- | --- | --- |
| 节点资源槽 | 35%-45% | 灵草、矿材、灵脉波动、妖兽材料、秘境产物 |
| 宗门库存 / 任务 | 20%-25% | 宗门资源申请、护法、丹药、功法载体 |
| 市场 / 交易 | 10%-15% | 坊市、商队、黑市、拍卖 |
| 机会窗口 / 事件 | 15%-20% | 秘境窗口、遗迹、机缘事件、争夺事件 |
| NPC 个人库存 | 5%-10% | NPC 可交易、可赠予、可争夺、可掉落资源 |

预算不应瞬间刷满，而应在 1-3 个宏观周期内逐渐显现：

```text
突破当刻：个人结果、宗门反应、少量相关机会。
下一个宏观周期：节点资源槽开始出现新阶段资源。
第二个宏观周期：宗门库存、市场、NPC 资源开始扩散。
第三个宏观周期：该阶段资源成为稳定世界预算。
```

扣除与落地规则：

```text
RealmBudgetPool 分配境界阶段份额；
WorldResourceBudget / WorldItemBudgetTier 记录预留、花费和剩余额度；
ResourcePool / NodeResourceSlot 表示自然产能或可采资源量；
AssetContainer 表示已经实例化并归属明确的资产；
BudgetValue / V_world_budget 用于扣除世界生成预算，不等于市场价格。
```

预算不在隐性候选生成时消耗，而在资源、物品或奖励进入玩家、宗门、NPC、市场、节点显性库存或事件锁定奖励时消耗。出售、拆解、销毁、上交、损坏或消耗不返还世界生成预算。

## 22. 先锋资源

为了让第一个突破到新境界的玩家合理成立，需要区分先锋资源和阶段预算。

先锋资源是突破前就能少量获得的下一阶段关键资源。

```text
next_realm_leakage_rate = 5%-10%
```

来源：

```text
高风险节点；
一次性秘境；
宗门特殊申请；
师承任务；
遗迹；
黑市；
强敌掉落；
后手遗产；
小概率事件。
```

先锋资源仍必须来自底层世界产出预算、已存在资产、事件锁定奖励、后手遗产或专属资源池。`next_realm_leakage_rate` 只是允许少量下一阶段资源提前进入世界，不允许无限刷新，也不允许绕过预算价值、来源日志和可见性记录。先锋资源不足以让整个世界大量成长，但足以让主动玩家集中资源完成突破。

## 23. NPC 与其他玩家成长分层

高于当前预算境界的 NPC：

```text
npc.realm > WorldStageBudgetState.active_budget_realm
```

规则：

```text
只走标准修士背景速度；
无法稳定获得本境界所需资源；
每个宏观周期修为进度变化很小；
默认不发生小境界晋升；
默认不发生大境界突破；
除非剧情、后手、宗门重大事件或专属资源池触发。
```

建议：

```text
visible_progress_cap_per_macro_period = 0.1%-0.5%
breakthrough_allowed = false by default
minor_stage_advance_allowed = scripted_only
```

不高于当前预算境界的 NPC：

```text
npc.realm <= WorldStageBudgetState.active_budget_realm
```

可以吃到阶段预算，但仍低于玩家主动路径倍率。

| NPC 类型 | 预算打开后的有效修炼倍率 |
| --- | --- |
| 普通 NPC | x1.2-x2 |
| 宗门重点培养 NPC | x2-x4 |
| 天才 / 亲传 / 关键竞争者 | x4-x8 |
| 剧情级竞争者 | x8-x12，但需要显式记录来源 |

其他玩家：

```text
低参与玩家：x2-x4
正常参与玩家：x5-x12
资源集中玩家：接近领先玩家倍率
显式托管玩家：倍率明显降低，错过高价值机会
```

## 24. 小境界节奏

炼气 1-9 层不均分，前期反馈更快，后期形成第一次瓶颈。

| 炼气层数 | 累计进度 |
| --- | --- |
| 1 层 | 3% |
| 2 层 | 7% |
| 3 层 | 12% |
| 4 层 | 18% |
| 5 层 | 27% |
| 6 层 | 39% |
| 7 层 | 55% |
| 8 层 | 75% |
| 9 层 / 圆满 | 100% |

筑基以上：

| 小阶段 | 境界内 CP 进度 | 设计含义 |
| --- | --- | --- |
| 初期 | 0%-25% | 刚入境界，战力质变但根基未厚 |
| 中期 | 25%-50% | 稳定期 |
| 后期 | 50%-80% | 主要战力成型 |
| 圆满 | 80%-100% | 准备突破，瓶颈 / 资源 / 风险成为核心 |

达到 80% 后：

```text
bottleneck_state = approaching
```

达到 100% 后：

```text
bottleneck_state = reached
允许玩家执行突破准备或开启大境界突破。
```

## 25. 突破承接

CP 或标准化进度达标只是开启条件。真正突破由 B1 挑战中的状态、资源、策略和轮内决策共同决定。

建议开启条件：

```text
normalized_segment_progress >= 1.0
method_mastery_norm >= required_method_mastery_norm
foundation_quality >= required_foundation_min
meridian_pressure <= allowed_meridian_pressure_max
injury <= allowed_injury_max
mental_risk <= allowed_mental_risk_max
location_allows_breakthrough == true
method_template_available == true
required_resource_available == true
```

`BreakthroughScoreBalance`：

```text
BreakthroughScoreBalance {
  breakthrough_template_id: String
  segment_id: String
  base_success_score: number
  base_quality_score: number
  required_rounds: int
  success_threshold: number
  quality_thresholds: Dictionary
  foundation_weight: number
  method_mastery_weight: number
  node_fit_weight: number
  resource_weight: number
  pressure_penalty_weight: number
  injury_penalty_weight: number
  round_decision_modifier_refs: Array
  failure_tags: Array
}
```

突破成功分：

```text
breakthrough_success_score =
  base_success_s
  + over_progress_bonus
  + method_mastery_bonus
  + foundation_bonus
  + node_aura_fit_bonus
  + facility_support_bonus
  + sect_protector_bonus
  + round_decision_bonus
  + round_resource_bonus
  - meridian_pressure_penalty
  - injury_penalty
  - mental_risk_penalty
  - resource_mismatch_penalty
```

突破品质分：

```text
breakthrough_quality_score =
  base_quality_s
  + foundation_bonus
  + method_fit_bonus
  + stable_resource_bonus
  + conservative_round_bonus
  - forced_breakthrough_penalty
  - high_pressure_penalty
  - severe_injury_penalty
```

突破应体现：

```text
成功 vs 品质；
速度 vs 根基；
资源消耗 vs 风险承担；
保守策略 vs 高品质追求；
继续准备 vs 立刻冲关。
```

## 26. 战斗力表现口径

突破成功后应立即提升，但提升来源不是 CP 瞬间暴涨，而是：

| 来源 | 占比感 | 具体变化 |
| --- | --- | --- |
| 境界倍率 | 40%-50% | `realm_power_multiplier` 进入新境界 |
| 属性质变 | 20%-30% | 体魄、神识、灵力上限、经脉承载上限提升 |
| 修为稳定度 | 10%-20% | 新境界 fullness 从低值起步，巩固后提高 |
| 术法 / 行动解锁 | 情境性强 | 飞行、婴火、神识离体、天地元气调用等 |

战斗力表现公式只能作为后续战斗数值的基准输入，不得绕过 S8 交锋模板：

```text
combat_power =
  base_stat_score
  * realm_power_multiplier[realm]
  * minor_stage_multiplier
  * foundation_quality_factor
  * method_mastery_factor
  * current_cultivation_fullness_factor
  * state_factor
  + equipment_spell_bonus
```

推荐境界倍率：

| 境界 | 战斗境界基准倍率 |
| --- | --- |
| 炼气 | 1 |
| 筑基 | 3 |
| 金丹 | 10 |
| 元婴 | 32 |
| 化神 | 100 |
| 炼虚 | 320 |
| 合体 | 1,000 |
| 大乘 | 3,200 |
| 渡劫 | 10,000 |

小阶段倍率：

| 小阶段 | 倍率 |
| --- | --- |
| 初期 | 1.00 |
| 中期 | 1.25 |
| 后期 | 1.55 |
| 圆满 | 1.90 |

## 27. 轮回效率判断

轮回价值由当前世代效率是否低于境界段基准决定，而不是由寿元或事件门槛粗暴触发。

```text
ReincarnationEfficiencyPolicy {
  segment_id: String
  cei_low_threshold: number
  cei_high_threshold: number
  window_hours_for_evaluation: number
  carryover_value_unit: benchmark_hours_saved
  max_low_quality_loop_reward: number
  diminishing_return_curve_id: String
  forced_reincarnation_by_lifespan: false
  forced_reincarnation_by_event_gate: false
  high_efficiency_continuation_policy: String
}
```

当前世代效率指数：

```text
CEI_s =
  actual_effective_milestone_progress_rate_s
  / calendar_benchmark_rate_s
```

有效进度建议：

```text
effective_progress =
  w_cultivation * normalized_segment_progress
  + w_method * method_mastery_norm
  + w_foundation * foundation_readiness_norm
  + w_resource * resource_bank_value_norm
  + w_sect * sect_support_value_norm
  + w_node * node_position_value_norm
  - w_injury * injury_cost_norm
  - w_pressure * meridian_pressure_cost_norm
  - w_mental * mental_risk_cost_norm
```

CEI 解释：

| CEI 区间 | 含义 | 轮回价值 |
| --- | --- | --- |
| `CEI < low_threshold` | 当前世代效率低于基准 | 轮回应具有明显效率修正价值 |
| `low_threshold <= CEI <= high_threshold` | 接近标准路径 | 继续或轮回都可行，取决于目标 |
| `CEI > high_threshold` | 当前世代效率高于基准 | 不应被寿元或事件门槛半强迫轮回 |

寿元进入继续可行性判断，而不是强制重开按钮：

```text
expected_hours_to_next_milestone =
  remaining_progress / projected_calendar_rate
  + expected_breakthrough_rounds
  + expected_recovery_or_consolidation_hours

life_budget_ratio =
  remaining_lifespan_hours / expected_hours_to_next_milestone
```

即使 `life_budget_ratio < 1.0`，也不应直接强制轮回。玩家仍可选择延寿资源、宗门支持、冒险抢节点、降低突破品质目标、布置后手后轮回或继续硬冲。

## 28. 结果包与日志

每次修炼结算应能输出：

```text
CultivationTickResult {
  world_day: int
  world_hour: int
  segment_id: String
  command_id: String
  compatible_hours: number
  base_benchmark_rate: number
  raw_efficiency_ratio: number
  clamped_efficiency_ratio: number
  normalized_gain: number
  cultivation_points_gain: number
  normalized_segment_progress_before: number
  normalized_segment_progress_after: number
  meridian_pressure_delta: number
  method_mastery_delta: number
  resource_effects_consumed: Array
  node_aura_effect: Dictionary
  facility_effect: Dictionary
  sect_support_effect: Dictionary
  visible_summary: String
  debug_formula_trace: Dictionary
}
```

世界产出预算、阶段调度、修炼收益、资源效果、节点变化、宗门支持、NPC 成长和突破初始分都必须通过 `ResultPackage` 或可引用的明细结构进入 `TimelineReplay`。

## 29. UI 展示

正式 UI 不建议默认展示大量 CP 数字。推荐默认显示：

```text
当前境界与小阶段；
当前瓶颈状态；
预计还需游戏时间；
预计还需现实时间；
本次闭关预计有效修炼年收益；
当前资源包贡献；
经脉压力 / 心魔 / 伤势风险；
是否具备 F1 条件；
是否存在 1 游戏日内到期待决事项。
```

调试面板或高级详情可显示：

```text
cultivation_points
normalized_segment_progress
effective_years_gained
各倍率明细
世界产出预算来源与阶段调度来源
资源包消耗记录
CP 转化结果
CEI
```

## 30. MVP 实施范围

MVP 先做：

```text
1. 境界到化神为止；
2. 标准年限表；
3. CP 阈值表；
4. RealmSegmentBalance 与自动生成 RealmBenchmarkRate；
5. normalized_segment_progress；
6. effective_cultivation_years 中间量；
7. 资源包绑定闭关行动；
8. WorldProductionBudgetState 的最小账本；
9. WorldStageBudgetState 的最小境界调度层；
10. NPC 按预算境界分层成长；
11. 玩家现实目标：1.5h / 2h / 3h / 4h；
12. F1 闭关消化 + N1 事件选择 + B1 突破挑战；
13. UI 显示游戏时间、现实时间、有效修炼收益和风险。
```

MVP 暂缓：

```text
1. 化神以后的完整内容平衡；
2. F2 或更高速宏观闭关；
3. 复杂 NPC 自动竞争 AI；
4. 全市场经济深度模拟；
5. 多阶段劫数终局；
6. 极端跨世资源套利；
7. 所有境界的完整事件库。
```

首版可模拟闭环：

```text
创建角色
-> 修炼
-> 使用资源
-> 产生经脉压力
-> 休整或继续冲刺
-> 达到瓶颈
-> 申请宗门支持
-> 进入 B1 突破挑战
-> 成功 / 失败 / 受伤 / 根基变化
-> 判断继续修行或轮回价值
```

## 31. 验收指标

验收不看每小时收益是否好看，而看：

1. 每个 `RealmSegment` 的实际完成时间是否接近 `target_elapsed_hours_standard`。
2. 安全、资源、高风险、宗门路径是否落在各自目标时间区间。
3. 自动兜底是否明显低效，不能成为长期最优路线。
4. 显式托管是否安全低收益，能服务低关注，但不是最高效率。
5. 同一资源在不同境界段的价值是否自然衰减或产生浪费。
6. 高阶资源给低境界是否有收益，同时伴随浪费或压力。
7. 普通灵地是否会随境界提升失去核心价值。
8. 宗门支持是否改变上限、风险和资源可得性，而不是免费全局加成。
9. 突破是否由准备质量和 B1 决策共同决定，而不是概率按钮。
10. CEI 低于基准时，轮回是否明显提高下一世效率。
11. CEI 高于基准时，寿元和事件门槛是否不会半强迫玩家轮回。
12. 多人竞争是否通过节点、资源、窗口、宗门库存和后手改变实际效率。
13. 世界产出预算是否保留资源流转、物品预算帽、预算价值和非返还规则。
14. 阶段预算打开后是否只增加资源机会，而不是自动赠送修为。
15. 高于当前预算境界的 NPC 是否默认不会无来源晋升。

## 32. 后续待定问题

后续继续细化：

```text
1. 每个境界资源包的模板表；
2. 世界物品预算帽和资源投放预算的首版数值；
3. 阶段预算每个宏观周期的具体点数；
4. 节点资源槽如何从预算池抽样；
5. BudgetValue / V_world_budget 与物品价值表如何映射；
6. 宗门库存与玩家申请权限的关系；
7. NPC 预算后成长如何进入 TimelineReplay；
8. 玩家资源充足倍率如何避免被重复套利；
9. 小境界事件的触发频率；
10. 化神以后是否需要 F2 或事件制宏观推进；
11. 渡劫 / 飞升阶段如何从纯修为转向劫数、因果和世界事件；
12. 战斗表现倍率如何接入正式战斗模板。
```

## 33. 来源与裁决

吸收来源：

```text
修为年限_现实时间_阶段预算数值方案_v0.1
核心数值设计方案_境界基准收益模型_v0.1
v2.3 01_共享日历_房间推进_权威结算
v2.3 02_角色真灵轮回_修炼养成
v2.3 03_个人行动队列_移动通行_托管
v2.3 04_地图节点_世界演化
v2.3 05_宗门组织_库存_宗门AI持续行动
v2.3 06_经济物品资产_NPC持久化
v2.3 08_事件突破战斗时间规则
v2.3 01_运行时状态_数据模型_结果包
[已过时]物品产出与获得的核心体验草稿 0426
[已过时]沙盒世界演化与地图节点生成规则草稿 0427
[已过时]经济系统框架性设计草稿 0427
[已过时]NPC持久化、库存与经济定位框架草稿 0426
```

裁决：

| 采用方案 | 废弃或限制方案 | 原因与实现影响 |
| --- | --- | --- |
| 标准修士年限作为背景墙和底表 | 把几十年 / 几百年直接换成玩家现实等待 | 保持世界尺度，同时避免挂机修仙 |
| 玩家现实目标按境界线性增长 | 后期现实时间指数膨胀 | 让高境界更重但仍可完成 |
| `RealmSegmentBalance` 作为数值根表 | 所有境界共用一个小时收益基准 | 境界段差异需要独立目标时间和适配 |
| `normalized_segment_progress` 作为调参核心 | 直接用 CP 膨胀值调全部曲线 | CP 用于表现，标准化进度用于稳定调参 |
| 资源价值折算 `benchmark_hours_saved` 和贡献上限 | 丹药、灵地、宗门支持写死 raw 修为 | 资源可跨境界适配并控制浪费 / 压力 |
| 世界产出预算保留物品预算帽、资源投放预算和资源池流转 | 把阶段预算当成唯一预算来源 | 旧设定的资源流转并未废弃；阶段预算只负责境界解锁和分配节奏 |
| 阶段预算随玩家首次大境界突破打开 | 世界无条件刷新所有高阶资源 | 让沙盒随玩家成长，同时避免高阶 NPC 无来源飞升 |
| 先锋资源 5%-10% 泄漏 | 先锋玩家必须等世界预算先打开 | 支持首个突破者靠冒险和集中投入成立 |
| 高于预算境界 NPC 默认背景速度 | 高阶 NPC 随玩家时间自然继续晋升 | 保持世界强者存在但不让其无来源滚雪球 |
| 突破初始分承接准备，结果由 B1 决策决定 | 单次概率按钮或开启时消耗所有资源 | 与 `FormalEncounterState` 和轮内资源消耗合同一致 |
| CEI 判断轮回价值 | 寿元或事件门槛半强迫轮回 | 高效率世代继续修行必须合理，低效率世代轮回才显著有价值 |
