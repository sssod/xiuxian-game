# 后手、遗产、可见性与多人间接竞争

状态：第三批正式定稿
更新日期：2026-05-08
来源主版本：v2.3 calendar_preinput

## 1. 系统定位

S7 负责跨世后手、普通遗产、隐藏层信息、可见性分发、传闻生成和多人间接竞争语义。

后手与遗产系统承载跨世连续性。玩家通过当世行动布置资源、信息、关系、节点影响或隐藏条件，在死亡、转世、节点变化、事件触发或竞争中产生延迟效果。

核心原则：

```text
后手可信；
遗产有去向；
多人间接；
信息不全知；
失效有原因链；
日志和回放可复盘。
```

S7 不直接绕过 S1 修改世界。后手、遗产、可见性、传闻和多人竞争结果必须输出结果包，由房间权威结算路径统一合并。

## 2. MVP 边界

MVP 保留：

```text
ContingencyRecord；
LegacyRecord；
ContingencyFailureReason；
后手创建、触发、失败、发现、争夺；
普通遗产生成、发现、认领、丢失、争夺；
后手 / 遗产挂载到节点、资产容器、NPC、宗门或事件目标；
private_player / known_to_party / sect_visible / rumor_visible / public_world / hidden_world / debug_only；
传闻条目；
多人资源、节点、窗口、宗门库存、路线和后手的间接竞争；
TimelineReplay 过滤与结果包记录。
```

MVP 不引入：

```text
玩家直接交易；
玩家直接赠予；
玩家共同秘境作为核心流程；
玩家互相护法作为核心流程；
离线袭击玩家主体；
围杀转世角色；
强 PvP 围杀；
复杂同宗议事投票；
后手无原因随机磨损；
世界日志全量公开；
Debug 信息进入玩家 UI。
```

直接玩家冲突若发生，必须进入 B1 `FormalEncounterState`，并受正式战斗、事件和可见性规则约束。S7 不把直接 PvP 做成默认多人压力来源。

## 3. 正式后手与普通遗产

必须区分两类跨世外在资产。

| 类型 | 规则含义 | 保护强度 |
| --- | --- | --- |
| 正式后手 | 经正式行动、事件或死亡结算封存、布置、记录的延迟安排 | 必须可追踪、有日志、失效有原因链 |
| 普通遗产 | 前世死亡、放置、遗落或组织接管后自然留在世界中的资产 / 信息 / 关系痕迹 | 可被发现、搬空、污染、破坏、转移或遗失 |

正式后手不是无限保险箱。它可以暴露、受损、触发失败或被争夺，但不能无日志、无原因地消失。

普通遗产不是正式后手。它可以作为下一世线索、回收对象或争夺对象，但只有经过正式封存、布置或转化规则后才成为 `ContingencyRecord`。

## 4. ContingencyRecord

`ContingencyRecord` 是正式后手的主记录。

```text
ContingencyRecord {
  contingency_id: String
  true_spirit_id: String
  creator_character_id: String
  created_world_day: int
  created_world_hour: int
  contingency_type: resource_cache | message | formation | relationship_debt | hidden_route | sect_influence | reincarnation_clue
  target_node_id: String | null
  target_ref: String | null
  activation_condition: Dictionary
  visibility_policy: String
  risk_tags: Array
  status: dormant | active | triggered | failed | discovered | contested
  result_package_refs: Array
}
```

字段要求：

1. `true_spirit_id` 关联跨世身份，不等同于当前角色。
2. `creator_character_id` 记录创建后手的当世角色。
3. `created_world_day / created_world_hour` 是唯一主时间，不使用 `created_turn_id` 或 `created_quarter`。
4. `target_node_id` 用于地图挂载；`target_ref` 用于关联资产容器、NPC、宗门、事件、路线、窗口或关系。
5. `activation_condition` 必须可由 S1 / S7 在结算时判定。
6. `visibility_policy` 决定后手线索、触发、发现和争夺信息如何分发。
7. `risk_tags` 只表达后手脆弱性和风险来源，不表示每小时随机检定。
8. `status` 是权威状态，UI 不一定完整显示。

## 5. 后手类型

MVP 后手类型以 v2.3 枚举为准：

| `contingency_type` | 用途 | 典型挂载 |
| --- | --- | --- |
| `resource_cache` | 藏物、灵石、丹药、法宝、功法载体、突破资源 | `AssetContainer`、节点隐藏层 |
| `message` | 遗书、暗号、路线提示、下一世提醒 | 轮回账本、节点线索、传闻 |
| `formation` | 阵法保护、封印、接引、节点影响 | 节点、路线、临时事件 |
| `relationship_debt` | NPC 承诺、宗门人情、护持关系 | NPC、宗门身份、关系记录 |
| `hidden_route` | 隐藏路线、短路入口、密道线索 | `RouteState`、隐藏层 |
| `sect_influence` | 宗门权限、宗门影响、库存申请优势 | 宗门状态、节点影响力 |
| `reincarnation_clue` | 转世后可被感应或追索的线索 | `LifeLedger`、`ReincarnationRecord`、地图隐藏层 |

旧版“藏物后手、地点后手、信息后手、权限后手、护持后手”只作为内容模板别名保留。实现层使用上述 `contingency_type`。

## 6. 后手创建

后手创建可以来自：

```text
个人 Command；
事件结果；
死亡 / 转世结算；
突破或正式交锋结果；
宗门或 NPC 关系兑现；
特定节点机会窗口；
高价值资产封存。
```

后手创建可消耗：

```text
行动小时；
资源；
物品；
宗门贡献；
NPC 关系；
地点机会；
公开代价；
隐藏代价。
```

创建流程：

```text
玩家或事件提出后手创建意图
→ S1 校验当前角色、真灵、地点、资源、权限和可见性
→ S3 校验 Command 或事件上下文
→ S6 预留或消耗资产 / 资源
→ S4 校验目标节点、隐藏层、路线或机会窗口
→ S5 校验宗门贡献、权限或关系
→ S7 生成 ContingencyRecord
→ S1 写入结果包、日志、轮回账本和 TimelineReplay
```

后手创建不是纯即时按钮。若通过主动行为创建，应是固定执行时间或可选投入执行时间的个人行动；若通过事件创建，应在事件结果包中记录成本和来源。

## 7. 后手容量与创建限制

v2.3 不把 `FormalContingencySlot` 作为 active schema。MVP 仍需要限制正式后手数量，但限制应作为校验策略，而不是旧式独立主实体。

建议规则：

```text
每个 true_spirit_id 同时可维护少量 active / dormant 后手；
高风险、高价值、可多人争夺的后手占用更高预算；
普通遗产不占正式后手预算；
被触发、失败、认领或丢失的记录仍保留历史日志；
具体容量公式作为数值与技术决策门，不在 S7 硬编码。
```

实现影响：

1. `ContingencyRecord` 是主记录。
2. 容量校验可由 `true_spirit_id`、后手状态、后手价值、境界阶段和房间配置共同计算。
3. UI 可以显示“后手占用 / 可维护数量”，但不得暴露隐藏后手的完整世界状态。

## 8. LegacyRecord

`LegacyRecord` 是普通遗产与跨世痕迹的主记录。

```text
LegacyRecord {
  legacy_id: String
  true_spirit_id: String
  source_character_id: String
  created_world_day: int
  created_world_hour: int
  legacy_type: item | method_clue | memory_tag | relationship | karma | node_hint | sect_trace
  visibility_policy: String
  inheritance_policy: String
  discovered_by: Array
  status: hidden | known | claimed | lost | contested
}
```

遗产类型：

| `legacy_type` | 用途 |
| --- | --- |
| `item` | 死亡遗留、洞府残物、组织接管资产、战利品线索 |
| `method_clue` | 完整功法载体线索、残页 / 章节线索、导师或权限线索 |
| `memory_tag` | 下一世可理解的失败、地点、人物、风险或执念标记 |
| `relationship` | NPC 承诺、恩怨、旧识、宗门评价痕迹 |
| `karma` | 因果痕迹、宿敌追索、世界回响 |
| `node_hint` | 节点、路线、秘境窗口、隐藏层提示 |
| `sect_trace` | 宗门身份、贡献、密库权限、组织记忆残留 |

遗产进入下一世时需要校验：

```text
真灵关联；
可见性；
地点；
后手状态；
竞争者干扰；
宗门或 NPC 关系；
事件结果；
存档与回放一致性。
```

## 9. 遗产生成与继承

遗产生成来源：

```text
角色死亡；
转世结算；
正式后手触发；
资产容器遗留；
NPC 或宗门接管；
重大事件后果；
突破失败或成功造成的公开影响；
节点隐藏层发现。
```

遗产继承流程：

```text
死亡或转世触发
→ S2 生成 LifeLedger / ReincarnationRecord
→ S6 处理资产去向
→ S4 处理节点、路线或隐藏层挂载
→ S5 处理宗门身份、贡献和关系痕迹
→ S7 生成或更新 LegacyRecord
→ 可见性系统决定下一世、宗门、传闻或世界可见信息
→ S1 写入结果包和 TimelineReplay
```

遗产不等于角色能力继承。功法掌握、当世境界、当世身份和随身资源默认随角色终结；跨世保留必须通过 `LegacyRecord`、`ContingencyRecord`、轮回账本或明确规则表达。

## 10. 后手感应与线索

后手感应是轮回账本和可见性系统的交互规则，不是稳定数值加成。

最小规则：

```text
玩家越接近正式后手所在区域，账本描述越清晰；
相关地点、传闻、路线、NPC 或事件可提高线索清晰度；
感应只提供线索，不自动传送、自动领取或自动避险；
真灵暴露、道韵、失败经历、地点状态和竞争压力可以影响线索质量；
高风险后手回收不得由托管主动执行。
```

线索质量可表达为：

```text
none；
vague；
regional；
node_hint；
specific_target；
access_ready。
```

线索质量是 UI 与事件模板的辅助状态，不替代 `visibility_policy` 和 `activation_condition`。

## 11. 可见性层级

S7 使用 v2.3 可见性层级：

```text
private_player
known_to_party
sect_visible
rumor_visible
public_world
hidden_world
debug_only
```

含义：

| 层级 | 可见范围 |
| --- | --- |
| `private_player` | 单个玩家 / 真灵 / 当前角色可见 |
| `known_to_party` | 当前事件、队伍、临时协作对象或受授权对象可见 |
| `sect_visible` | 宗门权限范围内可见，受职位、贡献、关系和宗门日志限制 |
| `rumor_visible` | 作为传闻、模糊信息、延迟信息或不完整情报可见 |
| `public_world` | 房间公共世界信息，可进入公开地图、速度原因或世界摘要 |
| `hidden_world` | 世界真实状态可记录，但玩家不可直接看到 |
| `debug_only` | 调试、审计、回放校验和开发工具可见 |

可见性影响：

```text
地图节点显示；
路线显示；
资源槽摘要；
机会窗口提示；
传闻推送；
NPC 对话；
宗门资源申请；
多人争夺；
后手发现；
日志分发；
TimelineReplay 过滤。
```

私人事件归因只进入本人日志、隐藏世界日志或 Debug 信息。

## 12. 可见性来源

可见性由多个来源合成：

```text
是否同节点；
是否同宗门或拥有权限；
行动是否公开；
行踪是否暴露；
是否进入传闻；
是否由宗门日志或世界事件公开；
NPC 关系；
情报能力；
后手或遗产自身 visibility_policy；
事件模板公开性；
节点人流和风险；
真灵 exposure_level；
Debug 权限。
```

合成规则：

1. 不同来源可提升可见性，但不能越过隐私红线。
2. 公开后果可以公开，私人归因不默认公开。
3. 宗门日志可显示宗门相关摘要，不泄露玩家隐秘后手真实归属。
4. 传闻可以模糊、延迟、不完整，不等同于世界真实日志。
5. Debug 层不参与玩家 UI。

## 13. 世界日志与传闻

世界日志默认玩家不可见。玩家看到的是：

```text
角色日志；
宗门摘要；
轮回账本；
地图公开变化；
传闻；
事件报告；
调试面板中被授权的 Debug 信息。
```

传闻由世界日志、事件结果、宗门动作、节点变化、突破公开影响、后手暴露或遗产争夺生成。

`RumorEntry` 推荐结构：

```text
RumorEntry {
  rumor_id: String
  source_ref: String
  created_world_day: int
  created_world_hour: int
  visibility_policy: String
  node_id: String | null
  sect_id: String | null
  confidence: low | medium | high
  delay_hours: int
  summary_text_key: String
  hidden_truth_ref: String | null
}
```

传闻生成受以下因素影响：

```text
事件公开性；
地点人流；
宗门关系；
玩家声望；
行踪暴露标签；
事件严重度；
情报能力；
节点控制权；
宗门清查；
后手风险标签。
```

传闻文本应描述可见后果，不应泄露 `hidden_truth_ref`。

## 14. 多人间接竞争

MVP 多人竞争重点：

```text
节点资源被采集或封锁；
秘境窗口被提前触发；
宗门库存被申请；
路线被发现、封锁或泄露；
传闻改变玩家判断；
NPC 关系偏移；
后手被发现或争夺；
突破公开影响改变宗门和世界态势。
```

多人原则：

```text
分宗并行；
间接竞争；
PvE 沙盒演化；
信息不完全；
不以高频社交和强 PvP 为 MVP 核心。
```

同宗多人不走强制投票，不恢复宗门主行动建议，也不引入 `SectDecisionIntent`。同宗玩家通过资源申请、事件处理、宗门贡献、职位、NPC 关系、传闻和个人行动间接影响彼此。

## 15. 竞争对象与争夺策略

S7 支持的竞争对象：

| 对象 | 竞争方式 | 可见结果 |
| --- | --- | --- |
| 节点资源 | 采集、宗门控制、事件消耗、后手封存 | 资源槽变化、库存短缺、传闻 |
| 秘境 / 机会窗口 | 进入、提前触发、名额占用、关闭 | 窗口状态、错过提示、传闻 |
| 宗门库存 | 申请、预留、消耗、奖励、清查 | 宗门摘要、申请结果、审计日志 |
| 路线 | 发现、封锁、泄露、临时开启 | 地图变化、路线提示、传闻 |
| NPC 关系 | 债务兑现、恩怨、关系偏移、死亡 | NPC 对话、事件入口、隐性权重 |
| 后手 / 遗产 | 发现、触发、争夺、搬空、污染 | 线索变化、争夺事件、失败原因链 |
| 突破公开影响 | 宗门评价、世界传闻、资源压力 | 公开日志、传闻、宗门态势 |

竞争可产生 `contested` 状态，也可进入事件链或 B1 `FormalEncounterState`。进入 B1 时，S7 只提供可见性、后手和遗产上下文，不替代战斗规则。

## 16. 后手触发

触发来源：

```text
world_hour 到达条件；
角色死亡或转世；
玩家进入节点；
NPC 关系变化；
宗门行动；
事件结果；
竞争者发现；
资源被取走；
宏观周期变化。
```

触发条件必须写在 `activation_condition` 中，并能由服务器权威校验。

触发结果：

```text
资源生成或转移；
信息提示；
路线显现；
阵法或保护生效；
宗门关系变化；
NPC 债务兑现；
失败或暴露；
多人争夺事件。
```

触发流程：

```text
S1 hour_tick 或事件结果调用 S7
→ 筛选 activation_condition 满足的 ContingencyRecord
→ 校验 target_node_id / target_ref 当前状态
→ 校验可见性、竞争和风险
→ 生成结果包
→ 更新后手状态
→ 写入日志、轮回账本、传闻和 TimelineReplay
```

C1 追赶期间只补确定性后手结果，不触发新的随机个人机缘。若后手触发导致公共 P0、正式交锋或重大公开事件，应交给 S1 速度状态机处理。

## 17. 后手失败与争夺

`ContingencyFailureReason` 记录正式后手失败、暴露、争夺失败或失效原因。

```text
ContingencyFailureReason {
  reason_id: String
  contingency_id: String
  failure_world_day: int
  failure_world_hour: int
  reason_tags: Array
  discovered_by: Array
  result_package_refs: Array
}
```

失败原因示例：

```text
节点被占；
资源被采尽；
宗门清查；
NPC 死亡；
竞争者发现；
世界事件破坏；
触发条件被改变；
目标资产被转移；
隐藏路线被封锁；
机会窗口关闭。
```

失败要求：

1. 正式后手失效必须有原因链。
2. 原因链必须记录 `failure_world_day / failure_world_hour`。
3. 若玩家有感应、线索或相关可见性，应产生可追查提示。
4. 失败可以给出补救事件、资产去向、损毁解释或传闻。
5. 不做每回合、每季度或无世界变化的随机磨损。

## 18. 后手回收

后手回收是个人行动和事件链，不是自动领取。

回收流程：

```text
玩家获得后手线索
→ 通过地图、传闻、账本感应定位区域
→ 规划 Command 前往节点或目标
→ 触发隐藏层 / 后手层事件
→ 检查访问条件、封存状态、风险状态和竞争状态
→ 处理守卫、污染、被发现、被搬空、争夺等结果
→ 生成回收、失败或争夺结果包
→ S1 回写资产、账本、节点状态、关系和日志
```

高风险后手回收不得由自动兜底或显式托管主动执行。托管可以维持安全行为，但不能主动暴露、移动、回收或销毁核心后手。

## 19. 与其他系统的集成

与 S1：

```text
所有后手、遗产、可见性、传闻和竞争结果进入 ResultPackage；
结果包由 room authoritative settlement 合并；
TimelineReplay 记录创建、触发、失败、争夺、发现和可见性变化；
速度状态由 S1 决定。
```

与 S2：

```text
读取 TrueSpiritState、CharacterState、LifeLedger、ReincarnationRecord；
死亡、转世和真灵暴露变化可生成后手或遗产；
TrueSpiritState.known_contingency_refs 只表示当前真灵已知后手。
```

与 S3：

```text
后手创建、搜寻、回收、封存和触发响应通过 Command 或事件入口执行；
队列执行前再次校验位置、权限和目标状态；
自动兜底不得主动回收高风险后手。
```

与 S4：

```text
后手和遗产可挂载到节点、路线、资源槽、隐藏层和机会窗口；
节点控制、风险、资源和窗口变化可触发后手风险检定；
地图 UI 只展示可见层级内的信息。
```

与 S5：

```text
宗门贡献、权限、库存、职位、清查和宗门 AI 行动可影响后手；
后手可影响宗门关系、节点影响力或库存申请优势；
宗门日志不得泄露隐秘后手真实归属。
```

与 S6：

```text
资源、物品和高价值资产通过 AssetContainer 封存、转移或回收；
后手资产封存和回收必须写资产流水；
普通遗产的资产去向由经济系统处理。
```

与 S8 / 事件与战斗：

```text
后手触发可生成事件、选择、正式交锋或突破上下文；
直接玩家冲突进入 FormalEncounterState；
事件公开性决定传闻和可见性分发。
```

## 20. 结果包与回放

S7 输出：

```text
contingency_delta；
legacy_delta；
visibility_delta；
rumor_entries；
resource_delta；
relationship_delta；
node_delta；
ledger_entries；
visible_log_entries；
hidden_world_log_entries；
debug_log_entries。
```

建议结果包细分：

```text
contingency_created；
contingency_triggered；
contingency_failed；
contingency_discovered；
contingency_contested；
legacy_created；
legacy_claimed；
legacy_lost；
visibility_changed；
rumor_created。
```

必须进入 `TimelineReplay` 的记录：

```text
后手创建；
后手触发；
后手失败；
后手争夺；
后手发现；
普通遗产生成、认领、丢失或争夺；
可见性变化；
传闻生成；
多人间接竞争结果；
与后手相关的资产、节点、关系和宗门变化。
```

回放过滤要求：

1. 玩家回放只显示其可见层级内的信息。
2. 调试回放可查看 `hidden_world` 和 `debug_only`。
3. 同一结果包可产生不同可见摘要。
4. 公开速度变化不得泄露私人事件归因。

## 21. UI 与验收约束

稳定 UI 要求：

```text
轮回账本展示已知后手、普通遗产线索、失败原因和下一世可用提示；
地图只展示可见节点、可见路线、可见后手线索和传闻；
后手创建界面展示成本、风险、可见性和可能触发条件；
后手回收界面展示线索质量、行动入口、风险和竞争状态；
多人摘要展示公开后果、宗门态势、节点变化和传闻，不展示私人归因；
Debug 面板可查看完整后手记录、遗产记录、可见性层级和结果包引用。
```

验收检查：

1. 后手使用 `ContingencyRecord`，主时间为 `created_world_day / created_world_hour`。
2. 普通遗产使用 `LegacyRecord`，不默认等同正式后手。
3. 后手创建消耗明确行动小时、资源、物品、贡献、关系或机会。
4. 高价值后手物通过 `AssetContainer` 封存和回收。
5. 后手触发、失败、争夺和发现都进入结果包。
6. 后手失效必须有 `ContingencyFailureReason` 或等价原因链。
7. 不存在无原因随机磨损。
8. 玩家 UI 只显示符合可见性的信息。
9. 传闻不等同于全知世界日志。
10. 多人竞争主要通过节点、资源、宗门、路线、NPC、传闻、后手和窗口间接发生。
11. 直接玩家冲突进入 B1 `FormalEncounterState`。
12. `TimelineReplay` 记录后手、遗产、可见性和多人竞争变化，并支持过滤。

## 22. Deprecated aliases 与迁移说明

| 旧口径 | 当前处理 | 说明 |
| --- | --- | --- |
| `spirit_id` | 迁移为 `true_spirit_id` | 与术语表和 S2 真灵字段统一 |
| `created_by_character` | 迁移为 `creator_character_id` | 与 v2.3 `ContingencyRecord` 对齐 |
| `created_turn_id` | 废弃 | 后手创建时间使用 `created_world_day / created_world_hour` |
| `created_quarter` | 废弃 | 不再使用季度作为后手主时间 |
| `failure_turn_id` | 废弃 | 失败时间使用 `failure_world_day / failure_world_hour` |
| `failure_quarter` | 废弃 | 不再使用季度失败时间 |
| `node_id / layer_id` 作为后手唯一目标 | 迁移为 `target_node_id / target_ref` | 后手可挂载节点、资产、NPC、宗门、路线、窗口或事件 |
| `private / local_visible / world_visible` | 迁移到 v2.3 可见性枚举 | 使用 `private_player / known_to_party / public_world` 等统一层级 |
| 行动格消耗 | 废弃 | 后手创建与回收消耗行动小时或事件成本 |
| `FormalContingencySlot` active schema | 暂不采用 | 后手容量作为校验策略，不作为 v2.3 主状态实体 |
| 宗门主行动建议冲突 | 废弃 | MVP 移除宗门主行动建议、提案和 `SectDecisionIntent` |
| 每季度后手随机磨损 | 废弃 | 失败必须有世界变化、竞争、清查、事件或条件变化原因 |
| Debug 世界日志玩家可见 | 废弃 | Debug 只用于开发、审计和调试回放 |

## 23. 来源与裁决

吸收来源：

```text
v2.3 07_后手遗产_可见性_多人间接竞争
v2.3 03_术语表_命名规范_字段统一
v2.3 01_运行时状态_数据模型_结果包
v2.3 02_角色真灵轮回_修炼养成
v2.3 03_个人行动队列_移动通行_托管
v2.3 04_地图节点_世界演化
v2.3 05_宗门组织_库存_宗门AI持续行动
v2.3 06_经济物品资产_NPC持久化
v2.3 08_事件突破战斗时间规则
v2.3 02_MVP开发切片与验收清单
v2.3 05_原始文档映射与来源索引
```

参考来源：

```text
v2.2 后手遗产_可见性_多人间接竞争
旧版 S11 前世后手、遗产与隐藏层子系统设计案
旧版 S13 多人互动、间接竞争与可见性子系统设计案
旧版 20260427 后手遗产_可见性_多人间接竞争
```

裁决：

| 采用方案 | 废弃方案 | 原因与实现影响 |
| --- | --- | --- |
| `ContingencyRecord` / `LegacyRecord` 作为 S7 主记录 | 普通遗产与正式后手混用 | 后手有强追踪和原因链，普通遗产可自然流转或丢失 |
| 主时间使用 `world_day / world_hour` | `created_turn_id`、`created_quarter`、`failure_quarter` | 与共享连续日历、结果包和 `TimelineReplay` 对齐 |
| 后手容量作为校验策略 | `FormalContingencySlot` active schema | v2.3 未保留独立槽位实体；MVP 需要限制数量但不锁死公式 |
| 后手创建消耗行动小时、资源、物品、贡献、关系或机会 | 纯即时布置或行动格消耗 | 与 `Command`、事件结果和资产容器一致 |
| 可见性使用 v2.3 七层枚举 | `private / local_visible / world_visible` 旧层级 | 玩家 UI、宗门摘要、传闻和 Debug 需要统一过滤 |
| 多人竞争以间接竞争为核心 | 玩家直接交易、赠予、共同秘境、离线袭击、强 PvP | MVP 验证共享世界压力，不把核心体验变成直接对抗 |
| 后手失败必须有原因链 | 每季度随机磨损或年久失修默认随机风险 | 轮回体验必须可信、可追查、可回放 |
| 同宗玩家通过资源申请、贡献、事件和传闻间接影响 | 宗门主行动建议冲突、强制投票、`SectDecisionIntent` | 与宗门 AI 持续行动 canonical 文档保持一致 |
| 直接玩家冲突进入 B1 `FormalEncounterState` | S7 内部处理直接 PvP | 事件、战斗和突破时间规则已定义正式交锋合同 |
