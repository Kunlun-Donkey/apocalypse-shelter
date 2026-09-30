class_name ShelterSystem
extends Node
# ============================================================
# ShelterSystem — 庇护所等级状态与升级 (Dev-S1)
# 升级 = 冷却结束即可升, 校验 requirements_shelter_level; 无资源成本 (S2 引入)
# 每级生效数值 (population_cap 等) 只存储, 消费方后续系统接入
# ============================================================

signal upgrade_started(cooldown_seconds: float)
signal upgrade_completed(new_level: int)
signal level_changed(new_level: int)

# S1 临时常量: 升级只花现实时间冷却, S2 引入资源后废弃
const TEMP_UPGRADE_COOLDOWN_REAL_SECONDS := 30.0

var current_level: int = 1
var upgrading: bool = false
var cooldown_remaining: float = 0.0
var _level_stats: Dictionary = {}


func _ready() -> void:
	set_process(false)
	apply_level(current_level)


func _process(delta: float) -> void:
	if not upgrading:
		return
	cooldown_remaining -= delta
	if cooldown_remaining <= 0.0:
		cooldown_remaining = 0.0
		upgrading = false
		set_process(false)
		current_level += 1
		apply_level(current_level)
		level_changed.emit(current_level)
		upgrade_completed.emit(current_level)


# ---------------- 状态查询 ----------------

func get_level_name(level: int = -1) -> String:
	if level < 0:
		level = current_level
	return str(ConfigManager.get_shelter_level(level).get("name", ""))


func get_max_level() -> int:
	return ConfigManager.get_max_available_level()


func is_max_level() -> bool:
	return current_level >= get_max_level()


# 升到下一级所需前置: requirements_shelter_level
func can_upgrade() -> bool:
	if upgrading or is_max_level():
		return false
	var next_level: Dictionary = ConfigManager.get_shelter_level(current_level + 1)
	return current_level >= int(next_level.get("requirements_shelter_level", 0))


func get_level_stats() -> Dictionary:
	return _level_stats


# ---------------- 升级流程 ----------------

func start_upgrade() -> bool:
	if not can_upgrade():
		return false
	upgrading = true
	cooldown_remaining = TEMP_UPGRADE_COOLDOWN_REAL_SECONDS
	set_process(true)
	upgrade_started.emit(TEMP_UPGRADE_COOLDOWN_REAL_SECONDS)
	return true


func apply_level(level: int) -> void:
	_level_stats = ConfigManager.get_shelter_level(level).duplicate()


# ---------------- 存档 ----------------

func get_state() -> Dictionary:
	return {
		"shelter_level": current_level,
		"upgrading": upgrading,
		"upgrade_cooldown_remaining": cooldown_remaining,
	}


func set_state(data: Dictionary) -> void:
	var level := int(data.get("shelter_level", 1))
	current_level = clampi(level, 1, get_max_level())
	upgrading = bool(data.get("upgrading", false)) and not is_max_level()
	cooldown_remaining = float(data.get("upgrade_cooldown_remaining", 0.0))
	if upgrading and cooldown_remaining <= 0.0:
		upgrading = false
	apply_level(current_level)
	set_process(upgrading)
	level_changed.emit(current_level)


func new_game() -> void:
	set_state({"shelter_level": 1, "upgrading": false, "upgrade_cooldown_remaining": 0.0})
