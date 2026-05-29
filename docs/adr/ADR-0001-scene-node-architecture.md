# ADR-0001: Scene/Node Architecture — Composition Root over Autoload Singletons

## Status

Accepted

## Context

Godot 4.x 提供 Autoload（单例节点）作为全局状态共享机制，官方文档和多数教程默认推荐此模式。但本项目采用严格的模块分层架构（Foundation → Core → Feature → Game Flow → Presentation），需要满足以下约束：

1. **可测试性**：单元测试必须在不启动完整场景树的情况下运行；Autoload 节点在测试环境下难以 mock 或替换。
2. **依赖透明**：任何子系统所需的依赖必须显式声明，而非通过全局节点隐式获取。
3. **层级隔离**：Core 层不能依赖 Feature 层，Presentation 层不能包含游戏规则；Autoload 容易打破这种有向无环的依赖结构。

## Decision

我们将使用 **GameManager 组合根（Composition Root）** 模式替代 Autoload 单例。

具体规则：

- **禁止 Autoload**：`project.godot` 中不注册任何全局单例节点。
- **显式注入**：所有需要外部依赖的类，通过 `initialize(deps...)` 方法接收依赖，而非在 `_ready()` 中调用 `get_node()` 或 `get_parent()`。
- **组合根职责**：顶层场景（如 `Game.tscn` 或当前过渡期的 `CombatInterface`）负责创建、组装并连接所有子系统，然后将组装好的对象注入下一层。
- **节点即壳**：`.tscn` 场景文件中的节点只负责信号连接、`add_child()` 和生命周期委托；所有游戏逻辑在纯脚本类（`RefCounted` 或 `Node` 子类）中实现。

## Consequences

### Positive

- **测试友好**：`CombatManager`、`EnemyAI`、`DamageCalculator` 等核心类可在 GdUnit4 中直接实例化并注入 mock 依赖，无需启动 Godot 场景树。
- **依赖可追踪**：通过 `initialize()` 的签名即可看出一个类依赖哪些外部系统，无需在场景树中逐层查找。
- **架构边界清晰**：没有全局节点可供随意引用，跨层调用必须通过显式 API，有效防止循环依赖。

### Negative

- **启动代码增多**：每个入口场景需要手动 `new()` 并 `initialize()` 所有依赖对象，组合逻辑比 Autoload 更冗长。
- **传递依赖问题**：深层对象需要的依赖，需要由组合根逐层向下传递，可能产生“依赖隧道”。（缓解：后续若规模扩大，可考虑小型工厂或容器模式，但现阶段显式传递可接受。）

## Alternatives Considered

| 方案 | 结果 | 理由 |
|------|------|------|
| **Autoload 单例** | 否决 | 破坏分层、隐式依赖、单元测试困难 |
| **get_node() / get_parent() 树遍历** | 否决 | 运行时才能发现节点缺失，重构场景树时风险高 |
| **Service Locator（半全局查找）** | 否决 | 比 Autoload 略好，但仍为隐式依赖，且 Godot 中无成熟实现 |

## Related Decisions

- [ADR-0008: UI Node Hierarchy](ADR-0008-ui-node-hierarchy.md) — 定义 Presentation 层节点如何与 Game Flow 层交互
- [ADR-0003: Signal Architecture](ADR-0003-signal-architecture.md) — 定义信号的发送方与接收方边界
- `docs/coding-standards.md` — 代码规范中关于 `initialize()` 和 `add_child()` 顺序的细则
