# ADR-0006: AI Strategy Pattern — Polymorphic EnemyAI over Switch Statements

## Status

Accepted

## Context

敌人类型包括：
- 普通敌人（无特殊机制）
- 艰难敌人（带特殊机制，如 HP 阈值触发攻击+1）
- Boss（多阶段、紧急治疗、跳过玩家回合等）

需要一个可扩展的架构，使得：
1. 新敌人类型不需要修改核心战斗循环。
2. AI 逻辑可单独测试。
3. 相同基础行为可复用，特殊行为可覆盖。

## Decision

使用 **Strategy Pattern**：`EnemyAI` 作为基类，提供默认实现；每个特殊敌人/Boss 创建子类覆盖相关方法。

```gdscript
class_name EnemyAI
extends RefCounted

func decide_turn_action(enemy_data: EnemyData, combat_state: CombatState) -> EnemyAction:
    var action := EnemyAction.new()
    if _should_use_emergency_heal(enemy_data, combat_state):
        action.is_emergency_heal = true
        action.self_heal = int(enemy_data.base_hp * 0.3)
        return action
    action.damage_to_player = _get_attack_power(enemy_data, combat_state)
    action.attack_count = _get_attack_count(enemy_data, combat_state)
    return action

func _get_attack_power(enemy_data: EnemyData, combat_state: CombatState) -> int:
    return enemy_data.base_attack

# Boss 子类覆盖
class_name BossNumbnessAI
extends EnemyAI

func _should_skip_player_turn(_enemy_data: EnemyData, combat_state: CombatState) -> bool:
    return combat_state.enemy_current_hp <= 160 and not combat_state.skip_used
```

- **注入方式**：`CombatManager` 通过 `initialize()` 接收 `EnemyAI` 实例；默认使用 `EnemyAI.new()`。
- **数据驱动入口**：`EnemyData` 中包含 `ai_script: Script` 字段（或枚举映射），`CombatManager` 根据敌人类型实例化对应的 AI 子类。

## Consequences

### Positive

- **开闭原则**：新增 Boss 只需新增一个 `EnemyAI` 子类文件，不修改 `CombatManager`。
- **可测试性**：可以为单元测试注入 `MockEnemyAI` 来精确控制敌人行为。
- **复用**：普通敌人直接使用基类；艰难敌人覆盖 `_get_attack_power()`；Boss 覆盖多个钩子。

### Negative

- **小项目文件膨胀**：10 个敌人可能需要 10 个 AI 文件，虽然每个文件很小。
- **状态共享陷阱**：`EnemyAI` 实例是 `RefCounted`，若持有跨战斗的状态需小心生命周期。

## Alternatives Considered

| 方案 | 结果 | 理由 |
|------|------|------|
| **大 switch / match 语句** | 否决 | 所有特殊逻辑集中在 CombatManager，违反开闭原则，难以测试 |
| **行为树 (Behavior Tree)** | 否决 | 单敌人、回合制、无复杂寻路，行为树过度设计 |
| **状态机 (State Machine)** | 否决 | 敌人回合内行为简单（攻击/治疗/跳过），无多状态转换需求 |
| **Resource 配置的 AI 规则表** | 保留为 future | 若敌人类型超过 30 种，可考虑用数据表 + 脚本钩子混合；当前 20 种以内，纯代码更清晰 |

## Related Decisions

- [ADR-0001: Scene/Node Architecture](ADR-0001-scene-node-architecture.md) — AI 通过 initialize() 注入 CombatManager
- [ADR-0004: Resolution Pipeline](ADR-0004-resolution-pipeline.md) — AI 决策在同步逻辑层
