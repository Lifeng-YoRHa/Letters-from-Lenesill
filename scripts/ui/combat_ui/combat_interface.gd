class_name CombatInterface
extends Control

@export var enemy_hp: int = 14
@export var enemy_attack: int = 4
@export var player_max_stamina: int = 12
@export var weapon_attack_power: int = 7
@export var activated_card_count: int = 3

var _stamina: Stamina
var _combat_manager: CombatManager
var _enemy_data: EnemyData

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


func start() -> void:
	if _combat_manager == null:
		return
	_connect_signals()
	_combat_manager.start_combat()
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
	_combat_manager.initialize(_enemy_data, GameEnums.EnemyType.NORMAL, _stamina, deck, null, null, activated_card_count)


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
	weapon.base_value = weapon_attack_power
	deck.append(weapon)

	var heavy := ActionCardData.new()
	heavy.id = &"heavy_strike"
	heavy.display_name = "Heavy Strike"
	heavy.stamina_cost = 1
	heavy.effect = GameEnums.ActionCardEffect.UNARMED_ATTACK
	heavy.base_value = 4
	deck.append(heavy)

	var quick := ActionCardData.new()
	quick.id = &"quick_jab"
	quick.display_name = "Quick Jab"
	quick.stamina_cost = 1
	quick.effect = GameEnums.ActionCardEffect.UNARMED_ATTACK
	quick.base_value = 2
	deck.append(quick)

	var bash := ActionCardData.new()
	bash.id = &"bash"
	bash.display_name = "Bash"
	bash.stamina_cost = 1
	bash.effect = GameEnums.ActionCardEffect.UNARMED_ATTACK
	bash.base_value = 3
	deck.append(bash)

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

	return deck


func _connect_signals() -> void:
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


func _update_ui() -> void:
	_update_stamina_display(_stamina.current_stamina)
	_update_enemy_hp_display(_combat_manager.combat_state.enemy_current_hp)
	_phase_label.text = _phase_name(_combat_manager.combat_state.combat_phase)
	_weapon_label.text = "Weapon: %d ATK" % weapon_attack_power


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
		var cost_text := "(%d)" % card.stamina_cost
		btn.text = "%s\n%s" % [name_text, cost_text]
		btn.custom_minimum_size = Vector2(100, 60)
		btn.pressed.connect(func() -> void: _on_card_clicked(card))
		_card_container.add_child(btn)


func _on_card_clicked(card: ActionCardData) -> void:
	if not _combat_manager.consume_action():
		_log("No actions remaining!")
		return

	_combat_manager.record_card_played(card)
	_stamina.deduct(card.stamina_cost)

	match card.effect:
		GameEnums.ActionCardEffect.UNARMED_ATTACK:
			var damage := card.base_value
			if _combat_manager.combat_state.courage_active:
				damage += 2
			_combat_manager.deal_damage_to_enemy(damage)

		GameEnums.ActionCardEffect.WEAPON_ATTACK:
			_combat_manager.deal_damage_to_enemy(weapon_attack_power)

		GameEnums.ActionCardEffect.DODGE:
			_combat_manager.combat_state.set_dodge_active(true, 4)
			_log("Dodge active: -4 damage next enemy attack")

		GameEnums.ActionCardEffect.SUMMON_COURAGE:
			_combat_manager.combat_state.set_courage_active(true)
			_log("Courage active: +2 damage to attacks")

		GameEnums.ActionCardEffect.FLEE:
			_combat_manager.flee()
			return

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
