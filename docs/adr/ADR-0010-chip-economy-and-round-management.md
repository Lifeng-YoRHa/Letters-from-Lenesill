# ADR-0010: Chip Economy & Round Management — Stamina as Dual Resource

## Status

Accepted

## Context

游戏的核心经济循环围绕两种资源展开：
- **Stamina（体力）**：既是生命值（受到伤害减少），也是行动资源（出牌消耗）。
- **Gold（金币）**：用于商店购买，上限 99，占用 1×1 背包格子。

回合管理方面：
- 每回合玩家有基础行动次数（初始为 3 次），受 Survivor Notes、卡牌效果（如 Adjust Breathing）或 debuff（如 Dullness）影响可能增减。
- 每回合随机激活 3 张行动卡（可升级至 5 张）。
- 敌人回合在玩家结束后自动执行。

需要决定这些数值的存储、计算和变更由哪个系统负责。

## Decision

1. **Stamina 作为单一双用途资源**：不分离 HP 和 Action Points。`Stamina` 类同时追踪 `current_stamina` 和 `max_stamina`，提供 `deduct(amount)` 和 `restore(amount)` 方法。死亡判定由 `CombatManager` 在收到 `stamina_changed` 信号后检查。

2. **Round 由 CombatManager 驱动**：`CombatManager` 维护 `_is_active` 和 `_combat_state.round_number`。回合切换是内部方法 `_start_round()` → `start_player_turn()` → `_start_enemy_turn()` → `_start_next_round()` 的调用链，不依赖 Godot 的 `_process()` 或 Timer。

3. **Action 计数独立**：每回合的行动上限存储在 `CombatState` 中，与 Stamina 解耦。`CombatManager.consume_action()` 检查 `actions_used_this_turn < max_actions_this_turn`。

4. **Gold 由 Resource System 管理**：`Inventory` 类持有 `gold_count`（上限 99），但空间占用由 `Backpack` 类管理（1×1 固定格子）。

```gdscript
class_name Stamina
extends RefCounted

signal stamina_changed(new_value: int, old_value: int)

var current_stamina: int
var max_stamina: int

func deduct(amount: int) -> void:
    var old := current_stamina
    current_stamina = maxi(current_stamina - amount, 0)
    stamina_changed.emit(current_stamina, old)
```

## Consequences

### Positive

- **资源紧张感**：同一资源同时承担 HP 和 AP，迫使玩家在"防御/逃跑"和"进攻"之间做高风险决策。
- **逻辑集中**：CombatManager 完全控制回合时序，单元测试可以精确模拟任意回合数的行为。
- **简单的心算**：玩家只需盯着一个数字（体力），无需同时管理 HP 条和蓝条。

### Negative

- **平衡敏感**：Stamina 的初始值、消耗值、恢复值任何微调都会同时影响生存能力和输出能力，调参难度大。
- **Last Effort 的边界复杂**：因为 Stamina 是 HP，所以"透支体力出牌"等于"自杀式攻击"，需要大量 edge case 规则（如 Adrenaline Needle 和 Last Effort 的触发顺序）。

## Alternatives Considered

| 方案 | 结果 | 理由 |
|------|------|------|
| **HP 与 AP 分离** | 否决 | 违背设计意图；资源极度受限是核心体验 |
| **卡牌有独立冷却而非行动次数** | 否决 | 8 张固定卡组不适合冷却制；行动次数更适配 roguelike 的短回合决策 |
| **敌人同时行动（非严格回合交替）** | 否决 | 会让玩家难以规划；当前设计意图是"玩家先动，敌人后动"的确定性节奏 |
| **每回合抽牌而非固定激活** | 否决 | 8 张固定卡组+随机激活 3 张是设计文档明确规则 |

## Related Decisions

- [ADR-0004: Resolution Pipeline](ADR-0004-resolution-pipeline.md) — 回合时序在同步逻辑层执行
- [ADR-0006: AI Strategy Pattern](ADR-0006-ai-strategy-pattern.md) — 敌人回合行为由 AI 策略决定
- [ADR-0011: Point Calculation & Hand Type](ADR-0011-point-calculation-and-hand-type.md) — 伤害计算影响 Stamina 扣除量
