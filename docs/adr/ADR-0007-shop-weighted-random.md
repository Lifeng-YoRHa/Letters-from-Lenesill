# ADR-0007: Shop Weighted Random — Cumulative Roulette with Per-Slot Independent Roll

## Status

Accepted

## Context

Black Market 商店有 5 个固定槽位：
- 槽位 1–3：固定为 Energy Drink、Stone、Whetstone（数量随机）
- 槽位 4：Torch (60%) / Relic (30%) / Weapon (10%)
- 槽位 5：Flashlight (60%) / Safe House Key (30%) / Backpack (10%)

**任务驱动的第 6 槽位**：当玩家已接取包含 "Lost Letter"（遗失的信件）的任务时，系统会先按全局概率决定该道具的刷新节点类型（艰难战斗 70% / 黑市 15% / 安全屋 10% / 普通战斗 5%）。若 roll 中黑市，则在该章节所有黑市节点中均匀随机选择一个，该被选中的黑市临时扩展为 6 槽位，第 6 槽固定出售 Lost Letter。Lost Letter 不占用原有 5 个槽位的任何位置，不参与常规库存的加权随机。

需要一个算法来根据权重选择槽位内容，同时保证：
1. 概率精确可控，可测试。
2. 实现简单，无需外部库。
3. 同一章节内库存持久化，不随重访刷新。

## Decision

采用 **累积权重轮盘算法（Cumulative Weighted Random）**，每个可变槽位独立计算：

```gdscript
func weighted_pick(items: Array[ShopItemDef]) -> ShopItemDef:
    var total_weight: float = 0.0
    for item in items:
        total_weight += item.weight

    var roll := _rng.randf_range(0.0, total_weight)
    var cumulative: float = 0.0
    for item in items:
        cumulative += item.weight
        if roll <= cumulative:
            return item
    return items[-1]  # fallback
```

**关键规则**：
- 每个槽位的权重总和独立计算，槽位之间互不干扰。
- Relic 出现时会检查 Survivor Notes 解锁状态和玩家是否已持有；不满足则重 roll 同类别。
- 数量（如 Energy Drink ×3）与价格是独立的第二次随机：先定种类，再 roll 数量范围。
- 商店库存生成后存入 `AdventureStateResource`，同一章节内不再重新生成。
- **第 6 槽位（Lost Letter）**：在地图生成阶段，Quest System 决定 Lost Letter 的刷新节点类型（艰难战斗 70% / 黑市 15% / 安全屋 10% / 普通战斗 5%）。若 roll 中黑市，则在该章节所有黑市节点中均匀随机指定一个目标黑市；该黑市在库存生成时会在常规 5 槽位之后追加第 6 槽位，固定出售 Lost Letter（价格由任务系统按章节指定）。该槽位不参与加权随机，购买后该黑市恢复为 5 槽位。

## Consequences

### Positive

- **概率精确**：权重直接映射到概率，无需预生成全排列表。
- **实现简洁**：50 行内完成，纯 GDScript，无依赖。
- **可测试性**：注入固定 seed 的 `RandomNumberGenerator` 可得到确定性结果，便于断言。

### Negative

- **权重总和需每次重算**：若槽位配置频繁变化，累积和重复计算有微小开销（对 3–5 个选项可忽略）。
- **重 roll 逻辑可能隐藏复杂度**：Relic 被过滤后的替补规则需在文档中显式说明，否则调试时难以理解为什么某次 roll 出了 Torch 而不是 Relic。

## Alternatives Considered

| 方案 | 结果 | 理由 |
|------|------|------|
| **简单随机 + 事后过滤** | 否决 | 若过滤条件严格（如 Relic 已全持有），可能多次无效 roll，性能差且概率失真 |
| **预生成全排列表** | 否决 | 5 个槽位、多种类别组合数不大，但维护额外数据文件增加负担 |
| **Alias Method (Vose)** | 否决 | O(1) 查询最优，但初始化复杂；对 3–5 个选项的槽位不值得 |
| **按章节写死 stock 表** | 否决 | 违背 roguelike 的随机性设计意图 |

## Related Decisions

- [ADR-0005: Save/Load Strategy](ADR-0005-save-load-strategy.md) — 商店库存随 Adventure Layer 持久化
- [ADR-0002: Card Data Model](ADR-0002-card-data-model.md) — 商品定义同样使用 Resource 数据模型
