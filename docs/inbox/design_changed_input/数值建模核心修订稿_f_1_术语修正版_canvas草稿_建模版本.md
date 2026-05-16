# 数值设计｜修为境界、F1 批量结算与洞天局部时间建模｜核心修订稿 v1.5 草案

## 0. 修订摘要

本稿用于修订《01\_修为境界与期望游玩时间建模》中与现实时长、外界世界日历、洞天局部时间、寿元压力、修炼资源消耗和长时段低交互结算相关的核心口径。

本次修订接受以下新裁决：

1. 曾尝试引入的独立宏观流年阶段若作为玩家可见阶段，会比原 F1 更不可靠：进入条件更复杂，且中途事件如何触发、是否退出、是否按预设处理都容易变成黑箱。
2. 原 F1 的优点应保留：进入门槛低、玩家容易理解、所有玩家都进入洞天修炼或其它长期低交互行动时自然生效。
3. 2 秒推进 1 游戏日若仍按 24 个小时 tick 逐小时结算，运算负担过大，尤其多人 + NPC + 世界资源 + 随机事件时不可持续。
4. 因此，本稿不再引入额外的玩家可见宏观阶段。玩家可见速度仍保留 F1；F1 内部使用批量结算、事件流采样和安全断点判断，避免逐小时全量 tick。
5. 玩家给出闭关承诺并不表示闭关期间无事件发生。事件仍然会在 F1 中触发；区别只是：可自动处理的事件进入结果摘要，需要玩家选择的事件会中断 F1 并切回 N1 / B1 / P0。

核心修订结论：

1. **修为境界建模终点**仍收束到 **大乘圆满并突破进入渡劫期**。渡劫期之后的劫数、因果、飞升和终局结算不纳入本文的修炼时间段。
2. **理论直线现实参考时长**仍暂定为 **32 小时**，用于标定“门槛满足时”的境界推进体验，不等于实际单局通关总时长。
3. **外界世界日历目标**调整为 **约 45-48 年**，验收范围为 **20-50 年**，且在该范围内越长越好。基准目标接近上限但不超过 50 年，用于支撑长期宗门兴衰、洞天定期开放、市场周期、NPC 成长与世界事件的沧桑感。
4. **角色主观修炼时间**由洞天 / 时间阵法 / 局部时间域承担，参考值约 **596 年**。寿元扣除按角色当前所在时间域判断：角色处于洞天 / 时间阵法 / 局部时间域内时，按主观修炼时间扣除；角色处于洞天外时，按共享外界世界日历扣除，不再受房间当前是 N1 还是 F1 的表现速度影响。药性、心魔、经脉压力和闭关风险也优先读取角色所在时间域。
5. **玩家可见速度状态保留为 N1 / F1 / B1 / P0**。不再新增任何独立宏观流年速度状态。
6. **F1 语义修订**：F1 是“房间处于长期低交互可批量结算状态”的外界日历高速推进。所有玩家处于洞天闭关、长行动、显式托管、行程、宗门职责或其它可自动结算状态时，房间可以进入 F1。
7. **F1 内部不按小时全量 tick**。系统改用 `BatchSettlementKernel`：按安全断点推进，确定性过程积分，随机事件用事件流 / 危险率采样，必要时只在事件附近展开局部小时结算。
8. **事件在 F1 中仍然会触发**。事件分为可摘要事件、可自动处理事件、软中断事件和硬中断事件。玩家预设只决定事件触发后的处理方式，不阻止事件发生。
9. **洞天必须消耗资源年**：洞天提供局部时间域、场地与部分环境，不等于免费修炼收益。有效修炼年数必须受资源包、丹药、聚灵阵、聚灵石、洞天灵气池、宗门护持、功法适配和寿元共同限制。
10. **阶段预算按外界时间刷新，不按洞天内时间刷新**。玩家在洞天内经历数百年，不会导致外界市场、宗门库存、节点资源和 NPC 成长刷新数百年。
11. **修行成长时间不等于角色生涯总时间，且不能用单一比例一刀切**。需要按角色所在时间域分配：洞天 / 时间阵法内的主观时间主要承载功法研习、道功修炼、巩固、恢复和局部闭关事件；洞天外的 F1 外界流年主要承载资源成熟、炼丹炼器、宗门职责、长期游历、等待洞天 / 秘境 / 大型投放窗口；N1 / B1 主要承载短途移动、交易、互动、现场探索、战斗和突破选择，不能强行折算成几十年消耗。
12. **功法研习与道功修炼比例保留为可调核心参数**。首版暂定 `method_study : dao_cultivation = 1 : 4`，即修行成长时间中 20% 用于功法研习、80% 用于道功修炼。这个比例主要作用于修行成长时间，不直接作用于全部生涯时间。
13. **轮回不保证缩短总通关时间**。合理轮回可以提高路线确定性、稳定性、成功率和结局质量，但由于世界资源可能不足，重修后实际总通关时间允许变长，用于等待世界资源产出、阶段预算积累和大型资源投放事件生成。

---

## 1. 四层时间模型

后续所有修炼、寿元、世界演化和多人同步必须区分四类时间：

| 时间层             | 字段建议                                                                             | 含义                                       | 主要读取系统                                     |
| --------------- | -------------------------------------------------------------------------------- | ---------------------------------------- | ------------------------------------------ |
| 现实游玩时间          | `real_elapsed_seconds` / `real_elapsed_hours`                                    | 玩家现实中花了多久                                | 体验时长、UI 预估、节奏验收                            |
| N1 / B1 现场外界时间  | `live_outer_world_hours`                                                         | 玩家正在处理地图、事件、战斗、突破、交易时同步流逝的外界时间           | 现场事件、短行动、交互节奏、正式交锋                         |
| F1 外界流年时间       | `f1_outer_world_days` / `f1_outer_years`                                         | 房间处于长期低交互状态时，高速推进的共享外界世界日历               | 定期洞天开放、宗门日程、市场刷新、节点再生、NPC 宏观成长、阶段预算        |
| 角色主观经历时间 / 修行时间 | `subjective_elapsed_years` / `subjective_cultivation_years` / `inner_time_years` | 角色在洞天、时间阵法、闭关局部时间中实际经历多久；其中只有一部分属于修行成长时间 | 寿元消耗、修行成长、功法研习、道功修炼、药性释放、心魔、经脉压力、功法熟练、突破准备 |

基本原则：

1. **现实时间决定玩家体验**：玩家不能为了修仙题材在现实中等待过久。
2. **N1 / B1 决定交互时的即时反馈**：玩家面对事件、战斗和选择时可以慢下来，不因外界日历目标而赶时间。
3. **F1 决定外界流年感**：季节、年份、宗门、市场、洞天窗口和世界预算可以在低交互阶段快速推进。
4. **主观时间决定修仙质感与寿元压力**：角色在洞天内真实修炼数百年，寿元与副作用按主观时间结算。
5. **寿元按角色所在时间域扣除**：角色在洞天 / 时间阵法 / 局部时间域内时，只按该局部时间域的主观时间扣寿，不关心外部世界此时处于 N1、F1、B1 或 P0；角色在洞天外时，按共享外界世界日历扣寿。
6. **世界预算读取外界时间，不读取洞天内时间**：洞天内百年不等于外界刷新百年。

---

## 2. 数学变量、参数与约束总表

本章用于把本文中的输入变量、可调参数、目标期望值、因变量和约束项集中定义。后续章节中的速度、局部时间域、资源年、事件流和结果包都应回读本章，避免把“可调输入”“模型校准目标”和“公式推导结果”混作同一类变量。

### 2.1 分类定义

| 分类         | 记号  | 定义                                            | 调整权限               | 示例                                                                                    |
| ---------- | --- | --------------------------------------------- | ------------------ | ------------------------------------------------------------------------------------- |
| 外部强约束      | `H` | 来自当前裁决、正式系统口径或跨系统一致性要求；本方案只能服从，不能在内部调参时改写     | 不可在本文内任意修改         | 速度状态只保留 N1 / F1 / B1 / P0；阶段预算按外界时间刷新                                                 |
| 可调输入变量     | `X` | 设计者可以直接调整的模型输入，用于反推体验节奏、时间分配、资源消耗和事件密度        | 可调                 | `f1_seconds_per_outer_day`、`local_domain_growth_ratio`、`method_study_ratio`           |
| 模型输出的可调期望值 | `T` | 用于校准模型的目标值或验收区间；它们不是单次运行的结算结果，但可以作为版本调参目标被改写9 | 可调，但应通过版本裁决修改      | 32 小时现实参考、45-48 外界年、596 局部主观年                                                         |
| 因变量 / 推导变量 | `Y` | 由 `H`、`X`、`T` 与运行时状态经公式推导得到；通常不应被手动直接填写       | 不直接调，随输入变化         | `F1_outer_years`、`local_dao_cultivation_years`、`unsupported_inner_years`              |
| 方案内生约束     | `C` | 本方案为了数学一致性设定的等式、不等式、优先级和守恒关系                  | 原则上不可破坏；可在新版本中整体重构 | `N1_ratio + F1_ratio + B1_ratio = 1`，`method_study_ratio + dao_cultivation_ratio = 1` |

基本使用原则：

```text
先固定 H 与 T；
再选择 X；
由公式计算 Y；
最后用 C 检查模型是否自洽。
```

若某个 `Y` 不符合目标，不应直接篡改 `Y`，而应回到对应的 `X` 或 `T` 调整。

### 2.2 外部强约束 `H`

| 编号    | 强约束                           | 数学 / 系统含义                          | 本方案影响                                                   |
| ----- | ----------------------------- | ---------------------------------- | ------------------------------------------------------- |
| `H01` | 修为时间建模终点为“大乘圆满 → 突破进入渡劫期”     | 终点之后的劫数、飞升、终局结算不进入本模型              | 本文不反推渡劫后的成长时间                                           |
| `H02` | 玩家可见速度状态只保留 N1 / F1 / B1 / P0 | 不新增独立宏观流年阶段                        | F1 承担长期低交互高速推进                                          |
| `H03` | 速度优先级为 `P0 > B1 > N1 > F1`    | 高优先级状态覆盖低优先级状态                     | F1 只能在无交锋、无公共暂停、无强交互阻塞时启用                               |
| `H04` | F1 内部不得逐小时全量 tick             | 不允许 `for each outer_hour` 全量刷新所有对象 | 必须使用批量结算、断点推进和事件流采样                                     |
| `H05` | 闭关承诺不吞掉事件                     | 事件仍会触发，只是处理方式可能自动化                 | EventStream 是 F1 的必要组成                                  |
| `H06` | 寿元按角色所在时间域扣除                  | 洞天内按主观时间；洞天外按共享外界日历                | 不能用房间当前速度直接决定寿元消耗                                       |
| `H07` | 阶段预算按外界时间刷新                   | 洞天内主观百年不等于外界预算百年                   | 资源、市场、NPC 宏观成长读取外界时间                                    |
| `H08` | 洞天 / 时间阵法不等于免费收益              | 局部时间域只提供时间和场地，修炼收益仍受资源年限制          | 必须计算有效修炼年与资源不足年份                                        |
| `H09` | 短交互行为不承担大规模年份消耗               | 短途移动、交易、互动、现场探索主要吃 N1 / B1 现实预算    | 非修行外界流年主要来自等待、生产、长期游历、宗门职责                              |
| `H10` | 高风险不可逆事件不能被普通预设自动处理           | 突破、转世、叛宗、强 PvP、稀有资源消耗等必须人工确认       | 这些事件会硬中断 F1 或进入 B1 / P0                                 |
| `H11` | 轮回不保证缩短总通关时间                  | 轮回提高稳定性、成功率和结局质量，但资源等待可能拉长总时长      | 不得设定 `reincarnation_total_time < single_life_time` 为硬约束 |

### 2.3 可调输入变量 `X`

#### 2.3.1 现实时间与速度分配输入

| 变量                          | 默认值  | 单位       | 含义                          | 主要影响                   |
| --------------------------- | ---- | -------- | --------------------------- | ---------------------- |
| `N1_real_ratio`             | 0.66 | 比例       | 32 小时中分配给 N1 现场交互的现实时间占比    | 现场交互密度、事件处理余量          |
| `F1_real_ratio`             | 0.22 | 比例       | 32 小时中分配给 F1 长期低交互推进的现实时间占比 | 外界流年长度、洞天窗口数量          |
| `B1_real_ratio`             | 0.12 | 比例       | 32 小时中分配给 B1 关键慢速轮的现实时间占比   | 战斗、突破、关键交锋体验           |
| `n1_seconds_per_outer_hour` | 15   | 秒 / 外界小时 | N1 现场状态的外界时间推进速度            | N1 外界年贡献               |
| `f1_seconds_per_outer_day`  | 1.5  | 秒 / 外界日  | F1 长期低交互状态的外界时间推进速度         | F1 外界年贡献，是外界年目标的核心调参杠杆 |
| `b1_seconds_per_outer_hour` | 60   | 秒 / 外界小时 | B1 慢速交锋状态的外界时间推进速度          | B1 外界年贡献               |

内生约束：

```text
N1_real_ratio + F1_real_ratio + B1_real_ratio = 1
N1_real_ratio >= 0
F1_real_ratio >= 0
B1_real_ratio >= 0
```

#### 2.3.2 分域时间分配输入

| 变量                                    | 默认值       | 单位 | 含义                           | 主要影响                 |
| ------------------------------------- | --------- | -- | ---------------------------- | -------------------- |
| `local_domain_growth_ratio`           | 0.70      | 比例 | 局部时间域主观时间中用于修行成长的比例          | 功法研习年、道功修炼年          |
| `local_domain_support_ratio`          | 0.30      | 比例 | 局部时间域主观时间中用于支持行为的比例          | 疗伤、巩固、恢复、心魔处理、局部事件余量 |
| `method_study_ratio`                  | 0.20      | 比例 | 修行成长时间中用于功法研习的比例             | 功法熟练、法门解锁、参悟节奏       |
| `dao_cultivation_ratio`               | 0.80      | 比例 | 修行成长时间中用于道功修炼的比例             | 修为推进、资源消耗、经脉压力       |
| `outer_f1_ordinary_cultivation_ratio` | 0.10-0.20 | 比例 | 洞天外 F1 外界流年中用于普通修炼 / 低阶修炼的比例 | 前期无洞天修炼、低阶静室修炼       |

内生约束：

```text
local_domain_growth_ratio + local_domain_support_ratio = 1
method_study_ratio + dao_cultivation_ratio = 1
0 <= outer_f1_ordinary_cultivation_ratio <= 1
```

#### 2.3.3 局部时间域与洞天输入

| 变量                                  | 默认值 / 范围   | 单位        | 含义               | 主要影响           |
| ----------------------------------- | ---------- | --------- | ---------------- | -------------- |
| `inner_years_per_outer_day`         | 按 T0-T5 配置 | 主观年 / 外界日 | 局部时间域相对外界日历的时间倍率 | 洞天内主观时间生成速度    |
| `max_inner_years_per_entry`         | 按 T0-T5 配置 | 主观年       | 单次进入局部时间域的主观年上限  | 单次闭关上限、出关断点    |
| `resource_year_capacity_multiplier` | 按洞天配置      | 倍率        | 洞天对资源年承载效率的修正    | 同一资源包可支撑的有效修炼年 |
| `lifespan_pressure_modifier`        | 按洞天配置      | 倍率        | 洞天对寿元压力的修正       | 寿元安全年、闭关风险     |
| `mental_risk_per_inner_year`        | 按洞天配置      | 风险 / 主观年  | 心魔或精神风险的年增长率     | 心魔阈值断点、事件流危险率  |
| `meridian_pressure_per_inner_year`  | 按洞天配置      | 压力 / 主观年  | 经脉压力的年增长率        | 降速、停药、巩固根基断点   |
| `fuel_cost_per_inner_year`          | 按洞天配置      | 成本 / 主观年  | 时间阵法或洞天运行燃料消耗    | 资源耗尽断点         |
| `maintenance_cost_per_outer_day`    | 按洞天配置      | 成本 / 外界日  | 局部时间域维持成本        | 外界日历推进下的维护压力   |

#### 2.3.4 资源年与收益输入

| 变量                                 | 默认值 / 范围     | 单位      | 含义               | 主要影响          |
| ---------------------------------- | ------------ | ------- | ---------------- | ------------- |
| `planned_inner_years`              | 行动输入         | 主观年     | 玩家计划闭关或修炼的主观年数   | 闭关目标、资源需求     |
| `resource_supported_inner_years`   | 由资源包提供       | 主观年     | 当前资源可支撑的主观修炼年    | 有效修炼年上限       |
| `method_supported_inner_years`     | 由功法 / 境界提供   | 主观年     | 当前功法可支撑的推进年数     | 功法瓶颈          |
| `lifespan_safe_years`              | 由寿元与风险阈值提供   | 主观年或外界年 | 当前状态下的安全耗寿区间     | 寿元断点          |
| `mental_stability_supported_years` | 由心魔 / 心神状态提供 | 主观年     | 当前心神可承受的连续闭关年数   | 心魔断点          |
| `unsupported_yield_ratio`          | 建议 0%-20%    | 比例      | 资源不足年份仍保留的基础收益比例 | 资源不足时是否允许低效枯坐 |

#### 2.3.5 F1 批量结算与事件输入

| 变量                           | 默认值 / 范围 | 单位       | 含义                | 主要影响            |
| ---------------------------- | -------- | -------- | ----------------- | --------------- |
| `max_f1_batch_horizon_early` | 1-3      | 外界日 / 批  | 早期 F1 单批最大推进上限    | 早期摘要频率、事件可读性    |
| `max_f1_batch_horizon_mid`   | 7-15     | 外界日 / 批  | 中期 F1 单批最大推进上限    | 中期性能与中断频率       |
| `max_f1_batch_horizon_late`  | 30-90    | 外界日 / 批  | 后期 F1 单批最大推进上限    | 后期长线闭关与世界流年效率   |
| `base_rate_per_outer_day`    | 事件配置     | 概率 / 外界日 | 读取外界日历的事件流基础危险率   | 路途、宗门、市场、世界事件触发 |
| `base_rate_per_inner_year`   | 事件配置     | 概率 / 主观年 | 读取局部主观时间的事件流基础危险率 | 心魔、药性、洞天异动触发    |
| `max_triggers_per_batch`     | 事件配置     | 次 / 批    | 单批最多触发次数          | 防止长批次事件堆叠失控     |
| `interrupt_level`            | 事件配置     | 枚举       | 事件中断等级            | 是否退出 F1         |

### 2.4 模型输出的可调期望值 `T`

这些值是当前版本的校准目标，不是每次运行的硬结算结果。它们可以被后续设计裁决调整，但调整后必须重新计算相关 `X` 与 `Y`。

| 目标值                                  | 当前口径      | 验收 / 说明                | 主要由哪些输入调节                                  |
| ------------------------------------ | --------- | ---------------------- | ------------------------------------------ |
| `target_real_reference_hours`        | 32 小时     | 理论直线现实参考时长，不等于实际单局总时长  | 版本级目标；分配到 N1 / F1 / B1                     |
| `target_outer_world_years`           | 约 45-48 年 | 理论直线外界日历目标             | `F1_real_ratio`、`f1_seconds_per_outer_day` |
| `outer_world_year_acceptance_range`  | 20-50 年   | 验收范围；当前倾向接近上限但不超过 50 年 | 速度分配与 F1 速度                                |
| `target_local_domain_inner_years`    | 约 596 年   | 局部时间域主观经历目标，不等同完整生涯总年数 | `inner_years_per_outer_day`、洞天进入次数、洞天窗口    |
| `target_local_growth_years`          | 约 417 年   | 596 年 × 70%，用于修行成长     | `local_domain_growth_ratio`                |
| `target_local_method_study_years`    | 约 83 年    | 417 年 × 20%，用于功法研习     | `method_study_ratio`                       |
| `target_local_dao_cultivation_years` | 约 334 年   | 417 年 × 80%，用于道功修炼     | `dao_cultivation_ratio`                    |
| `target_local_support_years`         | 约 179 年   | 596 年 × 30%，用于支持行为     | `local_domain_support_ratio`               |
| `target_total_outer_years_baseline`  | 约 47.55 年 | N1 + F1 + B1 合计外界年基准   | 速度占比与速度常量                                  |

期望值的使用方式：

```text
若 total_outer_years < 20：外界流年感不足，应提高 F1 占比或加快 F1；
若 total_outer_years > 50：理论直线路径过长，应降低 F1 占比或放慢外界年目标；
若 local_dao_cultivation_years 不足：修为推进年不够，应提高局部主观年或道功修炼比例；
若 local_support_years 不足：闭关风险、恢复、巩固和事件空间不足，应提高支持行为比例或减少连续高压修炼。
```

### 2.5 因变量 / 推导变量 `Y`

#### 2.5.1 现实时间分配

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

#### 2.5.2 外界世界日历推导

```text
N1_outer_years = N1_real_hours / 36
B1_outer_years = B1_real_hours / 144
F1_outer_years = F1_real_hours * 10 / f1_seconds_per_outer_day

total_outer_world_years =
  N1_outer_years
  + F1_outer_years
  + B1_outer_years
```

基准代入：

```text
N1_outer_years = 21.12 / 36 = 0.59
B1_outer_years = 3.84 / 144 = 0.03
F1_outer_years = 7.04 * 10 / 1.5 = 46.93

total_outer_world_years ≈ 47.55
```

#### 2.5.3 局部时间域分配推导

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

#### 2.5.4 洞天外 F1 分配推导

```text
outer_ordinary_cultivation_years =
  outer_f1_years * outer_f1_ordinary_cultivation_ratio

outer_non_cultivation_years =
  outer_f1_years - outer_ordinary_cultivation_years
```

其中：

```text
outer_non_cultivation_years
= 世界资源积累 / 大型窗口等待
+ 长耗时生产与准备
+ 长期游历 / 远程行程 / 宗门职责
+ 其它低交互非修行过程
```

#### 2.5.5 总修行成长时间推导

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

#### 2.5.6 有效修炼年与资源不足年推导

```text
effective_cultivation_inner_years =
  min(
    planned_inner_years,
    resource_supported_inner_years,
    method_supported_inner_years,
    lifespan_safe_years,
    mental_stability_supported_years
  )

unsupported_inner_years =
  max(0, planned_inner_years - effective_cultivation_inner_years)
```

资源不足时的收益上限：

```text
unsupported_cultivation_yield <=
  unsupported_inner_years * base_cultivation_yield * unsupported_yield_ratio
```

其中 `unsupported_yield_ratio` 建议限制在 0%-20%。

#### 2.5.7 生涯耗时推导

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

### 2.6 方案内生约束 `C`

| 编号    | 约束             | 表达式 / 规则                                                     | 目的                        |
| ----- | -------------- | ------------------------------------------------------------ | ------------------------- |
| `C01` | 现实时间占比守恒       | `N1_real_ratio + F1_real_ratio + B1_real_ratio = 1`          | 防止现实时间重复分配或漏分配            |
| `C02` | 速度优先级          | `P0 > B1 > N1 > F1`                                          | 保证关键阻塞和交锋不会被高速推进覆盖        |
| `C03` | F1 进入条件        | `can_enter_F1(room) = true` 才能进入 F1                          | 保证 F1 只发生在全员低交互可结算状态      |
| `C04` | F1 批量推进断点      | `F1_target_time = min(all_safe_stops, max_f1_batch_horizon)` | 保证批量结算不会越过事件、资源耗尽、行动完成等断点 |
| `C05` | 局部时间域比例守恒      | `local_domain_growth_ratio + local_domain_support_ratio = 1` | 防止局部主观年重复使用               |
| `C06` | 修行成长比例守恒       | `method_study_ratio + dao_cultivation_ratio = 1`             | 防止功法研习与道功修炼重复计年           |
| `C07` | 外界 F1 普通修炼比例边界 | `0 <= outer_f1_ordinary_cultivation_ratio <= 1`，默认 10%-20%   | 防止把全部外界流年都解释为修炼           |
| `C08` | 有效修炼年上限        | `effective_cultivation_inner_years <= planned_inner_years`   | 防止资源不足时仍获得完整收益            |
| `C09` | 资源不足年非负        | `unsupported_inner_years >= 0`                               | 保证结果包可解释                  |
| `C10` | 世界预算不读洞天主观年    | `world_budget_delta = f(outer_world_time)`                   | 防止玩家在洞天内刷出数百年世界资源         |
| `C11` | 寿元读取角色时间域      | `lifespan_delta = f(character_time_domain)`                  | 防止房间速度状态直接决定寿元            |
| `C12` | 事件不被闭关承诺消除     | `EventStream` 仍按适用时间域采样                                      | 保证长期闭关仍有风险与玩法             |
| `C13` | 高风险事件不可普通自动化   | `interrupt_level = hard_interrupt` 或进入 B1 / P0               | 防止预设吞掉重大路线选择              |
| `C14` | 轮回总时长无缩短硬约束    | 不设置 `reincarnation_total_time < single_life_time`            | 保证世界资源不足时允许轮回后总时长变长       |

### 2.7 模型依赖关系与调参顺序

推荐调参顺序：

```text
Step 1：确认 H
  固定终点、速度状态、寿元口径、阶段预算口径、F1 事件口径。

Step 2：设定 T
  确认 32 小时现实参考、45-48 外界年、596 局部主观年等版本目标。

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
模型目标 T  →  可调输入 X
        ↓          ↓
      推导变量 Y / 结果包字段
        ↓
    内生约束 C 校验
        ↓
  若不满足目标或约束，回调 X 或重裁 T
```

---

## 3. 速度状态修订：保留 F1，不新增 独立宏观流年阶段

### 2.1 玩家可见速度状态

| 状态 | 用途        | 现实时间 : 游戏时间      | 修订后规则含义                               |
| -- | --------- | ---------------- | ------------------------------------- |
| N1 | 常规推进      | 15 秒 = 1 外界小时    | 玩家正在操作、响应事件、移动、交易、队列编辑或处理低频选择         |
| F1 | 长期低交互高速推进 | 建议 1.5 秒 = 1 外界日 | 所有玩家处于可自动结算状态时启用；内部使用批量结算，不逐小时全量 tick |
| B1 | 交锋慢速      | 60 秒 = 1 外界小时    | 正式战斗、突破挑战、秘境关键交锋、玩家直接交锋               |
| P0 | 全局暂停      | 时间不流动            | 公共决策、同步保护、主机暂停、无安全默认的关键阻塞             |

速度优先级：

```text
P0 > B1 > N1 > F1
```

进入 F1 的基础条件：

```text
can_enter_F1(room):
  if room.has_active_global_pause: return false
  if room.has_active_formal_encounter: return false
  if room.has_unresolved_hard_interaction: return false
  if any(player.has_required_input_without_default): return false
  if any(player.current_state not in f1_eligible_states): return false
  return true
```

`f1_eligible_states` 包括：

```text
洞天 / 时间阵法闭关；
普通长期闭关；
长期修炼；
长距离移动且使用安全路线；
显式托管；
宗门低风险职责；
休整 / 疗伤；
资源采集 / 加工等低交互长行动；
离线托管且存在合法安全策略。
```

不满足 F1 的典型情况：

```text
玩家正在处理事件选择；
玩家正在编辑关键队列；
玩家进入 B1 突破或战斗；
公共决策需要 P0；
玩家行动队列为空且没有托管；
事件没有安全默认；
洞天闭关缺少资源绑定、结束条件或中断策略；
玩家间冲突即将触发且需要人工确认。
```

### 2.2 不新增独立宏观流年阶段

曾尝试引入独立宏观流年阶段，但该方案不作为最终口径保留。主要问题是：

1. 要求玩家给出宏观承诺，门槛高于 F1。
2. 多人节奏不同会让准备协议变复杂。
3. 若不逐小时结算，中途事件触发逻辑容易不透明。
4. 若事件全部预设处理，又会削弱事件作为玩法的存在感。
5. 若事件频繁中断，又会退化成 N1。

因此：

```text
不新增独立宏观流年速度状态；
玩家看到的是 F1；
F1 内部使用 BatchSettlementKernel 做批量结算和事件采样。
```

---

## 4. F1 批量结算内核

### 3.1 设计目标

F1 需要同时满足：

```text
进入门槛低；
可以让所有人都进入洞天修炼时自然生效；
不按小时全量 tick，降低运算负担；
中途事件仍可触发；
可自动处理的事件不频繁打断；
需要玩家选择的事件必须中断；
结算结果可复盘。
```

新增内部模块：

```text
BatchSettlementKernel
```

它不是玩家可见阶段，而是 F1 的结算实现。

### 3.2 批量结算基本流程

```text
进入 F1
→ 建立 batch_start_snapshot
→ 计算候选批量推进上限 batch_horizon
→ 收集确定性断点
→ 对随机事件流采样下一触发时间
→ 对资源、寿元、压力、行动完成等阈值计算 crossing_time
→ 取最近断点 settlement_target_time
→ 聚合结算到 settlement_target_time
→ 若断点需要玩家响应，退出 F1，切回 N1 / B1 / P0
→ 若断点可自动处理，写入摘要并继续下一批
```

伪代码：

```text
while can_continue_F1(room):
  horizon = compute_batch_horizon(room)
  deterministic_stops = collect_scheduled_stops(room, horizon)
  sampled_event_stops = sample_event_streams(room, horizon)
  threshold_stops = compute_threshold_crossings(room, horizon)
  target = min(horizon, deterministic_stops, sampled_event_stops, threshold_stops)

  settle_interval(batch_start, target)

  if target.reason.requires_player_input:
      exit_F1(target.reason)
      break

  if target.reason.auto_resolvable:
      resolve_and_log(target.reason)
      batch_start = target
      continue
```

### 3.3 不逐小时 tick 的核心方法

F1 内部不再执行：

```text
for each outer_hour:
  resolve_all_players()
  resolve_all_npcs()
  resolve_all_nodes()
  roll_all_events()
```

改为：

| 类型           | F1 处理方式                                                 |
| ------------ | ------------------------------------------------------- |
| 确定性收益        | 用 `rate × duration` 聚合结算                                |
| 资源消耗         | 用 `consumption_rate × duration` 聚合结算，计算耗尽时间             |
| 寿元           | 按角色所在时间域聚合扣除：在洞天 / 时间阵法 / 局部时间域内按主观时间扣除；在洞天外按共享外界世界日历扣除 |
| 经脉 / 心魔 / 药性 | 按年或按阶段积分，必要时在阈值附近展开局部结算                                 |
| 行动完成         | 直接计算完成时间，作为断点                                           |
| 定期开放         | 读取日历队列，作为断点                                             |
| 随机事件         | 不逐小时掷骰，改为事件流采样下一触发时间                                    |
| NPC / 世界     | 只结算活跃相关对象；非相关对象延迟到被观察或宏观周期结算                            |

---

## 5. F1 中事件如何触发

### 4.1 事件不依赖每小时掷骰

玩家给出的闭关承诺不表示“闭关期间没有事件”。事件依然存在，只是不需要逐小时检查。

每类事件定义为一个 `EventStream`：

```text
EventStream {
  stream_id: string
  scope: character | sect | node | market | world | local_time_domain
  applicable_states: Array<string>
  hazard_rate_model: constant | table | formula | scheduled | threshold
  base_rate_per_outer_day: number | null
  base_rate_per_inner_year: number | null
  interrupt_level: silent | summary | auto | soft_interrupt | hard_interrupt
  default_resolution_policy: string | null
  max_triggers_per_batch: number
  cooldown_policy: string
  visibility_policy: string
}
```

事件触发方式：

1. **预定事件**：宗门会议、洞天开放、市场刷新、行动完成，直接进入日历队列。
2. **阈值事件**：资源耗尽、寿元低于阈值、心魔超过阈值、阵法燃料不足，计算 crossing time。
3. **危险率事件**：闭关心魔、洞天异动、路途遭遇、宗门突发，以危险率采样下一触发时间。
4. **条件事件**：进入某节点、携带某物、达到某境界、触发某关系后，在满足条件的区间内采样或排程。

### 4.2 危险率采样

若某事件每小时概率为 `p`，传统做法是每小时掷骰。F1 中改为一次采样下一触发时间：

```text
P(no event in n hours) = (1 - p)^n
```

采样方式：

```text
u = random(0, 1)
next_event_hour = floor(log(1 - u) / log(1 - p))
```

若使用连续危险率 `lambda(t)`，则：

```text
H(t) = ∫ lambda(t) dt
事件发生条件：H(t) >= -ln(u)
```

这样可以在不逐小时 tick 的情况下，确定事件是否会在本批 F1 中发生，以及发生在什么时候。

### 4.3 事件等级与是否退出 F1

| 事件等级             | 是否退出 F1 | 处理方式                     |
| ---------------- | ------- | ------------------------ |
| `silent`         | 否       | 后台记录或仅影响数值，不打扰玩家         |
| `summary`        | 否       | 写入 F1 摘要，例如小额资源变化、低风险传闻  |
| `auto`           | 否       | 按玩家预设、托管策略或安全默认处理，并写入摘要  |
| `soft_interrupt` | 视情况     | 若有预设则自动处理；无预设则退出 F1 到 N1 |
| `hard_interrupt` | 是       | 立即退出 F1，进入 N1 / B1 / P0  |

例子：

| 事件           | 等级               | 说明                                |
| ------------ | ---------------- | --------------------------------- |
| 普通灵气波动       | `summary`        | 影响闭关收益，写入摘要即可                     |
| 低风险药性残余      | `auto`           | 按资源策略处理，不打断                       |
| 心魔初现         | `soft_interrupt` | 有“稳守心神”预案则自动处理，否则中断               |
| 突破契机出现       | `soft_interrupt` | 若玩家预设“不自动突破”则只记录提示；若预设“满足条件提醒”则中断 |
| 洞天入口被攻击      | `hard_interrupt` | 涉及控制权或多人冲突，必须中断                   |
| 直接玩家冲突       | `hard_interrupt` | 进入 B1 或 P0                        |
| 无安全默认的重大路线选择 | `hard_interrupt` | 必须玩家响应                            |

### 4.4 玩家预设的作用

玩家预设不是“让事件不触发”，而是“事件触发后如何处理”。

```text
事件仍会触发；
若事件有合法预设，F1 自动处理并继续；
若事件无合法预设，F1 中断并切回 N1 / B1 / P0。
```

推荐预设范围只覆盖低风险和闭关相关内容：

```text
资源不足时停止闭关 / 继续低效枯坐 / 消耗备用资源；
心魔低阶波动时稳守 / 服用定心丹 / 提前出关；
经脉压力超阈值时降速 / 停止丹药 / 巩固根基；
洞天轻微异动时继续 / 加固 / 出关；
普通传闻只摘要，不打断。
```

不允许预设自动处理：

```text
高风险突破；
主动转世；
叛宗；
强 PvP；
消耗稀有不可逆资源；
重大路线选择；
暴露核心后手；
开启高危藏宝；
决定他人利益的公共选择。
```

---

## 6. 多人共玩中的 F1 判定

### 5.1 保留原 F1 的低门槛特征

多人共玩不应要求所有玩家提交复杂宏观承诺。F1 判定应尽量接近原逻辑：

```text
所有玩家当前都处于低交互、可自动结算、可中断的长期状态
→ 房间进入 F1
```

与此前的宏观承诺方案相比，v1.5 删除“宏观承诺协议”的强依赖。

玩家只需要满足以下任一状态：

```text
有合法长期行动；
有合法洞天 / 时间阵法闭关；
有显式托管；
有安全长距离行程；
有可自动处理的宗门职责；
离线但有托管策略；
处于等待洞天 / 秘境 / 宗门会议等可自动推进状态。
```

### 5.2 全员洞天修炼时自然进入 F1

当所有玩家都进入洞天、宗门时间阵或其它局部时间域时：

```text
所有玩家 = local_time_run
→ 房间满足 F1 条件
→ 外界日历按 F1 推进
→ 每个玩家的洞天内主观时间按各自 LocalTimeDomainProfile 结算
→ 有人出关、资源耗尽、心魔中断、洞天被攻击或重大事件触发时退出 F1
```

不同玩家可以在不同洞天中修炼：

| 玩家 | 状态    | 外界持续时间 | 主观时间       |
| -- | ----- | ------ | ---------- |
| A  | 宗门时间阵 | 10 外界日 | 20 主观年     |
| B  | 洞天福地  | 12 外界日 | 80 主观年     |
| C  | 普通闭关  | 8 外界日  | 8 主观日或较低倍率 |

F1 推进到最近断点，例如 C 的 8 日闭关完成，而不是强制所有人同步出关。

### 5.3 F1 推进到哪里

F1 每批推进到最近安全断点：

```text
F1_target_time = min(
  next_player_action_completion_time,
  next_local_time_run_exit_time,
  next_resource_exhaustion_time,
  next_threshold_crossing_time,
  next_sampled_interrupt_event_time,
  next_domain_opening_time,
  next_stage_budget_activation_time,
  next_public_decision_time,
  max_f1_batch_horizon
)
```

`max_f1_batch_horizon` 用于防止一次批量推进过长。建议按阶段配置：

```text
早期：最多 1-3 外界日 / 批
中期：最多 7-15 外界日 / 批
后期：最多 30-90 外界日 / 批
```

这不是玩家等待时间，而是内部结算批次上限。

### 5.4 F1 退出条件

F1 遇到以下情况退出：

```text
任一玩家需要人工响应且无安全默认；
B1 战斗 / 突破 / 玩家冲突触发；
P0 公共决策触发；
洞天控制权、入口、席位、宗门重大事件需要确认；
玩家资源耗尽且预设为“停止闭关”；
心魔 / 经脉 / 药性 / 寿元风险超过硬阈值；
行动完成并需要新指令；
玩家主动打开关键编辑界面；
系统达到 F1 批次上限并需要展示摘要。
```

F1 不因以下情况退出：

```text
普通摘要事件；
可自动处理的低风险事件；
只影响数值的小额波动；
玩家打开只读报告或地图查看；
非相关 NPC 的后台成长；
不需要玩家响应的市场与资源变化。
```

---

## 7. 理论直线参考与 F1 占比

理论直线参考终点：

```text
大乘圆满 → 突破进入渡劫期
```

首版修订为：

```text
现实参考时长：32 小时
共享外界世界日历目标：约 45-48 年
共享外界世界日历验收范围：20-50 年，越接近上限越好
局部时间域主观经历时间目标：约 596 年
外界世界日历目标：约 45-48 年
洞天内修行成长占局部主观时间：暂定 70%，可调
洞天外修行成长占外界流年：暂定 10%-20%，主要服务前期无洞天修炼与低阶普通闭关
功法研习 : 道功修炼 = 1 : 4，暂定 20% : 80%，可调
```

推荐将 32 小时只分配到玩家可见速度状态 N1 / F1 / B1，不再单列“局部闭关表现”现实时间桶。洞天闭关、时间阵法、长行动和托管都属于 F1 内部可批量结算内容。

基准占比：

| 模式              | 现实占比 | 现实小时   | 换算口径                          | 外界年贡献     | 设计作用                       |
| --------------- | ---- | ------ | ----------------------------- | --------- | -------------------------- |
| N1 现场交互         | 66%  | 21.12h | 36h = 1 外界年                   | 0.59 年    | 地图、事件、宗门、交易、队列、短行动、普通选择    |
| F1 长期低交互 / 外界流年 | 22%  | 7.04h  | 1.5 秒 = 1 外界日，即 1h ≈ 6.67 外界年 | 46.93 年   | 洞天闭关、时间阵法、长行动、托管、宗门职责、外界流年 |
| B1 关键慢速轮        | 12%  | 3.84h  | 144h = 1 外界年                  | 0.03 年    | 突破、战斗、关键交锋                 |
| 合计              | 100% | 32.00h | —                             | 约 47.55 年 | 接近 50 年上限，保留少量事件和路线浮动空间    |

换算公式：

```text
N1_outer_years = N1_real_hours / 36
B1_outer_years = B1_real_hours / 144
F1_outer_years = F1_real_hours * 10 / f1_seconds_per_outer_day
```

基准代入：

```text
N1_outer_years = 21.12 / 36 = 0.59
B1_outer_years = 3.84 / 144 = 0.03
F1_outer_years = 7.04 * 10 / 1.5 = 46.93
total_outer_years ≈ 47.55
```

说明：

1. F1 现实占比从旧方案的 7% 提升到 22%，但由于 F1 内部批量结算，不再承受逐小时全量 tick 的性能压力。
2. F1 可见速度从 2 秒 / 外界日提高到 1.5 秒 / 外界日，使 7 小时左右的低交互现实时间即可支撑接近 47 年外界日历。
3. 洞天闭关表现不再是独立现实时间桶，而是 F1 中的局部时间域结算内容。外界 F1 推进若干日、月、年时，洞天内可根据 `LocalTimeDomainProfile` 结算数年到数百年主观修炼时间。
4. 如果所有玩家都在洞天修炼，房间自然处于 F1；外界流年与洞天主观年同步由批量结算内核推进。
5. N1 保持 66%，确保玩家面对事件、地图、宗门、交易和队列规划时仍有足够现实操作时间，不因追求外界年份而赶时间。

### 7.1 分域时间分配：不能用单一 60/40 一刀切

v1.4 中曾用：

```text
生涯总时间 × 60% = 修行成长时间
修行成长时间 × 20% = 功法研习
修行成长时间 × 80% = 道功修炼
```

这个口径过于粗糙，需要修正。原因是不同时间域能承载的行为不同：

1. **洞天 / 时间阵法内**可以消耗大量主观年，适合承载功法研习、道功修炼、闭关巩固、疗伤、心魔、药性和局部修行事件。
2. **洞天外 F1 外界流年**适合承载资源成熟、炼丹、炼器、材料加工、宗门职责、长期游历、等待洞天 / 秘境 / 大型资源投放窗口、世界预算积累和 NPC / 市场变化。
3. **N1 / B1 现场交互**适合承载短途移动、交易、互动、现场探索、战斗、突破选择和事件决策；这些行动现实交互密集，但很难自然消耗几十年外界日历，也不应硬塞进洞天主观年。
4. **前期部分修炼不在洞天主观时间中进行**，例如炼气、筑基早期的普通吐纳、普通静室、低阶宗门修炼、野外灵地修炼。这部分应读取外界共享日历，而不是洞天内主观年。

因此，v1.5 改为“分域分配”：

```text
局部时间域主观时间：主要分配给修行成长与局部闭关支持行为；
洞天外 F1 外界流年：主要分配给资源、生产、等待、长期游历和少量早期 / 普通修炼；
N1 / B1 现实交互时间：主要分配给短行动、选择、战斗、现场探索和交易。
```

### 7.2 默认比例组

#### 7.2.1 局部时间域内部比例

局部时间域指洞天、时间阵法、秘境时间窗口、宗门时间阵等角色主观时间显著加速的场景。

首版默认：

```text
local_domain_growth_ratio = 0.70
local_domain_support_ratio = 0.30
method_study_ratio = 0.20
dao_cultivation_ratio = 0.80
```

含义：

| 项         | 默认比例      | 作用                             |
| --------- | --------- | ------------------------------ |
| 局部时间域修行成长 | 70%       | 功法研习、道功修炼、突破准备、修行巩固            |
| 局部时间域支持行为 | 30%       | 疗伤、稳固根基、处理药性、恢复、局部炼化、闭关事件、心魔对抗 |
| 功法研习      | 修行成长的 20% | 功法掌握、法门理解、参悟、路线解锁              |
| 道功修炼      | 修行成长的 80% | 修为推进、资源消耗、经脉压力、CP / 标准化进度      |

以 `local_domain_inner_years = 596 年` 粗算：

| 项          | 年数      |
| ---------- | ------- |
| 局部时间域总主观时间 | 596 年   |
| 局部修行成长时间   | 约 417 年 |
| 功法研习       | 约 83 年  |
| 道功修炼       | 约 334 年 |
| 局部支持行为     | 约 179 年 |

注意：这 596 年不再等同于完整生涯总时间，而是“局部时间域中的主观经历时间”。角色在洞天外仍会额外经历外界日历。

#### 7.2.2 洞天外 F1 外界流年内部比例

洞天外 F1 流年约 45-48 年，不能全都视为短途移动、交易或现场探索。它主要承担低交互、长期性的外界过程。

首版建议把洞天外 F1 外界流年拆为：

| 类别                 | 建议占比    | 作用                            | 是否属于修行成长       |
| ------------------ | ------- | ----------------------------- | -------------- |
| 世界资源积累 / 大型窗口等待    | 35%-45% | 阶段预算积累、洞天开放、秘境、天象、市场周期、宗门库存成熟 | 否              |
| 长耗时生产与准备           | 20%-30% | 炼丹、炼器、材料加工、聚灵石准备、阵法维护、洞天席位申请  | 多数否，少量可作为研习或准备 |
| 长期游历 / 远程行程 / 宗门职责 | 15%-25% | 长线探索、远途路线、驻守、宗门任务、资源点经营       | 通常否            |
| 洞天外普通修炼 / 低阶修炼     | 10%-20% | 前期无洞天时的吐纳、普通静室、低阶灵地修炼         | 是              |
| N1/B1 现场交互折算       | 不按比例分配  | 短途移动、交易、互动、现场探索、战斗和选择         | 不用年份比例衡量       |

这意味着：

```text
非修行成长时间的大头，应来自世界资源等待、长耗时生产、长期游历和宗门职责；
短途移动、交易、互动、现场探索不应承担大规模外界年份消耗；
前期部分修炼可以占用外界 F1 年份，但比例应受阶段限制。
```

#### 7.2.3 N1 / B1 现场交互时间

N1 / B1 的现实时间占 78% 左右：

```text
N1 = 21.12h
B1 = 3.84h
N1 + B1 = 24.96h
```

它们的外界年贡献只有约 0.62 年，但现实交互含量最高。

因此，以下行动应主要吃 N1 / B1 现实预算，而不是吃大量外界年：

```text
短途移动；
交易；
NPC 对话；
事件选择；
现场探索；
节点侦查；
队列规划；
宗门申请操作；
战斗和突破轮内选择；
资源分配与背包处理。
```

如果需要让“游历”消耗更长外界时间，应区分：

```text
现场探索：N1，短时高交互；
长期游历：F1，低交互长行动，可触发事件流；
秘境探索：N1 / B1 / F1 混合，按模板声明。
```

### 7.3 计算公式

新增分域字段：

```text
local_domain_inner_years
outer_f1_years
live_outer_years
local_domain_growth_ratio
local_domain_support_ratio
outer_f1_ordinary_cultivation_ratio
method_study_ratio
dao_cultivation_ratio
```

局部时间域：

```text
local_growth_years =
  local_domain_inner_years * local_domain_growth_ratio

local_method_study_years =
  local_growth_years * method_study_ratio

local_dao_cultivation_years =
  local_growth_years * dao_cultivation_ratio

local_support_years =
  local_domain_inner_years * local_domain_support_ratio
```

洞天外 F1：

```text
outer_ordinary_cultivation_years =
  outer_f1_years * outer_f1_ordinary_cultivation_ratio

outer_non_cultivation_years =
  outer_f1_years - outer_ordinary_cultivation_years
```

总修行成长时间：

```text
total_method_study_years =
  local_method_study_years
  + outer_ordinary_cultivation_years * method_study_ratio

total_dao_cultivation_years =
  local_dao_cultivation_years
  + outer_ordinary_cultivation_years * dao_cultivation_ratio

total_cultivation_growth_years =
  total_method_study_years + total_dao_cultivation_years
```

总生涯时间：

```text
career_elapsed_years =
  local_domain_inner_years
  + outer_years_when_character_outside_local_domain
```

注意：

```text
outer_world_years 不能无条件加到 career_elapsed_years；
如果角色在洞天内，寿元按洞天主观时间扣；
如果角色在洞天外，寿元按外界日历扣。
```

### 7.4 对其它模块的反推作用

| 模块             | 读取比例                                                          | 调参方向                             |
| -------------- | ------------------------------------------------------------- | -------------------------------- |
| 修炼公式           | `total_dao_cultivation_years`                                 | 修为收益、资源消耗、经脉压力按道功修炼年校准           |
| 功法研习           | `total_method_study_years`                                    | 功法熟练、法门解锁、参悟事件按研习年校准             |
| 洞天资源年          | `local_domain_inner_years` + `local_dao_cultivation_years`    | 洞天消耗资源年，但只有有效道功修炼年转化为主要修为收益      |
| 资源投放           | `outer_non_cultivation_years` + `total_dao_cultivation_years` | 外界非修行年负责资源积累与获取，道功修炼年负责资源消耗      |
| 炼丹 / 炼器        | `outer_non_cultivation_years` 或 `local_support_years`         | 长耗时生产可吃 F1 外界流年或局部支持年，不能挤占短交互预算  |
| 洞天开放           | `outer_f1_years`                                              | 等待窗口、席位、争夺和大型投放主要读取外界 F1 年       |
| 短途移动 / 交易 / 互动 | `real_elapsed_hours` + `live_outer_world_hours`               | 主要按 N1/B1 现实交互预算调参，不强行消耗多年外界日历   |
| 游历 / 探索        | 区分 N1 现场探索与 F1 长期游历                                           | 现场探索吃 N1；长期游历吃 F1 并走 EventStream |
| 寿元             | 角色所在时间域                                                       | 洞天内按主观年扣，洞天外按外界年扣                |

结果包应新增：

```text
local_domain_inner_years_delta
local_growth_years_delta
local_method_study_years_delta
local_dao_cultivation_years_delta
local_support_years_delta
outer_f1_years_delta
outer_ordinary_cultivation_years_delta
outer_non_cultivation_years_delta
live_interaction_real_hours_delta
live_interaction_outer_years_delta
time_domain_allocation_profile_used
```

### 7.5 轮回重修不保证缩短总通关时间

需要修复旧隐含设定：

```text
合理轮回重修一定会让总通关时间短于单世通关。
```

该设定不合理。原因是世界资源并非无限供应：

1. 阶段预算按外界时间刷新，不按洞天内时间刷新。
2. 大型资源投放事件、洞天开放、秘境窗口、天象和宗门库存需要外界时间积累。
3. 玩家重修后虽然路线更清楚、先天形状更好、风险更低，但仍可能需要等待资源重新生成或等待大事件窗口。
4. 多次轮回可能提高成功率和结局质量，却未必压缩实际总现实时间或外界日历时间。

修订口径：

```text
合理轮回的主要收益 = 提高稳定性、成功率、资源利用率、路线确定性和结局质量；
合理轮回可能缩短某一世的境界推进时间；
合理轮回不承诺缩短完整通关总时长；
若世界资源不足，轮回后总时长允许变长，用于等待资源产出、阶段预算积累和大型投放事件生成。
```

建议公式：

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

新增字段建议：

```text
ReincarnationRunTimePolicy {
  reincarnation_may_extend_total_time: true
  route_knowledge_time_saved_estimate: number
  failure_risk_time_saved_estimate: number
  world_resource_accumulation_wait_years: number
  major_resource_event_wait_years: number
  expected_success_rate_gain: number
  expected_ending_quality_gain: number
}
```

UI 表达也应避免承诺“轮回后一定更快”，建议改为：

```text
轮回将提高路线确定性、先天适配和成功率；
但若关键资源尚未成熟，下一世可能需要等待世界资源积累或大型机缘窗口。
```

---

## 8. 洞天 / 时间阵法分级

洞天内时间缩放比例需要分级，但本稿不锁死具体数值。只固定结构和调参接口。

| 档位 | 类型            | 适用阶段        | 设计作用                 |
| -- | ------------- | ----------- | -------------------- |
| T0 | 普通闭关 / 静室     | 炼气前期、无洞天资格时 | 几乎不提供时间压缩，只提供安全和环境稳定 |
| T1 | 低阶时间阵         | 炼气后期、筑基     | 教学期后开始引入少量主观时间加速     |
| T2 | 宗门时间阵 / 小洞天   | 筑基、金丹、元婴    | 成为宗门席位、贡献和资源调度核心     |
| T3 | 洞天福地          | 元婴、化神、炼虚    | 高价值争夺点，配合突破准备和长期闭关   |
| T4 | 秘境时间窗口        | 化神、炼虚、合体    | 定期或随机开放，高收益高风险       |
| T5 | 禁术时间域 / 终局时间阵 | 大乘、渡劫前      | 极端冲刺，强寿元、心魔、道伤和因果代价  |

必须配置化的字段：

```text
inner_years_per_outer_day
inner_years_per_real_minute
max_inner_years_per_entry
resource_year_capacity_multiplier
lifespan_pressure_modifier
mental_risk_per_inner_year
array_fuel_cost_per_inner_year
```

---

## 9. 洞天必须配合修炼资源

洞天 / 时间阵法的基础定位：

```text
提供局部时间域；
提供部分环境灵气或空间稳定；
提供闭关、参悟、突破准备的场地；
但不自动提供完整修炼资源链。
```

有效修炼必须同时满足：

```text
有时间：洞天内主观年；
有资源：丹药、聚灵石、灵材、洞天灵气池、宗门护持、阵法燃料；
有功法：当前功法支持本境界推进；
有承载：寿元、体魄、经脉、心神能承受；
有适配：灵根、道功、资源和洞天相性不冲突。
```

核心字段：

```text
resource_supported_inner_years
```

有效修炼年数：

```text
effective_cultivation_inner_years =
  min(
    planned_inner_years,
    resource_supported_inner_years,
    method_supported_inner_years,
    lifespan_safe_years,
    mental_stability_supported_years
  )
```

资源不足年份：

```text
unsupported_inner_years = planned_inner_years - effective_cultivation_inner_years
```

资源不足年份的处理：

1. 仍消耗寿元。
2. 修为收益大幅降低，建议只保留 0%-20% 的基础吐纳收益。
3. 心魔、经脉压力、枯坐、状态恶化和事件风险上升。
4. UI 必须提示“资源不足，继续闭关会耗寿低效”。

---

## 10. 定期开放与外界日历节奏

首版建议从凡人到进入渡劫期的理论直线链路中，外界世界经过约 45-48 年；验收范围为 20-50 年，越接近 50 年越符合“流年沧桑感”的目标，但不建议突破 50 年作为理论直线基准。

这支持：

```text
季度窗口：约 180-192 次；
半年窗口：约 90-96 次；
年度窗口：约 45-48 次；
三年一次的大型洞天 / 秘境：约 15-16 次；
十年一次的大型天象：约 4-5 次。
```

开放节奏建议：

| 开放类型        | 外界周期    | 适用阶段     | 作用               |
| ----------- | ------- | -------- | ---------------- |
| 宗门低阶时间阵     | 30-90 日 | 炼气、筑基    | 教学后期、低阶闭关、宗门贡献消耗 |
| 小洞天 / 宗门秘室  | 半年      | 筑基、金丹、元婴 | 席位争夺、资源准备、阶段修炼   |
| 中型洞天窗口      | 1 年     | 金丹、元婴、化神 | 核心闭关、突破准备、宗门调度   |
| 高阶秘境时间域     | 3 年     | 化神、炼虚、合体 | 高风险机缘、资源争夺、阵营冲突  |
| 大型天象 / 终局窗口 | 10 年    | 大乘、渡劫前   | 终局前准备、因果、劫数、世界事件 |

外界开放节奏由 F1 流年承载，不要求玩家用 N1 现实操作等完整个季度或一年。

---

## 11. UI 与结果包要求

普通 UI 必须同时显示：

```text
现实预计耗时；
外界预计经过时间；
洞天内预计修炼年数；
预计寿元消耗；
资源可支撑年数；
资源不足年份；
预计有效修炼年数；
心魔 / 经脉 / 药性 / 阵法风险；
出洞后可能触发的外界事件；
下次洞天开放时间；
本次 F1 中断策略。
```

结果包至少输出：

```text
real_time_delta
outer_time_delta
f1_outer_time_delta
inner_time_delta
career_elapsed_years_delta
local_domain_inner_years_delta
local_growth_years_delta
local_method_study_years_delta
local_dao_cultivation_years_delta
local_support_years_delta
outer_f1_years_delta
outer_ordinary_cultivation_years_delta
outer_non_cultivation_years_delta
live_interaction_real_hours_delta
live_interaction_outer_years_delta
lifespan_delta
resource_supported_inner_years
effective_cultivation_inner_years
unsupported_inner_years
lifespan_time_domain_used
resource_consumed_refs
local_time_domain_ref
triggered_event_stream_refs
auto_resolved_event_refs
interrupted_event_ref
pending_world_stage_budget_activation
risk_delta
```

---

## 12. 字段与表结构同步建议

### 12.1 `RoomSpeedState`

```text
RoomSpeedState {
  current_speed: N1 | F1 | B1 | P0
  f1_batch_kernel_enabled: bool
  f1_current_batch_start: DateTime
  f1_current_batch_target: DateTime
  f1_exit_reason: string | null
}
```

### 12.2 `BatchSettlementKernel`

```text
BatchSettlementKernel {
  max_batch_outer_hours: number
  active_event_stream_refs: Array<string>
  deterministic_stop_refs: Array<string>
  sampled_event_stop_refs: Array<string>
  threshold_stop_refs: Array<string>
  batch_snapshot_ref: string
  batch_result_package_ref: string
}
```

### 12.3 `EventStream`

```text
EventStream {
  stream_id: string
  scope: character | sect | node | market | world | local_time_domain
  applicable_states: Array<string>
  hazard_rate_model: constant | table | formula | scheduled | threshold
  base_rate_per_outer_day: number | null
  base_rate_per_inner_year: number | null
  interrupt_level: silent | summary | auto | soft_interrupt | hard_interrupt
  default_resolution_policy: string | null
  max_triggers_per_batch: number
  cooldown_policy: string
  visibility_policy: string
}
```

### 12.4 `LocalTimeDomainProfile`

```text
LocalTimeDomainProfile {
  profile_id: string
  tier: T0 | T1 | T2 | T3 | T4 | T5
  realm_band: RealmRange
  inner_years_per_outer_day: number
  inner_years_per_real_minute: number
  max_inner_years_per_entry: number
  resource_year_capacity_multiplier: number
  lifespan_pressure_modifier: number
  mental_risk_per_inner_year: number
  meridian_pressure_per_inner_year: number
  fuel_cost_per_inner_year: CostBundle
  maintenance_cost_per_outer_day: CostBundle
  opening_window_policy_id: string
}
```

### 12.5 `TimeDomainActivityAllocationProfile`

```text
TimeDomainActivityAllocationProfile {
  profile_id: string
  local_domain_growth_ratio: number
  local_domain_support_ratio: number
  outer_f1_ordinary_cultivation_ratio_min: number
  outer_f1_ordinary_cultivation_ratio_max: number
  method_study_ratio: number
  dao_cultivation_ratio: number
  live_interaction_uses_real_time_budget: bool
  applicable_realm_range: RealmRange
  notes: string
}
```

首版默认：

```text
local_domain_growth_ratio = 0.70
local_domain_support_ratio = 0.30
outer_f1_ordinary_cultivation_ratio_min = 0.10
outer_f1_ordinary_cultivation_ratio_max = 0.20
method_study_ratio = 0.20
dao_cultivation_ratio = 0.80
live_interaction_uses_real_time_budget = true
```

### 12.6 `ReincarnationRunTimePolicy`

```text
ReincarnationRunTimePolicy {
  policy_id: string
  reincarnation_may_extend_total_time: bool
  route_knowledge_time_saved_estimate: number
  failure_risk_time_saved_estimate: number
  world_resource_accumulation_wait_years: number
  major_resource_event_wait_years: number
  expected_success_rate_gain: number
  expected_ending_quality_gain: number
}
```

### 12.7 `CultivationResourceYearBundle`

```text
CultivationResourceYearBundle {
  bundle_id: string
  resource_refs: Array<string>
  supported_realm_range: RealmRange
  supported_method_tags: Array<string>
  resource_supported_inner_years: number
  quality_factor: number
  side_effect_profile_id: string
  meridian_pressure_per_year: number
  mental_risk_per_year: number
  decay_policy: string
}
```

---

## 13. 数值与性能验算用例

```text
Case K：F1 可见速度调整为 1.5 秒 = 1 外界日，但内部不执行 24 个全量 hour_tick。
Case L：所有玩家都进入洞天修炼时，房间能稳定进入 F1，并推进到最近出关 / 事件 / 资源耗尽断点。
Case M：闭关期间心魔、资源耗尽、洞天异动等事件能通过 EventStream 触发，而不是被玩家承诺吞掉。
Case N：可自动处理事件写入摘要并继续 F1；无预设重大事件退出 F1。
Case O：资源不足年份导致耗寿低效，而不是继续高效修炼。
Case P：洞天修炼仍强需求修为丹药、聚灵阵、聚灵石、洞天灵气池、宗门护持和功法适配。
Case Q：非相关 NPC 和远端节点不逐小时全量刷新，改为惰性结算或宏观周期结算。
Case R：F1 批量结算结果可复盘，包括采样随机种子、事件流、断点和聚合收益。
Case S：596 年局部时间域主观经历按 70% 修行成长、其中 20% 研习 / 80% 道功修炼拆分后，是否能支撑功法系统与修为推进的目标节奏。
Case T：轮回重修在资源不足与大型投放事件等待存在时，是否允许总通关时间长于单世通关，同时提高成功率与结局质量。
```

---

## 14. 待裁决问题

| 问题               | 默认建议                               | 需要裁决的点                                    |
| ---------------- | ---------------------------------- | ----------------------------------------- |
| F1 可见速度          | 基准为 1.5 秒 = 1 外界日                  | 是否采用 1 秒、1.5 秒或 2 秒；基准建议 1.5 秒，兼顾流年长度与可读性 |
| F1 内部批量步长        | 按最近断点推进，设置 `max_batch_outer_hours` | 早中后期最大批次应是多少                              |
| 事件采样             | 使用 EventStream + hazard rate       | 是否接受非逐小时掷骰的事件触发模型                         |
| 可自动事件范围          | 低风险闭关事件、摘要事件、预设事件                  | 哪些事件必须硬中断                                 |
| 洞天时间倍率           | 分级但不锁具体值                           | 后续是否设定各档位比例表                              |
| 洞天资源年            | 必须带入资源，否则低效耗寿                      | 资源不足时保留多少基础收益，建议 0%-20%                   |
| 外界日历目标           | 凡人到进入渡劫期约 45-48 外界年，验收范围 20-50 年   | 是否接受接近上限的 47.5 年基准，或改为 30-40 年更保守口径       |
| 多人离线托管           | 有显式托管可参与 F1，无托管只短保护                | 保护窗口和兜底策略如何设定                             |
| 局部时间域修行成长占比      | 默认 70%                             | 是否改为 60%、75% 或按境界 / 洞天类型变化                |
| 洞天外普通修炼占外界 F1 流年 | 默认 10%-20%                         | 主要用于前期无洞天修炼和低阶普通闭关，是否按境界递减                |
| 功法研习 : 道功修炼      | 默认 1:4，即 20% : 80%                 | 是否按境界提高研习占比，或按功法复杂度动态调整                   |
| 非修行外界流年内部结构      | 世界资源等待、长耗时生产、长期游历、宗门职责为主           | 炼丹炼器、长期游历、资源成熟和短交互的边界如何定量                 |
| 轮回总时长            | 允许长于单世通关                           | 世界资源积累等待和大型投放事件等待应如何估算                    |

---

## 15. 本轮定稿建议

建议将本稿作为 v1.5 基线，并以后续总约束同步相关文档：

```text
保留 F1 作为玩家可见的长期低交互加速状态，不新增独立宏观流年玩家阶段。32 小时现实参考重新分配为 N1 66% / F1 22% / B1 12%；F1 可见速度基准调整为 1.5 秒 = 1 外界日，使理论直线链路约经过 47.5 外界年，落在 20-50 年目标范围内并接近上限。F1 进入门槛保持较低：所有玩家处于可自动结算的长期状态即可进入，所有人都进洞天修炼时自然生效。F1 内部不再逐小时全量 tick，而使用 BatchSettlementKernel：确定性过程聚合结算，随机事件用 EventStream 采样下一触发时间，资源耗尽和风险阈值用 crossing time 作为断点。事件不会因为玩家闭关承诺而消失；有预设则自动处理并摘要，无预设或重大事件则退出 F1。洞天和时间阵法提供局部时间域，但必须消耗修炼资源年和寿元；寿元按角色所在时间域扣除，人在洞天内按洞天主观时间扣寿，人在洞天外按共享外界日历扣寿。角色生涯总时间不全部等于修炼时间，且不能按单一 60/40 直接切分。首版改用分域分配：局部时间域主观时间约 70% 用于修行成长，其中功法研习 : 道功修炼 = 1 : 4；洞天外 F1 外界流年主要用于世界资源积累、炼丹炼器等长耗时生产、长期游历、宗门职责和少量前期普通修炼；短途移动、交易、互动、现场探索和战斗主要消耗 N1/B1 现实交互预算，不强行折算成大量年份。轮回重修提高稳定性、成功率和结局质量，但不保证总通关时间短于单世通关，世界资源不足时允许因等待资源产出与大型投放事件而变长。
```

