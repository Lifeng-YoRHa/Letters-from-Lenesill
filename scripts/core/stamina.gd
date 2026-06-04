class_name Stamina
extends RefCounted

signal stamina_changed(new_value: int, old_value: int)
signal max_stamina_changed(new_value: int, old_value: int)
signal stamina_depleted(current_value: int)

var current_stamina: int:
	get:
		return _current_stamina

var max_stamina: int:
	get:
		return _max_stamina

var _current_stamina: int = 0
var _max_stamina: int = 0


func initialize(starting_max: int) -> void:
	var old_max: int = _max_stamina
	_max_stamina = starting_max
	_current_stamina = starting_max
	max_stamina_changed.emit(_max_stamina, old_max)
	stamina_changed.emit(_current_stamina, 0)


func deduct(amount: int) -> int:
	if amount <= 0:
		return _current_stamina
	var old: int = _current_stamina
	_current_stamina -= amount
	stamina_changed.emit(_current_stamina, old)
	if _current_stamina <= 0:
		stamina_depleted.emit(_current_stamina)
	return _current_stamina


func restore(amount: int) -> int:
	if amount <= 0:
		return _current_stamina
	var old: int = _current_stamina
	_current_stamina = mini(_current_stamina + amount, _max_stamina)
	stamina_changed.emit(_current_stamina, old)
	return _current_stamina


func set_max_stamina(new_max: int) -> void:
	if new_max <= 0:
		return
	var old_max: int = _max_stamina
	_max_stamina = new_max
	max_stamina_changed.emit(_max_stamina, old_max)
	if _current_stamina > _max_stamina:
		var old: int = _current_stamina
		_current_stamina = _max_stamina
		stamina_changed.emit(_current_stamina, old)


func increase_max(amount: int) -> void:
	if amount <= 0:
		return
	set_max_stamina(_max_stamina + amount)
	restore(amount)
