extends Node
# ============================================================
# Boot — 启动流 (AGENTS.md §12.2 / SPEC PART T)
# ConfigManager 加载+校验 → 按开关初始化 System (禁用系统零初始化)
# → 进登录界面 (新游戏/读档) → Main
# ============================================================


func _ready() -> void:
	var err := ConfigManager.load_all()
	if err != OK:
		printerr("CONFIG ERROR: " + ConfigManager.get_error_message())
		get_tree().quit(1)
		return

	# 按开关初始化 System。S1 仅 shelter 开启; 其余 OFF 系统一律不创建。
	if ConfigManager.is_enabled("shelter"):
		var shelter := ShelterSystem.new()
		shelter.name = "ShelterSystem"
		get_tree().root.add_child.call_deferred(shelter)
	else:
		printerr("CONFIG ERROR: Dev-S1 requires system.conf shelter = true")
		get_tree().quit(1)
		return

	print("BOOT OK: enabled systems = %s" % [ConfigManager.get_enabled_systems()])
	get_tree().change_scene_to_file.call_deferred("res://src/scenes/login.tscn")
