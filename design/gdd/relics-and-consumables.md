# Relics and Consumables

## Overview

The Relic & Consumable System defines all non-weapon, non-quest items that provide passive effects, triggered abilities, or consumable actions. Relics (信物) are permanent items with passive/conditional effects; Consumables (消耗品) are single-use items that trigger immediate effects and are removed on use.

**Scope:** All relics and consumables — acquisition, effects, stacking rules, removal conditions, and UI presentation. Weapons are covered in the Backpack & Inventory System; quest items (Lost Letter, Survivor's Letter) are covered in the Node Interaction System.

**Key characteristics:**
- **Relics are permanent:** Once in backpack or pocket, a relic stays active until sold, destroyed by its own effect, or lost via auto-arrange discard.
- **Relics have no weight:** All relics occupy a 1×1 inventory cell regardless of type.
- **Consumables are single-use:** Each use removes one unit from inventory.
- **Consumable dimensions:** Whetstone, Stone, and Energy Drink are 1×1; Flashlight and Torch are 1×2 and rotatable.
- **Adrenaline Needle is once-per-adventure:** It triggers once, then the relic is destroyed.
- **Survivor Notes gate relic availability:** Relics only appear after the corresponding Survivor Note entry is written.

## Detailed Rules

### Definitions

- **Relic (信物):** A passive or triggered-effect item occupying a 1×1 cell. Relics provide permanent bonuses or conditional triggers for the entire adventure. They cannot be manually discarded during normal play, but can be sold at a Black Market.
- **Consumable (消耗品):** A single-use item removed from inventory after activation.
- **Relic trigger:** A condition under which a relic's effect activates.
- **Passive effect:** A constant bonus provided at all times (e.g., +max stamina from Cross).
- **Conditional effect:** A relic effect that activates only under specific circumstances.
- **Consumable activation:** The moment a consumable is used, its effect resolves, and the item is removed.

### 1. Relics

#### 1.1 Relic List

| Relic | Chinese | Effect | Initial Choice |
| :--- | :--- | :--- | :---: |
| Bottle Cap | 再来一瓶瓶盖 | Energy Drink restore +2 | No |
| Friendship Token | 友谊之证 | Black Market sell prices -30% (floor) | **Yes** |
| Cross | 十字架 | Max stamina +2; damage +1 | No |
| Badge | 警徽 | Immune to "Robbery" and "Theft" in Random Events | No |
| Adrenaline Needle | 肾上腺素针剂 | Once per adventure: when stamina would drop to ≤ 0, restore 10 stamina and destroy this relic | **Yes** |
| MP4 | MP4 | Node-to-node movement stamina cost -1 | No |
| Torn Doll | 破玩偶 | Ruins search stamina cost -1 | **Yes** |
| Instruction Manual | 说明书 | Using Whetstone no longer reduces weapon ATK | No |
| Combat Manual | 格斗教材 | Damage +2 | No |
| Coin Purse | 零钱包 | Once: immediately gain 16 gold and destroy this relic | No |
| Lighter | 打火机 | At start of each combat: deal 5 damage to enemy | No |
| Eye Mask | 眼罩 | Immune to Hard Combat debuffs | No |
| Battery | 蓄电池 | Flashlight reveals +1 additional random nodes | No |
| Smoke Grenade | 破烟雾弹 | Damage taken -2 | No |
| Heart of Hope | 希望之心 | At start of each new chapter: gain 1 random relic | No |
| Compass | 指南针 | After accepting a Quest: display shortest path length (in nodes) to the target Lost Letter | No |
| Brilliant Statue | 璀璨雕像 | Max stamina +3; damage +2 | No |
| Torn Photo | 破相片 | Quest completion gold reward +5 | **Yes** |
| Second-hand Drone | 二手无人机 | Choose a node type: highlight all instances of that type on the current map | No |
| Dim Lantern | 暗淡提灯 | Immune to all debuffs in Boss / Regional Pollution Source encounters | No |
| Running Shoes | 跑鞋 | +1 action per player turn in combat | No |

#### 1.2 Relic Acquisition

- **Survivor Notes unlock gate:** A relic type only appears after the corresponding Survivor Note entry is written. Before unlocking, that relic type does not appear in any loot table, shop stock, or reward pool.
- **Starting choice:** At adventure start, the player may select 1 relic from the "初始可选" list (Friendship Token, Adrenaline Needle, Torn Doll, Torn Photo). These four are available from the very first adventure.
- **Ruins search:** Small probability to find a relic when searching Ruins.
- **Hard Combat:** Probability to drop a relic after victory.
- **Random Event:** Probability to receive a relic as an event outcome.
- **Black Market:** Some relics appear in shop stock via weighted random (see ADR-0007).
- **One per adventure:** During any single adventure, each relic type can only be obtained once. If a duplicate would be acquired (e.g., from a shop), it does not appear or the transaction is blocked.

#### 1.3 Relic Stacking Rules

- **Cross + Brilliant Statue:** Both can be held simultaneously. Their max stamina bonuses stack additively: Cross +2 and Brilliant Statue +3 = +5 max stamina. Their damage bonuses also stack: Cross +1 and Brilliant Statue +2 = +3 damage.
- **Multiple passive relics:** Different relic types stack freely. For example, Cross (+2 max, +1 dmg) + Smoke Grenade (dmg taken -2) + Badge (event immunity) all apply simultaneously.
- **Same relic type:** Only one of each relic type can be held. Duplicates are not possible from acquisition sources.
- **Once-per-adventure relics:** Adrenaline Needle and Coin Purse each trigger once and are then destroyed. Their effects cannot be reused in the same adventure.

#### 1.4 Relic Removal

- **Adrenaline Needle:** Destroyed automatically after triggering once per adventure.
- **Coin Purse:** Destroyed automatically after triggering once per adventure.
- **Sale:** Relics can be sold at Black Market for 12 gold each (fixed buyback price).
- **Auto-arrange discard:** During backpack swap, if a relic cannot fit in the new backpack, it is silently discarded like any other item.
- **No manual discard:** Relics cannot be manually discarded during normal play.

#### 1.5 Relic Effects Detail

**Bottle Cap:**
- Modifies the Energy Drink restore amount: `base_restore + 2`.
- This bonus stacks with the Partner Survivor Note upgrade.

**Friendship Token:**
- At the time of a Black Market sell transaction, the final sell price is: `floor(original_price * 0.7)`.
- Buy prices are unaffected.
- Applies to all items sold, including weapons, consumables, and other relics.

**Cross:**
- Passive: max stamina +2 for the entire adventure.
- Passive: damage +1 on all attacks.
- Stacks additively with Brilliant Statue's bonuses.

**Badge:**
- Blocks the "Robbery" (抢劫) and "Theft" (偷窃) event outcomes entirely when they would be selected.
- The event still occurs; only those specific negative outcomes are replaced or suppressed.

**Adrenaline Needle:**
- Triggers when any event would reduce stamina to ≤ 0 (combat damage, card cost, movement overdraft, debuff tick).
- Stamina is set to 10. The relic is immediately destroyed.
- The triggering event resolves fully after the restore.
- Triggers before Last Effort evaluation.
- Once triggered, future stamina drops to ≤ 0 result in immediate death.

**MP4:**
- Modifies the movement stamina cost formula: `base_cost - 1`.
- Base movement cost is 1, so with MP4 the cost becomes 0 (minimum 0).
- This is the only situation where movement can cost 0 stamina.

**Torn Doll:**
- Reduces the stamina cost of Ruins search from 1 to 0.
- Only affects the search action itself; other costs (e.g., Torch) are unaffected.

**Instruction Manual:**
- When a Whetstone is used, the weapon's ATK is not reduced.
- Whetstone still restores durability as normal.
- If the weapon is already at max ATK, Whetstone cannot be used (item is not consumed in this case).

**Combat Manual:**
- Passive: damage +2 on all attacks.
- Stacks with Cross (+1) and Brilliant Statue (+2) for a total of +5 when all three are equipped.

**Coin Purse:**
- Triggers immediately upon use: player gains 16 gold (subject to 99 cap and spatial check).
- The relic is destroyed after the gold is added.
- If gold is already at 99 or no 1×1 space exists, the gold is discarded and the relic is still destroyed.

**Lighter:**
- Triggers automatically at the start of every combat encounter (before the first player turn).
- Deals 5 damage to the enemy immediately.
- This damage is not blockable by enemy mechanics that reduce incoming damage (minimum 1 damage still applies).
- No stamina or action is consumed.

**Eye Mask:**
- At the start of a Hard Combat encounter, if Eye Mask is equipped, no debuff is drawn.
- Boss-assigned debuffs (e.g., Sorrow's Hesitation) are mandatory and not blocked by Eye Mask.

**Battery:**
- Extends the Flashlight's reveal count: `base_reveal + 1`.
- Base reveal is 2 (upgradable to 4 via Survivor Notes), so with Battery it becomes 3 (upgradable to 5).

**Smoke Grenade:**
- Passive: all damage received is reduced by 2.
- Applied after all other damage modifications (e.g., Dodge reduction).
- Minimum damage taken is 1 (cannot be reduced to 0 or negative by this effect).

**Heart of Hope:**
- Triggers at the start of each new chapter (after Boss victory and before the new map loads).
- Grants 1 random relic from the currently unlocked pool.
- The relic goes through the normal loot Take/Abandon flow.
- If inventory has no space, the relic is abandoned.

**Compass:**
- After accepting a Quest (clicking Accept on a Quest node), the Compass activates.
- Displays the shortest path length (number of node traversals) from the player's current node to the node containing the target Lost Letter.
- The path length updates as the player moves.
- The display disappears after the quest is completed or failed.

**Brilliant Statue:**
- Passive: max stamina +3 for the entire adventure.
- Passive: damage +2 on all attacks.
- Stacks additively with Cross's bonuses.

**Torn Photo:**
- Modifies the gold reward granted when a Quest is completed.
- The bonus is +5 gold, added to the quest's base gold reward.
- Applied at the moment of quest completion.

**Second-hand Drone:**
- Once activated (usable during node traversal), the player selects one base node type from the list (Road, Normal Combat, Hard Combat, Random Event, Ruins, Safe House, Black Market, Quest).
- All nodes of that type on the current chapter's map are highlighted.
- The effect persists until the player leaves the current chapter.
- Only one node type can be highlighted at a time; using the drone again replaces the previous highlight.
- Does not reveal Hidden nodes — only makes already Revealed/Visited nodes of the selected type more visually prominent.

**Dim Lantern:**
- Passive: during Boss / Regional Pollution Source encounters, all debuffs assigned by the Boss are suppressed.
- Does not block debuffs from Hard Combat (those are blocked by Eye Mask).
- Does not block damage itself, only the debuff application.

**Running Shoes:**
- Passive: at the start of each player turn during combat, grants +1 additional action for that turn.
- Stacks with Adjust Breathing (+1 action next turn) and Dullness debuff (-1 action): net result is base 3 + Running Shoes + Adjust Breathing - Dullness = 4 actions.
- The bonus applies only during the player's turn; it does not affect enemy turns or non-combat states.

### 2. Consumables

#### 2.1 Consumable List

| Consumable | Chinese | Dimensions | Effect |
| :--- | :--- | :--- | :--- |
| Whetstone | 磨刀石 | 1×1 | Restore 3 weapon durability (upgradable to 5 via Survivor Notes). Reduce weapon ATK by 1. Weapon ATK cannot go below 4. |
| Energy Drink | 能量饮料 | 1×1 | Restore 7 stamina (upgradable to 10 via Survivor Notes). |
| Stone | 石块 | 1×1 | Spend 2 stamina. Flee current combat and return to previous node. |
| Flashlight | 手电筒 | 1×2 (rotatable) | Reveal the types of 2 random nodes (upgradable to 4 via Survivor Notes). Usable during node traversal only. |
| Safe House Key | 安全屋房卡 | 1×1 | Open one Safe House. Consumed on use. |
| Torch | 火把 | 1×2 (rotatable) | Spend 2 stamina. Deal 30 damage to one enemy. Usable in combat only (consumes 1 action). |

#### 2.2 Consumable Acquisition

- **Starting selection:** At adventure start, 3 consumables are randomly offered. The player picks 1 to carry. This count is upgradable to 3 via Survivor Notes.
- **Probability distribution (starting, before upgrades):**

| Consumable | Probability |
| :--- | :-: |
| Whetstone | 21% |
| Stone | 16% |
| Energy Drink | 32% |
| Flashlight | 15% |
| Torch | 12% |
| Safe House Key | 4% |

- **Combat loot:** Normal and Hard Combat drop consumables from probability tables (see Combat System).
- **Black Market:** Consumables appear in shop stock via weighted random.
- **Safe House Fridge:** Free Energy Drink can be obtained (per-Safe House limit, scales with Survivor Notes).
- **Random Event:** Events may grant consumables as outcomes.
- **Ruins search:** Ruins loot table includes consumables.

#### 2.3 Consumable Usage Rules

**Whetstone:**
- Must have a weapon equipped to use.
- Restores 3 durability to the equipped weapon (upgradable to 5 via Survivor Notes).
- Reduces weapon's current ATK by 1 after durability is restored.
- ATK cannot drop below 4; if weapon ATK is already 4, Whetstone can be used without reducing weapon's ATK.
- With the Instruction Manual relic equipped, the ATK reduction is waived.

**Energy Drink:**
- Usable during the player's turn in combat (consumes 1 action) or freely during node traversal.
- Cannot exceed max stamina; excess is discarded.
- Restore amount = `7 + partner_stages` (upgradable to 10 via Survivor Notes).
- Bottle Cap relic adds +2 on top: maximum restore is 12 with Partner stage 3 + Bottle Cap.
- If already at max stamina, the item is consumed with no effect.

**Stone:**
- Spends 2 stamina immediately.
- Usable during the player's turn in combat or during node traversal.
- Triggers the flee sequence: exit combat, return player to the previous node.
- If stamina is below 2, the use is blocked; the item is not consumed.
- Not usable against Boss enemies (flee from Boss uses the Flee card instead, which has its own rules).

**Flashlight:**
- Usable only during node traversal (not in combat, not during node interaction).
- Reveals the types of 2 random nodes on the current map (upgradable to 4 via Survivor Notes).
- Battery relic adds +1: maximum 5 nodes with Battery equipped.
- Revealed nodes transition from Hidden to Revealed (position visible, type hidden until visited).
- If fewer than the target number of Hidden nodes exist, all remaining Hidden nodes are revealed.

**Safe House Key:**
- Consumed immediately on use.
- Has no effect if used when not near a locked Safe House.
- Does not grant access to a Safe House that has already been fully used.

**Torch:**
- Spends 2 stamina on use.
- Usable in combat only: consumes 1 action, deals 30 damage to one enemy.
- If the Torch kills the enemy, Last Effort triggers and restores stamina to `last_effort_recovery` (base 2, upgradable to 4 via Survivor Notes).
- Item is consumed after the damage is dealt.

## Formulas

### Energy Drink Restore

```
energy_drink_restore = BASE_ENERGY_RESTORE + partner_stages
```

| Variable | Value | Range | Description |
| :--- | :-: | :-: | :--- |
| `BASE_ENERGY_RESTORE` | 7 | 5–10 | Base stamina restored by one Energy Drink. |
| `partner_stages` | 0–3 | 0–3 | Survivor Note "Partner" stages. Each adds +1 restore. |
| `bottle_cap_bonus` | 0 or 2 | 0–2 | +2 if Bottle Cap relic is equipped. |

**Example:** Player with Partner stage 2 and Bottle Cap → `7 + 2 + 2 = 11` stamina restored.

### Whetstone Durability Restore

```
whetstone_durability = BASE_WHETSTONE_DURA + manual_stages
```

| Variable | Value | Range | Description |
| :--- | :-: | :-: | :--- |
| `BASE_WHETSTONE_DURA` | 3 | 3–5 | Base durability restored by one Whetstone. |
| `manual_stages` | 0–2 | 0–2 | Survivor Note "Manual" stages. Each adds +1 restore. |

### Movement Cost with MP4

```
movement_cost = max(0, BASE_MOVE_COST - (1 if mp4_equipped else 0))
```

- `BASE_MOVE_COST` = 1.
- With MP4 equipped: cost = 0.
- Movement cost cannot go below 0.

### Adrenaline Needle Restore

```
adrenaline_needle_restore = 10
```

- Fixed value. No modifiers apply.
- Triggered when any stamina mutation would reduce stamina to ≤ 0.

### Cross and Brilliant Statue Stacking

```
total_max_stamina_bonus = cross_max_bonus + brilliant_max_bonus
total_damage_bonus = cross_damage_bonus + brilliant_damage_bonus
```

| Relic | Max Stamina Bonus | Damage Bonus |
| :--- | :-: | :-: |
| Cross | +2 | +1 |
| Brilliant Statue | +3 | +2 |
| Both equipped | +5 | +3 |

### Smoke Grenade Damage Reduction

```
final_damage_taken = max(1, raw_damage - smoke_grenade_reduction)
```

- `smoke_grenade_reduction` = 2.
- Minimum damage taken is 1 (cannot reduce to 0 or negative).

### Flashlight Reveal Count

```
flashlight_reveal_count = BASE_FLASHLIGHT_REVEAL + survivor_notes_bonus + (1 if battery_equipped else 0)
```

| Variable | Value | Description |
| :--- | :-: | :--- |
| `BASE_FLASHLIGHT_REVEAL` | 2 | Base number of nodes revealed |
| `survivor_notes_bonus` | 0–2 | +2 if Survivor Notes "Explorer" stage 3+ reached |
| `battery_equipped` | 0 or 1 | +1 if Battery relic equipped |

**Example:** Base + Survivor Notes stage 1 (+1) + Battery → 2 + 1 + 1 = 4 nodes.

### Friendship Token Sell Price

```
final_sell_price = floor(original_price * 0.7)
```

- Rounded down to nearest integer.
- Buy prices are unaffected.

### Stone Flee

```
stone_flee_cost = 2 stamina
```

- Deducted immediately. If insufficient stamina, use is blocked and item is not consumed.

### Torch Damage

```
torch_damage = 30
```

- Applied to one enemy target in combat.
- Usable in combat only (consumes 1 action).

## Edge Cases

### E1. Adrenaline Needle on Movement Overdraft

When moving between nodes with Adrenaline Needle equipped and stamina would drop to ≤ 0:
1. Stamina is set to 10.
2. The relic is destroyed.
3. Movement proceeds normally into the target node.

### E2. Adrenaline Needle on Despair Debuff

If the player has Adrenaline Needle and encounters a Boss with Despair debuff (lose 6 stamina at encounter start):
1. Despair deducts 6 stamina.
2. If stamina drops to ≤ 0, Adrenaline Needle triggers.
3. The encounter continues normally.
4. Adrenaline Needle is destroyed.

### E3. Energy Drink at Full Stamina

Using an Energy Drink at max stamina has no effect. The item is consumed but stamina does not change. No overflow is stored.

### E4. Whetstone on Weapon at ATK 4

If the weapon's ATK is already 4, Whetstone cannot be used. The item remains in inventory. The UI disables the use button and shows tooltip "ATK at minimum."

### E5. Whetstone with Instruction Manual

With the Instruction Manual relic equipped, using Whetstone restores durability but does not reduce ATK. The weapon remains at its current ATK.

### E6. Flashlight with Fewer Hidden Nodes Than Reveal Count

If the player uses Flashlight and fewer Hidden nodes exist than the reveal count, all remaining Hidden nodes are revealed. No error occurs.

### E7. Torch and Last Effort

Torch costs 2 stamina. If the player uses Torch and it kills the enemy, Last Effort triggers and sets stamina to `last_effort_recovery` (base 2, upgradable to 4 via Survivor Notes). This applies whether the player had sufficient stamina or not.

### E8. Stone with Insufficient Stamina

If stamina < 2, Stone cannot be used. The item is not consumed. The UI disables the use button.

### E9. Heart of Hope Chapter Transition with Full Inventory

When a new chapter begins and Heart of Hope grants a random relic:
1. The relic appears in the loot/Take flow.
2. If inventory has no space, the relic is automatically abandoned.
3. The player sees the abandonment message.
4. No relic is gained.

### E10. Second-hand Drone Reuse

Using the Second-hand Drone while a highlight is already active replaces the previous highlight with the new selection. The effect is not additive.

### E11. Compass on Quest Completion

When a Quest is completed, the Torn Photo gold bonus (+5) is added to the quest's base gold reward. The Compass display disappears at the same moment.

### E12. Badge Blocking Robbery vs. Eye Mask Blocking Hard Combat Debuff

Badge blocks Random Event robbery outcomes only. It does not affect combat debuffs.
Eye Mask blocks Hard Combat debuff draws only. It does not affect Boss debuffs.
Dim Lantern blocks Boss debuffs only. These three effects are distinct and non-overlapping.

### E13. MP4 Movement Cost at Zero

With MP4 equipped, movement cost is 0. The player can traverse nodes without spending stamina. This can allow unlimited movement if no other stamina constraints exist.

### E14. Coin Purse at 99 Gold

If current gold is 99, Coin Purse still triggers and the relic is destroyed. The 16 gold is discarded by the numeric cap. No partial amount is accepted.

### E15. Coin Purse at 99 Gold with Space

If current gold is 99 but a 1×1 inventory cell is empty, Coin Purse still triggers and the relic is destroyed. The gold is still discarded by the numeric cap; the spatial check is not evaluated because the numeric cap is checked first.

### E16. Dim Lantern Blocks Boss Debuffs but Not Boss Damage

Dim Lantern suppresses only the debuff application from Boss encounters. The Boss's attack damage and any Boss special mechanics (e.g., emergency heal, phase transitions) are unaffected.

### E17. Cross + Brilliant Statue + Combat Manual

All three damage relics stack: Cross (+1) + Brilliant Statue (+2) + Combat Manual (+2) = +5 total damage bonus. The max stamina bonuses also stack: Cross (+2) + Brilliant Statue (+3) = +5 total.

### E18. Second-hand Drone vs. Fog of War

Second-hand Drone highlights node types, not specific nodes. It does not reveal Hidden nodes — only makes existing Revealed/Visited nodes of the selected type more visually prominent.

## Dependencies

### Systems This Depends On

| System | Dependency Detail |
| :--- | :--- |
| **Backpack & Inventory System** | Relics and consumables occupy 1×1 or 1×2 cells; fit checks on acquisition; auto-arrange priority; shop sell prices |
| **Combat System** | Damage bonuses apply to attacks; Lighter triggers at combat start; Torch deals damage in combat; Stone triggers flee; Smoke Grenade reduces damage taken; Eye Mask blocks Hard Combat debuffs |
| **Node Interaction System** | Flashlight reveals Hidden nodes; MP4 reduces movement cost; Compass shows path length; Safe House Key opens Safe House |
| **Survivor Notes System** | Partner upgrades Energy Drink restore; Warrior upgrades damage; Manual upgrades Whetstone durability; Explorer upgrades Flashlight reveal count; choice count upgrades |
| **Shop System** | Friendship Token reduces sell prices; relics and consumables appear in shop stock via weighted random |

### Systems That Depend On This

| System | Dependency Detail |
| :--- | :--- |
| **Combat System** | Reads relic passive effects; applies damage bonuses; checks Eye Mask at Hard Combat start; Adrenaline Needle triggers on death check |
| **Node Interaction System** | Reads movement cost modifier from MP4; applies Flashlight reveal; Compass path display |
| **UI / Rendering System** | Displays relic icons and passive effect indicators; shows consumable count and dimensions in inventory |
| **Save/Load System** | Must serialize all relics (with used/destroyed flags for Adrenaline Needle and Coin Purse) and consumable item counts |
| **Shop System** | Reads relic and consumable stock generation; applies Friendship Token sell price reduction |

## Tuning Knobs

| Knob | Current Value | Safe Range | Description |
| :--- | :-: | :-: | :--- |
| `BASE_ENERGY_RESTORE` | 7 | 5–10 | Base stamina restored by Energy Drink. |
| `BASE_WHETSTONE_DURA` | 3 | 3–5 | Base durability restored by Whetstone. |
| `BOTTLE_CAP_BONUS` | +2 | +1–+3 | Extra Energy Drink restore from Bottle Cap relic. |
| `CROSS_MAX_BONUS` | +2 | +1–+4 | Max stamina bonus from Cross. |
| `CROSS_DAMAGE_BONUS` | +1 | +1–+3 | Damage bonus from Cross. |
| `BRILLIANT_MAX_BONUS` | +3 | +1–+5 | Max stamina bonus from Brilliant Statue. |
| `BRILLIANT_DAMAGE_BONUS` | +2 | +1–+4 | Damage bonus from Brilliant Statue. |
| `COMBAT_MANUAL_DAMAGE_BONUS` | +2 | +1–+3 | Damage bonus from Combat Manual. |
| `SMOKE_GRENADE_REDUCTION` | -2 | -1–-3 | Damage reduction from Smoke Grenade. |
| `TORCH_DAMAGE` | 30 | 20–50 | Damage dealt by Torch in combat. |
| `STONE_FLEE_COST` | 2 | 1–3 | Stamina cost to use Stone. |
| `LIGHTER_COMBAT_DAMAGE` | 5 | 3–10 | Damage dealt by Lighter at combat start. |
| `COIN_PURSE_GOLD` | 16 | 10–30 | Gold granted by Coin Purse. |
| `HEART_OF_HOPE_RELIC_COUNT` | 1 | 1–2 | Number of relics granted by Heart of Hope per chapter. |
| `TORN_PHOTO_GOLD_BONUS` | +5 | +3–+10 | Extra quest gold from Torn Photo. |
| `FRIENDSHIP_TOKEN_DISCOUNT` | 30% | 20–50% | Sell price reduction from Friendship Token. |
| `MP4_MOVE_COST_REDUCTION` | -1 | -1–-2 | Movement cost reduction from MP4. |
| `BASE_FLASHLIGHT_REVEAL` | 2 | 2–4 | Base nodes revealed by Flashlight. |
| `BATTERY_REVEAL_BONUS` | +1 | +1–+2 | Extra Flashlight reveals from Battery. |
| `RUNNING_SHOES_ACTION_BONUS` | +1 | +1–+2 | Extra actions per player turn from Running Shoes. |

## Acceptance Criteria

### AC1. Adrenaline Needle — Death Save in Combat
- [ ] Enter combat with Adrenaline Needle equipped and 2 stamina. Take 5 damage.
- [ ] Verify stamina becomes 10 and the relic is destroyed. Combat continues.
- [ ] Later in the same adventure, drop to 0 stamina again. Verify permadeath triggers.

### AC2. Adrenaline Needle — Movement Overdraft
- [ ] Equip Adrenaline Needle. Reduce stamina to 1. Click an adjacent node.
- [ ] Verify stamina becomes 10, relic is destroyed, and player enters the target node.

### AC3. Cross + Brilliant Statue Stacking
- [ ] Equip Cross. Verify max stamina +2 and damage +1.
- [ ] Equip Brilliant Statue additionally. Verify max stamina +5 and damage +3 total.

### AC4. Eye Mask Blocks Hard Combat Debuff
- [ ] Equip Eye Mask. Enter Hard Combat 10 times. Verify no debuff in any encounter.
- [ ] Unequip Eye Mask. Enter Hard Combat 10 times. Verify debuffs are drawn.

### AC5. Lighter Triggers at Combat Start
- [ ] Enter combat with Lighter equipped. Verify 5 damage is dealt to enemy before first player turn.
- [ ] Verify no stamina or action is consumed.

### AC6. Energy Drink Restore with Partner and Bottle Cap
- [ ] With Partner stage 0 and no Bottle Cap, use Energy Drink at 5 stamina. Verify stamina becomes 12 (5 + 7).
- [ ] With Partner stage 2 and Bottle Cap, use Energy Drink at 5 stamina. Verify stamina becomes 14 (5 + 7 + 2 + 2).

### AC7. Whetstone with Instruction Manual
- [ ] Equip Instruction Manual. Use Whetstone on a weapon at ATK 6, durability 2.
- [ ] Verify durability increases and ATK remains 6 (not reduced to 5).
- [ ] Remove Instruction Manual. Use Whetstone on same weapon. Verify ATK is reduced by 1.

### AC8. Stone Flee from Combat
- [ ] Enter combat with 3 stamina. Use Stone.
- [ ] Verify 2 stamina is spent, combat ends, and player returns to previous node.
- [ ] Enter combat with 1 stamina. Attempt to use Stone. Verify use is blocked.

### AC9. Flashlight Reveals Nodes
- [ ] During node traversal, use Flashlight.
- [ ] Verify the types of 2 random Hidden nodes are revealed.
- [ ] With Battery equipped, verify 3 nodes are revealed.

### AC10. Torch Deals Damage in Combat
- [ ] Enter combat. Use Torch on an enemy.
- [ ] Verify 30 damage is dealt and Torch is consumed.

### AC11. Smoke Grenade Damage Reduction
- [ ] Enter combat without Smoke Grenade. Note damage taken from enemy attack.
- [ ] Equip Smoke Grenade. Enter combat against same enemy.
- [ ] Verify damage taken is reduced by 2 (minimum 1).

### AC12. Coin Purse Once-Per-Adventure
- [ ] Use Coin Purse. Verify 16 gold is gained and relic is destroyed.
- [ ] Attempt to use Coin Purse again in same adventure. Verify it is no longer available.

### AC13. MP4 Movement Cost Zero
- [ ] With MP4 equipped, move between two adjacent nodes.
- [ ] Verify stamina cost is 0.
- [ ] Remove MP4. Move again. Verify stamina cost returns to 1.

### AC14. Friendship Token Sell Discount
- [ ] Sell a weapon at a Black Market without Friendship Token. Note price.
- [ ] Equip Friendship Token. Sell the same weapon. Verify price is floor(original × 0.7).

### AC15. Heart of Hope Chapter Transition
- [ ] Defeat Chapter 1 Boss with Heart of Hope equipped.
- [ ] Verify a random relic is offered before the Chapter 2 map loads.
- [ ] Accept the relic if space allows; verify it is added to inventory.

### AC16. Compass Shows Path Length
- [ ] Accept a Quest. Verify Compass displays the node count path to the target Lost Letter.
- [ ] Move toward the target. Verify the path length updates.
- [ ] Complete the quest. Verify the display disappears.

### AC17. Second-hand Drone Highlight
- [ ] Use Second-hand Drone. Select "Hard Combat" as the node type.
- [ ] Verify all Hard Combat nodes on the current map are highlighted.
- [ ] Use Second-hand Drone again. Select "Safe House." Verify the Hard Combat highlight is replaced.

### AC18. Badge Blocks Robbery Event
- [ ] Without Badge equipped, trigger 20 Random Events. Count robbery outcomes.
- [ ] Equip Badge. Trigger 20 Random Events. Verify robbery outcomes are blocked.

### AC19. Fading Lantern Blocks Boss Debuffs
- [ ] Fight Chapter 1 Boss (Sorrow) with Hesitation debuff without Dim Lantern. Verify debuff applies.
- [ ] Equip Fading Lantern. Fight the same Boss. Verify debuff is suppressed.

### AC20. Running Shoes — Extra Action Per Turn
- [ ] Enter combat without Running Shoes. Verify base actions per turn = 3.
- [ ] Equip Running Shoes. Enter combat. Verify actions per turn = 4.
- [ ] Play Adjust Breathing, then end turn. On the next turn, verify actions = 5 (base 3 + Running Shoes + Adjust Breathing).
- [ ] Enter combat with Dullness debuff and Running Shoes equipped. Verify actions per turn = 3 (base 3 + Running Shoes - Dullness).