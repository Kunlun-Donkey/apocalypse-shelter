extends Node
# ============================================================
# 登录界面跳转验证 (headless):
#   godot --headless --path . res://tests/dev_s1_navtest.tscn
# 覆盖: "开始新游戏"按钮 → 切换到 Main 场景 + 状态重置 (Lv1 / 第1天08:00)
#       + 顶部资源条 ResourceBar (wood/steel/food/water = 初始资源/库存上限)
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


func _find_by_name(node: Node, target: String) -> Node:
	if node.name == target:
		return node
	for child in node.get_children():
		var found := _find_by_name(child, target)
		if found != null:
			return found
	return null


func _run() -> void:
	await get_tree().process_frame
	# 自己脱离 current_scene, 防止 change_scene 时被一并释放
	get_tree().current_scene = null

	var err := ConfigManager.load_all()
	_check(err == OK, "配置加载 OK")
	if err != OK:
		printerr("CONFIG ERROR: " + ConfigManager.get_error_message())
		get_tree().quit(1)
		return

	var shelter := ShelterSystem.new()
	shelter.name = "ShelterSystem"
	get_tree().root.add_child.call_deferred(shelter)
	await get_tree().process_frame

	# 挂上登录界面 (模拟 Boot → Login)
	var login := (load("res://src/scenes/login.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(login)
	get_tree().current_scene = login
	await get_tree().process_frame

	var button := _find_by_name(login, "NewGameButton") as Button
	_check(button != null, "登录界面存在 开始新游戏 按钮")
	if button == null:
		get_tree().quit(1)
		return

	# 预先把状态弄乱, 验证"新游戏"确实重置
	shelter.set_state({"shelter_level": 3, "upgrading": false, "upgrade_cooldown_remaining": 0.0})
	TimeManager.game_hours = 100.0

	button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame

	var scene := get_tree().current_scene
	_check(scene != null and scene.name == "Main", "点击后 current_scene 切换到 Main")
	_check(shelter.current_level == 1, "新游戏重置为 Lv1")
	# 时钟重置到 08:00 后会继续走帧, 只验证落在 8.0~8.01
	_check(TimeManager.game_hours >= 8.0 and TimeManager.game_hours < 8.01, "新游戏重置为第1天 08:00")

	# 顶部资源条 (S1 纯 UI 展示: 当前数 = initial_resource_<id>, 上限 = base_capacity + storage_bonus)
	_check(scene != null and _find_by_name(scene, "ResourceBar") != null, "主界面存在顶部资源条")
	var items_ok := scene != null
	var values_ok := scene != null
	if scene != null:
		items_ok = (
			_find_by_name(scene, "ResourceItem_wood") != null
			and _find_by_name(scene, "ResourceItem_steel") != null
			and _find_by_name(scene, "ResourceItem_food") != null
			and _find_by_name(scene, "ResourceItem_water") != null
		)
		var v_wood := _find_by_name(scene, "ResourceValue_wood") as Label
		var v_steel := _find_by_name(scene, "ResourceValue_steel") as Label
		var v_food := _find_by_name(scene, "ResourceValue_food") as Label
		var v_water := _find_by_name(scene, "ResourceValue_water") as Label
		values_ok = (
			v_wood != null and v_wood.text == "200/200"
			and v_steel != null and v_steel.text == "100/200"
			and v_food != null and v_food.text == "140/200"
			and v_water != null and v_water.text == "60/200"
		)
	_check(items_ok, "资源条含 wood/steel/food/water 四项")
	_check(values_ok, "资源条数值 = 初始资源/库存上限")

	if _failed:
		printerr("NAVTEST: FAILED")
		get_tree().quit(1)
	else:
		print("NAVTEST: ALL PASSED")
		get_tree().quit(0)
