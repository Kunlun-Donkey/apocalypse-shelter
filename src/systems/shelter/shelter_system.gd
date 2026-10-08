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
signal hp_changed(current: int, maximum: int)

# S1 临时常量: 升级只花现实时间冷却, S2 引入资源后废弃
const TEMP_UPGRADE_COOLDOWN_REAL_SECONDS := 30.0

var current_level: int = 1
var upgrading: bool = false
var cooldown_remaining: float = 0.0
var current_hp: int = -1  # -1 = 未初始化哨兵 (真 0 血是合法状态), apply_level 时置为 hp_max
var _level_stats: Dictionary = {}


func _ready() -> void:
	set_process(false)
	apply_level(current_level)
	if not TimeManager.game_hour_elapsed.is_connected(_on_game_hour_elapsed):
		TimeManager.game_hour_elapsed.connect(_on_game_hour_elapsed)


func _process(delta: float) -> void:
	if not upgrading:
		return
	cooldown_remaining -= delta
	if cooldown_remaining <= 0.0:
		cooldown_remaining = 0.0
		upgrading = false
		set_process(false)
		var old_max: int = get_hp_max()
		current_level += 1
		apply_level(current_level)
		# 升级 = 新增结构满血并入, 已损部分保留
		var delta_hp: int = get_hp_max() - old_max
		if delta_hp > 0:
			current_hp = mini(current_hp + delta_hp, get_hp_max())
			hp_changed.emit(current_hp, get_hp_max())
		level_changed.emit(current_level)
		upgrade_completed.emit(current_level)


# 每游戏小时回血 (TimeManager.game_hour_elapsed)
func _on_game_hour_elapsed(_hour_index: int) -> void:
	if current_hp < get_hp_max():
		current_hp = mini(current_hp + get_recovery(), get_hp_max())
		hp_changed.emit(current_hp, get_hp_max())


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


func get_hp_max() -> int:
	return int(_level_stats.get("hp_max", 0))


func get_attack_base() -> int:
	return int(_level_stats.get("attack", 0))


# 建筑加成聚合入口 (S2/S3 建筑系统接入: 箭塔/炮塔→攻击), 本期恒 0
func get_building_attack_bonus() -> int:
	return 0


func get_attack() -> int:
	return get_attack_base() + get_building_attack_bonus()


func get_defense_base() -> int:
	return int(_level_stats.get("defense", 0))


# 建筑加成聚合入口 (S2/S3 建筑系统接入: 围栏/墙→防御), 本期恒 0
func get_building_defense_bonus() -> int:
	return 0


func get_defense() -> int:
	return get_defense_base() + get_building_defense_bonus()


func get_recovery() -> int:
	return int(_level_stats.get("recovery", 0))


func apply_damage(amount: int) -> void:
	if amount <= 0:
		return
	current_hp = clampi(current_hp - amount, 0, get_hp_max())
	hp_changed.emit(current_hp, get_hp_max())


func heal(amount: int) -> void:
	if amount <= 0:
		return
	current_hp = clampi(current_hp + amount, 0, get_hp_max())
	hp_changed.emit(current_hp, get_hp_max())


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
	if current_hp < 0:
		current_hp = get_hp_max()


# ---------------- 存档 ----------------

func get_state() -> Dictionary:
	return {
		"shelter_level": current_level,
		"upgrading": upgrading,
		"upgrade_cooldown_remaining": cooldown_remaining,
		"current_hp": current_hp,
	}


func set_state(data: Dictionary) -> void:
	var level := int(data.get("shelter_level", 1))
	current_level = clampi(level, 1, get_max_level())
	upgrading = bool(data.get("upgrading", false)) and not is_max_level()
	cooldown_remaining = float(data.get("upgrade_cooldown_remaining", 0.0))
	if upgrading and cooldown_remaining <= 0.0:
		upgrading = false
	current_hp = -1  # 让 apply_level 按新等级 hp_max 初始化
	apply_level(current_level)
	if data.has("current_hp"):
		current_hp = clampi(int(data.get("current_hp", 0)), 0, get_hp_max())
	set_process(upgrading)
	level_changed.emit(current_level)
	hp_changed.emit(current_hp, get_hp_max())


func new_game() -> void:
	set_state({"shelter_level": 1, "upgrading": false, "upgrade_cooldown_remaining": 0.0})
