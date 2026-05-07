# 经济、物品、资产容器与 NPC 持久化（v2.3）

## 1. 系统定位

经济与资产系统负责资源来源可信、物品持久化、资产容器权限、行动资源输入、交易与 NPC 状态记录。所有资源请求、预留、消耗日志使用 `world_day / world_hour / consumed_hours`。

---

## 2. AssetContainer

```text
AssetContainer {
  container_id: String
  owner_type: character | sect | node | npc | system
  owner_id: String
  location_node_id: String | null
  item_instance_refs: Array
  currency_balances: Dictionary
  access_policy: Dictionary
  audit_log_refs: Array
}
```

资产容器用于：

```text
角色背包；
宗门库存；
节点资源库；
NPC 持有物；
交易缓存；
事件临时容器。
```

---

## 3. ItemInstance

```text
ItemInstance {
  item_instance_id: String
  item_template_id: String
  container_id: String
  quantity: int
  quality: String
  tags: Array
  created_world_day: int
  created_world_hour: int
  source_ref: String
  visibility_policy: String
  bound_effect_refs: Array
}
```

物品类型：

```text
丹药；
灵材；
符箓；
法器；
功法载体；
残页 / 章节；
任务物；
后手凭据；
货币与资源包。
```

---

## 4. 行动资源输入

```text
ActionResourceInputBinding {
  binding_id: String
  owner_character_id: String
  source_container_id: String
  item_instance_id: String
  resource_template_id: String
  bound_command_id: String | null
  bound_event_option_id: String | null
  compatible_hours: int
  consumed_at_world_day: int
  consumed_at_world_hour: int
  residual_policy: String
  active_effect_ref: String | null
}
```

规则：

```text
资源输入绑定具体行动或事件选项；
入队时校验当前拥有和可用；
行动开始或事件选项生效时消耗；
消耗后写入资产流水；
未完全用完时生成 ActiveResourceEffect；
C1 追赶只补确定性资源效果。
```

---

## 5. ActiveResourceEffect

```text
ActiveResourceEffect {
  effect_id: String
  character_id: String
  source_binding_id: String
  effect_tags: Array
  started_world_day: int
  started_world_hour: int
  remaining_compatible_hours: int
  stack_policy: String
  expires_when: String
  log_refs: Array
}
```

适用：

```text
药性残余；
符箓持续效果；
灵材辅助；
临时护身；
经脉压力；
资源相性影响。
```

---

## 6. ResourceUseRequest

```text
ResourceUseRequest {
  request_id: String
  character_id: String
  source_container_id: String
  item_instance_id: String
  target_command_id: String | null
  target_event_option_id: String | null
  submitted_world_day: int
  submitted_world_hour: int
  status: pending | approved | rejected | consumed | refunded
  validation_result_ref: String
}
```

校验项：

```text
容器权限；
物品存在；
数量充足；
地点允许；
行动标签兼容；
角色状态允许；
叠加规则；
事件状态。
```

---

## 7. 交易与来源可信

每次物品转移必须写入：

```text
source_container_id；
target_container_id；
item_instance_id；
quantity；
world_day；
world_hour；
reason；
visible_log_refs；
hidden_debug_refs。
```

来源可信用于：

```text
防作弊；
回放；
任务验证；
后手争夺；
宗门审计；
NPC 关系；
多人争议处理。
```

---

## 8. NPC 持久化

```text
NpcState {
  npc_id: String
  display_name: String
  location_node_id: String
  sect_id: String | null
  realm: String
  relationship_map: Dictionary
  inventory_container_id: String
  schedule_state: Dictionary
  active_event_refs: Array
  rumor_refs: Array
  last_updated_world_day: int
  last_updated_world_hour: int
}
```

NPC 变化来源：

```text
玩家拜访；
宗门 AI；
节点事件；
交易；
战斗；
突破传闻；
后手触发；
世界演化。
```

---

## 9. 结果包

经济系统输出：

```text
inventory_delta；
currency_delta；
resource_effect_delta；
resource_use_records；
trade_records；
npc_delta；
ledger_entries；
visible_log_entries；
hidden_world_log_entries；
debug_log_entries。
```

所有输出交由 S1 合并。
