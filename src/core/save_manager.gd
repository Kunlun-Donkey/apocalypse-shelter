extends Node
# ============================================================
# SaveManager (autoload) — 存读档 (JSON, user://save_slot_N.json)
# GameState 序列化: shelter 等级/升级冷却 + 游戏时刻, 3 槽 (system.conf save_slots)
# 存档路径: Windows %APPDATA%/Godot/app_userdata/..., Linux ~/.local/share/...
# ============================================================

const SAVE_VERSION := 1


func _slot_path(slot: int) -> String:
	return "user://save_slot_%d.json" % slot


func get_slot_count() -> int:
	return ConfigManager.get_engine_save_slots()


func is_slot_valid(slot: int) -> bool:
	return slot >= 1 and slot <= get_slot_count()


func has_save(slot: int) -> bool:
	return is_slot_valid(slot) and FileAccess.file_exists(_slot_path(slot))


func save_game(slot: int, data: Dictionary) -> Error:
	if not is_slot_valid(slot):
		return ERR_INVALID_PARAMETER
	data["save_version"] = SAVE_VERSION
	data["saved_at"] = Time.get_datetime_string_from_system()
	var file := FileAccess.open(_slot_path(slot), FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	return OK


# 读档成功返回数据字典; 空槽/损坏返回 {}
func load_game(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}
	var file := FileAccess.open(_slot_path(slot), FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return {}
	var data: Dictionary = parsed
	if int(data.get("save_version", -1)) != SAVE_VERSION:
		push_warning("SaveManager: save_version mismatch in slot %d, ignored" % slot)
		return {}
	return data


func erase_slot(slot: int) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_slot_path(slot)))
