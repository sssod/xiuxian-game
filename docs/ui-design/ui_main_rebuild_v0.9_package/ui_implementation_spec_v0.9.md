# 主界面可实现规格 v0.9

**项目**：轮回修仙沙盒 / 主界面重构  
**用途**：给 UI、Godot 客户端、服务端规则对接、Figma 原型制作共用的当前实现规格。  
**版本状态**：当前为可实现规格草案，基于已确认的 S1–S7 方向与后续逐项取舍；不是最终 UI 定版。允许后续根据 Figma 实作、交互验证、开发实现继续返工或微调。  
**关键约束**：顶部与底部左下角已人工审核部分冻结；未审核区域按本规格重构。

---

## 0. 当前规格基线

已确认方向：

```text
S1 输出主界面组件树
S2 定义准备 / 规划 / 锁定等状态下组件显隐
S3 给核心组件绑定运行时字段
S4 输出 Godot UI 节点命名建议
S5 输出 MVP 验收清单
S6 保留 Figma 旧稿 → 新设计映射
S7 加入未决风险登记
```

同时沿用此前已确认的 v0.3–v0.8 设计决策：

```text
地图是顶部与底部之间的常驻视口
左右面板为覆盖层，可隐藏但不触发布局重排
左上是目标追踪栏
左下是全局消息区
地区消息与传闻锚定到地图节点旁
右侧是节点上下文面板，面板内左侧纵向页签
行动卡不使用图片，先保证功能可靠
规划阶段通过右侧行动卡设置参数并加入规划
底部预算条只展示，不直接编辑
回退可从锁定等待阶段一路退回准备阶段，但结算开始后不可回退
宗门操作统一从底部左下角宗门入口进入
```

---

## 1. 运行阶段与 UI 状态机

## 1.1 推荐 UI 状态枚举

```text
UIState_PrepareInfoProcessing
UIState_Planning
UIState_PlanningWithContinuation
UIState_PlanningContinuationCancelled
UIState_LockedWaiting
UIState_AutopilotPreview
UIState_SettlementReadonly
UIState_InsertedEvent
```

对应房间阶段：

| UI 状态 | 推荐关联 `RoomState.current_phase` |
|---|---|
| `PrepareInfoProcessing` | `report_review` / `instant_personal` |
| `Planning` | `personal_action_planning` |
| `PlanningWithContinuation` | `personal_action_planning` + 存在可延续 `ContinuousActionState` |
| `PlanningContinuationCancelled` | `personal_action_planning` + 当前 PlanningSession 删除延续项 |
| `LockedWaiting` | `waiting_lock` |
| `AutopilotPreview` | `instant_personal` 或 `personal_action_planning` 中的 UI 弹层态 |
| `SettlementReadonly` | `settlement` / `writeback` |
| `InsertedEvent` | `inserted_event` |

---

## 1.2 状态显隐表

| 组件 | 准备态 | 规划态 | 锁定等待 | 托管摘要 | 结算态 |
|---|---|---|---|---|---|
| `TopPhaseBar` | 可见 | 可见 | 可见 | 可见 | 可见 / 结算进度 |
| `MapViewport` | 可见 | 可见 | 可见只读 | 可见 | 可见只读 |
| `LeftTopGoalTrackerPanel` | 可见 / 可隐藏 | 可见 / 可隐藏 | 可见 / 可隐藏，只读 | 可见 | 可见只读或隐藏 |
| `LeftBottomGlobalNoticePanel` | 条件展开 / 可隐藏 | 可见 / 可隐藏 | 可见 / 可隐藏，只读 | 可见 | 只读 |
| `RightNodeContextPanel` | 可见 / 可隐藏 | 可见 / 可隐藏 | 可见只读 | 可见 | 只读或替换事件面板 |
| `TurnTimeBudgetBar` | 不显示 | 显示 | 显示只读 | 视所在阶段 | 只读 / 可隐藏 |
| `CurrentActionSummary` | 不显示 | 显示 | 显示只读 | 视所在阶段 | 只读 |
| `StartPlanningButton` | 显示 | 不显示 | 不显示 | 不显示 | 不显示 |
| `LockSubmitButton` | 不显示 | 显示 | 不显示 | 不显示 | 不显示 |
| `AutopilotButton` | 显示 | 显示 | 可隐藏 | 弹层激活 | 不显示 |
| `BackButton` | 不显示 | 显示 | 显示 | 视所在阶段 | 不显示 |
| `AutopilotPopover` | 不显示 | 不显示 | 不显示 | 显示 | 不显示 |

---

## 2. 主界面组件树

以下为实现级组件树建议，既可供 Godot UI 节点命名参考，也可映射到 Figma 组件层级。

```text
MainTurnWorkbenchRoot
├─ TopPhaseBar_Frozen
│  ├─ CharacterSummaryTopLeft
│  ├─ DecisionPhaseStepper
│  ├─ SubmitDeadlineBlock
│  ├─ LunarGameTimeBlock
│  └─ SettingsEntrance
│
├─ MapViewportLayer
│  ├─ WorldMapViewport
│  │  ├─ WorldMapContent
│  │  ├─ MapBaseLayer
│  │  ├─ RegionLabelLayer
│  │  ├─ RouteLayer
│  │  ├─ NodeMarkerLayer
│  │  ├─ NodeBadgeLayer
│  │  ├─ PlanIndexBadgeLayer
│  │  └─ MapInteractionOverlay
│  │
│  ├─ LeftTopGoalTrackerPanel
│  │  ├─ GoalTrackerHeader
│  │  ├─ PrimaryGoalCard
│  │  ├─ SecondaryGoalCardList
│  │  ├─ GoalClueChainPopover
│  │  └─ GoalCollapsedTab
│  │
│  ├─ LeftBottomGlobalNoticePanel
│  │  ├─ GlobalNoticeHeader
│  │  ├─ GlobalNoticeList
│  │  ├─ GlobalNoticeCard
│  │  ├─ GlobalNoticeFooter
│  │  └─ GlobalCollapsedTab
│  │
│  ├─ RightNodeContextPanel
│  │  ├─ NodeContextHeader
│  │  ├─ NodeContextVerticalTabRail
│  │  │  ├─ VTab_Detail
│  │  │  ├─ VTab_ShortActions
│  │  │  ├─ VTab_LongActions
│  │  │  ├─ VTab_ResourcesFacilities
│  │  │  └─ VTab_RisksClues
│  │  ├─ NodeDetailPage
│  │  ├─ ShortActionPage
│  │  ├─ LongActionPage
│  │  ├─ ResourcesFacilitiesPage
│  │  ├─ RisksCluesPage
│  │  └─ RightPanelCollapsedTab
│  │
│  └─ RightBottomPlanningControls
│     ├─ StartPlanningDiamondButton
│     ├─ LockSubmitDiamondButton
│     ├─ AutopilotRoundButton
│     ├─ BackSmallRoundButton
│     └─ AutopilotPopover
│
└─ BottomDockLayer
   ├─ CommonSystemEntrances_Frozen
   │  ├─ CultivationEntry
   │  ├─ ItemInventoryEntry
   │  ├─ MethodEntry
   │  ├─ MessageEntry
   │  ├─ SectEntry
   │  └─ LogLedgerEntry
   │
   ├─ TurnTimeBudgetBar
   │  ├─ DaySegmentTrack
   │  ├─ PlannedActionBarLayer
   │  ├─ OverflowIndicator
   │  └─ BudgetHoverTooltip
   │
   └─ CurrentActionSummary
```

---

## 3. 核心组件规格

## 3.1 `WorldMapViewport`

### 职责

```text
承载完整地图内容的视口
支持拖动 / 缩放 / 节点选择 / 徽记点击 / 计划序号展示
```

### 输入规则

| 操作 | 行为 |
|---|---|
| 左键点击节点 | 选中节点，右侧打开详情页。 |
| 左键点击徽记 | 选中节点，右侧打开对应纵向页签。 |
| 右键 / 中键 / 空格拖动 | 平移地图。 |
| 滚轮 | 缩放地图。 |
| 左键空白点击 | 可取消节点选中，是否关闭右侧面板由后续体验决定。 |

### 绑定字段

| UI 内容 | 数据来源 |
|---|---|
| 节点名 | `WorldNode.display_name_key` 本地化结果 |
| 节点类型 | `WorldNode.node_type` |
| 区域 | `WorldNode.region_id` / `RegionState` |
| 危险 | `WorldNode.danger_profile` |
| 灵气 | `WorldNode.aura_profile` |
| 控制权 | `WorldNode.control_owner_faction_id` |
| 影响力 | `WorldNode.node_influence_by_faction` |
| 资源徽记 | `WorldNode.resource_slots` |
| 设施徽记 | `WorldNode.building_slots` |
| 入口徽记 | `WorldNode.entrance_slots` |
| 后手徽记 | `WorldNode.legacy_layers` / `ContingencyRecord` |
| 宗门波及 | `SectContinuousActionState.target_node_id` |
| 计划编号 | `PlanningSession.instruction_queue` 中目标节点匹配 |

---

## 3.2 `LeftTopGoalTrackerPanel`

### 职责

```text
展示主目标 + 2 个次级目标
支持置顶
支持查看线索链
支持定位节点
不直接生成行动指令
```

### 绑定字段建议

```text
GoalTrackerState {
  primary_goal_id: String,
  secondary_goal_ids: Array,
  pinned_goal_ids: Array,
  goal_records: Dictionary,
  clue_chain_records: Dictionary,
  related_node_refs: Array,
  related_item_refs: Array,
  updated_this_turn: bool
}
```

### 按钮行为

| 按钮 | 行为 |
|---|---|
| 定位节点 | 地图平移到目标关联节点，右侧打开节点详情。 |
| 查看线索链 | 打开目标栏内线索链弹层。 |
| 置顶 | 改变 UI 优先级，不改变服务端任务状态。 |
| 查看全部 | 打开目标管理面板。 |

---

## 3.3 `LeftBottomGlobalNoticePanel`

### 职责

```text
显示 P0 / P1 / 目标强相关全局消息
提供归档
提供宗门面板与节点定位跳转
```

### 自动展开条件

```text
has_p0_notice == true
or has_p1_notice == true
or has_primary_goal_related_notice == true
```

### 绑定字段建议

```text
GlobalNoticeState {
  notice_id: String,
  priority: String,        # P0 / P1 / P2
  source_type: String,     # world / sect / ledger / room / rumor
  title_key: String,
  body_key: String,
  related_node_refs: Array,
  related_goal_refs: Array,
  related_sect_refs: Array,
  visibility_level: String,
  archived_by_player: bool
}
```

### 归档规则

归档只影响 UI；不删除日志、宗门摘要或轮回账本记录。

---

## 3.4 `RightNodeContextPanel`

### 职责

```text
只服务当前地图选中节点
使用面板内左侧纵向页签，视觉上可表现为玉简 / 书签 / 卷轴侧签
展示节点详情、短时行动、长时行动、资源设施、风险线索
```

### 页签

```text
纵向排列：
详情
短时行动 N
长时行动 N
资源设施 N
风险线索 N
```

### 点击映射

| 入口 | 打开页签 |
|---|---|
| 节点本体 | 详情 |
| 风险徽记 | 风险线索 |
| 传闻徽记 | 风险线索 |
| 宗门印徽记 | 风险线索，宗门波及段 |
| 资源徽记 | 资源设施 |
| 后手徽记 | 风险线索，后手段 |
| 秘境入口徽记 | 风险线索或资源设施 |

---

## 3.5 `ActionCard_NoImage`

### 职责

```text
展示一个可规划行动
先选择参数，再加入规划
不使用图片素材
```

### 基础字段

| UI 字段 | 数据字段 |
|---|---|
| 行动名 | `action_template_id` 本地化结果 |
| 行动类型 | `action_type` |
| 时间模式 | `duration_mode` |
| 预计耗时 | `planned_duration_hours` / 模板默认值 |
| 固定耗时 | `fixed_required_hours` |
| 最小有效投入 | `min_effective_hours` |
| 投入剩余时间 | `use_remaining_time` |
| 目标节点 | `target_node_id` |
| 资源预算 | `resource_budget` |
| 路线参数 | `route_params` |
| 前置条件 | `start_condition` |
| 中断策略 | `interrupt_policy` |
| 跨回合策略 | `overflow_policy` |
| 自动延续 | `auto_continue` |

### 加入规划输出

```text
PersonalActionInstruction {
  instruction_id,
  actor_ref,
  action_type,
  action_template_id,
  target_node_id,
  target_ref,
  duration_mode,
  planned_duration_days,
  planned_duration_hours,
  use_remaining_time,
  fixed_required_hours,
  min_effective_hours,
  route_params,
  resource_budget,
  start_condition,
  stop_condition,
  failure_policy,
  interrupt_policy,
  overflow_policy,
  auto_continue,
  created_turn_id,
  submitted_by_player_id
}
```

---

## 3.6 `TurnTimeBudgetBar`

### 职责

```text
展示本回合行动队列的预计时间占用
不负责编辑
```

### 不支持

```text
拖动排序
点击删除
修改时间
修改参数
```

### 显示内容

```text
第 1 天 ... 第 N 天
行动编号
行动名
延续标签
溢出 / 跨回合提示
悬停详情
当前选中行动摘要
```

### 拥挤处理

当行动很多时只显示编号：

```text
① ② ③ ④ ⑤ +3
```

悬停显示详情。

---

## 3.7 `RightBottomPlanningControls`

### 准备态

```text
StartPlanningDiamondButton
AutopilotRoundButton
```

### 规划态

```text
LockSubmitDiamondButton
AutopilotRoundButton
BackSmallRoundButton
```

### 锁定等待态

```text
BackSmallRoundButton
```

### 回退规则

```text
锁定等待态：先取消锁定，返回规划态，保留规划队列。
规划态：删除最后一条规划行动。
若队列为空：再次回退返回准备态。
结算开始后：不可回退。
```

---

## 4. PlanningSession 数据建议

UI 层可维护一个临时规划会话：

```text
PlanningSession {
  player_id: String,
  character_id: String,
  turn_id: int,
  state: String,  # editing / locked / cancelled
  instruction_queue: Array,
  selected_node_id: String,
  selected_right_panel_tab: String,
  selected_action_card_id: String,
  map_viewport_camera: Dictionary,
  continuation_seed_action_refs: Array,
  continuation_cancelled_refs: Array,
  validation_warnings: Array,
  last_back_action: Dictionary
}
```

### 进入规划阶段

```text
create PlanningSession
load eligible ContinuousActionState
convert each eligible continuation into PersonalActionInstruction preview
append as normal numbered instruction
```

### 默认延续行动

```text
行动 1｜闭关吐纳｜延续
```

它是普通规划项，占用编号，回退时按普通规划项删除。

### 退回准备阶段后再进入规划

丢弃旧 `PlanningSession`，重新读取运行时连续行动状态，再次生成默认延续规划项。

---

## 5. Godot UI 节点命名建议

以下命名可作为 Godot `Control` 节点树起点。

```text
MainTurnWorkbenchRoot : Control
  TopPhaseBarFrozen : Control
  MapViewportLayer : Control
    WorldMapViewport : Control
      WorldMapContent : Control
      MapBaseLayer : Control
      RegionLabelLayer : Control
      RouteLayer : Control
      NodeMarkerLayer : Control
      NodeBadgeLayer : Control
      PlanIndexBadgeLayer : Control
      MapInteractionOverlay : Control
    LeftTopGoalTrackerPanel : PanelContainer
      GoalTrackerHeader : HBoxContainer
      PrimaryGoalCard : PanelContainer
      SecondaryGoalList : VBoxContainer
      GoalCollapsedTab : Button
    LeftBottomGlobalNoticePanel : PanelContainer
      GlobalNoticeHeader : HBoxContainer
      GlobalNoticeScroll : ScrollContainer
      GlobalNoticeList : VBoxContainer
      GlobalCollapsedTab : Button
    RightNodeContextPanel : PanelContainer
      NodeContextHeader : HBoxContainer
      NodeContextVerticalTabRail : VBoxContainer
        VTab_Detail : Button
        VTab_ShortActions : Button
        VTab_LongActions : Button
        VTab_ResourcesFacilities : Button
        VTab_RisksClues : Button
      NodeContextPages : Control
        NodeDetailPage : ScrollContainer
        ShortActionPage : ScrollContainer
        LongActionPage : ScrollContainer
        ResourcesFacilitiesPage : ScrollContainer
        RisksCluesPage : ScrollContainer
      RightPanelCollapsedTab : Button
    RightBottomPlanningControls : Control
      StartPlanningButton : TextureButton
      LockSubmitButton : TextureButton
      AutopilotButton : TextureButton
      BackButton : TextureButton
      AutopilotPopover : PanelContainer
  BottomDockLayer : Control
    CommonSystemEntrancesFrozen : HBoxContainer
    TurnTimeBudgetBar : Control
      DaySegmentTrack : HBoxContainer
      PlannedActionBarLayer : Control
      CurrentActionSummary : Label
```

---

## 6. 旧 Figma 稿到新设计映射

| 旧 Figma 节点 | 新设计处理 |
|---|---|
| `MainFrame_1920x1080_TurnStart_InfoProcessing` | 作为原始参考，新建页面重新表现多个状态。 |
| `00_Background` | 保留纸面 / 山水底色思路，但地图视口扩展为全宽。 |
| `01_TopPhaseBar` | 冻结，不主动重构。 |
| `02_Left_PendingChangesCenter` | 替换为左上目标栏 + 左下全局消息区。 |
| `03_Map_WorldCanvas` | 从中央固定区域扩展为全宽地图视口。 |
| `04_Right_ContextPanel` | 重构为左侧纵向页签式节点上下文面板。 |
| `05_Bottom_CurrentStageActionDock_NoTimeBudget` | 准备态保留；规划态中部显示时间预算条。 |
| `06_CommonSystemEntrances_BottomLeft_CurrentStage` | 冻结；宗门相关操作统一进入宗门按钮。 |
| `Reference_TurnTimeBudget_PlanningStage_OutOfMainFrame` | 作为规划态预算条参考，但预算条仅展示，不直接编辑。 |

---

## 7. MVP 验收清单

## 7.1 Figma 验收

- [ ] 新建 `UI_MainFrame_Rebuild_v0.9` 页面。
- [ ] 至少创建 6 个状态 Frame。
- [ ] 每个 Frame 保留固定顶部栏和底部左下系统入口。
- [ ] 地图视口在所有状态中覆盖顶部与底部之间的完整区域。
- [ ] 左上目标栏和左下全局消息区可分别隐藏。
- [ ] 右侧节点面板使用面板内左侧纵向页签，不再使用顶部横向页签。
- [ ] 行动卡无图片，但包含参数区、加入规划、高级设置入口。
- [ ] 规划态底部预算条只展示，不表达可拖动编辑。
- [ ] 锁定等待态显示只读预算条和回退。
- [ ] 托管摘要是右下按钮旁弹层，不是居中模态框。

## 7.2 交互验收

- [ ] 准备态不显示回退。
- [ ] 准备态点击开始规划后进入规划态。
- [ ] 存在可延续行动时，规划态自动生成 `行动 1｜xxx｜延续`。
- [ ] 回退逐条删除规划队列，默认延续也按普通行动删除。
- [ ] 队列为空后再次回退返回准备态。
- [ ] 退回准备态后再次进入规划态，会重新显示默认延续行动。
- [ ] 锁定等待态回退取消锁定，返回规划态并保留队列。
- [ ] 结算开始后不可回退。
- [ ] 行动卡必须先选择参数，再加入规划。
- [ ] 地图节点徽记点击打开右侧对应纵向页签。

## 7.3 系统口径验收

- [ ] UI 不出现 `季度`、`朔望行动格`、`宗门主行动输入` 等旧口径。
- [ ] 宗门相关操作不在主界面直接提供，只跳转宗门面板或生成个人介入行动。
- [ ] 托管不主动执行高风险突破、高危秘境、高风险后手回收、稀有不可逆资源消耗。
- [ ] 时间预算条以天为显示单位，小时只在详情 / 悬停中展示。
- [ ] 传闻显示来源与不确定性，不表现为全知日志。

---

## 8. 风险登记

| 风险 ID | 风险 | 现阶段处理 |
|---|---|---|
| R-UI-01 | 规划行动过多时，回退链过长。 | 暂时接受；不加入队列编辑器，后续实测再评估。 |
| R-UI-02 | 时间预算条不可编辑可能让玩家觉得不方便。 | 强化右侧行动卡参数设置，预算条只展示。 |
| R-UI-03 | 无图片行动卡视觉识别度偏低。 | 先保证功能可靠，用标签、排序和文案补偿。 |
| R-UI-04 | 左上目标栏固定高度可能容纳不了复杂目标。 | 仅显示 1 主 + 2 次级，复杂线索进线索链。 |
| R-UI-05 | 左下全局消息自动展开可能遮挡地图。 | 仅 P0/P1/目标强相关自动展开，其余折叠。 |
| R-UI-06 | 锁定后可回退影响多人等待状态。 | 只允许结算前回退；顶部锁定进度实时更新。 |
| R-UI-07 | 宗门消息同时出现在左下与宗门面板。 | 左下只做摘要与跳转，完整内容进宗门面板。 |
| R-UI-08 | 地图徽记过多造成噪音。 | 每节点最多 3 个徽记，超过显示 `+N`。 |
| R-UI-09 | 传闻来源标签过多造成阅读负担。 | 只显示 1 个主来源 + 1 个可信度 / 可见性标签。 |
| R-UI-10 | Figma 初次创建长消息截断。 | 使用规格文档 + 可选插件草案先创建骨架。 |

---

## 9. 后续可返工点

以下内容不在本版定死：

1. 左右面板的精确宽度和动画。
2. 地图节点徽记的具体图形语言。
3. 右下菱形 / 圆形按钮的最终视觉。
4. 预算条在 7 天、10 天配置下的拥挤策略。
5. 插入事件态是否沿用同一右侧面板或替换为事件专用面板。
6. 目标栏“查看全部目标”的完整目标管理界面。
7. 宗门面板内部结构与主界面跳转后的落点。
