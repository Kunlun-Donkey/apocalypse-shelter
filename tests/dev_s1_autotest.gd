extends Node
# ============================================================
# Dev-S1 自动验收 (headless):
#   godot --headless --path . res://tests/dev_s1_autotest.tscn
# 覆盖 AGENTS.md §2.5: 配置加载 / Lv1→Lv3 升级链 / 满级禁用 / 存读档一致 /
# NpcSystem 招募三选一 / 被动查询 / 存读档恢复 / 旧档姓名迁移 / NPC_DATA↔CONF 防漂移 /
# OFF 系统零初始化 (resource/quest/trade)。CONFIG ERROR 路径由外部脚本改坏配置验证。
# 断言项数: 49 (原 23 → 49; 新增 26 = NpcSystem 块 21 + 零初始化节点 3 + quest/trade OFF 2;
# 另改 2 = npc 断言翻转 true / 零初始化计数 1→2; resource OFF 断言移入 npc 后三连组)
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
	_check(ConfigManager.is_enabled("npc"), "npc = true (招募提前实施)")
	_check(not ConfigManager.is_enabled("resource"), "resource = false (零初始化)")
	_check(not ConfigManager.is_enabled("quest"), "quest = false (零初始化)")
	_check(not ConfigManager.is_enabled("trade"), "trade = false (零初始化)")
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

	# ---- NpcSystem (与 Boot 相同的初始化方式): 招募三选一 / 被动 / 存读档 ----
	var npc_sys := NpcSystem.new()
	npc_sys.name = "NpcSystem"
	get_tree().root.add_child.call_deferred(npc_sys)
	await get_tree().process_frame
	_check(npc_sys.get_picked_id() == "", "NpcSystem 开局未招募")
	_check(npc_sys.recruit("npc.veteran_01"), "recruit(npc.veteran_01) 成功")
	_check(
		npc_sys.get_picked_id() == "npc.veteran_01"
		and npc_sys.get_picked_name() == "唐文轩"
		and npc_sys.is_recruited("npc.veteran_01"),
		"招募后 picked = npc.veteran_01 (唐文轩) 且 is_recruited"
	)
	_check(absf(npc_sys.get_passive_bonus("food_gain_bonus_percent") - 20.0) < 0.001, "被动 food_gain_bonus_percent = 20")
	_check(not npc_sys.recruit("npc.medic_01"), "三选一锁定: 第二次 recruit 拒绝")

	# 存读档恢复 id (槽 3 用完即 erase)
	_check(SaveManager.save_game(3, {"npc": npc_sys.get_state()}) == OK, "保存 npc 状态到槽 3")
	npc_sys.new_game()
	_check(npc_sys.get_picked_id() == "", "new_game 复位 → picked 空")
	var npc_save: Dictionary = SaveManager.load_game(3)
	npc_sys.set_state(npc_save.get("npc", {}))
	_check(npc_sys.get_picked_id() == "npc.veteran_01", "读档恢复 picked = npc.veteran_01")
	SaveManager.erase_slot(3)

	# 旧档姓名兼容: {"picked": "张睿"} → npc.medic_01
	npc_sys.set_state({"picked": "张睿"})
	_check(
		npc_sys.get_picked_id() == "npc.medic_01" and npc_sys.get_picked_name() == "张睿",
		"旧档姓名映射 张睿 → npc.medic_01"
	)
	npc_sys.new_game()

	# NPC_DATA ↔ CONF 一致性 (防 UI 字典与配置漂移)
	for entry: Dictionary in BtnRecruit.NPC_DATA:
		var entry_id: String = str(entry.get("id", ""))
		var entry_name: String = str(entry.get("name", ""))
		_check(ConfigManager.has_npc(entry_id), "NPC_DATA↔CONF has_npc(%s)" % entry_id)
		var conf: Dictionary = ConfigManager.get_npc(entry_id)
		_check(str(conf.get("name", "")) == entry_name, "NPC_DATA↔CONF %s name = %s" % [entry_id, entry_name])
		var attrs: Array = entry.get("attrs", [])
		_check(
			int(conf.get("attr_stamina", -1)) == int(attrs[0][1])
			and int(conf.get("attr_survival", -1)) == int(attrs[1][1])
			and int(conf.get("attr_wisdom", -1)) == int(attrs[2][1]),
			"NPC_DATA↔CONF %s (%s) 体力/生存/智慧 一致" % [entry_id, entry_name]
		)

	# starter_npcs 全员存在且可招募
	for starter_id in ConfigManager.get_starter_npcs():
		var sid: String = str(starter_id)
		var starter: Dictionary = ConfigManager.get_npc(sid)
		_check(
			ConfigManager.has_npc(sid) and bool(starter.get("recruit_allowed", false)),
			"starter_npcs %s has_npc 且 recruit_allowed = true" % sid
		)

	# ---- 零初始化验证: 根节点只挂了 ShelterSystem + NpcSystem 两个系统 ----
	var system_nodes := 0
	for child in get_tree().root.get_children():
		if child.name == "ShelterSystem" or child.name == "NpcSystem":
			system_nodes += 1
	_check(system_nodes == 2, "仅 ShelterSystem + NpcSystem 被初始化")
	_check(get_tree().root.get_node_or_null("ResourceSystem") == null, "ResourceSystem 未挂载 (零初始化)")
	_check(get_tree().root.get_node_or_null("QuestSystem") == null, "QuestSystem 未挂载 (零初始化)")
	_check(get_tree().root.get_node_or_null("TradeSystem") == null, "TradeSystem 未挂载 (零初始化)")

	if _failed:
		printerr("DEV-S1 AUTOTEST: FAILED")
		get_tree().quit(1)
	else:
		print("DEV-S1 AUTOTEST: ALL PASSED")
		get_tree().quit(0)
