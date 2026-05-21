# 行动配置内容基线 v0.3｜面向设计与体验版

版本：v0.3  
日期：2026-05-21  
用途：在 v0.2 行动配置基线基础上，合入“丹药常态服用、药性状态、修为流消化、经脉压力只来自外源资源”的新口径。

---

## 1. 版本变化摘要

v0.3 相对 v0.2 的核心变化：

1. 丹药不再只是主动吐纳行动的附加资源输入。
2. 丹药可以常态化直接服用，服用后形成体内药性状态。
3. 体内药性可被所有兼容的修为增长流消化。
4. 主动吐纳仍然是最高效的药性消化方式，但不是唯一方式。
5. 被动吐纳、主动运转、被动运转可以消化药性。
6. 修为类事件可通过事件配置消化药性。
7. 正常修行不再默认产生经脉压力。
8. 经脉压力主要由丹药、灵材、符箓、阵法灌注或其他外源资源产生。
9. 经脉压力限制能够同时服用的丹药数量、强度和叠加类型。
10. 巩固根基重点承接服丹后的经脉压力、残余药性和根基浮躁处理。

---

## 2. 行动配置字段：面向设计与体验版

行动配置表仍然不暴露运行时、服务端校验和日志字段。策划只维护玩家体验层面的行动定义。

```yaml
ActionDesignConfig:
  action_id: string              # 行动配置 ID，策划可读
  name: string                   # 玩家看到的行动名
  category: string               # 修炼 / 移动 / 休整 / 生产 / 社交等
  player_intent: string          # 玩家执行这个行动想达成什么
  entry_points: list             # 从哪些页面或场景进入
  availability: string           # 什么时候可用
  time_and_pace: object          # 时间成本、是否长行动、是否可 F1
  inputs_and_costs: object       # 玩家可选择的投入、默认消耗、药性/经脉规则
  outcomes_and_feedback: object  # 主要收益、风险反馈、日志反馈
  design_boundaries: list        # 明确不能做什么，防止配置歧义
```

药性和经脉压力不新增顶层字段，而是归入：

```plain text
inputs_and_costs.medicine_rule
outcomes_and_feedback.medicine_feedback
outcomes_and_feedback.meridian_feedback
```

这样可以保持行动表结构简洁。

---

## 3. 修炼通用药性规则

所有修炼相关行动共享以下口径：

```yaml
CultivationMedicineCommonRule:
  direct_medicine_use: true
  direct_use_result: 创建体内药性状态
  instant_full_cultivation_gain: false
  normal_cultivation_causes_meridian_pressure: false
  meridian_pressure_sources:
    - 丹药
    - 灵材
    - 符箓
    - 阵法灌注
    - 强行吸收外源灵气
    - 特殊事件外源资源
  medicine_can_be_consumed_by:
    - 主动吐纳
    - 被动吐纳
    - 主动运转
    - 被动运转
    - 闭关修炼
    - 明确允许的修为事件
  medicine_overload_limits:
    - 经脉总负载
    - 同类药性叠加组
    - 强刺激型药性互斥
    - 境界与体魄承载
```

玩家侧表达：

```plain text
丹药可以直接服用，但不是即时经验药。
服用后会形成体内药性。
主动修炼吸收最快，被动运转也会缓慢吸收。
吃得太多会占满经脉承载，带来散逸、胀痛或根基浮躁风险。
```

---

## 4. 修炼行动与修行流配置样例

### 4.1 服用丹药

```yaml
- action_id: cultivate.take_medicine
  name: 服用丹药
  category: 修炼资源使用
  player_intent: 直接服用丹药，使其在体内形成持续药性，等待后续修行流逐步消化。
  entry_points:
    - 背包丹药详情
    - 修为页药性入口
    - 角色状态页
    - 行动规划页快捷服用
  availability: 角色未处于硬阻塞状态，丹药可使用，且经脉承载或风险策略允许服用。
  time_and_pace:
    player_time_choice: 无需选择持续时间
    duration_feel: 服用本身是短操作；收益随后按时间和修行流释放
    f1_support: 服用动作本身不作为 F1 依据；服用后的药性可在 F1 修行中被消化
    settlement_feel: 不即时发放完整修为，只创建体内药性状态
  inputs_and_costs:
    default_costs:
      - 消耗丹药
      - 占用经脉承载
    medicine_rule:
      - 服用后形成体内药性
      - 药性持续一段游戏时间
      - 药性可被主动吐纳、被动吐纳、主动运转、被动运转、闭关和修为事件消化
      - 经脉负载超过上限时不能服用，或触发高风险确认
    optional_inputs:
      - 辅助服药资源
      - 护脉类资源
  outcomes_and_feedback:
    primary_outputs:
      - 体内药性增加
      - 后续修为增长流获得可消化药性
    secondary_outputs:
      - 经脉承载变化
      - 药性剩余时间提示
      - 过量服用风险提示
    player_feedback_examples:
      - 你服下清灵丹，温和药性在体内化开。
      - 当前经脉承载 80/100，再服用强刺激丹药风险较高。
      - 主动吐纳可高效吸收当前药性。
  design_boundaries:
    - 服用丹药不直接获得完整修为。
    - 不能通过连续服丹绕过经脉承载上限。
    - 事件完成后服丹不能回溯放大事件收益。
    - 不自动替玩家吞服高价值丹药。
```

### 4.2 主动吐纳

```yaml
- action_id: cultivate.active_tunai
  name: 主动吐纳
  category: 修炼
  player_intent: 投入一段时间主动推进当前小阶段修为，并高效消化体内药性。
  entry_points:
    - 修为页
    - 指令管理页
    - 当前地点的修炼入口
  availability: 角色处于可修炼状态，当前地点允许修炼，并已选择可用主修道功。
  time_and_pace:
    player_time_choice: 1-72 游戏小时
    default_duration: 12 游戏小时
    min_duration: 1 游戏小时
    f1_support: 长时段且全员低交互时可参与 F1；短时段默认 N1
    settlement_feel: 按小时推进，可被事件、状态风险或玩家中止打断
  inputs_and_costs:
    default_costs:
      - 游戏时间
    medicine_rule:
      - 可消化已服用丹药形成的体内药性
      - 主动吐纳对修为药性的转化效率最高
      - 正常吐纳本身不产生经脉压力
      - 经脉压力只在存在药性、外源资源或特殊灌注时变化
    optional_inputs:
      - 行动开始前快捷服用丹药
      - 护脉类资源
      - 定心或降压资源
  outcomes_and_feedback:
    primary_outputs:
      - 修为进度提升
      - 主修道功经验提升
      - 体内药性转化
    secondary_outputs:
      - 药性剩余时间变化
      - 经脉承载变化，仅在存在药性或外源资源时出现
      - 瓶颈或突破准备提示
    player_feedback_examples:
      - 本次吐纳推进了当前小阶段进度。
      - 清灵丹药性已吸收 6/12 小时，剩余药性暂留体内。
      - 正常吐纳未增加经脉压力；药性负载仍占用经脉承载。
  design_boundaries:
    - 主动吐纳不是唯一能消化丹药的渠道。
    - 正常吐纳不默认造成经脉压力。
    - 不允许通过事后服丹回溯本次吐纳收益。
    - 不在普通 UI 展示完整公式倍率。
```

### 4.3 主动运转

```yaml
- action_id: cultivate.active_operation
  name: 主动运转
  category: 修炼
  player_intent: 主动引导主修功法或特定法门运转，在不完全进入吐纳状态时推进修为并消化药性。
  entry_points:
    - 修为页
    - 功法页
    - 指令管理页
  availability: 角色掌握可运转功法，当前状态允许运转，且没有硬事件或正式交锋阻塞。
  time_and_pace:
    player_time_choice: 1-72 游戏小时
    default_duration: 6 游戏小时
    min_duration: 1 游戏小时
    f1_support: 长时段可参与 F1，但效率低于专注闭关或主动吐纳
    settlement_feel: 介于主动吐纳与被动运转之间，适合稳态引导药性
  inputs_and_costs:
    default_costs:
      - 游戏时间
    medicine_rule:
      - 可以消化体内药性
      - 药性转化效率低于主动吐纳，高于被动运转
      - 正常主动运转不产生经脉压力
      - 药性或外源资源才会带来经脉负载变化
    optional_inputs:
      - 行动开始前快捷服用丹药
      - 护脉资源
      - 定心资源
  outcomes_and_feedback:
    primary_outputs:
      - 少量或中等修为推进
      - 功法运转熟练度提升
      - 药性转化
    secondary_outputs:
      - 体内药性变化
      - 经脉负载提示
    player_feedback_examples:
      - 你主动运转功法，引导药性缓缓归入经脉。
      - 当前药性仍适合主动吐纳，主动运转转化效率略低。
  design_boundaries:
    - 主动运转不应完全替代主动吐纳。
    - 不默认产生经脉压力。
    - 不自动吞服未选择的丹药。
```

### 4.4 被动吐纳

```yaml
- action_id: cultivate.passive_tunai_flow
  name: 被动吐纳
  category: 修炼后台流
  player_intent: 角色在安全、非硬阻塞状态下维持低额自然吐纳，并缓慢消化体内药性。
  entry_points:
    - 后台自动生效
    - 角色状态页展示
    - 修为页摘要
  availability: 角色未处于重伤、昏迷、正式交锋、硬事件锁定或禁用修炼状态。
  time_and_pace:
    player_time_choice: 不由玩家单独排队
    default_duration: 随世界时间推进
    f1_support: 可在 F1 批量摘要中结算
    settlement_feel: 低额、慢速、不可替代主动修炼
  inputs_and_costs:
    default_costs:
      - 世界时间
    medicine_rule:
      - 可以低效消化体内药性
      - 不主动消耗未服用的丹药
      - 正常被动吐纳不产生经脉压力
      - 药性负载过高时可能出现散逸或风险提示
  outcomes_and_feedback:
    primary_outputs:
      - 少量修为增长
      - 少量药性转化
    secondary_outputs:
      - 药性即将散逸提示
      - 经脉承载接近上限提示
    player_feedback_examples:
      - 体内药性在日常吐纳中缓慢吸收。
      - 被动吐纳效率较低，主动修炼可更快消化药性。
  design_boundaries:
    - 不能替代主动吐纳。
    - 不能完成大境界突破。
    - 不能全额高效消化高价值丹药。
    - 不作为玩家普通行动队列中的手动行动。
```

### 4.5 被动运转

```yaml
- action_id: cultivate.passive_operation_flow
  name: 被动运转
  category: 修炼后台流
  player_intent: 主修功法在日常状态下自然运转，提供极低额成长与药性缓慢消化。
  entry_points:
    - 后台自动生效
    - 功法页展示
    - 修为页摘要
  availability: 角色拥有可被动运转的主修功法，且未处于禁用修炼或硬阻塞状态。
  time_and_pace:
    player_time_choice: 不由玩家单独排队
    default_duration: 随世界时间推进
    f1_support: 可在 F1 批量摘要中结算
    settlement_feel: 比被动吐纳更依赖功法状态，整体仍为低额收益
  inputs_and_costs:
    default_costs:
      - 世界时间
    medicine_rule:
      - 可以低效消化体内药性
      - 不主动消耗未服用的丹药
      - 正常被动运转不产生经脉压力
      - 药性消化效率受功法适配影响
  outcomes_and_feedback:
    primary_outputs:
      - 极低额修为增长
      - 极低额或低额药性转化
    secondary_outputs:
      - 功法自然运转日志摘要
      - 药性散逸或过载提示
    player_feedback_examples:
      - 主修功法缓慢运转，少量吸收体内药性。
      - 当前功法与药性相性一般，转化效率较低。
  design_boundaries:
    - 不能替代主动吐纳或主动运转。
    - 不能主动消耗背包丹药。
    - 不能完成大境界突破。
    - 不应成为主要修为来源。
```

### 4.6 闭关修炼

```yaml
- action_id: cultivate.seclusion
  name: 闭关修炼
  category: 修炼
  player_intent: 进入长时间低交互修炼，用于批量消化地点、资源、功法、体内药性和时间条件。
  entry_points:
    - 修为页
    - 洞府或静室入口
    - 指令管理页
    - 宗门修炼设施
  availability: 当前地点支持闭关，角色状态允许长时间修炼，并已设置结束条件、资源策略和中断策略。
  time_and_pace:
    player_time_choice: 1-90 游戏日
    default_duration: 30 游戏日
    min_duration: 1 游戏日
    f1_support: 默认可作为 F1 候选
    f1_conditions:
      - 全员处于长期低交互行动
      - 无待处理硬事件
      - 有结束条件
      - 有资源绑定或资源不足处理策略
      - 有安全默认
    settlement_feel: F1 中按外界日批量提交摘要，遇到硬中断退出到 N1/B1/P0。
  inputs_and_costs:
    default_costs:
      - 大量游戏时间
      - 可能消耗寿元
      - 可能积累心魔或枯坐风险
    medicine_rule:
      - 闭关可批量消化体内药性
      - 闭关前可允许快捷服用丹药
      - 正常闭关修行不产生经脉压力
      - 体内药性、强效灵材或阵法灌注会带来经脉负载
      - 经脉承载过高时应设置停止、降速或提醒策略
    optional_inputs:
      - 闭关资源年包
      - 聚灵石或阵法燃料
      - 修炼设施支持
      - 护法或宗门支持
      - 护脉或定心资源
  outcomes_and_feedback:
    primary_outputs:
      - 批量修为进度
      - 主修道功经验
      - 体内药性消化摘要
      - 闭关摘要
    secondary_outputs:
      - 功法研习进度
      - 寿元消耗
      - 心魔或枯坐风险
      - 经脉承载和药性残余变化
    player_feedback_examples:
      - 闭关 30 日，修为稳步增长。
      - 体内清灵丹药性已全部吸收。
      - 经脉承载接近阈值，已按预设停止继续服丹。
      - 资源将在第 18 日耗尽，继续闭关会耗寿低效。
  design_boundaries:
    - 闭关不是免费收益。
    - 正常闭关不默认造成经脉压力。
    - 药性过载、重大心魔、突破契机、洞天受袭、公共决策不能静默跳过。
    - F1 不改变修炼单位，仍按游戏时间结算。
```

### 4.7 研习功法

```yaml
- action_id: cultivate.study_method
  name: 研习功法
  category: 修炼
  player_intent: 学习或提高目标道功/法门掌握度，为后续修炼、战斗或移动解锁能力。
  entry_points:
    - 功法页
    - 修为页
    - 指令管理页
    - 功法载体详情
  availability: 角色拥有目标功法线索、载体或学习权限，当前状态允许研习。
  time_and_pace:
    player_time_choice: 1-168 游戏小时
    default_duration: 24 游戏小时
    min_duration: 1 游戏小时
    f1_support: 长时段研习可参与 F1
    settlement_feel: 按小时推进，低交互时可批量结算。
  inputs_and_costs:
    default_costs:
      - 游戏时间
      - 可能消耗功法载体耐久、借阅额度或宗门权限
    medicine_rule:
      - 普通修为丹药不因研习功法而高效消化
      - 若存在启悟类药性，应按功法研习资源处理
      - 正常研习不产生经脉压力
      - 启悟丹、强效悟性资源等外源资源可产生对应负载或副作用
    optional_inputs:
      - 启悟丹
      - 悟性类灵材
      - 辅助讲解或师承支持
  outcomes_and_feedback:
    primary_outputs:
      - 功法经验
      - 掌握度提升
      - 可修上限或能力提示
    secondary_outputs:
      - 新法门线索
      - 相性不佳提示
      - 学习瓶颈提示
    player_feedback_examples:
      - 你对《青木养真诀》的理解更深了。
      - 当前悟性不足，继续研习效率较低。
      - 此法门已可用于轻身赶路。
  design_boundaries:
    - 研习功法不直接获得修为。
    - 普通修为丹药不应通过研习功法满额转化。
    - 不替代主动吐纳。
    - 不自动消耗高价值功法载体。
```

### 4.8 巩固根基

```yaml
- action_id: cultivate.consolidate_foundation
  name: 巩固根基
  category: 修炼
  player_intent: 处理服丹、外源资源和快速成长带来的经脉压力、残余药性与根基浮躁。
  entry_points:
    - 修为页
    - 角色状态页
    - 指令管理页
  availability: 角色处于可休整或可修炼地点；存在经脉压力、残余药性、根基波动或突破准备需求时优先推荐。
  time_and_pace:
    player_time_choice: 1-168 游戏小时
    default_duration: 12 游戏小时
    min_duration: 1 游戏小时
    f1_support: 长时段可参与 F1
    settlement_feel: 偏修正型行动，收益以状态改善和风险下降为主。
  inputs_and_costs:
    default_costs:
      - 游戏时间
    medicine_rule:
      - 可收束残余药性
      - 可降低经脉压力
      - 可减少药性散逸或反噬
      - 不把残余修为药性直接转化为修为
    optional_inputs:
      - 定心丹
      - 护脉丹
      - 稳固根基类资源
      - 疗伤或降压类资源
  outcomes_and_feedback:
    primary_outputs:
      - 经脉压力下降
      - 根基稳定性改善
      - 药性风险下降
    secondary_outputs:
      - 药性散逸速度下降
      - 反噬风险下降
      - 突破准备质量改善
    player_feedback_examples:
      - 经脉压力已回落到安全范围。
      - 残余药性已被收束，未转化为修为。
      - 根基趋于稳定，突破准备评分提高。
  design_boundaries:
    - 不直接提供修为进度。
    - 不把药性当作经验一次性结算。
    - 不免费清除所有伤势、心魔或压力。
    - 不绕过大境界突破准备。
```

---

## 5. 移动行动配置样例

移动行动沿用 v0.2 口径。本轮丹药与经脉压力修改不改变移动基础规则：移动仍是改变角色所在地图节点的行动，最小消耗 1 游戏小时，普通移动默认消耗元气，不自动消耗背包物品。

### 5.1 步行赶路

```yaml
- action_id: travel.walk
  name: 步行赶路
  category: 移动
  player_intent: 从当前节点前往目标节点，承担基础时间成本、元气消耗和路线风险。
  entry_points:
    - 地图页
    - 当前节点页
    - 指令管理页
  availability: 目标节点可见或有合法线索，存在可通行路线，角色状态允许移动。
  time_and_pace:
    player_time_choice: 由路线决定
    min_duration: 1 游戏小时
    f1_support: 短途默认不进 F1；安全长途可作为 F1 候选
    settlement_feel: 按路线小时推进，途中可能触发移动来源事件。
  inputs_and_costs:
    default_costs:
      - 元气
      - 游戏时间
    optional_inputs:
      - 避险符箓
      - 避瘴丹
      - 通行令
      - 干粮或补给
    input_rule: 常规步行不自动消耗背包物品；只有路线要求、玩家主动选择或事件选项要求时才消耗。
    medicine_rule:
      - 移动默认不高效消化修为药性
      - 若角色存在被动运转，体内药性可按后台流低效处理
      - 移动本身不产生经脉压力
  outcomes_and_feedback:
    primary_outputs:
      - 角色位置改变
      - 路线经过记录
    secondary_outputs:
      - 元气消耗
      - 延误
      - 遭遇事件
      - 行踪暴露
      - 临时停靠
    player_feedback_examples:
      - 预计耗时 3 小时，消耗少量元气。
      - 山路有低风险遭遇可能。
      - 路线被临时封锁，角色停留在安全中转点。
  design_boundaries:
    - 移动不是瞬移。
    - 改变地图节点的行动最少消耗 1 游戏小时。
    - 不自动吃玩家背包中的关键资源。
    - 不展示未发现事件的完整真相。
```

### 5.2 轻身赶路

```yaml
- action_id: travel.lightness
  name: 轻身赶路
  category: 移动
  player_intent: 使用身法、轻身功法或移动能力更快、更稳地通过路线。
  entry_points:
    - 地图页
    - 功法能力入口
    - 指令管理页
  availability: 角色掌握可用轻身功法、移动法门或相关临时能力，且当前状态没有禁用移动。
  time_and_pace:
    player_time_choice: 由路线与能力修正后决定
    min_duration: 1 游戏小时
    f1_support: 安全长途可作为 F1 候选
    settlement_feel: 比步行更快或更省元气，但仍有路线与事件风险。
  inputs_and_costs:
    default_costs:
      - 元气
      - 游戏时间
    optional_inputs:
      - 移动辅助符箓
      - 法宝充能
      - 临时身法增益
    input_rule: 能力可降低耗时、元气或延误损失，但不能突破最小 1 小时规则。
    medicine_rule:
      - 轻身赶路默认不作为修为药性高效消化渠道
      - 若功法有特殊设定，可通过功法或事件覆盖
  outcomes_and_feedback:
    primary_outputs:
      - 角色位置改变
      - 移动时间降低
    secondary_outputs:
      - 元气消耗变化
      - 低阶遭遇选项改善
      - 延误损失下降
    player_feedback_examples:
      - 轻身法门使本段路程耗时减少。
      - 当前疲惫较重，轻身效果被削弱。
      - 你避开了普通山道阻碍。
  design_boundaries:
    - 轻身不是免费传送。
    - 仍然受路线可见性、通行条件和风险影响。
    - 不默认跳过移动来源事件。
    - 不默认替玩家消耗高价值移动资源。
```

### 5.3 安全长途赶路

```yaml
- action_id: travel.safe_long_route
  name: 安全长途赶路
  category: 移动
  player_intent: 选择低风险或已控制路线进行长距离移动，减少频繁操作。
  entry_points:
    - 地图页
    - 指令管理页
    - 路线预览页
  availability: 存在低风险、宗门控制或已知安全路线；预计路程较长；角色状态允许长途移动。
  time_and_pace:
    player_time_choice: 由路线总耗时决定
    suggested_min_duration: 24 游戏小时
    min_duration: 1 游戏小时
    f1_support: 默认可作为 F1 候选，但必须无待处理硬事件、无自动兜底、全员低交互
    settlement_feel: 适合批量推进，以摘要展示途中小事。
  inputs_and_costs:
    default_costs:
      - 元气
      - 游戏时间
    optional_inputs:
      - 补给
      - 护行符箓
      - 通行令
      - 交通服务费用
    input_rule: 长途安全路线优先保证不中断体验，但硬事件仍可打断。
    medicine_rule:
      - 长途赶路不是主动修炼
      - 体内药性只通过被动吐纳或被动运转低效消化
      - 移动本身不产生经脉压力
  outcomes_and_feedback:
    primary_outputs:
      - 跨节点或跨区域移动
      - 长途赶路摘要
    secondary_outputs:
      - 元气阶段性消耗
      - 普通传闻
      - 小额资源波动
      - 低风险事件自动摘要
    player_feedback_examples:
      - 你沿宗门驿道赶路 2 日，途中无大事。
      - 低风险传闻已写入摘要。
      - 前方路线出现公共封锁，F1 已中断。
  design_boundaries:
    - 自动兜底行动不能作为 F1 依据。
    - 高风险路线不应默认进入安全长途赶路。
    - 遭遇正式追击、公共封锁或玩家冲突时必须退出高速。
    - 不隐藏重大路线变化。
```

### 5.4 传送阵通行

```yaml
- action_id: travel.teleport_facility
  name: 传送阵通行
  category: 移动
  player_intent: 使用传送阵、阵台或空间设施快速前往目标节点。
  entry_points:
    - 地图页
    - 当前节点设施入口
    - 指令管理页
  availability: 当前节点存在可用传送设施，目标锚点可达，角色拥有权限并能支付费用或能量。
  time_and_pace:
    player_time_choice: 由设施路线决定
    min_duration: 1 游戏小时
    f1_support: 默认不作为 F1 行动
    settlement_feel: 快速、条件明确、资源成本更高。
  inputs_and_costs:
    default_costs:
      - 游戏时间
      - 少量元气或状态负担
    required_inputs:
      - 灵石或聚灵石
      - 传送权限
      - 设施供能或维护费用
    input_rule: 费用和权限在行动开始时生效；执行前校验失败不提前消耗。
    medicine_rule:
      - 传送不作为修为药性消化渠道
      - 传送本身不产生经脉压力
  outcomes_and_feedback:
    primary_outputs:
      - 快速抵达目标节点
    secondary_outputs:
      - 费用消耗
      - 设施使用记录
      - 传送失败或锚点异常提示
    player_feedback_examples:
      - 传送阵可用，预计耗时 1 小时。
      - 目标锚点暂不可用。
      - 宗门权限不足，无法使用此传送阵。
  design_boundaries:
    - 传送仍属于移动行动，不是无成本瞬移。
    - 改变节点仍至少消耗 1 游戏小时。
    - 设施、权限、目标锚点和费用必须可预览。
    - 不应默认进入 F1。
```

---

## 6. 不进入策划行动表的实现字段

以下字段不建议出现在行动内容配置表中：

```yaml
HiddenImplementationFields:
  - command_id
  - actor_ref
  - character_id
  - submitted_by_player_id
  - created_world_day
  - created_world_hour
  - status
  - validation.phase
  - validation.checked_world_day
  - validation.checked_world_hour
  - validation.resource_check
  - validation.location_check
  - route_segment_refs
  - event_candidate_refs
  - batch_settlement_summary_ref
  - safe_default_policy_ref
  - bound_resource_years_ref
  - selected_items
  - resource_binding_id
  - active_medicine_effect_id
  - medicine_tick_result_id
```

这些字段可以由服务端、运行时状态、日志和回放系统处理。策划配置只维护体验层规则。

---

## 7. 后续需要同步的配置表方向

若后续进入正式配置表，建议将药性相关配置拆为独立内容表，而不是塞进所有行动表。

```plain text
ActionDesignConfig              # 行动体验表
MedicineEffectDesign            # 丹药药性体验表
CultivationFlowDesign           # 修为增长流配置表
MeridianLoadRule                # 经脉承载与同服限制表
CultivationEventMedicineRule    # 修为事件消化药性规则表
```

其中 `ActionDesignConfig` 仍然面向玩家行动；`MedicineEffectDesign` 和 `CultivationFlowDesign` 决定药性如何被消化；`MeridianLoadRule` 决定能不能继续服药；`CultivationEventMedicineRule` 决定事件能不能吸收体内药性。

---

## 8. 待裁决项

1. 主动运转是否作为正式玩家行动进入普通队列。
2. 被动吐纳与被动运转是否保留为两个后台流，还是合并为一个“被动修行流”。
3. 同类修为丹药默认允许同时激活 1 种还是 2 种。
4. 药性在战斗、昏迷、重伤、局部时停和 C1 期间的默认推进策略。
5. 经脉承载上限主要由境界、体魄、功法、根基质量中的哪些因素决定。
6. 修为事件默认可消化药性，还是必须逐事件显式开启。
