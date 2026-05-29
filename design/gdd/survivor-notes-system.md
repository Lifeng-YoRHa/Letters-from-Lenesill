# Survivor Notes System

## Overview

The Survivor Notes System (幸存者笔记撰写) is a meta-progression system that tracks the player's historical achievements across all adventures and grants permanent rewards. Every significant action — consuming items, winning combats, visiting nodes, accumulating gold — contributes to unlocking note entries, which in turn grant upgrades, unlock relics, or improve starting resources for future runs.

**Scope:** All Survivor Note entries, stage thresholds, rewards, unlock conditions, and the writing/persistence mechanics. Covers how note progress is tracked, when entries are written, and how rewards are applied to subsequent adventures.

**Key characteristics:**
- **Meta-progression:** Notes persist across adventures; progress never lost.
- **Cumulative tracking:** Most entries count actions across all adventures, not per-run.
- **Entry unlock gates content:** New relic types, starting item choices, and resource bonuses only become available after their corresponding note entry is written.
- **One-time write:** Each entry is written exactly once. Its reward is permanently granted.
- **No degradation:** Progress toward an entry is never lost or reduced.
- **Optional Carry:** Player can select whether they carry the buff from Survivor Note to begin a new game, if the selection is negative, all buff provided by Survivor Note will be disabled(Note that unlocked relics are still avaliable under this circumstance)

## Detailed Rules

### Definitions

- **Survivor Note Entry:** A single achievement track, identified by an English name and a description. Each entry has one or more stages.
- **Stage:** A discrete milestone within an entry. Each stage has a threshold (cumulative value) and a reward.
- **Written Entry:** An entry whose reward has been permanently granted. The note text is appended to the Survivor's Journal.
- **Unlock:** When an entry's reward is a relic, the relic type becomes available in all loot tables and shop stock from that point forward.
- **Starting Bonus:** When an entry's reward modifies initial adventure values (max stamina, starting gold), that bonus applies automatically on every subsequent adventure.
- **Threshold:** The cumulative value required to reach a given stage.

### 1. Entry List

#### 1.1 Partner (合作伙伴)

**Description:** 累计通过"能量饮料"恢复220/450/750点体力

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 220 | Energy Drink restore amount +1 |
| 2 | 450 | Energy Drink restore amount +1 |
| 3 | 750 | Energy Drink restore amount +1 |

**Total bonus:** Energy Drink restore +3 (from base 7 to max 10).

#### 1.2 Spokesperson (代言人)

**Description:** 累计饮用240瓶能量饮料

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 240 | Unlock relic: Bottle Cap (再来一瓶瓶盖) |

#### 1.3 Apprentice (学徒)

**Description:** 累计通过"磨刀石"恢复80/200点武器耐久

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 80 | Whetstone durability restore +1 |
| 2 | 200 | Whetstone durability restore +1 |

**Total bonus:** Whetstone durability restore +2 (from base 3 to max 5).

#### 1.4 Master (师傅)

**Description:** 累计使用100块磨刀石

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 100 | Unlock relic: Instruction Manual (说明书) |

#### 1.5 Wayfarer (行路人)

**Description:** 累计经过150/350/650/1100个非"普通道路"节点

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 150 | Initial max stamina +1 |
| 2 | 350 | Initial max stamina +1 |
| 3 | 650 | Initial max stamina +1 |
| 4 | 1100 | Initial max stamina +1 |

**Total bonus:** Initial max stamina +4 (from base 12 to max 16).

#### 1.6 Pathfinder (探路者)

**Description:** 单次游戏经过75个非"普通道路"节点

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 75 (single run) | Unlock relic: MP4 |

#### 1.7 Hardship Survivor (苦旅人)

**Description:** 累计进入第二章10次

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 10 | Unlock relic: Adrenaline Needle (肾上腺素针剂) |

#### 1.8 Sufferer (受难者)

**Description:** 累计进入第三章10次

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 10 | Unlock relic: Cross (十字架) |

#### 1.9 Hoarder (囤积者)

**Description:** 累计获得100/250/500/800枚金币

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 100 | Starting gold +1 |
| 2 | 250 | Starting gold +1 |
| 3 | 500 | Starting gold +1 |
| 4 | 800 | Starting gold +1 |

**Total bonus:** Starting gold +4 (from base 8 to max 12).

#### 1.10 Miser (守财奴)

**Description:** 累计获得1000枚金币

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 1000 | Unlock relic: Coin Purse (零钱包) |

#### 1.11 Trade Master (贸易大师)

**Description:** 累计在"黑市"中消耗400枚金币

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 400 | Unlock relic: Friendship Token (友谊之证) |

#### 1.12 Warrior (战士)

**Description:** 累计造成350/650点伤害

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 350 | Unarmed Attack damage +1 |
| 2 | 650 | Unarmed Attack damage +1 |

**Total bonus:** Unarmed Attack damage +2 (from base 3 to max 5, when combined with base 3).

#### 1.13 Combat Master (战斗大师)

**Description:** 累计完成100次"普通战斗"或"艰难战斗"

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 100 | Unlock relic: Combat Manual (格斗教材) |

#### 1.14 Sports Enthusiast (运动爱好者)

**Description:** 累计打出70/150次"闪避"

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 70 | Dodge damage reduction +1 |
| 2 | 150 | Dodge damage reduction +1 |

**Total bonus:** Dodge reduction +2 (from base 4 to max 6).

#### 1.15 Extreme Sports Enthusiast (极限运动者)

**Description:** 累计打出200次"闪避"

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 200 | Unlock relic: Smoke Grenade (破烟雾弹) |

#### 1.16 Scavenger (拾荒者)

**Description:** 累计搜索200次"废墟"

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 200 | Unlock relic: Torn Doll (破玩偶) |

#### 1.17 Mischief Maker (顽童)

**Description:** 累计进入150次"突发事件"

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 150 | Unlock relic: Badge (警徽) |

#### 1.18 Chef (大厨)

**Description:** 累计使用"火把"消灭30名敌人

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 30 | Unlock relic: Lighter (打火机) |

#### 1.19 Scholar (学者)

**Description:** 累计进入"安全屋"10/22/35/50/70次

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 10 | Scattered consumables +1 |
| 2 | 22 | Safe House Fridge Energy Drink count +1 |
| 3 | 35 | Safe House Piggy Bank gold +1 |
| 4 | 50 | Safe House Anvil uses +1 |
| 5 | 70 | Scattered consumables +1 |

#### 1.20 Hypnotist (催眠师)

**Description:** 累计进入"安全屋"100次

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 100 | Unlock relic: Eye Mask (眼罩) |

#### 1.21 Electrician (电工)

**Description:** 累计使用"手电筒"25/60次

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 25 | Flashlight reveal count +1 |
| 2 | 60 | Flashlight reveal count +1 |

**Total bonus:** Flashlight reveals +2 (from base 2 to max 4).

#### 1.22 Adventurer (冒险家)

**Description:** 累计使用"手电筒"85次

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 85 | Unlock relic: Battery (蓄电池) |

#### 1.23 Survivor (幸存者)

**Description:** 通关一次游戏

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 1 | Unlock relic: Heart of Hope (希望之心) |

#### 1.24 Seeker (求索者)

**Description:** 进入一次隐藏地图

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 1 | Unlock relic: Compass (指南针) |

#### 1.25 Martyr (殉道人)

**Description:** 累计进入第四章10次

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 10 | Unlock relic: Brilliant Statue (璀璨雕像) |

#### 1.26 Backpacker (背包客)

**Description:** 累计发现2/5种背包

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 2 | Satchel secondary space expands to 1×3 |
| 2 | 5 | Satchel primary space expands to 4×4 |

**Note:** The Satchel is the starting backpack. These upgrades improve the Satchel's grid shape (see Backpack & Inventory System for grid details).

#### 1.27 Escape Master (逃脱大师)

**Description:** 累计逃离战斗75/175次

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 75 | Flee card cost -1 |
| 2 | 175 | Flee card cost -1 |

**Total bonus:** Flee cost -2 (from base 5 to min 3).

#### 1.28 Survival Expert (生存专家)

**Description:** 使用300/800次消耗品

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 300 | Starting consumable choice count +1 |
| 2 | 800 | Starting consumable choice count +1 |

**Total bonus:** Consumable choice count +2 (from base 1 to max 3).

#### 1.29 Messenger (信使)

**Description:** 完成10次委托任务

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 10 | Unlock relic: Torn Photo (破相片) |

#### 1.30 Improviser (即兴表演者)

**Description:** 打出150/350张行动牌

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 150 | Activated cards per turn +1 |
| 2 | 350 | Activated cards per turn +1 |

**Total bonus:** Activated cards +2 (from base 3 to max 5).

#### 1.31 Advanced Collector (进阶收藏)

**Description:** "幸存者笔记"中，解锁20个条目

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 20 | Unlock relic: Second-hand Drone (二手无人机) |

#### 1.32 Witness (见证者)

**Description:** 完成一次真正的结局

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 1 | Unlock relic: Dim Lantern (暗淡提灯) |

#### 1.33 Berserker (狂战士)

**Description:** 体力不高于5点的情况下，获得20/50次战斗胜利

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 20 | Last Effort recovery +1 |
| 2 | 50 | Last Effort recovery +1 |

**Total bonus:** Last Effort recovery +2 (from base 2 to max 4).

#### 1.34 Magician (魔术师)

**Description:** 在战斗中，从口袋中使用物品100次

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 100 | Pocket slot capacity expanded to 1×3 (from base 1×2) |

**Note:** The Magician reward upgrades each of the two pocket mini-grids from 1×2 to 1×3 cells. This increases the total pocket capacity from 4 cells to 6 cells per mini-grid, or 12 cells total across both slots. This affects how many small items can fit in the pocket without changing the number of slots.

#### 1.35 Lightning Reflex (闪电反应者)

**Description:** 在进入战斗的第一回合即取得胜利，完成30次

| Stage | Threshold | Reward |
| :--- | :--- | :--- |
| 1 | 30 | Unlock relic: Running Shoes (跑鞋) |

**Note:** "First-turn victory" means the enemy is reduced to 0 HP during the first player turn of the encounter, before the enemy ever acts. Fleeing on the first turn does not count.

### 2. Writing Mechanics

#### 2.1 When Entries Are Written

An entry is written and its reward granted at the moment the player crosses a threshold during an adventure. This happens in real time — the player does not need to complete the adventure.

- **Per-adventure thresholds** (e.g., Pathfinder, Survivor, Witness, Seeker): Checked at adventure end.
- **Cumulative thresholds** (e.g., Partner, Wayfarer, Hoarder): Tracked globally across all adventures. Updated after each relevant action.

#### 2.2 Notification

When a stage threshold is crossed:
1. A notification appears on screen indicating the entry name and reward.
2. If the reward is a relic: the relic is **unlocked** (made available in future loot, shop stock, and starting choices). The player in the **current** adventure does **not** receive the relic immediately.
3. If the reward is an upgrade (e.g., +1 damage, +1 restore), it applies immediately and persists for all future adventures.

#### 2.3 Progress Tracking

All cumulative counters are persisted to the save file after each relevant action. If a counter reaches exactly a threshold value, the stage is immediately granted.

### 3. Relic Unlock Flow

When a relic is unlocked via a Survivor Note entry:
1. The relic type becomes available in all loot generation sources (Hard Combat drops, shop stock, event rewards).
2. The relic becomes available as a starting choice if it is marked as "初始可选" in the Relics and Consumables System.
3. **The player in the current adventure does NOT receive the relic immediately.** Unlocking only gates future availability; it does not grant the relic in the ongoing run.

### 4. Starting Bonuses Application

Starting bonuses (max stamina, starting gold, starting consumable choices, relic upgrades) are applied at the moment a new adventure begins. However, the player may choose to **disable all Survivor Note buffs** at the start of a new adventure:

**Optional Carry:**
- At the start of each new adventure, the player is offered a choice: carry Survivor Note buffs or disable them.
- If the player chooses to **disable** buffs: all Survivor Note bonuses (max stamina increase, starting gold increase, Energy Drink restore upgrades, Whetstone upgrades, action card upgrades, etc.) are **suspended** for that adventure. The player's adventure starts at base values.
- **Unlocked relics remain available** even when buffs are disabled. The player can still find relics in loot, buy them from shops, and select them as starting choices.
- If the player chooses to **carry** buffs: all Survivor Note bonuses apply normally.

```
if carry_notes == true:
    adventure_starting_max_stamina = BASE_MAX_STAMINA + wayfarer_stages
    adventure_starting_gold = BASE_STARTING_GOLD + hoarder_stages
    adventure_consumable_choices = BASE_CONSUMABLE_CHOICES + survival_expert_stages
    energy_drink_restore = BASE_ENERGY_RESTORE + partner_stages
    # ... all other Survivor Note upgrades apply
else:
    adventure_starting_max_stamina = BASE_MAX_STAMINA
    adventure_starting_gold = BASE_STARTING_GOLD
    adventure_consumable_choices = BASE_CONSUMABLE_CHOICES
    energy_drink_restore = BASE_ENERGY_RESTORE
    # ... all other Survivor Note bonuses use base values
    # BUT: unlocked relics are still available in loot, shop, and starting choices
```

### 5. Ending and Reset

#### 5.1 False Ending

After a false ending:
- All Survivor Note progress is retained. No counters are reset.
- The player may start a new adventure. The Optional Carry choice is presented again at the start of the next adventure.

#### 5.2 True Ending

After completing the true ending (defeating Origin with 4 Survivor's Letters):
- All Survivor Note progress is retained. No counters are reset.
- The player may continue with a new adventure from Chapter 1. The Optional Carry choice is presented again.

## Formulas

### Energy Drink Restore

```
energy_drink_restore = BASE_ENERGY_RESTORE + partner_stages
```

| Variable | Value | Range | Description |
| :--- | :-: | :-: | :--- |
| `BASE_ENERGY_RESTORE` | 7 | 7–10 | Base restore amount |
| `partner_stages` | 0–3 | 0–3 | Partner entry stages completed |

### Whetstone Durability Restore

```
whetstone_durability = BASE_WHETSTONE_DURA + apprentice_stages
```

| Variable | Value | Range | Description |
| :--- | :-: | :-: | :--- |
| `BASE_WHETSTONE_DURA` | 3 | 3–5 | Base durability restored |
| `apprentice_stages` | 0–2 | 0–2 | Apprentice entry stages completed |

### Starting Max Stamina

```
starting_max_stamina = BASE_MAX_STAMINA + wayfarer_stages + boss_victories_this_adventure
```

| Variable | Value | Range | Description |
| :--- | :-: | :-: | :--- |
| `BASE_MAX_STAMINA` | 12 | 12–16 | Base starting max stamina |
| `wayfarer_stages` | 0–4 | 0–4 | Wayfarer entry stages completed |
| `boss_victories_this_adventure` | 0–4 | 0–4 | Bosses defeated in current adventure |

### Starting Gold

```
starting_gold = BASE_STARTING_GOLD + hoarder_stages
```

| Variable | Value | Range | Description |
| :--- | :-: | :-: | :--- |
| `BASE_STARTING_GOLD` | 8 | 8–12 | Base starting gold |
| `hoarder_stages` | 0–4 | 0–4 | Hoarder entry stages completed |

### Unarmed Attack Damage

```
unarmed_damage = BASE_UNARMED_DAMAGE + warrior_stages
```

| Variable | Value | Range | Description |
| :--- | :-: | :-: | :--- |
| `BASE_UNARMED_DAMAGE` | 3 | 3–5 | Base Unarmed Attack damage |
| `warrior_stages` | 0–2 | 0–2 | Warrior entry stages completed |

### Dodge Reduction

```
dodge_reduction = BASE_DODGE_REDUCTION + sports_enthusiast_stages
```

| Variable | Value | Range | Description |
| :--- | :-: | :-: | :--- |
| `BASE_DODGE_REDUCTION` | 4 | 4–6 | Base damage reduction from Dodge |
| `sports_enthusiast_stages` | 0–2 | 0–2 | Sports Enthusiast stages completed |

### Flee Card Cost

```
flee_cost = max(1, BASE_FLEE_COST - escape_master_stages)
```

| Variable | Value | Range | Description |
| :--- | :-: | :-: | :--- |
| `BASE_FLEE_COST` | 5 | 3–5 | Base Flee card cost |
| `escape_master_stages` | 0–2 | 0–2 | Escape Master stages completed |

### Last Effort Recovery

```
last_effort_recovery = BASE_LAST_EFFORT_RECOVERY + berserker_stages
```

| Variable | Value | Range | Description |
| :--- | :-: | :-: | :--- |
| `BASE_LAST_EFFORT_RECOVERY` | 2 | 2–4 | Base stamina restored on successful Last Effort |
| `berserker_stages` | 0–2 | 0–2 | Berserker stages completed |

### Flashlight Reveal Count

```
flashlight_reveal_count = BASE_FLASHLIGHT_REVEAL + electrician_stages
```

| Variable | Value | Range | Description |
| :--- | :-: | :-: | :--- |
| `BASE_FLASHLIGHT_REVEAL` | 2 | 2–4 | Base nodes revealed by Flashlight |
| `electrician_stages` | 0–2 | 0–2 | Electrician stages completed |

### Starting Consumable Choices

```
consumable_choice_count = BASE_CONSUMABLE_CHOICES + survival_expert_stages
```

| Variable | Value | Range | Description |
| :--- | :-: | :-: | :--- |
| `BASE_CONSUMABLE_CHOICES` | 1 | 1–3 | Base consumable choices at adventure start |
| `survival_expert_stages` | 0–2 | 0–2 | Survival Expert stages completed |

### Activated Cards Per Turn

```
activated_cards = BASE_ACTIVATED_CARDS + improviser_stages
```

| Variable | Value | Range | Description |
| :--- | :-: | :-: | :--- |
| `BASE_ACTIVATED_CARDS` | 3 | 3–5 | Base cards activated per player turn |
| `improviser_stages` | 0–2 | 0–2 | Improviser stages completed |

## Edge Cases

### E1. Relic Unlock Does Not Grant to Current Adventure

Unlocking a relic via Survivor Notes does not add it to the player's current inventory. The relic simply becomes available in future loot, shop stock, and starting choices. There is no "no inventory space" issue because the relic is never physically added to the current adventure's inventory.

### E2. Partner Threshold Exact Match

If the player restores exactly 220 stamina from Energy Drinks across adventures, stage 1 of Partner is written. The next point of Energy Drink restore counts toward stage 2.

### E3. Pathfinder Single-Run Tracking

Pathfinder requires 75 non-Road nodes in a **single** adventure. This counter resets each new adventure. If the player reaches 75 in one run, the entry is written and the reward is granted.

### E4. Wayfarer Counts Non-Road Nodes Only

Wayfarer tracks only nodes that are not Road nodes. Traveling on Road nodes does not contribute to Wayfarer progress.

### E5. Berserker Low-Stamina Victory Counting

Berserker requires winning combat while stamina is 5 or lower. This includes:
- Winning with Last Effort while at 1 stamina.
- Winning with Adrenaline Needle restoring to 10 and then dropping back to ≤ 5.
- The win must be a full combat victory (enemy dies), not a flee.

### E6. Scholar — Order of Stage Rewards

Scholar's 5 stages grant rewards in a fixed order: scattered consumables, then Fridge count, then Piggy Bank, then Anvil uses, then scattered consumables again. The stages must be completed in order; later stage rewards cannot be obtained before earlier ones.

### E7. Backpacker Upgrades Apply to Satchel Only

The Backpacker stages upgrade the Satchel (starting backpack). If the player later swaps to a different backpack type, the Satchel's upgrades are lost for that adventure. The Satchel upgrades persist across adventures and apply each time the player starts with a Satchel or equips one.

### E8. Advanced Collector — 20 Entries Unlocked

The count of "解锁20个条目" refers to the number of Survivor Note **entries** that have been written (not stages). Each entry counts as 1 regardless of whether it has 1 stage or multiple stages.

### E9. Witness and True Ending

Witness requires completing a true ending. This means the player must have 4 Survivor's Letters, defeat the Final Boss (Origin), and reach the true ending screen. A false ending does not count.

### E10. Hoarder Cumulative Gold

Hoarder counts **total gold ever accumulated** across all adventures, not current gold held. If the player earns 100 gold and spends 80, the Hoarder counter shows 100 toward the threshold.

### E11. Scholar Safe House Fridge Bonus

The Scholar stage 2 reward (+1 to Safe House Fridge Energy Drink count) applies to **all** Safe Houses in the current chapter. The per-visit Fridge limit becomes 3 (base 2 + 1) for every Safe House in the new chapter.

### E12. Trade Master Cumulative Spend

Trade Master counts gold **spent** at Black Markets, not gold earned or held. Selling items does not count; only purchasing from the shop deducts from the player's gold and contributes to the threshold.

## Dependencies

### Systems This Depends On

| System | Dependency Detail |
| :--- | :--- |
| **Combat System** | Tracks combat wins, damage dealt, Dodge uses, flee count, low-stamina wins for Berserker |
| **Node Interaction System** | Tracks non-Road node visits, Safe House entrances, Random Event entrances, ruins searches |
| **Backpack & Inventory System** | Tracks consumable use count, weapon durability restored |
| **Resource System** | Tracks gold accumulated, gold spent, Energy Drink restore totals |
| **Relics and Consumables System** | Grants relic unlocks; reads starting relic choices |
| **Boss and Chapter Transition System** | Tracks chapters entered, Boss victories, true/false ending completion |
| **Shop System** | Tracks gold spent at Black Market for Trade Master |
| **Map Generation System** | Pathfinder single-run node tracking |

### Systems That Depend On This

| System | Dependency Detail |
| :--- | :--- |
| **Combat System** | Reads upgrade values for Unarmed damage, Dodge reduction, Flee cost, activated cards, Last Effort recovery; tracks pocket item uses for Magician |
| **Resource System** | Reads starting max stamina and starting gold for adventure initialization |
| **Backpack & Inventory System** | Reads Satchel grid upgrade state, Magician pocket capacity upgrade; Safe House resource quantities |
| **Relics and Consumables System** | Reads relic unlock state for loot generation; starting consumable choice count |
| **Node Interaction System** | Reads Scholar's Safe House resource bonuses for Fridge/Piggy Bank/Anvil limits |
| **Save/Load System** | Must serialize all Survivor Note entry states, stage progress, and cumulative counters |

## Tuning Knobs

| Knob | Current Value | Safe Range | Description |
| :--- | :-: | :-: | :--- |
| `BASE_MAX_STAMINA` | 12 | 10–16 | Base starting max stamina |
| `BASE_STARTING_GOLD` | 8 | 5–15 | Base starting gold |
| `BASE_ENERGY_RESTORE` | 7 | 5–10 | Base Energy Drink restore |
| `BASE_WHETSTONE_DURA` | 3 | 3–5 | Base Whetstone durability restore |
| `BASE_UNARMED_DAMAGE` | 3 | 2–5 | Base Unarmed Attack damage |
| `BASE_DODGE_REDUCTION` | 4 | 2–6 | Base Dodge damage reduction |
| `BASE_FLEE_COST` | 5 | 3–7 | Base Flee card cost |
| `BASE_LAST_EFFORT_RECOVERY` | 2 | 1–4 | Base Last Effort recovery |
| `BASE_FLASHLIGHT_REVEAL` | 2 | 2–4 | Base Flashlight reveal count |
| `BASE_CONSUMABLE_CHOICES` | 1 | 1–3 | Base consumable choices at start |
| `BASE_ACTIVATED_CARDS` | 3 | 2–5 | Base cards activated per turn |
| `WAYFARER_MAX_STAMINA_PER_STAGE` | +1 | +1–+2 | Max stamina bonus per Wayfarer stage |
| `HOARDER_GOLD_PER_STAGE` | +1 | +1–+2 | Starting gold bonus per Hoarder stage |
| `PARTNER_RESTORE_PER_STAGE` | +1 | +1–+2 | Energy Drink restore bonus per Partner stage |
| `APPRENTICE_DURA_PER_STAGE` | +1 | +1–+2 | Whetstone durability bonus per Apprentice stage |
| `WARRIOR_DAMAGE_PER_STAGE` | +1 | +1–+2 | Unarmed damage bonus per Warrior stage |
| `SPORTS_ENTHUSIAST_DODGE_PER_STAGE` | +1 | +1–+2 | Dodge reduction bonus per Sports Enthusiast stage |
| `ESCAPE_MASTER_FLEE_PER_STAGE` | -1 | -1–-2 | Flee cost reduction per Escape Master stage |
| `BERSERKER_RECOVERY_PER_STAGE` | +1 | +1–+2 | Last Effort recovery bonus per Berserker stage |
| `ELECTRICIAN_REVEAL_PER_STAGE` | +1 | +1–+2 | Flashlight reveal bonus per Electrician stage |
| `SURVIVAL_EXPERT_CHOICES_PER_STAGE` | +1 | +1–+2 | Consumable choice bonus per Survival Expert stage |
| `IMPROVISER_CARDS_PER_STAGE` | +1 | +1–+2 | Activated cards bonus per Improviser stage |
| `MAGICIAN_THRESHOLD` | 100 | 50–200 | Pocket uses required to unlock Magician entry |

## Acceptance Criteria

### AC1. Partner — Energy Drink Restore Upgrade
- [ ] Use Energy Drinks to restore 220 total stamina across adventures.
- [ ] Verify Partner stage 1 is written and Energy Drink restore increases by +1.
- [ ] Continue to 450 total. Verify restore increases again.
- [ ] Continue to 750 total. Verify restore increases to +3 total.

### AC2. Wayfarer — Max Stamina Increase
- [ ] Complete 150 non-Road node visits across adventures.
- [ ] Verify Wayfarer stage 1 is written and starting max stamina increases by +1.
- [ ] Continue to 1100 total. Verify all 4 stages are written and starting max stamina is +4.

### AC3. Hoarder — Starting Gold Increase
- [ ] Accumulate 100 total gold across adventures (earn and keep).
- [ ] Verify Hoarder stage 1 is written and starting gold increases by +1.
- [ ] Continue to 800 total. Verify all 4 stages are written and starting gold is +4.

### AC4. Relic Unlock — Bottle Cap
- [ ] Drink 240 Energy Drinks across adventures.
- [ ] Verify Spokesperson entry is written and Bottle Cap relic is unlocked.
- [ ] Verify Bottle Cap now appears in Hard Combat loot tables and shop stock.

### AC5. Pathfinder — Single Run Threshold
- [ ] Visit 75 non-Road nodes in a single adventure.
- [ ] Verify Pathfinder is written and MP4 relic is unlocked.
- [ ] Start a new adventure. Verify the counter resets to 0.

### AC6. Berserker — Low-Stamina Wins
- [ ] Win 20 combats with stamina ≤ 5.
- [ ] Verify Berserker stage 1 is written and Last Effort recovery increases by +1.
- [ ] Win 50 more (total 50). Verify stage 2 is written and recovery is +2 total.

### AC7. Scholar — Safe House Bonuses
- [ ] Enter Safe Houses 22 times total.
- [ ] Verify Scholar stage 2 is written.
- [ ] Enter a new Safe House. Verify Fridge has 3 Energy Drinks (base 2 + 1).

### AC8. Backpacker — Satchel Upgrades
- [ ] Discover 2 backpack types across adventures.
- [ ] Verify Backpacker stage 1 is written. Verify Satchel secondary space is 1×3.
- [ ] Discover 5 backpack types. Verify Satchel primary space is 4×4.

### AC9. Trade Master — Gold Spent
- [ ] Spend 400 gold total at Black Markets across adventures.
- [ ] Verify Trade Master is written and Friendship Token relic is unlocked.

### AC10. Improviser — Activated Cards
- [ ] Play 150 action cards across adventures.
- [ ] Verify Improviser stage 1 is written.
- [ ] Verify 4 cards are activated per player turn (base 3 + 1).

### AC11. Survivor Notes Persist After False Ending
- [ ] Complete a false ending. Verify all Survivor Note progress is retained.
- [ ] Start a new adventure. Verify all previously unlocked relics and starting bonuses are active.

### AC12. True Ending — Witness Entry
- [ ] Complete the true ending (defeat Origin with 4 Survivor's Letters).
- [ ] Verify Witness entry is written and Dim Lantern relic is unlocked.

### AC13. Advanced Collector — 20 Entries
- [ ] Write 20 Survivor Note entries across adventures.
- [ ] Verify Advanced Collector is written and Second-hand Drone relic is unlocked.

### AC14. Relic Unlock Does Not Grant to Current Adventure
- [ ] Unlock a relic via Survivor Notes (e.g., reach 240 Energy Drinks for Bottle Cap).
- [ ] Verify the relic is unlocked but NOT added to the current adventure's inventory.
- [ ] Start a new adventure. Verify the relic now appears in loot tables, shop stock, or starting choices.

### AC15. Optional Carry — Disable Buffs
- [ ] At adventure start, choose to disable Survivor Note buffs.
- [ ] Verify starting max stamina is 12 (base), not increased by Wayfarer.
- [ ] Verify starting gold is 8 (base), not increased by Hoarder.
- [ ] Verify Energy Drink restore is 7 (base), not increased by Partner.
- [ ] Verify relics are still available in loot, shop, and starting choices.

### AC16. Optional Carry — Enable Buffs
- [ ] At adventure start, choose to carry Survivor Note buffs.
- [ ] Verify all buffs apply normally (max stamina, starting gold, upgrades, etc.).
- [ ] Verify relics are still available in loot, shop, and starting choices.

### AC17. Magician — Pocket Capacity Upgrade
- [ ] Use items from the pocket 100 times in combat across adventures.
- [ ] Verify Magician entry is written.
- [ ] Verify each pocket mini-grid is expanded from 1×2 to 1×3.

### AC18. Lightning Reflex — First-Turn Victory Unlock
- [ ] Win 30 combats on the first player turn (enemy dies before acting) across adventures.
- [ ] Verify Lightning Reflex entry is written and Running Shoes relic is unlocked.
- [ ] Start a new adventure. Verify Running Shoes appears in starting choices and shop stock.
