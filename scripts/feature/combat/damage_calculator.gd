class_name DamageCalculator
extends RefCounted


func calculate_player_damage(
	base_damage: int,
	combat_state: CombatState,
	enemy_damage_reduction: int = 0,
	relic_damage_bonus: int = 0,
	delirium_triggered: bool = false
) -> int:
	if delirium_triggered and combat_state.active_debuffs.has(GameEnums.DebuffType.DELIRIUM):
		return 0

	var damage := base_damage
	if combat_state.courage_active:
		damage += 2
	damage += relic_damage_bonus

	if combat_state.active_debuffs.has(GameEnums.DebuffType.COWARDICE):
		damage -= 2
	if combat_state.active_debuffs.has(GameEnums.DebuffType.MADNESS):
		damage += 1

	damage -= enemy_damage_reduction
	return maxi(damage, 1)


func calculate_enemy_damage(
	enemy_attack: int,
	combat_state: CombatState,
) -> int:
	var damage := enemy_attack
	if combat_state.active_debuffs.has(GameEnums.DebuffType.WEAKNESS):
		damage += 1
	if combat_state.dodge_active:
		return maxi(damage - combat_state.dodge_reduction, 0)
	return damage


func calculate_last_effort_recovery(berserker_stage: int) -> int:
	return mini(2 + berserker_stage, 4)
