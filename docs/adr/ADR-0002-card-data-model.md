# ADR-0002: Card Data Model — Custom Resource over Dictionary

## Status

Accepted

## Context

The game has a fixed 8-card action deck with well-defined properties: stamina cost, effect enum, base value, display name, and optional unlock/upgrade states. We needed a data model that:

1. Survives Godot serialization for save/load.
2. Provides static typing throughout the codebase.
3. Is editable in the Godot inspector for designers.
4. Does not require hand-rolled JSON parsing.

## Decision

All card definitions use `ActionCardData extends Resource` with `@export` fields. Cards are instantiated in code via `ActionCardData.new()` or loaded from `.tres` files; they are never represented as untyped `Dictionary`.

```gdscript
class_name ActionCardData
extends Resource

@export var id: StringName
@export var display_name: String
@export var stamina_cost: int
@export var effect: GameEnums.ActionCardEffect
@export var base_value: int
```

- **Deck composition**: The 8-card fixed deck is an `Array[ActionCardData]` held by `CombatManager`.
- **Activation**: Each turn, `CombatManager` shuffles the deck and selects the first N cards into a new `Array[ActionCardData]`.
- **No mutation of definition**: Card definitions are immutable flyweights. Runtime state (e.g., "this card is disabled because weapon is broken") is tracked in `CombatState`, not in `ActionCardData`.

## Consequences

### Positive

- **Type safety**: `Array[ActionCardData]` is enforced by GDScript static typing; no string-key lookups.
- **Serialization**: `var_to_bytes` handles `Resource` subclasses automatically; no custom save logic for cards.
- **Inspector support**: Designers can tweak card values in `.tres` files without touching code.

### Negative

- **Memory overhead**: Each card in the deck is a distinct `Resource` instance (not a shared reference) because we `duplicate()` the deck to avoid mutating the source. For 8 cards this is negligible.
- **Boilerplate**: Adding a new field requires updating the `ActionCardData` script plus any `.tres` files.

## Alternatives Considered

| 方案 | 结果 | 理由 |
|------|------|------|
| **Dictionary** (`{"id": "unarmed", ...}`) | 否决 | 无类型、运行时才能发现键错误、无法 inspector 编辑 |
| **纯 GDScript 类 (非 Resource)** | 否决 | 无法直接用 `var_to_bytes` 序列化，需手写 to_dict/from_dict |
| **PackedScene 预制体** | 否决 | 卡牌是纯数据，无节点层级，用 Scene 过度设计 |

## Related Decisions

- [ADR-0001: Scene/Node Architecture](ADR-0001-scene-node-architecture.md) — 卡牌数据通过 `initialize()` 注入 CombatManager
- [ADR-0005: Save/Load Strategy](ADR-0005-save-load-strategy.md) — Resource 序列化是存档的基础
