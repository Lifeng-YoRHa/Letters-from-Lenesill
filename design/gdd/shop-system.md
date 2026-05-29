# Shop System

## Overview

The Shop System governs the Black Market node interface — a buy/sell interface for items, relics, and consumables. Stock is generated via weighted random per chapter; the player can purchase items (subject to gold and inventory fit checks) and sell items from inventory for gold. The system handles stock generation, transaction validation, price calculation, stock depletion, and chapter-locked stock persistence.

**Scope:** All Black Market interactions — stock generation, buy/sell transactions, price formulas, stock limits, and overlay UI flow. Black Market node behavior (arrival trigger, chapter lock) is covered in the Node Interaction System.

**Key characteristics:**
- **Fixed 5-slot structure:** Each Black Market has exactly 5 slots. Three are guaranteed consumable slots; the remaining two slots carry variable categories.
- **Friendship Token buy discount:** The Friendship Token relic reduces all buy prices by 30% (floor). Sell prices are unaffected.
- **Spatial fit gates:** Purchase is blocked if the item cannot fit in inventory; sell is always allowed if the item is in inventory.
- **Stock depletion:** Purchased items are removed from stock; sold items are removed from inventory. Neither action restores stock within the chapter.
- **Chapter-locked persistence:** Stock does not refresh during a chapter; each new chapter generates fresh stock.

## Detailed Rules

### Definitions

- **Black Market Slot:** A fixed item slot in the shop UI. Each Black Market has 5 slots.(Or 6 slots, only when selling the quest item "Lost Letter")
- **Shop Stock:** The current list of items available for purchase in this chapter's Black Market.
- **Buy Price:** The amount of gold required to purchase an item from stock.
- **Sell Price:** The amount of gold received when selling an item to the shop.
- **Friendship Token Effect:** Reduces all buy prices by 30% (floor). Sell prices are unaffected.

### 1. Stock Generation

#### 1.1 Generation Timing

- Stock is generated **once** when the chapter's map is created.
- It persists for the duration of the chapter.
- Transitions to the next chapter generate **new independent stock**.
- If the player revisits the same Black Market node within a chapter, the stock is unchanged.

#### 1.2 Slot Structure

Each Black Market has exactly **5 slots** with the following guaranteed arrangement:

| Slot | Guaranteed Content | Variable Content |
| :--- | :--- | :--- |
| Slot 1 | Energy Drink (energy drink) | — |
| Slot 2 | Stone (stone) | — |
| Slot 3 | Whetstone (whetstone) | — |
| Slot 4 | — | Torch / Relic / Weapon |
| Slot 5 | — | Flashlight / Safe House Key / Backpack |

The three guaranteed consumable slots each occupy one slot regardless of their quantity.

#### 1.3 Inventory Quantity Ranges

The inventory quantity for each consumable is rolled randomly within the given range, with equal probability:

| Consumable | Inventory Range | Notes |
| :--- | :--- | :--- |
| Energy Drink | 3 / 4 / 5 / 6 | |
| Stone | 1 / 2 / 3 / 4 | |
| Whetstone | 1 / 2 / 3 / 4 | |
| Torch | 1 / 2 | |
| Flashlight | 1 / 2 | |
| Safe House Key | 1 / 2 | |

#### 1.4 Variable Slot Selection

**Slot 4 (probability weights):**
| Item | Probability |
| :--- | :-: |
| Torch | 60% |
| Relic | 30% |
| Weapon | 10% |

**Slot 5 (probability weights):**
| Item | Probability |
| :--- | :-: |
| Flashlight | 60% |
| Safe House Key | 30% |
| Backpack | 10% |

#### 1.5 Relic Rules

- Only relics whose Survivor Note entry has been written appear in stock.
- One-per-adventure rule applies: if the player already holds a relic type, that type does not appear in stock.
- Adrenaline Needle and Coin Purse do not appear in shop stock (acquisition only via starting choice / event).

#### 1.6 Weapon Rules

- Weapons in stock scale with chapter and difficulty (see price formula).
- Only one weapon per Black Market (in slot 4).
- Weapon type is determined by chapter and difficulty scaling.

#### 1.7 Backpack Rules

- Backpacks appear in slot 5 at 10% probability.
- The backpack type is determined by chapter unlock progression.
- Backpacks cannot be sold.

### 2. Buy Transactions

#### 2.1 Purchase Flow

1. Player clicks an item in the shop stock.
2. System checks if `current_gold >= buy_price`.
3. System checks if item fits in inventory (pocket + backpack combined).
4. If either check fails, the purchase button is disabled with a tooltip.
5. If both pass, player clicks **Buy**.
6. Gold is deducted; inventory quantity is decremented for consumables (or item removed for 1-of-1 items); item is added to inventory.
7. If inventory quantity for a consumable reaches 0, the slot becomes empty/grayed out.
8. Transaction is atomic: if the inventory add fails (should not happen given pre-check), gold is refunded.

#### 2.2 Buy Price Formulas

**Consumables:**
| Consumable | C1 Price | C2 Price | C3 Price | C4 Price | C5 Price |
| :--- | :-: | :-: | :-: | :-: | :-: |
| Energy Drink | 3–4 | 4–5 | 5–6 | 6–7 | 7–8 |
| Stone | 2–3 | 3–4 | 4–5 | 5–6 | 6–7 |
| Whetstone | 3–4 | 4–5 | 5–6 | 6–7 | 7–8 |
| Torch | 6/7 | 7/8 | 9/10 | 10/11 | 12/13 |
| Flashlight | 5/6 | 6/7 | 8/9 | 9/10 | 10/11 |
| Safe House Key | 12/13/14/15 | 14/15/16/17 | 16/17/18/19 | 17/18/19/20 | 18/19/20/21 |

The price for each consumable slot is rolled independently within the given range (with equal probability per value), regardless of the inventory quantity in that slot. The rolled price has no correlation with the quantity — buying 1 Safe House Key and buying 2 both pay the same price for that stock instance.

**Relics:**
| Chapter | Buy Price |
| :--- | :--- |
| C1 | 25/26/27/28/29/30 |
| C2 | 27/28/29/30/31/32 |
| C3 | 30/31/32/33/34/35 |
| C4 | 33/34/35/36/37/38 |
| C5 | 35/36/37/38/39/40 |

**Weapons:**
```
buy_price = weapon_attack + 5 × weapon_max_durability + 6 × current_chapter
```

**Backpacks:**
```
buy_price = total_storage_cells + 4 × current_chapter
```

| Backpack | Total Cells |
| :--- | :-: |
| Satchel (随身挎包) | 14 (or 19 if upgraded) |
| Student Backpack (学生背包) | 24 |
| Travel Backpack (旅行背包) | 36 |
| Padlocked Laptop Bag (挂锁电脑包) | 36 |
| Marching Backpack (行军背包) | 50 |
| Oversized Backpack (超大背包) | 66 |

### 3. Sell Transactions

#### 3.1 Sell Flow

1. Player clicks an item in their inventory while the Black Market overlay is open.
2. Player clicks **Sell**.
3. The item is removed from inventory; sell price is added to gold.
4. The sold item is **not** added back to shop stock.

#### 3.2 Sell Price Formulas

**Weapons:**
```
sell_price = weapon_attack + floor(2 × (current_durability / max_durability))
```

**Consumables:**
| Consumable | Sell Price |
| :--- | :-: |
| Energy Drink | 2 |
| Stone | 1 |
| Whetstone | 2 |
| Torch | 4 |
| Flashlight | 3 |
| Safe House Key | 8 |

**Relics:**
| Item | Sell Price |
| :--- | :-: |
| Relic (any) | 12 |

**Backpacks:** Cannot be sold.

### 4. Friendship Token

The Friendship Token relic (友谊之证) applies a **30% discount to all buy prices**:
```
final_buy_price = floor(original_price × 0.7)
```

- Applied to all consumables, relics, weapons, and backpacks purchased.
- Sell prices are **not** affected.
- Rounded down to nearest integer.

### 5. Shop Overlay UI

- **Layout:** Grid of item slots (left/center), inventory panel (right), gold display (top).
- **Item card:** Shows item name, icon, inventory quantity (for consumables), buy price.
- **Buy button:** Enabled only when gold >= price AND item fits.
- **Sell button:** Shown only when viewing inventory in the shop overlay.
- **Detail panel:** Clicking a shop stock item shows detailed stats, description, weapon ATK/durability, or consumable effect.
- **Leave button:** Closes the overlay and returns to map.
- **Friendship Token indicator:** If the relic is equipped, a small icon indicator appears on the buy price labels.
- **Quantity badge:** Consumable slots show the inventory quantity (e.g., "×3") on the card.

### 6. Departure from Shop

- The player may leave the Black Market at any time via the **Leave** button.
- There is no forced transaction requirement.
- Departure does not clear or refresh stock.

## Formulas

### Consumable Buy Price Table

| Consumable | C1 | C2 | C3 | C4 | C5 |
| :--- | :-: | :-: | :-: | :-: | :-: |
| Energy Drink | 3–4 | 4–5 | 5–6 | 6–7 | 7–8 |
| Stone | 2–3 | 3–4 | 4–5 | 5–6 | 6–7 |
| Whetstone | 3–4 | 4–5 | 5–6 | 6–7 | 7–8 |
| Torch | 6/7 | 7/8 | 9/10 | 10/11 | 12/13 |
| Flashlight | 5/6 | 6/7 | 8/9 | 9/10 | 10/11 |
| Safe House Key | 12/13/14/15 | 14/15/16/17 | 16/17/18/19 | 17/18/19/20 | 18/19/20/21 |

Price for each consumable slot is rolled independently within the given range (with equal probability per value), regardless of the inventory quantity in that slot.

### Relic Buy Price Table

| C1 | C2 | C3 | C4 | C5 |
| :-: | :-: | :-: | :-: | :-: |
| 25/26/27/28/29/30 | 27/28/29/30/31/32 | 30/31/32/33/34/35 | 33/34/35/36/37/38 | 35/36/37/38/39/40 |

### Weapon Buy Price

```
buy_price = weapon_attack + 5 × max_durability + 6 × chapter
```

| Variable | Value | Description |
| :--- | :-: | :--- |
| `weapon_attack` | varies by weapon | Base attack stat. |
| `max_durability` | varies by weapon | Maximum durability. |
| `chapter` | 1–5 | Current chapter number. |

### Weapon Sell Price

```
sell_price = weapon_attack + floor(2 × (current_durability / max_durability))
```

### Backpack Buy Price

```
buy_price = total_storage_cells + 4 × chapter
```

| Backpack | Total Cells |
| :--- | :-: |
| Satchel | 14 (19 if upgraded) |
| Student Backpack | 24 |
| Travel Backpack | 36 |
| Padlocked Laptop Bag | 36 |
| Marching Backpack | 50 |
| Oversized Backpack | 66 |

### Friendship Token Buy Discount

```
final_buy_price = floor(buy_price × 0.7)
```

- Applied to all buy transactions.
- Sell prices are unaffected.
- Minimum buy price after discount is 1.

### Consumable / Relic Sell Prices

| Item | Sell Price |
| :--- | :-: |
| Energy Drink | 2 |
| Stone | 1 |
| Whetstone | 2 |
| Torch | 4 |
| Flashlight | 3 |
| Safe House Key | 8 |
| Relic | 12 |

## Edge Cases

### E1. Consumable Slot Exhausted

If a consumable's inventory quantity is depleted through purchases (e.g., buying 3 of 3 Energy Drinks), the slot card becomes grayed out and disabled. It cannot be refilled within the same chapter.

### E2. Duplicate Relic in Stock

If a relic type already held by the player would appear in stock generation, it is skipped and a new roll is performed. The slot remains filled with the replacement relic. Adrenaline Needle and Coin Purse never appear in shop stock regardless of unlock status.

### E3. Purchase with Exact Gold

If `current_gold == buy_price`, the purchase is allowed. Gold becomes 0.

### E4. Purchase with Insufficient Gold

The Buy button is disabled. The disabled state is the UI feedback; no error message is shown.

### E5. Purchase with No Inventory Space

The Buy button is disabled with "No space" tooltip. The slot item remains available; the player may free space and return.

### E6. Weapon Price Scaling Example

A Kitchen Knife (ATK 9, max durability 5) in Chapter 3:
`buy_price = 9 + 5×5 + 6×3 = 9 + 25 + 18 = 52` gold.

### E7. Friendship Token with Weapon at Exact Price

If the player has Friendship Token and a weapon buy price is 20 gold: `floor(20 × 0.7) = 14`. Buy price becomes 14.

### E8. Black Market Stock Does Not Refresh Within Chapter

Re-entering the same Black Market shows identical stock. Quantity-reduced consumable slots reflect previous purchases. This is intentional behavior per Node Interaction System E7.

### E9. Backpack Cannot Be Sold

Backpacks appear in shop stock but cannot be sold back. The Sell button is not shown for backpack items. Backpacks equipped by the player also cannot be sold.

### E10. Sell Price of 0 with Friendship Token

The Friendship Token only affects buy prices. Sell prices are unaffected by Friendship Token.

### E11. Chapter Transition — New Stock Generation

When the player transitions to the next chapter, the previous chapter's Black Market stock is lost. The new chapter's Black Market node (or the same node on the new map) has freshly generated stock, inventory quantities, and price tiers. Per Node Interaction System E7.

### E12. Variable Slot Rolls Weapon but No Weapon Available for Chapter

If the slot 4 roll results in Weapon (10%) but no weapon is currently available (e.g., all weapons already held or none unlocked for chapter), the slot re-rolls within its category until a valid weapon is selected.

### E13. Purchase Quantity and Inventory Fit

When buying a consumable slot (e.g., 3 Energy Drinks), the fit check validates that all units can fit in inventory simultaneously. If space is insufficient for the full quantity, purchase is blocked. The player cannot partially buy a slot.

### E14. Black Market Node State

Black Market nodes do not become Cleared. They remain Visited indefinitely and can be re-entered at any time. This state management is handled by the Node Interaction System; this document assumes external enforcement.

## Dependencies

### Systems This Depends On

| System | Dependency Detail |
| :--- | :--- |
| **Node Interaction System** | Black Market node arrival trigger; chapter-locked stock persistence rule; node state (Visited, not Cleared) |
| **Backpack & Inventory System** | Inventory fit check for purchase; sell price lookup; item removal on sell; item / backpack acquisition |
| **Resource System** | Gold read for buy validation; gold deduction on buy; gold addition on sell; gold cap enforcement |
| **Relic System** | Relic buy/sell prices; one-per-adventure duplicate check; Friendship Token buy discount |
| **Survivor Notes System** | Relic unlock gate (entry must be written before relic appears in shop); backpack upgrade state for Satchel |

### Systems That Depend on This

| System | Dependency Detail |
| :--- | :--- |
| **Node Interaction System** | Calls shop overlay on Black Market node arrival; departs to map on Leave |
| **Combat System** | Consumables and weapons bought from shop are usable in combat |
| **Save/Load System** | Must serialize current chapter's Black Market stock (item IDs, inventory quantities per slot) |
| **Achievement / Survivor Notes** | "Trader" tracks total gold spent on Black Market purchases |

## Tuning Knobs

| Knob | Current Value | Safe Range | Description |
| :--- | :-: | :-: | :--- |
| `BLACK_MARKET_SLOTS` | 5 | 4–6 | Number of slots per Black Market. |
| `TORCH SLOT4 WEIGHT` | 60% | 40–80% | Probability Torch appears in slot 4. |
| `RELIC SLOT4 WEIGHT` | 30% | 20–40% | Probability Relic appears in slot 4. |
| `WEAPON SLOT4 WEIGHT` | 10% | 5–20% | Probability Weapon appears in slot 4. |
| `FLASHLIGHT SLOT5 WEIGHT` | 60% | 40–80% | Probability Flashlight appears in slot 5. |
| `SAFE_HOUSE_KEY SLOT5 WEIGHT` | 30% | 20–40% | Probability Safe House Key appears in slot 5. |
| `BACKPACK SLOT5 WEIGHT` | 10% | 5–20% | Probability Backpack appears in slot 5. |
| `FRIENDSHIP_TOKEN_BUY_DISCOUNT` | 30% | 20–50% | Buy price reduction when Friendship Token equipped. |
| `WEAPON_SELL_DURA_WEIGHT` | 2.0 | 1.0–5.0 | Multiplier for durability portion of weapon sell price. |
| `BACKPACK_PRICE_PER_CHAPTER` | 4 | 2–6 | Gold added per chapter to backpack buy price. |
| `WEAPON_PRICE_DURA_MULTIPLIER` | 5 | 3–8 | Multiplier for max durability in weapon buy price formula. |
| `WEAPON_PRICE_CHAPTER Adder` | 6 | 3–10 | Flat gold added per chapter in weapon buy price formula. |

## Acceptance Criteria

### AC1. Stock Structure
- [ ] Enter a Black Market in Chapter 1. Verify exactly 5 slots.
- [ ] Verify slot 1 = Energy Drink, slot 2 = Stone, slot 3 = Whetstone.
- [ ] Verify slot 4 is one of: Torch (60%), Relic (30%), Weapon (10%).
- [ ] Verify slot 5 is one of: Flashlight (60%), Safe House Key (30%), Backpack (10%).

### AC2. Consumable Inventory Quantity
- [ ] Enter a Black Market. Note the Energy Drink quantity.
- [ ] Enter the same Black Market in a different chapter run. Verify quantities may differ (random within range).
- [ ] Buy all Energy Drinks. Verify the slot becomes grayed out and disabled.

### AC3. Buy — Sufficient Gold and Space
- [ ] With 50 gold and inventory space, buy a weapon priced at 30.
- [ ] Verify gold becomes 20 and the weapon is in inventory.

### AC4. Buy — Insufficient Gold
- [ ] With 10 gold, attempt to buy an item priced at 20.
- [ ] Verify the Buy button is disabled. Verify no gold is deducted.

### AC5. Buy — No Inventory Space
- [ ] Fill inventory so no empty cell exists. Attempt to buy any shop item.
- [ ] Verify the Buy button is disabled with "No space" tooltip. Verify no gold is deducted.

### AC6. Weapon Buy Price Formula
- [ ] In Chapter 1, note the buy price of a weapon with ATK 6, max durability 8.
- [ ] Verify buy price = 6 + 5×8 + 6×1 = 6 + 40 + 6 = 52.
- [ ] In Chapter 3, verify same weapon: 6 + 5×8 + 6×3 = 6 + 40 + 18 = 64.

### AC7. Weapon Sell Price Formula
- [ ] Sell a weapon with ATK 8 and current durability 6/10.
- [ ] Verify sell price = 8 + floor(2 × 0.6) = 8 + 1 = 9 gold.

### AC8. Sell — Consumables and Relics
- [ ] Sell an Energy Drink. Verify sell price = 2 gold.
- [ ] Sell a Whetstone. Verify sell price = 2 gold.
- [ ] Sell a Torch. Verify sell price = 4 gold.
- [ ] Sell a Relic. Verify sell price = 12 gold.

### AC9. Friendship Token Buy Discount
- [ ] Without Friendship Token, note the buy price of a Relic in Chapter 1 (e.g., 25–30).
- [ ] Equip Friendship Token. Attempt to buy the same Relic.
- [ ] Verify buy price = floor(original × 0.7).

### AC10. Backpack Buy Price
- [ ] In Chapter 1, buy a Travel Backpack (36 cells). Verify price = 36 + 4×1 = 40 gold.
- [ ] In Chapter 3, buy the same backpack. Verify price = 36 + 4×3 = 48 gold.

### AC11. Backpack Cannot Be Sold
- [ ] Sell is not shown as an option for any backpack item in the shop.

### AC12. Stock Persists Through Departure
- [ ] Enter Black Market. Buy 2 items from a consumable slot. Note the remaining quantity.
- [ ] Leave and re-enter. Verify the quantity is unchanged (no refresh within chapter).

### AC13. Chapter Transition — Fresh Stock
- [ ] Defeat the Boss and enter Chapter 2 Black Market.
- [ ] Verify all 5 slots are populated with new stock and quantities.

### AC14. Relic Not in Stock If Already Held
- [ ] Obtain a Cross relic during an adventure.
- [ ] Enter a Black Market in the same chapter. Verify Cross does not appear in stock.

### AC15. Black Market Revisit Same Chapter
- [ ] Enter Black Market. Note all 5 slot items and quantities.
- [ ] Leave, travel to another node, return to Black Market.
- [ ] Verify identical stock and quantities (no refresh within chapter).