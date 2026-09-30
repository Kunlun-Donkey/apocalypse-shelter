extends Node
# ============================================================
# 庇护所室内场景导航验证 (headless):
#   godot --headless --path . res://tests/dev_s1_inttest.tscn
# 覆盖: 登录"开始新游戏" → Main → "进入庇护所" → ShelterInterior
#         → 室内节点齐全 (BackButton/RoomGrid/RoomPanel_1..5/RoomSummary)
#         → BackButton 返回 Main
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


func _abort() -> void:
	printerr("INTTEST: FAILED")
	get_tree().quit(1)


func _run() -> void:
	await get_tree().process_frame
	# 自己脱离 current_scene, 防止 change_scene 时被一并释放
	get_tree().current_scene = null

	var err := ConfigManager.load_all()
	_check(err == OK, "配置加载 OK")
	if err != OK:
		printerr("CONFIG ERROR: " + ConfigManager.get_error_message())
		_abort()
		return

	# 模拟 Boot 创建 ShelterSystem (login/main 依赖 /root/ShelterSystem)
	var shelter := ShelterSystem.new()
	shelter.name = "ShelterSystem"
	get_tree().root.add_child.call_deferred(shelter)
	await get_tree().process_frame

	# 挂上登录界面 (模拟 Boot → Login)
	var login := (load("res://src/scenes/login.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(login)
	get_tree().current_scene = login
	await get_tree().process_frame

	var new_game := _find_by_name(login, "NewGameButton") as Button
	_check(new_game != null, "登录界面存在 开始新游戏 按钮")
	if new_game == null:
		_abort()
		return

	new_game.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	# 断言到达主界面 (能找到 UpgradeButton 即算到主界面)
	var main_scene := get_tree().current_scene
	_check(main_scene != null and _find_by_name(main_scene, "UpgradeButton") != null, "点击后进入主界面 (存在 UpgradeButton)")
	if main_scene == null or _find_by_name(main_scene, "UpgradeButton") == null:
		_abort()
		return

	# 主界面存在"进入庇护所"入口按钮
	var enter := _find_by_name(main_scene, "EnterShelterButton") as Button
	_check(enter != null, "主界面存在 进入庇护所 按钮")
	if enter == null:
		_abort()
		return

	# 进入室内场景
	enter.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var interior := get_tree().current_scene
	_check(interior != null and interior.name == "ShelterInterior", "点击后 current_scene 切换到 ShelterInterior")
	if interior == null or interior.name != "ShelterInterior":
		_abort()
		return

	# 室内节点齐全
	_check(_find_by_name(interior, "BackButton") != null, "室内存在 BackButton")
	_check(_find_by_name(interior, "RoomGrid") != null, "室内存在 RoomGrid")
	for i in range(1, 6):
		_check(_find_by_name(interior, "RoomPanel_%d" % i) != null, "室内存在 RoomPanel_%d" % i)
	_check(_find_by_name(interior, "RoomSummary") != null, "室内存在 RoomSummary")

	# BackButton 返回主界面
	var back := _find_by_name(interior, "BackButton") as Button
	if back == null:
		_abort()
		return
	back.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var back_scene := get_tree().current_scene
	_check(back_scene != null and _find_by_name(back_scene, "UpgradeButton") != null, "返回后回到主界面 (存在 UpgradeButton)")

	if _failed:
		printerr("INTTEST: FAILED")
		get_tree().quit(1)
	else:
		print("INTTEST: ALL PASSED")
		get_tree().quit(0)
