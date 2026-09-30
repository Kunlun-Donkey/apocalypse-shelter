class_name SettingsOverlay
extends Control
# ============================================================
# 设置面板 (覆盖层): 全屏开关 + 主音量, 修改即生效并自动保存
# 存档: user://settings.json (与游戏存档分离)
# 用法: SettingsOverlay.open(任意父节点); Esc 或关闭按钮退出
# ============================================================

const SETTINGS_PATH := "user://settings.json"
const DEFAULT_VOLUME_PERCENT := 80.0

var _fullscreen: CheckButton
var _volume_slider: HSlider
var _volume_label: Label


static func open(parent: Node) -> SettingsOverlay:
	var overlay := SettingsOverlay.new()
	overlay.name = "SettingsOverlay"
	parent.add_child(overlay)
	return overlay


static func load_settings() -> Dictionary:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return {}
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return {}
	return parsed


static func save_settings(data: Dictionary) -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_apply_all()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close()


# ---------------- UI ----------------

func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.14, 0.97)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	panel.add_child(box)

	var title := Label.new()
	title.text = "设置"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var full_row := HBoxContainer.new()
	full_row.add_theme_constant_override("separation", 24)
	box.add_child(full_row)
	var full_label := Label.new()
	full_label.text = "全屏"
	full_label.add_theme_font_size_override("font_size", 22)
	full_label.custom_minimum_size = Vector2(160, 40)
	full_row.add_child(full_label)
	_fullscreen = CheckButton.new()
	_fullscreen.name = "FullscreenToggle"
	_fullscreen.custom_minimum_size = Vector2(120, 40)
	_fullscreen.toggled.connect(_on_fullscreen_toggled)
	full_row.add_child(_fullscreen)

	var vol_row := HBoxContainer.new()
	vol_row.add_theme_constant_override("separation", 24)
	box.add_child(vol_row)
	var vol_label := Label.new()
	vol_label.text = "主音量"
	vol_label.add_theme_font_size_override("font_size", 22)
	vol_label.custom_minimum_size = Vector2(160, 40)
	vol_row.add_child(vol_label)
	_volume_slider = HSlider.new()
	_volume_slider.name = "VolumeSlider"
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 100.0
	_volume_slider.step = 1.0
	_volume_slider.custom_minimum_size = Vector2(220, 40)
	_volume_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_volume_slider.value_changed.connect(_on_volume_changed)
	vol_row.add_child(_volume_slider)
	_volume_label = Label.new()
	_volume_label.custom_minimum_size = Vector2(80, 40)
	_volume_label.add_theme_font_size_override("font_size", 22)
	vol_row.add_child(_volume_label)

	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(360, 52)
	close_button.add_theme_font_size_override("font_size", 24)
	close_button.pressed.connect(_close)
	ButtonSkin.apply(close_button)
	box.add_child(close_button)


# ---------------- 设置读写与应用 ----------------

func _apply_all() -> void:
	var data := load_settings()
	var fullscreen := bool(data.get("fullscreen", false))
	var volume := float(data.get("volume_percent", DEFAULT_VOLUME_PERCENT))
	_fullscreen.set_pressed_no_signal(fullscreen)
	_volume_slider.set_value_no_signal(volume)
	_volume_label.text = "%d%%" % int(volume)
	_apply_fullscreen(fullscreen)
	_apply_volume(volume)


func _persist() -> void:
	save_settings({
		"fullscreen": _fullscreen.button_pressed,
		"volume_percent": _volume_slider.value,
	})


func _on_fullscreen_toggled(pressed: bool) -> void:
	_apply_fullscreen(pressed)
	_persist()


func _on_volume_changed(value: float) -> void:
	_volume_label.text = "%d%%" % int(value)
	_apply_volume(value)
	_persist()


func _apply_fullscreen(fullscreen: bool) -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)


func _apply_volume(percent: float) -> void:
	if percent <= 0.0:
		AudioServer.set_bus_volume_db(0, -80.0)
	else:
		AudioServer.set_bus_volume_db(0, linear_to_db(percent / 100.0))


func _close() -> void:
	queue_free()
