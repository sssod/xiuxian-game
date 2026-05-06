# 自动检查报告

检查日期：2026-05-06

生成文档数：22

## 1. 版本检查

- `v2.1`：仅作为 v2.2 来源说明或历史 Notion / 外部资源说明出现。
- `_v2.1.md`：0 处。
- `修仙轮回沙盒_设计文档包_v2.1/`：0 处。
- 当前本地交付包路径：`docs/inbox/修仙轮回沙盒_设计文档包_v2.2/`。

## 2. 旧术语残留检查

以下旧术语仍有命中，但均位于“废弃旧入口 / 字段迁移 / 冲突决议 / 禁止项 / Prompt 反向约束”等语境：

- `朔望行动格`
- `宗门经营命令`
- `宗门主行动输入`
- `SectDecisionIntent`
- `current_quarter`
- `QuarterReplay`
- `action_slot`

处理口径：

- 若表示玩家最小推进单位，使用 `turn_id`。
- 若表示世界宏观周期，使用 `macro_period_id` 或专用周期字段。
- 宗门主行动、宗门经营命令和 `SectDecisionIntent` 不进入 MVP 输入流程。

## 3. 本轮新增口径覆盖检查

已覆盖以下新增字段 / 类型：

- `theoretical_max_cap_stage`
- `mastery_cap_profile`
- `breakthrough_transition_support`
- `root_affinity_tags`
- `root_affinity_profile`
- `ActionResourceInputBinding`
- `ResourceEffectTemplate`
- `ActiveResourceEffect`
- `MethodComponentItem`
- `MethodCarrierItem`

已覆盖以下设计决议：

- 功法系统采用完整功法载体学习 + 掌握度成长。
- 残页 / 篇章不作为运行时学习进度。
- 主修道功只在大境界第一小阶段常规开放无时间成本更换。
- 丹药、灵材、符箓和临时增益资源作为行动资源输入。
- 修为丹药只挂载主动吐纳，不支持即时服丹涨修为。
- 行动未开始不消耗资源。
- 行动开始后按实际兼容小时结算资源效果。
- 未用完资源效果进入 `ActiveResourceEffect` 并可跨回合保存。
- 巩固根基可选择性收束残余修为药性，但不转化为修为进度。
- 常规 MVP 不投放 `forced_release` 修为丹药。

## 4. 仍需后续数值化事项

- 修为数值曲线。
- 根骨承载公式。
- 资源输入模板样例。
- 行动模板实际耗时、收益和风险曲线。
