extends Control
# ============================================================
# Main — Dev-S1 最小游戏界面 (场景背景 assets/blank_lvN_1920x1080.png, 按等级切换, 后续填实际 UI 资源)
# 庇护所面板: 名称/等级/满级进度/数值 + 升级按钮(冷却) + 保存/读档
# ============================================================

const LOGIN_SCENE := "res://src/scenes/login.tscn"

var _shelter: ShelterSystem

var _bg: TextureRect
var _title_label: Label
var _level_label: Label
var _progress_label: Label
var _stats_label: Label
var _time_label: Label
var _upgrade_button: Button
var _cooldown_label: Label
var _slot_option: OptionButton
var _save_button: Button
var _load_button: Button
var _status_label: Label


func _ready() -> void:
	_shelter = get_node("/root/ShelterSystem") as ShelterSystem
	_build_ui()
	_shelter.upgrade_started.connect(_on_upgrade_started)
	_shelter.upgrade_completed.connect(_on_upgrade_completed)
	_shelter.level_changed.connect(_on_level_changed)
	_refresh()


func _process(_delta: float) -> void:
	_time_label.text = TimeManager.get_time_text()
	if _shelter.upgrading:
		_cooldown_label.text = "升级中, 剩余 %.1f 秒" % _shelter.cooldown_remaining


# ---------------- UI ----------------

func _build_ui() -> void:
	_bg = TextureRect.new()
	_bg.texture = _level_bg_texture()
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	_time_label = Label.new()
	_time_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_time_label.position = Vector2(-320, 24)
	_time_label.size = Vector2(296, 40)
	_time_label.add_theme_font_size_override("font_size", 28)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_time_label)

	if ConfigManager.is_enabled("settings"):
		var settings_button := Button.new()
		settings_button.name = "SettingsButton"
		settings_button.text = "设置"
		settings_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		settings_button.position = Vector2(-160, 80)
		settings_button.size = Vector2(136, 48)
		settings_button.add_theme_font_size_override("font_size", 22)
		settings_button.pressed.connect(_on_settings_pressed)
		ButtonSkin.apply(settings_button)
		add_child(settings_button)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.1, 0.85)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.position = Vector2(48, -420)
	panel.size = Vector2(560, 372)
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 36)
	box.add_child(_title_label)

	_level_label = Label.new()
	_level_label.add_theme_font_size_override("font_size", 28)
	box.add_child(_level_label)

	_progress_label = Label.new()
	_progress_label.add_theme_font_size_override("font_size", 20)
	_progress_label.modulate = Color(1, 1, 1, 0.75)
	box.add_child(_progress_label)

	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 20)
	_stats_label.modulate = Color(1, 1, 1, 0.85)
	box.add_child(_stats_label)

	_upgrade_button = Button.new()
	_upgrade_button.name = "UpgradeButton"
	_upgrade_button.text = "升级"
	_upgrade_button.custom_minimum_size = Vector2(496, 56)
	_upgrade_button.add_theme_font_size_override("font_size", 26)
	_upgrade_button.pressed.connect(_on_upgrade_pressed)
	ButtonSkin.apply(_upgrade_button)
	box.add_child(_upgrade_button)

	_cooldown_label = Label.new()
	_cooldown_label.add_theme_font_size_override("font_size", 18)
	_cooldown_label.modulate = Color(1, 0.9, 0.6, 0.9)
	box.add_child(_cooldown_label)

	var save_row := HBoxContainer.new()
	save_row.add_theme_constant_override("separation", 12)
	box.add_child(save_row)

	_slot_option = OptionButton.new()
	_slot_option.custom_minimum_size = Vector2(160, 48)
	_slot_option.add_theme_font_size_override("font_size", 20)
	save_row.add_child(_slot_option)

	_save_button = Button.new()
	_save_button.name = "SaveButton"
	_save_button.text = "保存"
	_save_button.custom_minimum_size = Vector2(140, 48)
	_save_button.add_theme_font_size_override("font_size", 22)
	_save_button.pressed.connect(_on_save_pressed)
	ButtonSkin.apply(_save_button)
	save_row.add_child(_save_button)

	_load_button = Button.new()
	_load_button.name = "LoadButton"
	_load_button.text = "读档"
	_load_button.custom_minimum_size = Vector2(140, 48)
	_load_button.add_theme_font_size_override("font_size", 22)
	_load_button.pressed.connect(_on_load_pressed)
	ButtonSkin.apply(_load_button)
	save_row.add_child(_load_button)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 18)
	box.add_child(_status_label)

	var back_button := Button.new()
	back_button.name = "BackButton"
	back_button.text = "返回标题"
	back_button.custom_minimum_size = Vector2(496, 44)
	back_button.pressed.connect(_on_back_pressed)
	ButtonSkin.apply(back_button)
	box.add_child(back_button)

	_slot_option.clear()
	for slot in range(1, SaveManager.get_slot_count() + 1):
		_slot_option.add_item("存档 %d" % slot, slot)
	_slot_option.select(0)


# ---------------- 刷新 ----------------

# 场景图按庇护所等级取: blank_lvN_1920x1080.png, 缺文件回退 Lv1 (实际 UI 资源直接覆盖同名文件)
func _level_bg_texture() -> Texture2D:
	var level_path := "res://assets/blank_lv%d_1920x1080.png" % _shelter.current_level
	if not ResourceLoader.exists(level_path):
		level_path = "res://assets/blank_lv1_1920x1080.png"
	return load(level_path) as Texture2D


func _refresh() -> void:
	_bg.texture = _level_bg_texture()
	var base: Dictionary = ConfigManager.get_shelter_base()
	_title_label.text = str(base.get("name", ""))
	_level_label.text = "Lv%d %s" % [_shelter.current_level, _shelter.get_level_name()]
	_progress_label.text = "满级进度 %d/%d" % [_shelter.current_level, _shelter.get_max_level()]
	var stats: Dictionary = _shelter.get_level_stats()
	_stats_label.text = (
		"人口上限 %d | 建筑位 %d | 防御 %d\n产量加成 +%d%% | 仓储加成 +%d"
		% [
			int(stats.get("population_cap", 0)),
			int(stats.get("building_slots", 0)),
			int(stats.get("defense", 0)),
			int(stats.get("production_bonus_percent", 0)),
			int(stats.get("storage_bonus", 0)),
		]
	)
	if _shelter.upgrading:
		_upgrade_button.disabled = true
		_upgrade_button.text = "升级中..."
	elif _shelter.is_max_level():
		_upgrade_button.disabled = true
		_upgrade_button.text = "已满级 (等待后续版本开放更高等级)"
		_cooldown_label.text = ""
	else:
		_upgrade_button.disabled = not _shelter.can_upgrade()
		_upgrade_button.text = "升级 → Lv%d %s" % [
			_shelter.current_level + 1,
			_shelter.get_level_name(_shelter.current_level + 1),
		]
		if not _shelter.upgrading:
			_cooldown_label.text = "升级耗时 %.0f 秒 (S1 临时冷却)" % ShelterSystem.TEMP_UPGRADE_COOLDOWN_REAL_SECONDS
	_time_label.text = TimeManager.get_time_text()


# ---------------- 交互 ----------------

func _selected_slot() -> int:
	if _slot_option.get_item_count() == 0:
		return 1
	return _slot_option.get_selected_id()


func _on_upgrade_pressed() -> void:
	if _shelter.start_upgrade():
		_status_label.text = "开始升级..."
		_refresh()
	else:
		_status_label.text = "当前无法升级"
	_refresh()


func _on_save_pressed() -> void:
	var slot := _selected_slot()
	var data := {
		"shelter": _shelter.get_state(),
		"time": TimeManager.get_state(),
	}
	var err := SaveManager.save_game(slot, data)
	_status_label.text = "保存成功 (存档 %d)" % slot if err == OK else "保存失败 (错误 %d)" % err


func _on_load_pressed() -> void:
	var slot := _selected_slot()
	var data := SaveManager.load_game(slot)
	if data.is_empty():
		_status_label.text = "读档失败: 存档损坏或为空"
		return
	_shelter.set_state(data.get("shelter", {}))
	TimeManager.set_state(data.get("time", {}))
	_status_label.text = "已读取存档 %d" % slot
	_refresh()


func _on_settings_pressed() -> void:
	SettingsOverlay.open(self)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(LOGIN_SCENE)


func _on_upgrade_started(_cooldown: float) -> void:
	_refresh()


func _on_upgrade_completed(new_level: int) -> void:
	_status_label.text = "升级完成: Lv%d %s" % [new_level, _shelter.get_level_name(new_level)]
	_refresh()


func _on_level_changed(_new_level: int) -> void:
	_refresh()
