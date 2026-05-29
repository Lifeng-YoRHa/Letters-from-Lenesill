# ADR-0005: Save/Load Strategy — Binary Resource Serialization with Dual Layers

## Status

Accepted

## Context

Roguelike 游戏需要两种持久化：
1. **冒险中途保存**（pause-and-resume）：地图、背包、战斗状态等。
2. **跨局元进度**（meta-progression）：幸存者笔记、解锁难度、累计统计。

Godot 提供多种序列化方式：`to_json`（已废弃）、`var_to_bytes` / `bytes_to_var`、`FileAccess` 文本/二进制模式、以及 `Resource` 的 `get_property_list` 反射。

## Decision

采用 **双层二进制 Resource 序列化**：

- **Adventure Layer**：当前冒险的全部状态，用 `AdventureStateResource extends Resource` 封装。
- **Meta Layer**：跨局进度，用 `MetaStateResource extends Resource` 封装。
- **文件格式**：单文件 `user://save_slot_{N}.dat`，使用 `FileAccess` + `var_to_bytes` 写入，同一文件内包含两个层。
- **校验**：`murmur3` 哈希校验和防止篡改。
- **版本控制**：`version` 字段（当前 = 1），版本不匹配时拒绝加载。

```gdscript
class_name SaveSlotResource
extends Resource

@export var version: int = 1
@export var checksum: int
@export var last_saved_at: int
@export var adventure_layer: AdventureStateResource
@export var meta_layer: MetaStateResource
```

**触发规则**：进入/离开节点、章节过渡、打开暂停菜单、战后自动保存。500ms debounce 防连写。

## Consequences

### Positive

- **Godot 原生集成**：`var_to_bytes` 自动处理所有 `@export` 字段，包括嵌套 Resource 和 typed Array/Dictionary。
- **类型安全**：加载后得到的是强类型对象，无需手动 cast。
- **体积可控**：估算最坏情况约 14 KB，远低于 1 MB 上限。

### Negative

- **二进制不可读**：无法人工用文本编辑器查看存档内容，调试时需借助日志。
- **版本迁移成本**：修改 Resource schema 后需写迁移函数或提升 `version` 并拒绝旧存档。
- **主线程 I/O**：Godot `FileAccess` 在 Windows 上非线程安全，所有读写必须在主线程同步完成。

## Alternatives Considered

| 方案 | 结果 | 理由 |
|------|------|------|
| **JSON 文本存档** | 否决 | 无类型、需手写校验、大数组体积膨胀 |
| **SQLite** | 否决 | Godot 无原生 SQLite 支持；依赖第三方 GDExtension 增加维护成本 |
| **每系统一个文件** | 否决 | 文件数量多、一致性难保证、原子写入复杂 |
| **Godot ConfigFile** | 否决 | 设计用于配置而非状态；不支持嵌套 Resource |

## Related Decisions

- [ADR-0001: Scene/Node Architecture](ADR-0001-scene-node-architecture.md) — 组合根负责在加载后重新注入依赖
- [ADR-0002: Card Data Model](ADR-0002-card-data-model.md) — Resource 数据模型天然支持 var_to_bytes
