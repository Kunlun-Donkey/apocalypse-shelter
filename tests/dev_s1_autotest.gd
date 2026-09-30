extends Node
# ============================================================
# Dev-S1 自动验收 (headless):
#   godot --headless --path . res://tests/dev_s1_autotest.tscn
# 覆盖 AGENTS.md §2.5: 配置加载 / Lv1→Lv3 升级链 / 满级禁用 /
# 存读档一致 / OFF 系统零初始化。CONFIG ERROR 路径由外部脚本改坏配置验证。
# ============================================================

var _failed := false


func _ready() -> void:
	_run()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		_failed = true
		printerr("FAIL: " + label)


func _run() -> void:
	# ---- 配置加载 ----
	var err := ConfigManager.load_all()
	_check(err == OK, "ConfigManager.load_all OK")
	if err != OK:
		printerr("CONFIG ERROR: " + ConfigManager.get_error_message())
		get_tree().quit(1)
		return

	_check(ConfigManager.is_enabled("shelter"), "shelter = true")
	_check(not ConfigManager.is_enabled("resource"), "resource = false (零初始化)")
	_check(not ConfigManager.is_enabled("npc"), "npc = false (零初始化)")
	_check(ConfigManager.get_max_available_level() == 3, "MVP 等级表 1..3")
	_check(
		ConfigManager.parse_list("[a.b, c.d]") == ["a.b", "c.d"],
		"parse_list [a.b, c.d]"
	)
	_check(ConfigManager.parse_id_level("building.generator:2") == {"id": "building.generator", "level": 2}, "parse_id_level")
	_check(ConfigManager.parse_range("10~30") == {"min": 10.0, "max": 30.0}, "parse_range 10~30")

	# ---- ShelterSystem (与 Boot 相同的初始化方式) ----
	var shelter := ShelterSystem.new()
	shelter.name = "ShelterSystem"
	get_tree().root.add_child.call_deferred(shelter)
	await get_tree().process_frame
	_check(shelter.current_level == 1 and shelter.get_level_name() == "小木屋", "开局 Lv1 小木屋")
	_check(shelter.can_upgrade(), "Lv1 可升级")

	# ---- 升级链 Lv1 → Lv2 (30 秒冷却) ----
	_check(shelter.start_upgrade(), "发起升级 Lv1→Lv2")
	await get_tree().create_timer(ShelterSystem.TEMP_UPGRADE_COOLDOWN_REAL_SECONDS + 1.0).timeout
	_check(shelter.current_level == 2 and shelter.get_level_name() == "加固木屋", "冷却结束 → Lv2 加固木屋")

	# ---- Lv2 → Lv3 ----
	_check(shelter.start_upgrade(), "发起升级 Lv2→Lv3")
	await get_tree().create_timer(ShelterSystem.TEMP_UPGRADE_COOLDOWN_REAL_SECONDS + 1.0).timeout
	_check(shelter.current_level == 3 and shelter.get_level_name() == "修补营地", "冷却结束 → Lv3 修补营地")

	# ---- 满级禁用 ----
	_check(shelter.is_max_level(), "Lv3 = MVP 满级")
	_check(not shelter.can_upgrade(), "满级后 can_upgrade = false")
	_check(not shelter.start_upgrade(), "满级后 start_upgrade 拒绝")

	# ---- 存读档一致性 ----
	var time_before: float = TimeManager.game_hours
	var slot := 3
	_check(SaveManager.save_game(slot, {"shelter": shelter.get_state(), "time": TimeManager.get_state()}) == OK, "保存存档槽 3")
	shelter.new_game()
	TimeManager.new_game()
	_check(shelter.current_level == 1, "重开新档 → Lv1")
	var data := SaveManager.load_game(slot)
	_check(not data.is_empty(), "读档非空")
	shelter.set_state(data.get("shelter", {}))
	TimeManager.set_state(data.get("time", {}))
	_check(shelter.current_level == 3 and not shelter.upgrading, "读档恢复 Lv3 状态")
	_check(absf(TimeManager.game_hours - time_before) < 0.01, "读档恢复游戏时刻")
	SaveManager.erase_slot(slot)

	# ---- 零初始化验证: 根节点只挂了 ShelterSystem 一个系统 ----
	var system_nodes := 0
	for child in get_tree().root.get_children():
		if child.name == "ShelterSystem":
			system_nodes += 1
	_check(system_nodes == 1, "仅 ShelterSystem 被初始化")

	if _failed:
		printerr("DEV-S1 AUTOTEST: FAILED")
		get_tree().quit(1)
	else:
		print("DEV-S1 AUTOTEST: ALL PASSED")
		get_tree().quit(0)
