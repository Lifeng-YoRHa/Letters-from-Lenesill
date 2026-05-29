# ADR-0009: Side Pool System — Pocket as Independent Mini-Grids

## Status

Accepted

## Context

背包系统有两个存储区域：
- **Backpack（背包）**：大容量可变形状网格，非战斗状态下自由访问；战斗中需消耗行动打开。
- **Pocket（口袋）**：两个固定 1×2（可升级至 1×3）迷你网格，战斗中无需额外成本即可使用。

设计上的关键约束是：战斗中口袋和背包的访问规则截然不同。如果将口袋实现为背包的一个特殊区域，会导致访问规则耦合；如果取消口袋，则违背"战斗中快速使用少量物品"的设计意图。

## Decision

将 **Pocket 实现为独立于 Backpack 的 Side Pool（边池）系统**：

1. **独立数据结构**：`Pocket` 是一个专门的类，内部管理两个（或升级后等效数量的）`MiniGrid` 实例。它不继承 Backpack，也不依赖 Backpack 的坐标系。

2. **独立容量规则**：每个 mini-grid 是固定形状的局部容器。多个 1×1 物品可共存于同一 mini-grid，只要不重叠；2×1 旋转后的物品也可放入。

3. **独立访问接口**：
   - 非战斗状态：Pocket 和 Backpack 都可自由读写。
   - 战斗状态：只有 Pocket 可直接使用；Backpack 必须经由 `Search Backpack` 行动打开。

4. **序列化独立**：存档时 `pocket_contents` 和 `grid_layout` 是分开的字段。

```gdscript
class_name Pocket
extends RefCounted

var _mini_grids: Array[MiniGrid] = [MiniGrid.new(Vector2i(1, 2)), MiniGrid.new(Vector2i(1, 2))]

func can_fit_item(item: ItemData) -> bool:
    for grid in _mini_grids:
        if grid.can_fit(item):
            return true
    return false
```

## Consequences

### Positive

- **规则清晰**：战斗中"哪些物品可用"的判断变为"物品是否在 Pocket 中"，无需查询复杂的背包状态。
- **UI 解耦**：Pocket 的快速访问栏可以独立渲染，不需要加载完整背包网格。
- **测试简单**：可以单独测试 Pocket 的容量边界，无需构造整个 Backpack。

### Negative

- **移动逻辑重复**：物品在 Pocket ↔ Backpack 之间移动时，需要处理两个不同的坐标系和放置算法。
- **自动整理复杂度**：更换背包时的 auto-arrange 只处理 Backpack 内容；Pocket 内容保持不变，玩家可能误以为 Pocket 物品也会被重新排列。

## Alternatives Considered

| 方案 | 结果 | 理由 |
|------|------|------|
| **Pocket 作为 Backpack 的特殊区域** | 否决 | 战斗中访问规则不同，若耦合在一起，Backpack 类需维护"战斗中禁用部分区域"的复杂逻辑 |
| **无 Pocket，全部从 Backpack 取** | 否决 | 违背设计意图；战斗中翻找背包消耗行动，会大幅降低道具的战略价值 |
| **Pocket 用简单列表而非网格** | 否决 | 与背包的"空间管理"核心玩法不一致；列表无法体现 1×2 物品的旋转决策 |

## Related Decisions

- [ADR-0002: Card Data Model](ADR-0002-card-data-model.md) — 物品数据同样使用 Resource 模型
- [ADR-0005: Save/Load Strategy](ADR-0005-save-load-strategy.md) — Pocket 独立序列化
- [ADR-0008: UI Node Hierarchy](ADR-0008-ui-node-hierarchy.md) — Pocket 快速访问栏的 UI 渲染
