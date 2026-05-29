# Map Generation System

## Overview

The Map Generation System procedurally creates the directed graph that represents a chapter's adventure map. For each new adventure, it randomly selects one of the exist topological variants for each chapter(mind that each chapter's topological variants are seperated from each other), fixes the positions of special kind of nodes (Quest, Safe House and Black Market), fills the remaining slots from a randomized type pool, generates bidirectional connections under structural constraints, and assigns screen coordinates with per-generation jitter.

The system serves as the spatial backbone of the game: all node interactions (combat, events, shops) occur on nodes produced by this system, and the player's path-planning decisions are shaped by the revealed topology.

**Scope:** All chapters (1–4 + Final). Chapter 1 is the reference implementation; later chapters scale node counts and structural complexity but follow the same generation pipeline.

**Key characteristics:**
- **Several fixed variants** per chapter, chosen at adventure start.
- **Special node positions are invariant** across all variants and all adventures.
- **Non-special node types are randomized** per adventure from a fixed-count pool.
- **Connections respect structural slots** (fixed edges) plus random edges within constraints.
- **Fog of war:** every node that has been explored are visible(both kind and position), apart from that, direct neighbor of explored node are partly visible(only position),all other node are invisible
- **Screen layout:** horizontal layer distribution with slight random float; no strict grid.

## Detailed Rules

### Definitions

- **Node:** A single location on the map. Every node has a type, a layer index, a slot index within that layer, a screen position, and a list of bidirectional connections.
- **Layer:** A visual grouping of nodes. Layer 1 is the leftmost (closest to START), the highest layer is the rightmost (closest to BOSS). Layers are visual labels; edges may connect any layers.
- **Slot:** A named position within a layer, written as `L{layer}_{index}`. Example: `L3_2` means layer 3, slot 2.
- **Special Node:** Quest, Safe House, or Black Market. Positions are invariant per variant.
- **Structural Slot:** A non-special slot whose connections are fixed by the variant design, but whose node type is drawn from the random pool.
- **Random Pool:** The set of non-special node types and their per-chapter counts, used to fill all remaining slots.

### 1. Runtime Generation Pipeline

For every new adventure, the system executes the following steps in order:

1. **Select variant.** Randomly choose one variant from the chapter's predefined variant set (Chapter 1 has three: Free Graph, Funnel Strangulation, Loop Maze).
2. **Load layer distribution.** Read the fixed layer-to-slot-count table for the selected variant.
3. **Place special nodes.** Insert Quest, Safe House, and Black Market nodes into their fixed slots. These nodes never participate in randomization.
4. **Shuffle random pool.** Take the chapter's random pool, shuffle it, and assign the shuffled types to the remaining empty slots.
5. **Build fixed connections.** Create all bidirectional edges defined by structural slots and special-node connection tables.
6. **Build random connections.** Within the variant's constraint rules, generate edges between non-structural slots. All edges are bidirectional.
7. **Generate coordinates.** Assign each node a screen position: X = layer baseline + small random offset; Y = uniform vertical distribution within the layer + small random offset.
8. **Validate.** Assert that:
   - START can reach BOSS via some path.
   - The special-node service chain is intact.
   - Dead-end ratio is within the variant's target range.
   - No slot has more connections than the engine rendering limit.

If validation fails, the system regenerates from step 4 (keeps variant, layer layout, and special nodes; only reshuffles random pool and reconnects).

### 2. Special Node Placement

The following slots are reserved across **all** Chapter 1 variants:

| Slot | Type |
| :--- | :--- |
| L2_3 | Black Market 1 |
| L3_2 | Safe House 1 |
| L3_3 | Quest |
| L5_2 | Black Market 2 |
| L5_4 | Safe House 2 |

The exact connections of these nodes vary by variant, but their layer and slot index never change.

### 3. Random Pool (Chapter 1)

After placing 5 special nodes, 29 slots remain. They are filled from this pool:

| Type | Count |
| :--- | :-: |
| Normal Combat | 8 |
| Hard Combat | 4 |
| Random Event | 8 |
| Ruins | 3 |
| Road | 6 |

The pool is shuffled and assigned slot-by-slot to the remaining empty positions. Every adventure consumes the entire pool exactly once.

### 4. Connection Rules

All edges are **bidirectional**.

#### 4.1 Fixed Connections

Each variant defines a set of connections that are always present:

- **Special node connections:** Defined per variant (e.g., in Funnel, L2_3 always connects to L2_2, L3_2, L3_3, L2_4).
- **Structural slot connections:** Certain non-special slots have fixed edges mandated by the variant (e.g., in Free Graph, L2_1 must connect to L4_6).

#### 4.2 Random Connection Constraints

After fixed edges are placed, the generator adds edges between non-structural slots subject to the variant's constraint profile:

**Free Graph constraints:**
- Graph must remain connected from START to BOSS.
- Dead-end ratio: ~20% of nodes have degree 1.
- Same-layer clustering: connections within a layer form 2–3 node clusters, never span the full layer.
- Hub concentration: minority of nodes have degree 3–4, majority have degree 1–2.
- Cross-layer jumps: Layer i may directly connect to Layer i+2.

**Funnel Strangulation constraints:**
- Layer 4 forms a choke maze: slots L4_1–L4_4 connect only to each other; only L4_5 connects forward to Layer 5.
- South fork trap: L2_5 connects to L2_6 (which leads to dead-end L3_4) and to L3_5; L3_5 connects to L4_3 (maze trap), L4_4, and L4_5 (only exit).
- Final gamble: Layer 6 has 4 slots; 2 lead to BOSS, 2 lead to dead ends (L7_2, L7_4).
- Dead-end ratio: ~25%.

**Loop Maze constraints:**
- Fixed cross-layer loops:
  - L3_2 (Safe House 1) ↔ L1_4
  - L5_2 (Black Market 2) ↔ L3_2
  - L6_2 ↔ L4_2
  - L6_4 ↔ L4_4
- Dense subnetworks: northwest subnet (L1_4–L2_4–L3_2–L4_2–L5_2–L6_2) and southeast subnet (L3_4–L4_4–L5_4–L6_4) have heavy internal connectivity.
- L7_2 and L7_4 do not connect to BOSS.
- L3_2 is the single super-hub with degree 5+.

### 5. Node Visibility (Fog of War)

Node visibility states are defined by the **Node Interaction System** and supersede any local 3-state model in this document:

1. **Unexplored:** The node is hidden by fog of war. Neither position nor type is visible.
2. **Revealed:** The node's position is visible, but its type is hidden (shown as a silhouette). Revealed nodes are directly adjacent to a visited node.
3. **Visited:** The player has arrived at this node at least once. Type and position are fully visible. The node may or may not be interactable again.
4. **Cleared:** The node's primary interaction has been resolved (combat won, event completed, ruins searched). Type and position are fully visible. Re-interaction rules vary by type.

For fog of war reveal logic, the Map Generation System's visibility states map to the Node Interaction System's states as follows: Unexplored (hidden), Revealed (position revealed), Visited/Cleared (fully revealed). The fog of war rules in the Node Interaction System govern state transitions.

**Flashlight consumable:** When used, reveals exactly 2 random nodes (position + type), regardless of distance or visibility state. This does not change their fully-revealed status for connection drawing.

### 6. Screen Coordinate Generation

- **X-axis:** Each layer has a fixed horizontal baseline. A node's X = baseline + uniform random offset in `[-12, +12]` pixels.
- **Y-axis:** Nodes within the same layer are distributed vertically across the available screen height. A node's Y = layer_uniform_position + uniform random offset in `[-8, +8]` pixels.
- **Edges:** Rendered as straight lines between node centers. Slight Bézier curvature is allowed for same-layer edges to reduce visual overlap.

### 7. Boss Escape

Escaping from a Boss fight is a pure gameplay logic event; the map topology is **not** modified.

When the player escapes:
1. The player's current node is instantly moved to the **topologically nearest** Safe House node (shortest path distance).
2. The Boss retains its current health and will recover 50% of lost health on the next encounter (handled by combat system, not map system).

## Formulas

### Coordinate Generation

**X-axis baseline per layer:**
```
X_baseline(layer) = screen_left_margin + (layer - 1) * horizontal_spacing
```
- `screen_left_margin`: 80 px
- `horizontal_spacing`: 140 px
- `layer`: 1-indexed layer number

**Final node X:**
```
X(node) = X_baseline(layer) + randf_range(-12.0, +12.0)
```

**Y-axis uniform distribution:**
```
Y_uniform(slot_index, slots_in_layer) = top_margin + (slot_index / (slots_in_layer + 1)) * available_height
```
- `top_margin`: 60 px
- `available_height`: screen_height - 120 px
- `slot_index`: 0-indexed within the layer

**Final node Y:**
```
Y(node) = Y_uniform + randf_range(-8.0, +8.0)
```

### Dead-End Validation

```
dead_end_target_min = floor(total_intermediate_nodes * variant.dead_end_ratio_min)
dead_end_target_max = floor(total_intermediate_nodes * variant.dead_end_ratio_max)
```

| Variant | dead_end_ratio_min | dead_end_ratio_max |
| :--- | :-: | :-: |
| Free Graph | 0.18 | 0.24 |
| Funnel Strangulation | 0.23 | 0.27 |
| Loop Maze | 0.15 | 0.20 |

**Example (Chapter 1, Free Graph):**
- `total_intermediate_nodes = 34` (excluding START and BOSS)
- `dead_end_target_min = floor(34 * 0.18) = 6`
- `dead_end_target_max = floor(34 * 0.24) = 8`
- Validation passes if the generated graph has 6–8 nodes with degree == 1.

### Node Degree Distribution Targets

```
avg_degree = (2 * total_edges) / total_nodes
hub_count   = count(nodes where degree >= 3)
dead_count  = count(nodes where degree == 1)
```

**Acceptable ranges per variant (Chapter 1):**

| Metric | Free Graph | Funnel | Loop |
| :--- | :-: | :-: | :-: |
| avg_degree | 1.6–2.2 | 1.5–2.0 | 1.8–2.4 |
| hub_count (degree >= 3) | 4–7 | 3–6 | 5–8 |
| dead_count | 6–7 | 8–9 | 5–7 |

### Chapter Node Totals

```
total_nodes = 2 + sum(layer_distribution)
```

| Chapter | START + BOSS | Intermediate Nodes | Total |
| :-: | :-: | :-: | :-: |
| 1 | 2 | 34 | 36 |
| 2 | 2 | 47 | 49 |
| 3 | 2 | 55 | 57 |
| 4 | 2 | 67 | 69 |
| Final | 2 | 15 | 17 |

### Flashlight Reveal Count

```
reveal_count = 2 + survivor_note_bonus
```
- Base: 2 nodes
- `survivor_note_bonus`: +1 at Electrician stage 1 (25 uses), +1 at Electrician stage 2 (60 uses)
- Maximum: 4 nodes

### Boss Escape: Nearest Safe House

```
escape_target = argmin(safe_houses, path_distance(player_node, safe_house))
```
- `path_distance` is the shortest path length in the bidirectional graph.
- Ties are broken by lower slot index (`L3_2` before `L5_4`).

## Edge Cases

### E1. Validation Exhaustion

If the random connection phase fails validation 100 consecutive times, the generator falls back to a deterministic connection pattern that is guaranteed to pass (a minimally connected tree from START to BOSS, with extra edges added to meet the dead-end target). This prevents infinite loops on future variants with tighter constraints.

### E2. All Slots Are Structural

If a variant defines so many structural slots that no slots remain for random connection generation, the system skips step 6 (Build random connections) entirely and validates only on fixed edges. This edge case currently does not occur in any Chapter 1 variant but is handled defensively.

### E3. Flashlight Targets a Fully Revealed Node

If the flashlight randomly selects a node that is already fully revealed, the reveal has no visible effect but the consumable is still consumed. The system does not reroll.

### E4. Flashlight Targets a Node with No Position Revealed

If the flashlight targets a hidden node (neither position nor type known), that node becomes fully revealed immediately, and its connections to already-revealed neighbors are drawn. Neighbors of that node that were previously hidden now become position-revealed.

### E5. Player Escapes Boss but No Safe House Exists

If the Boss node has no path to any Safe House (theoretically impossible in all designed variants due to the service chain), the escape logic teleports the player to the **Quest node** as a failsafe. This should never trigger in practice.

### E6. Boss Escape with Equidistant Safe Houses

If two Safe Houses are exactly the same path distance from the Boss node, the tie-breaker rule (lower slot index) deterministically chooses one. The player cannot influence which Safe House they escape to.

### E7. Node Coordinate Collision

If two nodes within the same layer receive random offsets that place them within 4 pixels of each other, the generator re-rolls the Y offset for the second node up to 3 times. If collision persists after 3 retries, the node is placed at the next available uniform slot position (`slot_index + 1` modulo `slots_in_layer`).

### E8. Chapter Transition with Active Lost Letter

When entering a new chapter, the "Lost Letter" (Quest item) is automatically removed from inventory. If the player is currently carrying a "Lost Letter" from an unfinished Quest, that Quest is implicitly abandoned and must be re-acquired in the new chapter. The map generator does not track Quest state; this is handled by the Quest system before generation begins.

## Dependencies

### Upstream (systems this system depends on)

- **Boss and Chapter Transition System:** Determines which chapter is being generated and whether the player has unlocked the Final chapter (requires all 4 Survivor's Letters). The map generator only receives a chapter index; it does not query unlock state directly.
- **Survivor Notes System:** Provides the flashlight reveal bonus count. The map generator reads this value at generation time but does not modify it.
- **Screen Resolution / Display Settings:** The coordinate formulas use screen dimensions (`screen_height`). If the resolution changes mid-game, already-generated maps are not repositioned; the change takes effect on the next adventure.

### Downstream (systems that depend on this system)

- **Node Interaction System:** Every node type (Combat, Shop, Safe House, Ruins, Random Event, Quest, Road) depends on the map generator to provide the node graph, node types, and neighbor lists. The interaction system does not modify the graph structure.
- **Combat System:** Boss escape logic queries the map graph for shortest path to the nearest Safe House. Combat system also receives the Boss node's position and layer for arena background selection.
- **Rendering / UI System:** Draws nodes and edges based on screen coordinates produced by this system. The renderer reads visibility state (fully revealed / position revealed / hidden) to decide what to draw.
- **Save / Load System:** Persists the generated map graph, node types, and visibility state across pause-and-exit sessions. The save system does not regenerate the map on load.
- **Quest System:** After placing the Quest node, the map generator reports its slot ID so the Quest system can later spawn the "Lost Letter" at a compliant random node.

## Tuning Knobs

| Knob | Default | Safe Range | Gameplay Impact |
| :--- | :-: | :-: | :--- |
| `horizontal_spacing` | 140 px | 100–200 px | Controls how stretched the map feels horizontally. Lower = denser, harder to read edges. Higher = too spread out on small screens. |
| `x_jitter` | 12 px | 0–24 px | Horizontal randomness per node. 0 = perfectly aligned columns; too high = layers visually overlap. |
| `y_jitter` | 8 px | 0–16 px | Vertical randomness per node. 0 = rigid rows; too high = nodes collide within a layer. |
| `dead_end_ratio_min` / `max` | variant-specific | ±0.05 from default | Controls how often the player hits a dead end. Raising both makes the map feel more maze-like; lowering both makes routes more straightforward. |
| `validation_retry_limit` | 100 | 50–500 | How many times the generator reshuffles before falling back to deterministic mode. Lower = faster generation on weak hardware; higher = more attempts to hit ideal randomness. |
| `flashlight_base_reveal` | 2 | 1–3 | Nodes revealed per flashlight use before Survivor Note bonuses. Lower makes information scarcer; higher reduces exploration tension. |
| `collision_retry_limit` | 3 | 1–5 | How many times Y offset is rerolled when two nodes overlap. Higher = cleaner visuals but slightly slower generation. |

## Acceptance Criteria

A QA tester can verify the Map Generation System by running these checks on a fresh adventure:

1. **[Variant Selection]** Start 30 new adventures. Statistically, all variants in the chapter's set should appear at least once (not guaranteed by strict probability, but used as a smoke test).

2. **[Special Node Invariance]** In any Chapter 1 map, verify that L2_3 is always Black Market, L3_2 is always Safe House, L3_3 is always Quest, L5_2 is always Black Market, and L5_4 is always Safe House. This must hold across 10 consecutive adventures.

3. **[Random Pool Exhaustion]** In any Chapter 1 map, count the non-special nodes. There must be exactly 8 Normal Combat, 4 Hard Combat, 8 Random Event, 3 Ruins, and 6 Road nodes. No duplicates or omissions.

4. **[START-to-BOSS Connectivity]** For any generated map, perform a BFS from START. BOSS must be reachable.

5. **[Dead-End Ratio]** For any Chapter 1 map, count nodes with degree == 1 (excluding START and BOSS). The count must be within the variant's target range (Free Graph: 6–7, Funnel: 8–9, Loop: 5–7).

6. **[Bidirectional Edges]** For every edge A–B in the graph, verify that B's neighbor list contains A.

7. **[Fog of War – Initial State]** At the start of an adventure, only START is fully revealed. All nodes directly connected to START are position-revealed. All other nodes are hidden.

8. **[Fog of War – Step Reveal]** Move to an adjacent node. That node becomes fully revealed. Its previously hidden neighbors (if any) become position-revealed. No nodes beyond that become visible.

9. **[Flashlight Reveal]** Use a flashlight. Exactly 2 nodes (or 3/4 with Survivor Note upgrades) become fully revealed, regardless of previous visibility state. Connections from those nodes to already-revealed neighbors are drawn.

10. **[Boss Escape – Nearest Safe House]** Enter a Boss fight, then escape. Verify the player is teleported to the Safe House with the shortest path distance from the Boss node. If distances are equal, verify the lower slot index is chosen.

11. **[Coordinate Jitter]** Generate 5 maps of the same variant. Verify that node positions are not pixel-identical across runs (jitter is working). Verify that no two nodes within the same layer overlap visually.

12. **[Funnel Strangulation – Layer 4 Maze]** In a Funnel variant, verify that L4_1–L4_4 have no edges to Layer 5. Verify that only L4_5 connects to Layer 5 nodes.

13. **[Loop Maze – Cross-Layer Loops]** In a Loop variant, verify that L3_2 ↔ L1_4, L5_2 ↔ L3_2, L6_2 ↔ L4_2, and L6_4 ↔ L4_4 edges exist and are bidirectional.

14. **[Chapter 1 Layer Distribution – Free Graph]** Verify the layer counts are: L1=5, L2=6, L3=4, L4=6, L5=5, L6=5, L7=3.

15. **[Chapter 1 Layer Distribution – Funnel]** Verify the layer counts are: L1=6, L2=6, L3=5, L4=5, L5=4, L6=4, L7=4.

16. **[Chapter 1 Layer Distribution – Loop]** Verify the layer counts are: L1=5, L2=5, L3=5, L4=5, L5=5, L6=5, L7=4.
