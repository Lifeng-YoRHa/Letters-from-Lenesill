# ADR-0004: Resolution Pipeline — Synchronous Logic, Asynchronous Feedback

## Status

Accepted

## Context

Combat is turn-based with strict ordering: player acts → enemy acts → next round. However, Godot UI animations (damage numbers, card fly, HP bar tween) are inherently asynchronous. We needed a pipeline that:

1. Guarantees combat state is always consistent and deterministic.
2. Allows UI to animate without blocking game logic.
3. Makes unit tests possible without running the rendering thread.

## Decision

The resolution pipeline is split into two layers:

- **Logic Layer (同步)**: `CombatManager`, `DamageCalculator`, `EnemyAI` run synchronously. Methods like `deal_damage_to_enemy()`, `apply_damage_to_player()`, `resolve_enemy_turn()` mutate state immediately and return.
- **Feedback Layer (异步)**: `CombatInterface` listens to signals and triggers tweens/animations. It never mutates combat state.

```gdscript
# Logic layer — 同步，可单元测试
func deal_damage_to_enemy(amount: int) -> void:
    _combat_state.damage_enemy(amount)
    enemy_took_damage.emit(amount, _combat_state.enemy_current_hp)
    if _combat_state.enemy_current_hp <= 0:
        _end_combat(GameEnums.CombatPhase.VICTORY)

# Feedback layer — 异步，只处理表现
func _on_enemy_took_damage(amount: int, remaining_hp: int) -> void:
    _enemy_hp_bar.value = remaining_hp  # tween if desired
    _log("Dealt %d damage!" % amount)
```

**Coroutine boundary**: The only `await` in combat flow is the 0.3s pause between `end_player_turn()` and `resolve_enemy_turn()` in `CombatInterface`, giving玩家视觉缓冲. This await lives in Presentation, not in Feature logic.

## Consequences

### Positive

- **可测试性**: `CombatManager` 的完整回合可以在 GdUnit4 中单线程断言，无需等待动画。
- **确定性**: 同样的输入永远产生同样的 combat 状态；UI 动画不影响结果。
- **解耦**: 替换战斗 UI（如加入完整动画）不需要修改 `CombatManager`。

### Negative

- **时序幻觉**: UI 动画可能还在播放，但逻辑层已经进入了下一回合。需要 UI 在适当时候禁用输入（如敌方回合期间封锁按钮）。
- **状态查询歧义**: UI 查询 `_combat_manager.combat_state` 时，状态可能已经领先于动画表现。UI 必须信任信号携带的参数，而不是事后去状态对象中重新读取。

## Alternatives Considered

| 方案 | 结果 | 理由 |
|------|------|------|
| **完全同步（阻塞动画）** | 否决 | 体验差，无视觉反馈 |
| **完全异步协程管线** | 否决 | 时序难以推理，测试需模拟时间，易产生竞态 |
| **命令队列 + 帧步进** | 否决 | 对单敌人回合制过度设计；格斗游戏才需要帧级精度 |

## Related Decisions

- [ADR-0002: Card Data Model](ADR-0002-card-data-model.md) — 卡牌数据在同步层中解析
- [ADR-0003: Signal Architecture](ADR-0003-signal-architecture.md) — 信号是两层之间的边界
- [ADR-0006: AI Strategy Pattern](ADR-0006-ai-strategy-pattern.md) — AI 决策完全在同步层
