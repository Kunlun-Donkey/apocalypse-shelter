extends Node
# ============================================================
# 设置面板验证 (headless):
#   godot --headless --path . res://tests/dev_s1_settest.tscn
# 覆盖: 登录界面设置入口 → 面板出现(全屏/音量/关闭) → 音量持久化
#        → 关闭后重开数值保留 → Esc 关闭
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
	get_tree().current_scene = null

	var err := ConfigManager.load_all()
	_check(err == OK, "配置加载 OK")
	if err != OK:
		printerr("CONFIG ERROR: " + ConfigManager.get_error_message())
		get_tree().quit(1)
		return

	_check(ConfigManager.is_enabled("settings"), "settings 开关已开启")

	# 挂上登录界面 (与 navtest 相同手法)
	var login := (load("res://src/scenes/login.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(login)
	get_tree().current_scene = login
	await get_tree().process_frame

	var settings_button := _find_by_name(login, "SettingsButton") as Button
	_check(settings_button != null, "登录界面存在 设置 按钮")
	if settings_button == null:
		get_tree().quit(1)
		return

	settings_button.pressed.emit()
	await get_tree().process_frame

	var overlay := _find_by_name(login, "SettingsOverlay")
	_check(overlay != null, "点击后弹出设置面板")
	if overlay == null:
		get_tree().quit(1)
		return

	var fullscreen := _find_by_name(overlay, "FullscreenToggle") as CheckButton
	var slider := _find_by_name(overlay, "VolumeSlider") as HSlider
	var close_button := _find_by_name(overlay, "CloseButton") as Button
	_check(fullscreen != null, "面板含 全屏 开关")
	_check(slider != null, "面板含 音量 滑条")
	_check(close_button != null, "面板含 关闭 按钮")
	if slider == null or close_button == null:
		get_tree().quit(1)
		return

	# 改音量 → 即时持久化
	slider.value = 35.0
	slider.value_changed.emit(35.0)
	await get_tree().process_frame
	var saved := SettingsOverlay.load_settings()
	_check(int(saved.get("volume_percent", -1)) == 35, "音量修改即写入 settings.json")

	# 关闭后重开, 数值保留
	close_button.pressed.emit()
	await get_tree().process_frame
	_check(_find_by_name(login, "SettingsOverlay") == null, "关闭后面板消失")

	settings_button.pressed.emit()
	await get_tree().process_frame
	overlay = _find_by_name(login, "SettingsOverlay")
	if overlay == null:
		printerr("FAIL: 重开设置面板")
		get_tree().quit(1)
		return
	slider = _find_by_name(overlay, "VolumeSlider") as HSlider
	_check(slider != null and int(slider.value) == 35, "重开后音量保留 35%")

	# Esc 关闭
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	overlay._unhandled_input(esc)
	await get_tree().process_frame
	_check(_find_by_name(login, "SettingsOverlay") == null, "Esc 关闭面板")

	# 还原默认音量, 不污染后续测试/用户设置
	SettingsOverlay.save_settings({"fullscreen": false, "volume_percent": 80.0})

	if _failed:
		printerr("SETTEST: FAILED")
		get_tree().quit(1)
	else:
		print("SETTEST: ALL PASSED")
		get_tree().quit(0)
