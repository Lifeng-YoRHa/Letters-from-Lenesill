# ADR-0011: Point Calculation & Hand Type — Linear Additive Formula with Floor of 1

## Status

Accepted

## Context

战斗中的伤害计算涉及多个加减项：
- 基础伤害（卡牌基础值或武器攻击力）
- 固定加成（Summon Courage +2、Cross +1、Combat Manual +2、Brilliant Statue +2）
- 减伤（Dodge -4、Smoke Grenade -2、敌人特殊机制减伤）
- Debuff 影响（Cowardice -2、Madness +1）
- 最小伤害约束

需要一个公式，使得玩家可以在战斗中快速心算，同时保证测试断言简单。

## Decision

采用 **线性加法公式，最小伤害为 1**：

```gdscript
func calculate_player_damage(
    base_damage: int,
    combat_state: CombatState,
    enemy_damage_reduction: int = 0,
    relic_damage_bonus: int = 0,
    delirium_triggered: bool = false
) -> int:
    if delirium_triggered and combat_state.active_debuffs.has(GameEnums.DebuffType.DELIRIUM):
        return 0

    var damage := base_damage
    if combat_state.courage_active:
        damage += 2
    damage += relic_damage_bonus

    if combat_state.active_debuffs.has(GameEnums.DebuffType.COWARDICE):
        damage -= 2
    if combat_state.active_debuffs.has(GameEnums.DebuffType.MADNESS):
        damage += 1

    damage -= enemy_damage_reduction
    return maxi(damage, 1)
```

**关键规则**：
- 所有加成/减伤都是 **固定数值**（flat），没有乘区。
- `maxi(damage, 1)` 保证无论减伤多高，至少造成 1 点伤害（Delirium 的 0 伤害是显式例外）。
- 敌人对玩家的伤害同样使用线性模型：`maxi(enemy_attack - dodge_reduction, 0)`，这里允许减到 0（Dodge 可以完全规避伤害）。

## Consequences

### Positive

- **心算友好**：玩家看到"敌人 ATK 4，我有 Dodge -4"，立刻知道受伤 0。
- **测试简单**：输入固定时输出完全确定，无需处理浮点误差或随机波动。
- **可预测性**：Roguelike 的核心是信息决策；确定性伤害让玩家可以精确规划斩杀线。

### Negative

- **后期数值平淡**：随着章节推进，敌人 HP 和攻击力增长，但玩家的固定加成不变，可能导致后期"刮痧"感。缓解：通过 Survivor Notes 升级和更强武器来 scaling。
- **无暴击/随机波动**：缺少惊喜感，但这也符合设计意图（资源受限下的精确计算）。

## Alternatives Considered

| 方案 | 结果 | 理由 |
|------|------|------|
| **乘区公式（如暗黑破坏神式）** | 否决 | 对小数值系统过度膨胀；3 点基础伤害×1.5=4.5，需要取整，引入不确定性 |
| **百分比减伤** | 否决 | 玩家难以心算；"减伤 30%"对 ATK 4 和 ATK 8 效果不同，增加认知负担 |
| **掷骰伤害（如 D&D）** | 否决 | 违背确定性设计；roguelike 的惩罚已足够重，随机伤害会让玩家感到不公平 |
| **无最小伤害限制** | 否决 | 会导致高减伤敌人完全免疫，玩家无计可施，体验极差 |

## Related Decisions

- [ADR-0002: Card Data Model](ADR-0002-card-data-model.md) — 卡牌 base_value 是伤害公式的输入
- [ADR-0004: Resolution Pipeline](ADR-0004-resolution-pipeline.md) — 伤害计算在同步逻辑层完成
- [ADR-0010: Chip Economy & Round Management](ADR-0010-chip-economy-and-round-management.md) — 伤害结果直接扣除 Stamina
