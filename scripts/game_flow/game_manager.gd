class_name GameManager
extends Node

enum GameState {
	MAIN_MENU,
	MAP_EXPLORATION,
	COMBAT,
	SHOP,
	EVENT,
	SAFE_HOUSE,
	CHAPTER_TRANSITION,
	ENDING,
}

signal state_changed(new_state: int, old_state: int)
signal chapter_started(chapter: int)
signal adventure_started()
signal adventure_ended(ending_type: StringName)
signal combat_prepared(combat_manager: CombatManager)


# === Public references (for UI layer access) ===
var rng: RandomNumberGenerator
var map_generator: MapGenerator
var map_state: MapState
var path_finder: PathFinder
var node_manager: NodeManager
var node_interaction_manager: NodeInteractionManager
var backpack_manager: BackpackManager
var relic_handler: RelicHandler
var shop_manager: ShopManager
var event_manager: EventManager
var quest_manager: QuestManager
var survivor_notes: SurvivorNotes
var save_load_manager: SaveLoadManager
var ending_manager: EndingManager

# === Adventure runtime state ===
var current_state: int = GameState.MAIN_MENU
var current_chapter: int = 1
var current_combat_manager: CombatManager = null
var current_combat_node_id: StringName = &""
var current_stamina: Stamina
var non_road_nodes_visited: int = 0


func _ready() -> void:
	_initialize_systems()
	_connect_signals()


func _initialize_systems() -> void:
	rng = RandomNumberGenerator.new()

	# Meta progression
	survivor_notes = SurvivorNotes.new()
	survivor_notes.initialize()

	# Save/Load
	save_load_manager = SaveLoadManager.new()

	# Map system
	map_generator = MapGenerator.new()
	map_generator.initialize(rng)
	map_state = MapState.new()
	path_finder = PathFinder.new()

	# Backpack & Relics
	backpack_manager = BackpackManager.new()
	backpack_manager.initialize()
	relic_handler = RelicHandler.new()
	relic_handler.initialize()

	# Node traversal & interaction
	node_manager = NodeManager.new()
	node_interaction_manager = NodeInteractionManager.new()

	# Events, Quests, Shop
	event_manager = EventManager.new()
	event_manager.initialize(rng, backpack_manager, relic_handler)
	quest_manager = QuestManager.new()
	quest_manager.initialize(rng, map_state, backpack_manager, survivor_notes, relic_handler)
	shop_manager = ShopManager.new()
	shop_manager.initialize(rng, relic_handler, backpack_manager)

	# Ending
	ending_manager = EndingManager.new()
	ending_manager.initialize(quest_manager, survivor_notes)


func _connect_signals() -> void:
	# Node traversal
	node_manager.player_moved.connect(_on_player_moved)
	node_manager.node_visited.connect(_on_node_visited)
	node_manager.node_cleared.connect(_on_node_cleared)

	# Node interaction routing
	node_interaction_manager.combat_triggered.connect(_on_combat_triggered)
	node_interaction_manager.boss_combat_triggered.connect(_on_boss_combat_triggered)
	node_interaction_manager.shop_opened.connect(_on_shop_opened)
	node_interaction_manager.safe_house_opened.connect(_on_safe_house_opened)
	node_interaction_manager.event_triggered.connect(_on_event_triggered)
	node_interaction_manager.ruins_searched.connect(_on_ruins_searched)
	node_interaction_manager.quest_triggered.connect(_on_quest_triggered)

	# Event outcomes
	event_manager.teleport_requested.connect(_on_teleport_requested)
	# TODO: connect event_manager.combat_triggered for event-driven combat
	# TODO: connect event_manager.stamina_changed for stamina restore events
	# TODO: connect event_manager.locked_box_granted for UI notification

	# Ending
	ending_manager.false_ending_triggered.connect(_on_false_ending)
	ending_manager.true_ending_triggered.connect(_on_true_ending)
	ending_manager.run_completed.connect(_on_run_completed)


# === Public API ===

func start_new_adventure() -> void:
	current_chapter = 1
	non_road_nodes_visited = 0
	adventure_started.emit()
	_setup_chapter(current_chapter)
	_change_state(GameState.MAP_EXPLORATION)


func _setup_chapter(chapter: int) -> void:
	current_chapter = chapter

	# Generate map
	var nodes := map_generator.generate(chapter)
	map_state.initialize_from_graph(nodes, &"START")
	path_finder.initialize(map_state)

	# Create stamina for this chapter
	var stamina := _create_stamina()
	current_stamina = stamina
	node_manager.initialize(map_state, path_finder, stamina)
	node_interaction_manager.initialize(map_state, node_manager)

	# Chapter-specific setup
	quest_manager.start_chapter_quest(chapter, &"QUEST")
	shop_manager.generate_stock(chapter)

	# Relic chapter-start effects
	var granted_relics := relic_handler.on_chapter_start()
	for relic in granted_relics:
		if relic != null:
			# TODO: add relic to backpack / relic handler
			pass

	chapter_started.emit(chapter)


func _create_stamina() -> Stamina:
	var stamina := Stamina.new()
	var max_stamina := 12 + relic_handler.get_max_stamina_bonus() + survivor_notes.get_max_stamina_bonus()
	stamina.initialize(max_stamina)
	return stamina


func return_to_exploration() -> void:
	_change_state(GameState.MAP_EXPLORATION)


func _change_state(new_state: int) -> void:
	var old_state := current_state
	current_state = new_state
	state_changed.emit(new_state, old_state)


# === Signal Handlers: Node Traversal ===

func _on_player_moved(_to_node_id: StringName, _stamina_cost: int) -> void:
	# TODO: trigger auto-save via save_load_manager.request_auto_save()
	pass


func _on_node_visited(node_id: StringName, node_type: GameEnums.MapNodeType) -> void:
	# Route to interaction system
	node_interaction_manager.process_node_arrival(node_id)

	# Survivor Notes: Wayfarer & Pathfinder
	if node_type != GameEnums.MapNodeType.ROAD and node_type != GameEnums.MapNodeType.START:
		non_road_nodes_visited += 1
		survivor_notes.add_progress(&"wayfarer", 1)
		if non_road_nodes_visited >= 75:
			# Pathfinder is "single run" threshold; add_progress handles duplicate calls safely
			survivor_notes.add_progress(&"pathfinder", non_road_nodes_visited)


func _on_node_cleared(node_id: StringName) -> void:
	# TODO: check if chapter boss defeated -> ending_manager.check_chapter4_boss_outcome()
	# TODO: request auto-save
	pass


# === Signal Handlers: Node Interaction ===

func _on_combat_triggered(node_id: StringName, enemy_type: GameEnums.EnemyType) -> void:
	current_combat_node_id = node_id
	var enemy := _get_enemy_data(enemy_type)
	var deck := _create_default_deck()
	current_combat_manager = CombatManager.new()
	current_combat_manager.initialize(enemy, enemy_type, current_stamina, deck, null, null, 3, rng)
	current_combat_manager.card_played.connect(_on_card_played)
	current_combat_manager.combat_ended.connect(_on_combat_ended)
	combat_prepared.emit(current_combat_manager)
	_change_state(GameState.COMBAT)


func _on_boss_combat_triggered(node_id: StringName, boss_data: EnemyData) -> void:
	current_combat_node_id = node_id
	var enemy := boss_data if boss_data != null else _get_enemy_data(GameEnums.EnemyType.BOSS)
	var deck := _create_default_deck()
	current_combat_manager = CombatManager.new()
	current_combat_manager.initialize(enemy, GameEnums.EnemyType.BOSS, current_stamina, deck, null, null, 3, rng)
	current_combat_manager.card_played.connect(_on_card_played)
	current_combat_manager.combat_ended.connect(_on_combat_ended)
	combat_prepared.emit(current_combat_manager)
	_change_state(GameState.COMBAT)


func _on_shop_opened(node_id: StringName) -> void:
	_change_state(GameState.SHOP)

	var has_quest := quest_manager.get_quest_state() == QuestManager.QuestState.ACCEPTED
	var lost_letter_location := quest_manager.get_lost_letter_location()
	var has_lost_letter_here := has_quest and lost_letter_location == node_id

	shop_manager.generate_stock(current_chapter, has_lost_letter_here, 5)
	# TODO: open shop UI overlay


func _on_safe_house_opened(node_id: StringName) -> void:
	_change_state(GameState.SAFE_HOUSE)
	quest_manager.on_safe_house_entered(node_id)
	survivor_notes.add_progress(&"scholar", 1)
	# TODO: apply stamina recovery, open safe house UI


func _on_event_triggered(node_id: StringName, _event_type: StringName) -> void:
	_change_state(GameState.EVENT)
	var event_type := event_manager.pick_event_type(current_chapter)
	var outcome := event_manager.resolve_event(event_type, current_chapter)
	# TODO: route outcome to event UI overlay
	# TODO: if outcome has "choices", present them to player and call resolve_*_choice()
	outcome  # suppress unused warning


func _on_ruins_searched(node_id: StringName, search_count: int) -> void:
	node_interaction_manager.record_ruins_search(node_id)
	survivor_notes.add_progress(&"scavenger", 1)
	if search_count >= 1:
		# TODO: second search triggers loot roll from EventManager / loot system
		pass


func _on_quest_triggered(_node_id: StringName, _quest_state: int) -> void:
	quest_manager.accept_quest()


# === Signal Handlers: Event Outcomes ===

func _on_teleport_requested(target_node_id: StringName) -> void:
	# TODO: validate target is reachable / non-boss, then move player
	# node_manager.move_to(target_node_id)
	target_node_id  # suppress unused warning


# === Signal Handlers: Combat (TODO) ===

func _create_default_deck() -> Array[ActionCardData]:
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
	weapon.base_value = 7
	deck.append(weapon)

	var heavy := ActionCardData.new()
	heavy.id = &"heavy_strike"
	heavy.display_name = "Heavy Strike"
	heavy.stamina_cost = 1
	heavy.effect = GameEnums.ActionCardEffect.UNARMED_ATTACK
	heavy.base_value = 4
	deck.append(heavy)

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


func _get_enemy_data(enemy_type: GameEnums.EnemyType) -> EnemyData:
	var enemy := EnemyData.new()
	match enemy_type:
		GameEnums.EnemyType.NORMAL:
			enemy.id = &"normal_enemy"
			enemy.display_name = "Normal Enemy"
			enemy.base_hp = 14
			enemy.base_attack = 4
		GameEnums.EnemyType.HARD:
			enemy.id = &"hard_enemy"
			enemy.display_name = "Hard Enemy"
			enemy.base_hp = 20
			enemy.base_attack = 6
		GameEnums.EnemyType.BOSS:
			enemy.id = &"boss_enemy"
			enemy.display_name = "Boss"
			enemy.base_hp = 50
			enemy.base_attack = 10
	enemy.enemy_type = enemy_type
	return enemy


func _on_combat_ended(result: GameEnums.CombatPhase) -> void:
	current_combat_manager = null
	_change_state(GameState.MAP_EXPLORATION)

	match result:
		GameEnums.CombatPhase.VICTORY:
			quest_manager.on_combat_victory(current_combat_node_id)
			node_interaction_manager.mark_node_cleared(current_combat_node_id)
			# TODO: grant loot, check chapter boss ending
		GameEnums.CombatPhase.DEFEAT:
			# TODO: check RelicHandler.on_death_save(), if still dead handle game over
			pass
		GameEnums.CombatPhase.FLED:
			node_interaction_manager.mark_node_cleared(current_combat_node_id)


func _on_card_played(card: ActionCardData) -> void:
	match card.effect:
		GameEnums.ActionCardEffect.DODGE:
			survivor_notes.add_progress(&"sports_enthusiast", 1)
		GameEnums.ActionCardEffect.UNARMED_ATTACK, \
		GameEnums.ActionCardEffect.WEAPON_ATTACK, \
		GameEnums.ActionCardEffect.SUMMON_COURAGE:
			survivor_notes.add_progress(&"improviser", 1)
		_:
			pass


# === Signal Handlers: Ending ===

func _on_false_ending(_stats: EndingManager.AdventureStats) -> void:
	_change_state(GameState.ENDING)
	# TODO: show false ending UI, then return to main menu


func _on_true_ending(_stats: EndingManager.AdventureStats) -> void:
	_change_state(GameState.ENDING)
	# TODO: show true ending UI, then return to main menu


func _on_run_completed(ending_type: StringName, _stats: EndingManager.AdventureStats) -> void:
	adventure_ended.emit(ending_type)
	# TODO: commit meta progression (SurvivorNotes, unlocked endings, difficulty)
	# TODO: return to main menu
