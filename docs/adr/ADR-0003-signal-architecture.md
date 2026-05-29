# ADR-0003: Signal Architecture — Typed Signals with Explicit Ownership

## Status

Accepted

## Context

Godot 4.x offers two ways to connect signals: typed `signal_name.connect(callable)` (推荐) and legacy string-based `connect("signal_name", callable)`. Additionally, large Godot projects often adopt a global "Event Bus" singleton to decouple emitters from listeners. We needed rules that:

1. Prevent runtime spelling errors.
2. Make signal flows traceable without global indirection.
3. Keep tests runnable without the full scene tree.

## Decision

1. **Typed signals only**: All signals are declared with `signal name(args: Type)` and connected via `.connect(callable)`. String-based `connect()` is forbidden.
2. **No Event Bus**: There is no global signal router. Signals are emitted and connected within known parent-child boundaries.
3. **Explicit ownership**: The object that creates a subsystem is responsible for connecting its signals. Example: `CombatInterface` creates `CombatManager`, so `CombatInterface` connects all `CombatManager` signals to its own handlers.
4. **Signal direction**: Core/Feature layers emit signals upward; Presentation layers listen and react. Game Flow layers may bridge signals between two Feature systems when direct coupling would create a cycle.

```gdscript
# CombatManager.gd (Feature layer)
signal player_took_damage(amount: int, remaining_stamina: int)

# CombatInterface.gd (Presentation layer) — the owner connects
func _connect_signals() -> void:
    _combat_manager.player_took_damage.connect(_on_player_took_damage)
```

## Consequences

### Positive

- **Compile-time safety**: Misspelled or mismatched-arity connections are caught before running.
- **Traceability**: To find who listens to `player_took_damage`, grep for `.connect(_on_player_took_damage)` — no hidden global subscriptions.
- **Testability**: Unit tests can instantiate `CombatManager` and assert on emitted signals using a Dictionary spy; no scene tree required.

### Negative

- **Bridge boilerplate**: When two Feature systems need to communicate (e.g., Combat → Inventory for loot), a Game Flow class must wire the signals manually.
- **Refactoring cost**: Renaming a signal requires updating all `.connect()` call sites; grep mitigates this.

## Alternatives Considered

| 方案 | 结果 | 理由 |
|------|------|------|
| **String-based `connect()`** | 否决 | Godot 4.0 已废弃，无编译时检查 |
| **Global Event Bus (Autoload)** | 否决 | 与 ADR-0001（禁止 Autoload）冲突；隐藏依赖难以追踪 |
| **Callback / Callable 注入** | 否决 | GDScript lambda 闭包在循环变量捕获上易出错；信号更符合 Godot 习惯 |

## Related Decisions

- [ADR-0001: Scene/Node Architecture](ADR-0001-scene-node-architecture.md) — 显式注入与信号连接的结合模式
- [ADR-0008: UI Node Hierarchy](ADR-0008-ui-node-hierarchy.md) — UI 层如何监听 Feature 层信号
