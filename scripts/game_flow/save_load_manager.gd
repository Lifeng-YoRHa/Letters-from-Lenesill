class_name SaveLoadManager
extends RefCounted

signal save_completed(slot_index: int)
signal load_completed(slot_index: int)
signal save_failed(slot_index: int, error_message: String)
signal load_failed(slot_index: int, error_message: String)

const SAVE_VERSION: int = 1
const SAVE_SLOT_COUNT: int = 3
const SAVE_DEBOUNCE_MS: int = 500
const SAVE_MAX_SIZE_BYTES: int = 1048576

var _pending_save_timer: SceneTreeTimer = null


func get_save_path(slot_index: int) -> String:
	return "user://save_slot_%d.dat" % slot_index


func get_temp_path(slot_index: int) -> String:
	return "user://save_slot_%d.tmp" % slot_index


func save_slot(slot_index: int, adventure_state: AdventureStateResource, meta_state: MetaStateResource) -> bool:
	if slot_index < 0 or slot_index >= SAVE_SLOT_COUNT:
		save_failed.emit(slot_index, "Invalid slot index.")
		return false

	var slot := SaveSlotResource.new()
	slot.version = SAVE_VERSION
	slot.last_saved_at = int(Time.get_unix_time_from_system())
	slot.adventure_layer = adventure_state
	slot.meta_layer = meta_state
	slot.checksum = _calculate_checksum(adventure_state, meta_state)

	var bytes := var_to_bytes(slot)
	if bytes.size() > SAVE_MAX_SIZE_BYTES:
		save_failed.emit(slot_index, "Save file exceeds maximum size.")
		return false

	var temp_path := get_temp_path(slot_index)
	var final_path := get_save_path(slot_index)

	var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		save_failed.emit(slot_index, "Failed to open temp file: %s" % FileAccess.get_open_error())
		return false

	file.store_buffer(bytes)
	file.close()

	var rename_ok := DirAccess.rename_absolute(temp_path, final_path)
	if rename_ok != OK:
		save_failed.emit(slot_index, "Failed to finalize save file.")
		return false

	save_completed.emit(slot_index)
	return true


func load_slot(slot_index: int) -> SaveSlotResource:
	if slot_index < 0 or slot_index >= SAVE_SLOT_COUNT:
		load_failed.emit(slot_index, "Invalid slot index.")
		return null

	var path := get_save_path(slot_index)
	if not FileAccess.file_exists(path):
		load_failed.emit(slot_index, "Save file does not exist.")
		return null

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		load_failed.emit(slot_index, "Failed to open save file: %s" % FileAccess.get_open_error())
		return null

	var bytes: PackedByteArray = file.get_buffer(file.get_length())
	file.close()

	var variant: Variant = bytes_to_var(bytes)
	if not variant is SaveSlotResource:
		load_failed.emit(slot_index, "Invalid save file format.")
		return null

	var slot := variant as SaveSlotResource
	if slot.version != SAVE_VERSION:
		load_failed.emit(slot_index, "Save version mismatch: expected %d, got %d." % [SAVE_VERSION, slot.version])
		return null

	var expected_checksum := _calculate_checksum(slot.adventure_layer, slot.meta_layer)
	if slot.checksum != expected_checksum:
		load_failed.emit(slot_index, "Checksum mismatch. Save file may be corrupted.")
		return null

	load_completed.emit(slot_index)
	return slot


func has_save(slot_index: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot_index))


func delete_slot(slot_index: int) -> bool:
	var path := get_save_path(slot_index)
	if FileAccess.file_exists(path):
		return DirAccess.remove_absolute(path) == OK
	return true


func get_all_slot_status() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in range(SAVE_SLOT_COUNT):
		var has := has_save(i)
		var info := {"index": i, "has_save": has}
		if has:
			var slot := load_slot(i)
			if slot != null:
				info["last_saved_at"] = slot.last_saved_at
				info["has_adventure"] = slot.adventure_layer != null
		result.append(info)
	return result


func request_auto_save(slot_index: int, adventure_state: AdventureStateResource, meta_state: MetaStateResource) -> void:
	if _pending_save_timer != null:
		_pending_save_timer.timeout.disconnect(_on_auto_save_timeout)

	var tree := Engine.get_main_loop()
	if tree is SceneTree:
		_pending_save_timer = tree.create_timer(SAVE_DEBOUNCE_MS / 1000.0)
		_pending_save_timer.timeout.connect(func() -> void:
			save_slot(slot_index, adventure_state, meta_state)
		)


func _on_auto_save_timeout() -> void:
	_pending_save_timer = null


func _calculate_checksum(adventure_state: AdventureStateResource, meta_state: MetaStateResource) -> int:
	var adv_bytes := var_to_bytes(adventure_state) if adventure_state != null else PackedByteArray()
	var meta_bytes := var_to_bytes(meta_state) if meta_state != null else PackedByteArray()
	var adv_hash := _hash_bytes(adv_bytes)
	var meta_hash := _hash_bytes(meta_bytes)
	return (adv_hash ^ meta_hash) & 0x7FFFFFFF


func _hash_bytes(data: PackedByteArray) -> int:
	var hash := 0
	for b in data:
		hash = ((hash << 5) - hash + b) & 0x7FFFFFFF
	return hash
