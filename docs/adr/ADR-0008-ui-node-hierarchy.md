# ADR-0008: UI Node Hierarchy — CanvasLayer Overlays with Read-Only State Binding

## Status

Accepted

## Context

游戏 UI 包含多种界面：地图、战斗、背包、商店、安全屋、事件、结局等。这些界面有不同的模态行为：
- 模态（Modal）：暂停游戏逻辑，阻塞后方输入（如商店、暂停菜单）。
- 非模态（Non-Modal）：允许后方继续交互（如卡牌详情、物品详情）。

Godot 提供 `CanvasLayer` 用于独立于相机视角的 UI 渲染，`Control` 节点用于具体布局。需要一套规则防止 UI 直接修改游戏状态。

## Decision

1. **分层渲染**：所有覆盖层（Overlay）使用 `CanvasLayer` 节点，按 Z-index 堆叠：
   - `z_index = 0`：游戏视图（地图/战斗场景）
   - `z_index = 10`：HUD（体力条、金币、章节指示器）
   - `z_index = 20`：模态覆盖层（商店、背包、安全屋、事件）
   - `z_index = 30`：全局弹窗（确认对话框、丢弃提示）
   - `z_index = 40`：结局画面

2. **状态只读**：UI 脚本从不直接修改 Feature/Game Flow 层的状态。所有变更通过信号向上传递，由拥有状态的系统执行。

   ```gdscript
   # 正确：UI 发出请求，CombatManager 执行
   _end_turn_button.pressed.connect(func() -> void: _combat_manager.end_player_turn())

   # 错误：UI 直接修改状态
   # _combat_manager.combat_state.set_phase(PLAYER_TURN)  # 禁止
   ```

3. **初始化注入**：每个 UI 面板通过 `initialize(data)` 接收只读数据或回调接口，而非在 `_ready()` 中 `get_node()` 查找。

4. **模态管理**：`UIManager`（Game Flow 层）维护一个模态栈。打开模态覆盖层时压栈并暂停后方逻辑；关闭时弹栈并恢复。

## Consequences

### Positive

- **严格的单向数据流**：UI 是状态的纯函数式投影，bug 定位时无需怀疑 UI 是否偷偷改了数据。
- **层级隔离**：`CanvasLayer` 的 Z-index 天然防止渲染顺序混乱；模态栈防止输入穿透。
- **可替换性**：整个战斗 UI 可以被新的视觉主题替换，只要不改变信号接口。

### Negative

- **信号爆炸**：大量 UI 交互都需要定义信号和回调，增加了桥接代码。
- **模态栈复杂度**：当多个模态叠加（如商店里打开背包，背包里弹出确认丢弃），栈管理容易出错。

## Alternatives Considered

| 方案 | 结果 | 理由 |
|------|------|------|
| **UI 直接写状态** | 否决 | 破坏分层，测试困难，重构时风险高 |
| **每个屏幕独立 Scene 切换** | 否决 | 状态传递复杂（如战斗中打开背包需保留 combat 上下文） |
| **MVVM / 数据绑定框架** | 否决 | Godot 无原生 MVVM；引入第三方框架增加依赖 |
| **单一 CanvasLayer，靠 visible 切换** | 否决 | 模态/非模态混合时输入路由混乱，z_index 不够灵活 |

## Related Decisions

- [ADR-0001: Scene/Node Architecture](ADR-0001-scene-node-architecture.md) — 节点组装与注入规则
- [ADR-0003: Signal Architecture](ADR-0003-signal-architecture.md) — UI 与逻辑层的信号边界
- [ADR-0004: Resolution Pipeline](ADR-0004-resolution-pipeline.md) — UI 动画不阻塞逻辑
