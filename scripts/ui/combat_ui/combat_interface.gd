class_name CombatInterface
extends Control

signal pocket_item_used(item_id: StringName)
signal backpack_open_requested

@export var enemy_hp: int = 14
@export var enemy_attack: int = 4
@export var player_max_stamina: int = 16
@export var activated_card_count: int = 3

const ITEM_COLORS := {
	GameEnums.ItemType.WEAPON: Color(0.75, 0.35, 0.35),
	GameEnums.ItemType.CONSUMABLE: Color(0.35, 0.7, 0.4),
	GameEnums.ItemType.RELIC: Color(0.9, 0.75, 0.25),
	GameEnums.ItemType.BACKPACK: Color(0.35, 0.55, 0.8),
	GameEnums.ItemType.GOLD: Color(0.9, 0.8, 0.2),
}

const POCKET_CELL_SIZE := 40

var _stamina: Stamina
var _combat_manager: CombatManager
var _enemy_data: EnemyData
var _backpack_manager: BackpackManager

@onready var _stamina_bar: ProgressBar = %StaminaBar
@onready var _stamina_label: Label = %StaminaLabel
@onready var _weapon_label: Label = %WeaponLabel
@onready var _enemy_hp_bar: ProgressBar = %EnemyHPBar
@onready var _enemy_hp_label: Label = %EnemyHPLabel
@onready var _enemy_name_label: Label = %EnemyName
@onready var _card_container: HBoxContainer = %CardContainer
@onready var _end_turn_button: Button = %EndTurnButton
@onready var _log_label: Label = %LogLabel
@onready var _round_label: Label = %RoundLabel
@onready var _phase_label: Label = %PhaseLabel
@onready var _pocket_a_container: Control = %PocketA
@onready var _pocket_b_container: Control = %PocketB


func _ready() -> void:
	if _combat_manager == null:
		_setup_test_combat()
		_connect_signals()
		_combat_manager.start_combat()
		_update_ui()


func initialize(combat_manager: CombatManager) -> void:
	_combat_manager = combat_manager
	_enemy_data = combat_manager.combat_state.enemy_data
	_stamina = combat_manager.player_stamina
	_backpack_manager = combat_manager.backpack_manager


func start() -> void:
	if _combat_manager == null:
		return
	_connect_signals()
	_combat_manager.start_combat()
	_update_ui()


func refresh() -> void:
	_update_ui()


func _setup_test_combat() -> void:
	_enemy_data = EnemyData.new()
	_enemy_data.id = &"test_enemy"
	_enemy_data.base_hp = enemy_hp
	_enemy_data.base_attack = enemy_attack

	_stamina = Stamina.new()
	_stamina.initialize(player_max_stamina)

	var deck := _make_test_deck()
	_combat_manager = CombatManager.new()
	_combat_manager.initialize(_enemy_data, GameEnums.EnemyType.NORMAL, _stamina, deck, null, null, null, activated_card_count)


func _make_test_deck() -> Array[ActionCardData]:
	var deck: Array[ActionCardData] = []

	var unarmed := ActionCardData.new()
	unarmed.id = &"unarmed_attack"
	unarmed.display_name = "Unarmed Attack"
	unarmed.stamina_cost = 1
	unarmed.effect = GameEnums.ActionCardEffect.UNARMED_ATTACK
	unarmed.base_value = 3
	deck.append(unarmed)

	var weapon := ActionCardData.new()
	weapon.id = &"weapon_attack"
	weapon.display_name = "Weapon Attack"
	weapon.stamina_cost = 1
	weapon.effect = GameEnums.ActionCardEffect.WEAPON_ATTACK
	weapon.base_value = _get_weapon_attack_power()
	deck.append(weapon)

	var dodge := ActionCardData.new()
	dodge.id = &"dodge"
	dodge.display_name = "Dodge"
	dodge.stamina_cost = 2
	dodge.effect = GameEnums.ActionCardEffect.DODGE
	deck.append(dodge)

	var courage := ActionCardData.new()
	courage.id = &"summon_courage"
	courage.display_name = "Summon Courage"
	courage.stamina_cost = 1
	courage.effect = GameEnums.ActionCardEffect.SUMMON_COURAGE
	deck.append(courage)

	var flee := ActionCardData.new()
	flee.id = &"flee"
	flee.display_name = "Flee"
	flee.stamina_cost = 5
	flee.effect = GameEnums.ActionCardEffect.FLEE
	deck.append(flee)

	var search_backpack := ActionCardData.new()
	search_backpack.id = &"search_backpack"
	search_backpack.display_name = "Search Backpack"
	search_backpack.stamina_cost = 1
	search_backpack.effect = GameEnums.ActionCardEffect.SEARCH_BACKPACK
	deck.append(search_backpack)

	var analyze := ActionCardData.new()
	analyze.id = &"analyze_countermeasure"
	analyze.display_name = "Analyze Countermeasure"
	analyze.stamina_cost = 1
	analyze.effect = GameEnums.ActionCardEffect.ANALYZE_COUNTERMEASURE
	deck.append(analyze)

	var adjust_breathing := ActionCardData.new()
	adjust_breathing.id = &"adjust_breathing"
	adjust_breathing.display_name = "Adjust Breathing"
	adjust_breathing.stamina_cost = 1
	adjust_breathing.effect = GameEnums.ActionCardEffect.ADJUST_BREATHING
	deck.append(adjust_breathing)

	return deck


func _connect_signals() -> void:
	_safe_connect(_combat_manager.combat_started, _on_combat_started)
	_safe_connect(_combat_manager.player_turn_started, _on_player_turn_started)
	_safe_connect(_combat_manager.enemy_turn_started, _on_enemy_turn_started)
	_safe_connect(_combat_manager.enemy_action_resolved, _on_enemy_action_resolved)
	_safe_connect(_combat_manager.player_took_damage, _on_player_took_damage)
	_safe_connect(_combat_manager.enemy_took_damage, _on_enemy_took_damage)
	_safe_connect(_combat_manager.combat_ended, _on_combat_ended)
	_safe_connect(_combat_manager.round_started, _on_round_started)
	_safe_connect(_stamina.stamina_changed, _on_stamina_changed)
	if not _end_turn_button.pressed.is_connected(_on_end_turn_pressed):
		_end_turn_button.pressed.connect(_on_end_turn_pressed)


func _safe_connect(sig: Signal, callable: Callable) -> void:
	if sig.is_connected(callable):
		sig.disconnect(callable)
	sig.connect(callable)


func _on_combat_started() -> void:
	_log_label.text = ""
	if _combat_manager != null:
		for debuff in _combat_manager.combat_state.active_debuffs:
			_log("受到负面情绪：%s" % _debuff_name(debuff))


func _update_ui() -> void:
	_update_stamina_display(_stamina.current_stamina)
	_update_enemy_hp_display(_combat_manager.combat_state.enemy_current_hp)
	_phase_label.text = _phase_name(_combat_manager.combat_state.combat_phase)
	_update_weapon_display()
	_render_pockets()


func _update_weapon_display() -> void:
	if _backpack_manager == null or _backpack_manager.equipped_weapon == null:
		_weapon_label.text = "Weapon: None"
		return
	var w := _backpack_manager.equipped_weapon
	var atk := w.get_weapon_attack()
	var dur := w.weapon_current_durability
	var max_dur := w.get_weapon_max_durability()
	var name_text := w.display_name
	_weapon_label.text = "Weapon: %s %d ATK %d/%d" % [name_text, atk, dur, max_dur]


func _get_weapon_attack_power() -> int:
	if _backpack_manager == null or _backpack_manager.equipped_weapon == null:
		return 7
	return _backpack_manager.equipped_weapon.get_weapon_attack()


func _get_weapon_cost_modifier() -> int:
	if _backpack_manager == null or _backpack_manager.equipped_weapon == null:
		return 0
	var weapon_trait := _backpack_manager.equipped_weapon.get_weapon_trait_id()
	match weapon_trait:
		&"hammer_heavy": return 1
		&"baton_light": return -1
		_:
			return 0


func _consume_weapon_durability() -> void:
	if _backpack_manager == null or _backpack_manager.equipped_weapon == null:
		return
	var w := _backpack_manager.equipped_weapon
	w.weapon_current_durability = maxi(w.weapon_current_durability - 1, 0)
	_update_weapon_display()
	if w.weapon_current_durability <= 0:
		_update_card_buttons(_combat_manager.combat_state.activated_cards)


func _is_weapon_attack_available() -> bool:
	if _backpack_manager == null or _backpack_manager.equipped_weapon == null:
		return true
	return _backpack_manager.equipped_weapon.weapon_current_durability > 0


func _update_stamina_display(current: int) -> void:
	_stamina_bar.max_value = _stamina.max_stamina
	_stamina_bar.value = current
	_stamina_label.text = "%d / %d" % [current, _stamina.max_stamina]


func _update_enemy_hp_display(current: int) -> void:
	_enemy_hp_bar.max_value = _enemy_data.base_hp
	_enemy_hp_bar.value = current
	_enemy_hp_label.text = "%d / %d" % [current, _enemy_data.base_hp]


func _phase_name(phase: GameEnums.CombatPhase) -> String:
	match phase:
		GameEnums.CombatPhase.SETUP:
			return "SETUP"
		GameEnums.CombatPhase.PLAYER_TURN:
			return "PLAYER TURN"
		GameEnums.CombatPhase.ENEMY_TURN:
			return "ENEMY TURN"
		GameEnums.CombatPhase.VICTORY:
			return "VICTORY"
		GameEnums.CombatPhase.DEFEAT:
			return "DEFEAT"
		GameEnums.CombatPhase.FLED:
			return "FLED"
		_:
			return "UNKNOWN"


func _log(message: String) -> void:
	var text := _log_label.text
	if not text.is_empty():
		text += "\n"
	text += message
	var lines := text.split("\n")
	if lines.size() > 20:
		text = "\n".join(lines.slice(-20))
	_log_label.text = text


func _update_card_buttons(cards: Array[ActionCardData]) -> void:
	for child in _card_container.get_children():
		_card_container.remove_child(child)
		child.queue_free()

	for card in cards:
		var btn := Button.new()
		var name_text := card.display_name
		var display_cost := _get_card_effective_cost(card)
		var cost_text := "(%d)" % display_cost
		btn.text = "%s\n%s" % [name_text, cost_text]
		btn.custom_minimum_size = Vector2(100, 60)
		btn.pressed.connect(func() -> void: _on_card_clicked(card))
		if card.effect == GameEnums.ActionCardEffect.WEAPON_ATTACK and not _is_weapon_attack_available():
			btn.disabled = true
			btn.text = "%s\n[BROKEN]" % name_text
		_card_container.add_child(btn)


func _on_card_clicked(card: ActionCardData) -> void:
	if not _combat_manager.consume_action():
		_log("No actions remaining!")
		return

	_combat_manager.record_card_played(card)

	var actual_cost := _get_card_effective_cost(card)
	if _combat_manager.combat_state.analyze_active:
		actual_cost = maxi(actual_cost - 3, 0)
		_combat_manager.combat_state.set_analyze_active(false)
		_log("Analyze countermeasure: next card cost reduced to %d" % actual_cost)

	# Last effort check for attack cards
	if _combat_manager.is_last_effort_available(actual_cost, card.effect):
		_log("最后一搏！")
		match card.effect:
			GameEnums.ActionCardEffect.UNARMED_ATTACK:
				_combat_manager.execute_last_effort_attack(card.base_value)
				_log_attack_result(card.base_value, "空手攻击（最后一搏）")
			GameEnums.ActionCardEffect.WEAPON_ATTACK:
				if not _is_weapon_attack_available():
					_log("Weapon is broken! Cannot use weapon attack.")
					return
				var dmg := _get_weapon_attack_power()
				_consume_weapon_durability()
				_combat_manager.execute_last_effort_attack(dmg)
				_log_attack_result(dmg, "武器攻击（最后一搏）")
		_update_ui()
		return

	_stamina.deduct(actual_cost)

	match card.effect:
		GameEnums.ActionCardEffect.UNARMED_ATTACK:
			var actual_dmg := _combat_manager.resolve_player_attack(card.base_value)
			_log_attack_result(actual_dmg, "空手攻击")

		GameEnums.ActionCardEffect.WEAPON_ATTACK:
			if not _is_weapon_attack_available():
				_log("Weapon is broken! Cannot use weapon attack.")
				return
			var actual_dmg := _combat_manager.resolve_player_attack(_get_weapon_attack_power())
			_consume_weapon_durability()
			_log_attack_result(actual_dmg, "武器攻击")

		GameEnums.ActionCardEffect.DODGE:
			_combat_manager.combat_state.set_dodge_active(true, 4)
			_log("Dodge active: -4 damage next enemy attack")

		GameEnums.ActionCardEffect.SUMMON_COURAGE:
			_combat_manager.combat_state.set_courage_active(true)
			_log("Courage active: +2 damage to attacks")

		GameEnums.ActionCardEffect.FLEE:
			_combat_manager.flee()
			return

		GameEnums.ActionCardEffect.SEARCH_BACKPACK:
			_log("Opened backpack")
			backpack_open_requested.emit()

		GameEnums.ActionCardEffect.ANALYZE_COUNTERMEASURE:
			_combat_manager.combat_state.set_analyze_active(true)
			_log("Analyze countermeasure active: next card cost -3")

		GameEnums.ActionCardEffect.ADJUST_BREATHING:
			_combat_manager.combat_state.set_extra_action_next_turn(true)
			_log("Adjusted breathing: +1 action next turn")

		_:
			_log("Card effect not implemented in demo")

	_combat_manager.check_defeat_if_no_victory()
	_update_ui()


func _on_end_turn_pressed() -> void:
	_combat_manager.end_player_turn()
	await get_tree().create_timer(0.3).timeout
	_combat_manager.resolve_enemy_turn()


func _on_player_turn_started(_cards: Array[ActionCardData]) -> void:
	_update_card_buttons(_cards)
	_end_turn_button.disabled = false
	_log("--- Your Turn ---")


func _on_enemy_turn_started() -> void:
	for child in _card_container.get_children():
		child.disabled = true
	_end_turn_button.disabled = true
	_log("--- Enemy Turn ---")


func _on_enemy_action_resolved(action: EnemyAction) -> void:
	if action.is_emergency_heal:
		_log("Enemy heals %d HP!" % action.self_heal)
	else:
		var dodge_text := ""
		if _combat_manager.combat_state.dodge_active:
			dodge_text = " (Dodge active)"
		_log("Enemy attacks for %d x%d%s" % [action.damage_to_player, action.attack_count, dodge_text])


func _on_player_took_damage(amount: int, remaining: int) -> void:
	_log("You took %d damage! Stamina: %d" % [amount, remaining])


func _on_enemy_took_damage(amount: int, remaining_hp: int) -> void:
	_log("Dealt %d damage! Enemy HP: %d" % [amount, remaining_hp])


func _on_combat_ended(result: GameEnums.CombatPhase) -> void:
	match result:
		GameEnums.CombatPhase.VICTORY:
			_log("=== VICTORY ===")
		GameEnums.CombatPhase.DEFEAT:
			_log("=== DEFEAT ===")
		GameEnums.CombatPhase.FLED:
			_log("=== FLED ===")
	_end_turn_button.disabled = true
	_update_ui()


func _on_round_started(round_number: int) -> void:
	_round_label.text = "Round: %d" % round_number


func _on_stamina_changed(new_value: int, _old_value: int) -> void:
	_update_stamina_display(new_value)


func _render_pockets() -> void:
	if _backpack_manager == null:
		return
	_render_pocket(_pocket_a_container, _backpack_manager.pocket_a)
	_render_pocket(_pocket_b_container, _backpack_manager.pocket_b)


func _render_pocket(container: Control, grid: BackpackGrid) -> void:
	for child in container.get_children():
		child.queue_free()

	var dims := grid.get_grid_dimensions()
	container.custom_minimum_size = Vector2(dims.x * POCKET_CELL_SIZE, dims.y * POCKET_CELL_SIZE)

	for item in grid.get_items():
		var pos := grid.get_item_position(item)
		if pos.is_empty():
			continue

		var item_dims := item.get_dimensions(pos.rotated)
		var panel := Panel.new()
		panel.position = Vector2(pos.x * POCKET_CELL_SIZE, pos.y * POCKET_CELL_SIZE)
		panel.size = Vector2(item_dims.x * POCKET_CELL_SIZE, item_dims.y * POCKET_CELL_SIZE)
		panel.mouse_filter = Control.MOUSE_FILTER_STOP

		var color: Color = ITEM_COLORS.get(item.item_type, Color(0.5, 0.5, 0.5))
		var style := StyleBoxFlat.new()
		style.bg_color = color
		style.border_color = Color(color.r * 0.7, color.g * 0.7, color.b * 0.7)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		panel.add_theme_stylebox_override("panel", style)

		var label := Label.new()
		label.text = _abbreviate(item.display_name)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.clip_text = true
		label.custom_minimum_size = panel.size
		label.size = panel.size
		label.add_theme_font_size_override("font_size", 10)
		panel.add_child(label)

		panel.tooltip_text = "%s\n%s" % [item.display_name, item.description]
		panel.gui_input.connect(func(event: InputEvent) -> void: _on_pocket_item_clicked(event, item, grid))
		container.add_child(panel)


func _on_pocket_item_clicked(event: InputEvent, item: ItemData, grid: BackpackGrid) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if _combat_manager == null:
		return
	if _combat_manager.combat_state.combat_phase != GameEnums.CombatPhase.PLAYER_TURN:
		return
	if item.item_type != GameEnums.ItemType.CONSUMABLE:
		_log("Only consumables can be used in combat!")
		return
	if not _combat_manager.consume_action():
		_log("No actions remaining!")
		return

	_apply_consumable_effect(item)
	pocket_item_used.emit(item.id)
	grid.remove(item)
	if _backpack_manager != null:
		_backpack_manager.item_removed.emit(item)
	_combat_manager.check_defeat_if_no_victory()
	_update_ui()


func _apply_consumable_effect(item: ItemData) -> void:
	match item.id:
		&"energy_drink":
			_stamina.restore(6)
			_log("Used Energy Drink: restored 6 stamina")
		&"stone":
			_stamina.deduct(2)
			_log("Used Stone: spent 2 stamina to flee")
			_combat_manager.flee()
		&"whetstone":
			_log("Whetstone: weapon repair not yet implemented")
		&"torch":
			var torch_dmg := 20
			if _backpack_manager != null and _backpack_manager.equipped_weapon != null:
				if _backpack_manager.equipped_weapon.get_weapon_trait_id() == &"extinguisher_boost":
					torch_dmg += 10
					_log("Extinguisher boost: torch damage +10")
			if _combat_manager.is_last_effort_torch_available(2):
				_log("最后一搏！")
				_combat_manager.execute_last_effort_torch(torch_dmg)
				_log("Used Torch (last effort): dealt %d damage" % torch_dmg)
			else:
				_stamina.deduct(2)
				_combat_manager.deal_damage_to_enemy(torch_dmg)
				_log("Used Torch: spent 2 stamina, dealt %d damage" % torch_dmg)
		&"flashlight":
			_log("Flashlight cannot be used in combat")
		&"safe_house_key":
			_log("Safe House Key cannot be used in combat")
		_:
			_log("Unknown consumable effect")


func _get_card_effective_cost(card: ActionCardData) -> int:
	var cost := card.stamina_cost
	if card.effect == GameEnums.ActionCardEffect.WEAPON_ATTACK:
		cost += _get_weapon_cost_modifier()
	if _combat_manager != null and _combat_manager.combat_state.trembling_effects.has(card.effect):
		cost += 1
	return cost


func _log_attack_result(damage: int, attack_name: String) -> void:
	if damage == 0 and _combat_manager.combat_state.active_debuffs.has(GameEnums.DebuffType.DELIRIUM):
		_log("%s：谵妄发作，攻击未命中！" % attack_name)
	else:
		_log("%s造成了 %d 点伤害" % [attack_name, damage])
		if _combat_manager.combat_state.active_debuffs.has(GameEnums.DebuffType.MADNESS) and damage > 0:
			_log("癫狂：你因狂怒失去了1点体力")


func _debuff_name(debuff: GameEnums.DebuffType) -> String:
	match debuff:
		GameEnums.DebuffType.COWARDICE:   return "怯懦"
		GameEnums.DebuffType.WEAKNESS:    return "虚弱"
		GameEnums.DebuffType.BLEEDING:    return "出血"
		GameEnums.DebuffType.TREMBLING:   return "颤抖"
		GameEnums.DebuffType.MADNESS:     return "癫狂"
		GameEnums.DebuffType.DELIRIUM:    return "谵妄"
		GameEnums.DebuffType.DESPAIR:     return "绝望"
		GameEnums.DebuffType.DULLNESS:    return "呆滞"
		GameEnums.DebuffType.HESITATION:  return "迟疑"
		_: return "未知"


func _abbreviate(name: String) -> String:
	if name.length() <= 8:
		return name
	return name.substr(0, 7) + "…"
