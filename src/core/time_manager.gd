extends Node
# ============================================================
# TimeManager (autoload) — 游戏时钟
# 1 游戏日 = 24 游戏时; 1 游戏时 = real_seconds_per_game_hour 现实秒 (默认 60)
# 1 现实小时 ≈ 2.5 游戏天; 开局 2~3h 现实 = 5~7 游戏天 (逻辑书 A5)
# 升级冷却不走本时钟 (用现实秒, 见 shelter_system.gd)
# ============================================================

const NEW_GAME_START_HOUR := 8.0  # 新开局: 第 1 天 08:00

var game_hours: float = NEW_GAME_START_HOUR


func _process(delta: float) -> void:
	# 倍率从 ConfigManager 实时读取 (Boot 在 autoload _ready 之后才加载配置)
	var rate := ConfigManager.get_engine_real_seconds_per_game_hour()
	game_hours += delta / rate


func new_game() -> void:
	game_hours = NEW_GAME_START_HOUR


func get_game_day() -> int:
	return int(game_hours / 24.0) + 1


func get_hour_of_day() -> float:
	return fposmod(game_hours, 24.0)


# "第1天 08:00"
func get_time_text() -> String:
	var hour := get_hour_of_day()
	return "第%d天 %02d:%02d" % [get_game_day(), int(hour), int(fmod(hour, 1.0) * 60.0)]


func get_state() -> Dictionary:
	return {"game_hours": game_hours}


func set_state(data: Dictionary) -> void:
	game_hours = float(data.get("game_hours", NEW_GAME_START_HOUR))
