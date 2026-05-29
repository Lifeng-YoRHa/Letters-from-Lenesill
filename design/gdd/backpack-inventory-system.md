# Backpack & Inventory System

## Overview

The Backpack & Inventory System manages all item storage, equipment, and spatial organization for the player. It distinguishes between the **pocket** (two fixed 1×2 mini-grids, always accessible in combat) and the **backpack** (variable grid shape, while in combat, only via the Search Backpack action can gain access, while freely access while moving between nodes). Items occupy physical space with width × height dimensions; they can be rotated freely. Gold coins always occupy 1×1 regardless of count.

The system enforces hard capacity limits: if a new item cannot fit, the player must either abandon it or make room. When swapping backpacks, the old contents are auto-arranged into the new grid according to a fixed priority order; overflow is discarded.

**Scope:** All items (weapons, consumables, relics, gold, quest items, password boxes). Covers inventory UI, combat pocket access, backpack auto-arrange, and shop sell/buy interactions.

**Key characteristics:**
- **Free rotation:** Any item can be rotated 90° (1×2 ↔ 2×1).
- **Grid-based storage:** Every backpack has a unique grid silhouette; items must fit entirely inside empty cells.
- **Pocket combat access:** Items in the pocket mini-grids are usable during combat without spending the Search Backpack action.
- **Auto-arrange on swap:** Changing backpacks triggers priority-based repacking; overflow is silently lost.
- **Gold is spatial:** Coins occupy 1×1 even at 0 count; dropping to 0 gold does not remove the slot occupation.

## Detailed Rules

### Definitions

- **Pocket:** Two fixed 1×2 mini-grids, always accessible. Items placed here can be used in combat directly, but each use consumes 1 action. Each mini-grid operates like an independent 1×2 backpack: multiple smaller items can share a slot as long as their combined footprint fits within the 1×2 bounds and they do not overlap.
- **Backpack:** A variable grid of empty cells. The player owns exactly one backpack at a time. Items placed here are **not** usable in combat unless the player first plays "Search Backpack."
- **Grid Cell:** A single 1×1 unit of storage space. All item dimensions are expressed in cells.
- **Occupied Cell:** A cell that is covered by an item. Items cannot overlap.
- **Equipped Weapon:** The currently held weapon. It does **not** occupy any pocket or backpack space.
- **Held Backpack:** The backpack currently worn by the player. Its grid shape determines total storage capacity.

### 1. Pocket

- The pocket always contains exactly **two mini-grids** (base shape: 1×2 each, total 4 cells). With the Magician Survivor Note entry written, each mini-grid expands to **1×3** (total 6 cells per mini-grid, 12 cells total).
- Pocket capacity is independent of the backpack.
- Items in the pocket are usable at any time during the player's combat turn, but each use consumes 1 action.
- Items can be moved between pocket and backpack freely when **not** in combat.
- During combat, items can only be moved from backpack to pocket via the "Search Backpack" action, which opens the inventory interface.
- Within a single mini-grid, multiple items can coexist as long as they fit without overlapping. For example, two 1×1 items (e.g., a Whetstone and a Relic) can occupy the same mini-grid side by side, or one 1×2 (or 1×3 with Magician) item can fill it entirely.

### 2. Backpack Types

The player can obtain larger backpacks throughout the adventure. Only one backpack can be equipped at a time; equipping a new backpack discards the old one.

Each backpack has a **primary grid** (the main rectangular area) and a **secondary space** (one or more disconnected slots on the right side). Items must be placed within valid cells; blocked cells (`——`) are structural walls and cannot hold items. **The primary grid and secondary space are disconnected — no item can be placed so that it straddles both areas, and items cannot be moved directly between the primary grid and a secondary slot.**

| Backpack | Primary Grid | Secondary Space | Total Cells | Chapter |
| :--- | :---: | :---: | :---: | :---: |
| Satchel (随身挎包) | 3×4 | 1×2 | 14 | 1 |
| Student Backpack (学生背包) | 4×5 | two 1×2 | 24 | 1 |
| Travel Backpack (旅行背包) | 5×6 | two 1×3 | 36 | 2 |
| Padlocked Laptop Bag (挂锁电脑包) | 6×4 | three 2×2 | 36 | 3 |
| Marching Backpack (行军背包) | 7×6 | two 1×4 | 50 | 3 |
| Oversized Backpack (超大背包) | 8×7 | two 1×5 | 66 | 4 |

**Special effects:**
- **Oversized Backpack:** Stamina cost for moving between nodes is +1.
- **Padlocked Laptop Bag:** Immune to "Theft" random events.

**Survivor Note upgrades for Satchel:**
- Secondary space expands from 1×2 to 1×3 (Backpacker stage 1: 2 backpacks found).
- Primary space expands from 3×4 to 4×4 (Backpacker stage 2: 5 backpacks found).

#### 2.1 Satchel (随身挎包) — 3×4 + 1×2

Primary grid (3 wide × 4 tall). The 1×2 secondary slot attaches to the right side at rows 2–3.

Full grid (4 columns + 1 secondary column, 4 rows):

```
| P | P | P | S |
| P | P | P | S |
| P | P | P | — |
| P | P | P | — |
```
`P` = primary cell, `S` = secondary cell, `—` = blocked structural cell

After Backpacker stage 1 upgrade (secondary → 1×3, rows 2–4):

```
| P | P | P | S |
| P | P | P | S |
| P | P | P | S |
| P | P | P | — |
```

After Backpacker stage 2 upgrade (primary → 4×4):

```
| P | P | P | P |
| P | P | P | P |
| P | P | P | P |
| P | P | P | P |
```
(secondary remains 1×3 if stage 1 was also unlocked; otherwise 1×2)

#### 2.2 Student Backpack (学生背包) — 4×5 + two 1×2

Primary grid (4 wide × 5 tall). Two 1×2 secondary slots on the right, occupying rows 2–3 and 4–5.

```
| P | P | P | P | — | — |
| P | P | P | P | S | S |
| P | P | P | P | — | — |
| P | P | P | P | S | S |
| P | P | P | P | — | — |
```

#### 2.3 Travel Backpack (旅行背包) — 5×6 + two 1×3

Primary grid (5 wide × 6 tall). Two 1×3 secondary slots on the right, occupying rows 2–4 and 4–6.

```
| P | P | P | P | P | — | — |
| P | P | P | P | P | S | S |
| P | P | P | P | P | S | S |
| P | P | P | P | P | — | — |
| P | P | P | P | P | S | S |
| P | P | P | P | P | S | S |
```

#### 2.4 Padlocked Laptop Bag (挂锁电脑包) — 6×4 + three 2×2

Primary grid (6 wide × 4 tall). Three 2×2 secondary blocks below the primary area (independent sub-grids, not contiguous with primary).

```
| P | P | P | P | P | P | — | — |
| P | P | P | P | P | P | — | — |
| P | P | P | P | P | P | — | — |
| P | P | P | P | P | P | — | — |
| — | — | — | — | — | — | — | — |
| S | S | — | S | S | — | S | S |
| S | S | — | S | S | — | S | S |
```

**Immune to "Theft" event.** Items placed in the 2×2 blocks cannot be stolen.

#### 2.5 Marching Backpack (行军背包) — 7×6 + two 1×4

Primary grid (7 wide × 6 tall). Two 1×4 secondary slots on the right, occupying rows 2–5 and 3–6.

```
| P | P | P | P | P | P | P | — | — |
| P | P | P | P | P | P | P | S | S |
| P | P | P | P | P | P | P | S | S |
| P | P | P | P | P | P | P | — | — |
| P | P | P | P | P | P | P | S | S |
| P | P | P | P | P | P | P | S | S |
```

#### 2.6 Oversized Backpack (超大背包) — 8×7 + two 1×5

Primary grid (8 wide × 7 tall). Two 1×5 secondary slots on the right, occupying rows 1–5 and 3–7.

```
| P | P | P | P | P | P | P | P | - | - |
| P | P | P | P | P | P | P | P | S | S |
| P | P | P | P | P | P | P | P | S | S |
| P | P | P | P | P | P | P | P | S | S |
| P | P | P | P | P | P | P | P | S | S |
| P | P | P | P | P | P | P | P | S | S |
| P | P | P | P | P | P | P | P | - | - |
```

**Movement penalty:** Moving between nodes with this backpack equipped costs +1 additional stamina.

### 3. Item Dimensions

| Item | Dimensions | Rotatable |
| :--- | :-: | :-: |
| Gold coins | 1×1 | No |
| Whetstone | 1×1 | No |
| Stone | 1×1 | No |
| Safe House Key | 1×1 | No |
| Relic (all) | 1×1 | No |
| Lost Letter | 1×1 | No |
| Survivor's Letter | 1×1 | No |
| Energy Drink | 1×1 | No |
| Flashlight | 1×2 | **Yes** |
| Torch | 1×2 | **Yes** |
| Fruit Knife | 1×2 | **Yes** |
| Kitchen Knife | 2×2 | **Yes** |
| Decorative Katana | 1×5 | **Yes** |
| Iron Rod | 1×4 | **Yes** |
| Fire Extinguisher | 2×3 | **Yes** |
| Stonemason Hammer | 2×5 | **Yes** |
| Diesel Chainsaw | 3×4 | **Yes** |
| Crowbar | 1×5 | **Yes** |
| Baton | 1×4 | **Yes** |
| Military Dagger | 1×3 | **Yes** |
| Password Box (unopened) | 2×2 | **Yes** |

### 4. Rotation Rules

- Any item marked "Yes" in the Rotatable column can be rotated 90°.
- Rotation changes width and height (e.g., 1×2 becomes 2×1).
- Items cannot be rotated diagonally or flipped; only 90° increments.
- Gold, relics, and all 1×1 items have no effect when rotated.

### 5. Gold Storage

- Gold coins always occupy exactly **1×1** cell, regardless of the current coin count (even 0).
- Gold pickup is blocked if there is no empty 1×1 cell available.
- The 99-coin cap is enforced **before** the spatial check: if the player is at 99 coins, new coins are auto-discarded regardless of space.

### 6. Weapon Equipping

- Only **one** weapon can be equipped at a time.
- Equipping a weapon removes it from the backpack/pocket grid; it no longer occupies cells.
- Unequipping a weapon places it back into the backpack (or pocket, if chosen by the player).
- If no space exists when unequipping, the player must discard items or the unequip is canceled.

### 7. Access Rules by Game State

**Moving between nodes (non-combat):**
- Backpack and pocket are freely accessible.
- Items can be moved, rotated, equipped, unequipped, used, or discarded.

**In combat (before Search Backpack):**
- Only pocket items are usable.
- Backpack contents are invisible and unusable.

**In combat (after Search Backpack):**
- Backpack interface opens as an overlay.
- Moving items between backpack and pocket does **not** close the interface.
- Using an item or equipping a weapon from the backpack **immediately** closes the interface and consumes 1 action.

### 8. Auto-Arrange on Backpack Swap

When the player equips a new backpack:
1. The old backpack and all its contents are removed.
2. Items are placed into the new backpack in strict priority order:
   1. Lost Letter
   2. Survivor's Letter
   3. Gold coins
   4. Equipped weapon (if not currently held)
   5. Relics
   6. Password Box
   7. Safe House Key
   8. Torch
   9. Flashlight
   10. Other consumables (Energy Drink, Whetstone, Stone)
3. For each item, the system attempts placement in reading order (left-to-right, top-to-bottom), trying both orientations if rotatable.
4. If an item cannot fit, it is **silently discarded**.
5. The player is shown a summary of discarded items.

### 9. Acquiring Items

**Loot (combat victory, ruins, quest rewards):**
- Items are presented one at a time with Take / Abandon.
- "Take" checks if the item fits in the combined pocket + backpack space.
- If it does not fit, the player must either Abandon or open inventory to make room (if not in combat).
- If in combat and the item does not fit, Take is disabled; only Abandon is available.

**Shop purchase:**
- Purchase is blocked if the item cannot fit.
- The shop UI displays a "No space" indicator.

**Shop sell:**
- Sold items are removed from inventory immediately; their cells become empty.

### 10. Dropping and Discarding

- The player can manually discard any item from inventory at any time (non-combat).
- Discarded items are permanently lost.
- There is no "ground" or temporary storage; discard = destroy.

## Formulas

### Backpack Capacity

```
total_cells = primary_grid_cells + secondary_grid_cells
```

| Backpack | Primary Grid | Secondary Grid | Total Cells |
| :--- | :-: | :-: | :-: |
| Satchel | 3×4 = 12 | 1×2 = 2 | 14 |
| Satchel (upgraded) | 4×4 = 16 | 1×3 = 3 | 19 |
| Student Backpack | 4×5 = 20 | two 1×2 = 4 | 24 |
| Travel Backpack | 5×6 = 30 | two 1×3 = 6 | 36 |
| Padlocked Laptop Bag | 6×4 = 24 | three 2×2 = 12 | 36 |
| Marching Backpack | 7×6 = 42 | two 1×4 = 8 | 50 |
| Oversized Backpack | 8×7 = 56 | two 1×5 = 10 | 66 |

### Auto-Arrange Placement Algorithm

```
for each item in priority_order:
    placed = false
    for each cell in reading_order(left→right, top→bottom):
        for orientation in [original, rotated]:
            if item fits at cell with orientation:
                place item
                placed = true
                break
        if placed: break
    if not placed:
        discard item
```

- **Reading order:** Row-major scan of the grid.
- **Rotation:** Tried only if the item is rotatable and `rotated_dimensions != original_dimensions`.
- **Fit check:** All cells covered by the item's bounding box must be within grid bounds and empty.

### Gold Space Check

```
if coin_count >= 99:
    reject new coins
else if no empty 1×1 cell exists:
    reject new coins (space reason)
else:
    accept coins into the 1×1 gold cell
```

### Shop Sell Price Formula

**Weapons:**
```
sell_price = weapon_attack + floor(2 * (current_durability / max_durability))
```

**Consumables / Relics (fixed buyback prices):**

| Item | Buyback Price |
| :--- | :-: |
| Energy Drink | 2 |
| Stone | 1 |
| Whetstone | 2 |
| Torch | 4 |
| Flashlight | 3 |
| Safe House Key | 8 |
| Relic | 12 |

**Backpacks:** Cannot be sold.

### Item Fit Check

```
function can_fit(item, pocket_cells, backpack_grid):
    # Try pocket first (only for small items)
    if item_area <= 4:
        if pocket_has_space(item): return true
    # Try backpack
    if backpack_has_space(item): return true
    return false
```

- The fit check is called before every "Take" action in loot, shop purchase, or quest reward.
- If the player is in combat, the pocket is the only available space (backpack is locked until Search Backpack is played).

## Edge Cases

### E1. Pocket Mini-Grid Layout
Each of the two pocket mini-grids is a 1×2 space. Multiple items can share a mini-grid provided they do not overlap and remain within the 1×2 bounds. For example, two 1×1 items can sit side by side, or one 1×2 item can fill the entire mini-grid. A 2×1 rotated item also fits. A 1×3 item cannot fit in a single mini-grid (exceeds bounds), but a 2×2 item also cannot fit. When moving items between the two pocket mini-grids, items cannot cross mini-grid boundaries: an item placed in mini-grid A cannot overlap into mini-grid B.

### E2. Gold at 99 with Space Available
If the player has exactly 99 coins, all new coin pickups are rejected immediately by the 99-cap rule, even if empty cells exist. The spatial check is skipped.

### E3. Gold Below 99 with No 1×1 Space
If the player has fewer than 99 coins but no empty 1×1 cell exists, coin pickup is rejected for space reasons. The player sees a "No space" message, not a cap message.

### E4. Unequipping Weapon with Full Inventory
When unequipping a weapon, if neither pocket nor backpack has space, the unequip is canceled and the weapon remains equipped. The player is notified. They must manually discard items first.

### E5. Auto-Arrange Discards Equipped Weapon
If the equipped weapon is included in auto-arrange (because the player is swapping backpacks and the weapon is no longer "equipped" in the transition state) and does not fit in the new backpack, it is discarded like any other item. To prevent this, the auto-arrange priority places the weapon 4th, after gold and before relics.

### E6. Auto-Arrange Overflow Summary
After a backpack swap, the player is shown a modal summary listing all discarded items by name and quantity. This summary blocks input until dismissed. If no items were discarded, the summary is skipped.

### E7. Rotating an Item into an Invalid Position
During inventory manipulation (non-combat), if rotating an item would cause it to overlap another item or exceed grid bounds, the rotation is rejected and the item snaps back to its pre-rotation orientation and position.

### E8. Quest Items Cannot Be Discarded
Lost Letter, Survivor's Letter, and Safe House Key cannot be manually discarded. The discard button is hidden for these items. If auto-arrange cannot fit them, they are still silently discarded; this is the only way to lose them.

### E9. Loot During Combat with Full Pocket
If the player wins combat and receives loot while their pocket is full and backpack is inaccessible, the "Take" button is disabled for all items. Only "Abandon" is available. Still, the player can open inventory to make room during this state.

### E10. Shop Purchase with Full Inventory
If the player attempts to buy an item that does not fit, the purchase button is disabled with a "No space" tooltip. The player must free space before purchasing.

### E11. Backpack Swap During Combat
Backpacks cannot be swapped while in combat. The equip action is disabled during combat states. If the player acquires a new backpack during combat (e.g., from loot), it is queued for auto-arrange after combat ends.

### E12. Search Backpack with Empty Backpack
If the player plays "Search Backpack" but the backpack contains no items, the inventory overlay still opens, showing the empty grid. The player can close it without consuming additional actions beyond the Search Backpack action itself.

### E13. Using a Pocket Item with Zero Actions Remaining
Items in the pocket require 1 action to use. If the player has 0 actions remaining in their turn, pocket items are visually grayed out and unusable. The hover tooltip states "No actions remaining."

### E14. Drag-and-Drop Outside Grid Bounds
If the player releases an item drag outside the inventory grid area, the item snaps back to its original position. No item is lost.

### E15. Identical Items Stacked vs Separate
Gold coins occupy a single 1×1 cell regardless of count. All other items do not stack: 3 Energy Drinks occupy 3 separate cells (or slots). There is no stacking mechanic for non-gold items.

### E16. Password Box State Change
An unopened Password Box is 2×2 and rotatable. Once opened (via correct password entry), its contents are extracted and the box is destroyed; it no longer occupies space. There is no "opened but empty" box state.

## Dependencies

### Systems This Depends On

| System | Dependency Detail |
| :--- | :--- |
| **Combat System** | Pocket access rules differ by combat state; Search Backpack is a combat action consuming 1 action; loot drops occur at combat end |
| **Map / Node System** | Backpack is freely accessible while moving between nodes; backpack swap queue triggers after node transition |
| **Shop System** | Buy/sell interactions call inventory fit checks; sell prices defined in this document |
| **Relic System** | Relics occupy 1×1 cells; some relics may modify inventory behavior (future) |
| **Save/Load System** | Full inventory state (grid layout, pocket contents, equipped weapon, held backpack type) must serialize and deserialize |
| **Resource System** | Moving between nodes with Oversized Backpack costs +1 stamina; this is checked by the map movement system, not inventory itself |
| **Survivor Notes System** | Reads Magician entry state to determine pocket mini-grid shape (1×2 or 1×3) |

### Systems That Depend on This

| System | Dependency Detail |
| :--- | :--- |
| **Combat System** | Loot drop UI queries inventory fit before enabling "Take"; pocket items usable during combat; tracks pocket item uses for Magician |
| **Shop System** | Shop UI queries inventory fit before enabling purchase; sells remove items from inventory |
| **Survivor Notes System** | Pocket mini-grid shape must be serialized so the Magician upgrade persists across save/load |
| **Quest System** | Quest rewards (e.g., Lost Letter) must fit in inventory or be abandoned |
| **Achievement / Survivor Notes** | "Backpacker" note tracks backpacks found; Satchel upgrades affect grid dimensions |

## Tuning Knobs

| Knob | Current Value | Safe Range | Description |
| :--- | :-: | :-: | :--- |
| `MAX_GOLD` | 99 | 50–999 | Maximum coins per slot. Higher values reduce inventory pressure. |
| `POCKET_SLOT_COUNT` | 2 | 1–3 | Number of pocket slots. More slots increase combat flexibility. |
| `POCKET_SLOT_SHAPE` | 1×2 (base), 1×3 (with Magician) | 1×2–1×4 | Shape of each pocket slot. Upgradable via Magician Survivor Note entry. |
| `BACKPACK_SWAP_PRIORITY` | see auto-arrange list | reorderable | Order of items during auto-arrange. Earlier items are more likely to survive. |
| `OVERSIZED_STAMINA_PENALTY` | +1 | 0–3 | Extra stamina cost for Oversized Backpack. |
| `WEAPON_SELL_DURA_WEIGHT` | 2.0 | 1.0–5.0 | Multiplier for durability portion of weapon sell price. Higher = durability matters more. |
| `RELIC_BUYBACK_PRICE` | 12 | 5–50 | Fixed sell price for all relics. Higher = more gold from relics. |
| `SHOP_KEY_PRICE` | 8 | 3–20 | Fixed sell price for Safe House Key. |

## Acceptance Criteria

### AC1. Pocket Combat Access
- [ ] Start a combat encounter. Place an Energy Drink in a pocket slot.
- [ ] Verify the Energy Drink is visible and usable during the player's turn.
- [ ] Verify using it consumes 1 action and the item is removed.
- [ ] Verify backpack items are NOT visible before playing Search Backpack.

### AC2. Search Backpack Action
- [ ] During combat, play the Search Backpack action.
- [ ] Verify the inventory overlay opens.
- [ ] Move an item from backpack to pocket.
- [ ] Use the moved item; verify the overlay closes and 1 action is consumed.

### AC3. Grid Placement and Rotation
- [ ] Open inventory between nodes. Place a 1×2 Energy Drink in the backpack.
- [ ] Rotate it; verify it becomes 2×1 and occupies the correct cells.
- [ ] Attempt to rotate it into an occupied cell; verify rotation is rejected.
- [ ] Attempt to place an item partially outside the grid; verify snap-back.

### AC4. Gold Space Enforcement
- [ ] Fill backpack so only one 1×1 cell remains. Set gold to 99.
- [ ] Attempt to pick up coins; verify rejection with cap message.
- [ ] Reduce gold to 98. Fill the last 1×1 cell with a non-gold 1×1 item.
- [ ] Attempt to pick up coins; verify rejection with space message.

### AC5. Weapon Equip/Unequip
- [ ] Equip a Kitchen Knife from the backpack; verify grid cells are freed.
- [ ] Fill all pocket and backpack cells. Attempt to unequip.
- [ ] Verify unequip is canceled and weapon remains equipped.
- [ ] Discard one item; verify unequip now succeeds.

### AC6. Auto-Arrange on Swap
- [ ] Fill a Satchel with a known set of items.
- [ ] Equip a Student Backpack.
- [ ] Verify items appear in the new grid according to priority order.
- [ ] Overfill the Satchel deliberately; swap to the same Satchel.
- [ ] Verify overflow items are listed in the discard summary.

### AC7. Loot Fit Check
- [ ] Fill pocket and backpack during combat.
- [ ] Win combat and receive a loot drop.
- [ ] Verify the "Take" button is disabled; only "Abandon" is available.
- [ ] Outside combat, fill inventory. Receive a loot drop.
- [ ] Verify "Take" is disabled but the player can open inventory to make room.

### AC8. Shop Sell Price
- [ ] Equip a weapon with 10 attack and 10/10 durability. Sell it.
- [ ] Verify sell price = 10 + floor(2 × 1.0) = 12.
- [ ] Reduce durability to 5/10. Sell it.
- [ ] Verify sell price = 10 + floor(2 × 0.5) = 11.

### AC9. Quest Item Protection
- [ ] Place a Lost Letter in inventory. Verify no discard button is shown.
- [ ] Fill inventory except one cell. Obtain a Lost Letter via quest.
- [ ] Verify the quest reward interface forces Abandon if it does not fit.

### AC10. Backpack Special Effects
- [ ] Equip Oversized Backpack. Move between two nodes.
- [ ] Verify stamina cost is +1 compared to unequipped state.
- [ ] Equip Padlocked Laptop Bag. Trigger a Theft random event.
- [ ] Verify the event is prevented / skipped.
