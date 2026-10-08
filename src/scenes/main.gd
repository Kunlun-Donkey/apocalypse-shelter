extends Control
# ============================================================
# Main — Dev-S1 世界界面 (顶部资源条 + 底部功能按钮, 逻辑书 B4)
# 顶部 HUD 通栏: 资源条 + spacer + 等级 LevelLabel + 时间 + 设置
# 底部一排 6 功能按钮 BottomBar + 其上提示行 StatusLabel
#   升级/存读档已移出 main: 升级只在庇护所室内 (interior), 存读档/返回标题在设置弹层 game_menu 段
#   level_changed 仍是读档/升级后刷新楼体+等级的唯一通道
# 中央 = main.tscn 实体节点 MapBackground (first_scene.png 世界底图) + ShelterLayer (庇护所图 shelter_level%d.png)
#   庇护所图位置/大小在 Godot 编辑器里拖拽摆位, 存 tscn 即定稿 (用户后续生成覆盖)
# ============================================================

const INTERIOR_SCENE := "res://src/scenes/shelter_interior.tscn"

var _shelter: ShelterSystem

var _bg: TextureRect
var _shelter_layer: TextureRect
var _level_label: Label
var _time_label: Label
var _status_label: Label
var _resource_value_labels: Dictionary = {}  # key -> Label


func _ready() -> void:
	_shelter = get_node("/root/ShelterSystem") as ShelterSystem
	_bg = get_node("MapBackground") as TextureRect
	_shelter_layer = get_node("ShelterLayer") as TextureRect
	_bg.texture = _map_bg_texture()
	_build_ui()
	_shelter.level_changed.connect(_on_level_changed)
	_refresh()


func _process(_delta: float) -> void:
	_time_label.text = TimeManager.get_time_text()


# ---------------- UI ----------------

func _build_ui() -> void:
	# 底图 MapBackground / 楼体 ShelterLayer 是 main.tscn 实体节点 (编辑器拖拽摆位), 这里只搭 UI
	# ---- 顶部 HUD 通栏: 左资源条 + 右等级/时间/设置 ----
	var hud := PanelContainer.new()
	hud.name = "TopHud"
	var hud_style := StyleBoxFlat.new()
	hud_style.bg_color = Color(0.05, 0.07, 0.1, 0.72)
	hud_style.content_margin_left = 32
	hud_style.content_margin_right = 32
	hud_style.content_margin_top = 14
	hud_style.content_margin_bottom = 14
	hud.add_theme_stylebox_override("panel", hud_style)
	hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud.custom_minimum_size = Vector2(0, 88)
	add_child(hud)

	var hud_row := HBoxContainer.new()
	hud_row.add_theme_constant_override("separation", 24)
	hud.add_child(hud_row)

	_build_resource_bar(hud_row)

	var hud_spacer := Control.new()
	hud_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud_row.add_child(hud_spacer)

	_level_label = Label.new()
	_level_label.name = "LevelLabel"
	_level_label.add_theme_font_size_override("font_size", 28)
	_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud_row.add_child(_level_label)

	_time_label = Label.new()
	_time_label.add_theme_font_size_override("font_size", 28)
	_time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud_row.add_child(_time_label)

	if ConfigManager.is_enabled("settings"):
		var settings_button := Button.new()
		settings_button.name = "SettingsButton"
		settings_button.text = "设置"
		settings_button.custom_minimum_size = Vector2(120, 48)
		settings_button.add_theme_font_size_override("font_size", 22)
		settings_button.pressed.connect(_on_settings_pressed)
		ButtonSkin.apply(settings_button)
		hud_row.add_child(settings_button)

	# ---- 底部提示行 (BottomBar 上方) ----
	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.add_theme_font_size_override("font_size", 20)
	_status_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_status_label.offset_left = 48
	_status_label.offset_right = -48
	_status_label.offset_top = -136
	_status_label.offset_bottom = -104
	add_child(_status_label)

	# ---- 底部一排 6 功能按钮 (等分; 任务=卷轴面板, 进入=室内, 其余占位提示) ----
	# 六按钮 → 系统映射 (system.conf 全 OFF, 除任务面板为 UI 壳外零逻辑):
	#   任务=quest (TaskPanel 卷轴, 内容占位) / 仓库=resource(+building 容量) / 出城=map+location /
	#   探索=exploration+loot / 招募=npc+survivor / 进入=shelter (已开)
	var bottom_bar := HBoxContainer.new()
	bottom_bar.name = "BottomBar"
	bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_bar.offset_left = 48
	bottom_bar.offset_right = -48
	bottom_bar.offset_top = -96
	bottom_bar.offset_bottom = -16
	bottom_bar.add_theme_constant_override("separation", 16)
	add_child(bottom_bar)

	var task_button := Button.new()
	task_button.name = "TaskButton"
	task_button.text = "任务"
	task_button.custom_minimum_size = Vector2(0, 68)
	task_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	task_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	task_button.add_theme_font_size_override("font_size", 26)
	task_button.pressed.connect(_on_task_pressed)
	ButtonSkin.apply(task_button)
	bottom_bar.add_child(task_button)

	var placeholders := [
		["WarehouseButton", "仓库"],
		["OutCityButton", "出城"],
		["ExploreButton", "探索"],
	]
	for item: Array in placeholders:
		var btn := Button.new()
		btn.name = str(item[0])
		btn.text = str(item[1])
		btn.custom_minimum_size = Vector2(0, 68)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.add_theme_font_size_override("font_size", 26)
		btn.pressed.connect(_on_placeholder_pressed.bind(str(item[1])))
		ButtonSkin.apply(btn)
		bottom_bar.add_child(btn)

	var recruit_button := BtnRecruit.new()
	recruit_button.name = "Btn_Recruit"
	recruit_button.text = "招募"
	recruit_button.custom_minimum_size = Vector2(0, 68)
	recruit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recruit_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	recruit_button.add_theme_font_size_override("font_size", 26)
	ButtonSkin.apply(recruit_button)
	bottom_bar.add_child(recruit_button)

	var enter_shelter_button := Button.new()
	enter_shelter_button.name = "EnterShelterButton"
	enter_shelter_button.text = "进入"
	enter_shelter_button.custom_minimum_size = Vector2(0, 68)
	enter_shelter_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enter_shelter_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	enter_shelter_button.add_theme_font_size_override("font_size", 26)
	enter_shelter_button.pressed.connect(_on_enter_shelter_pressed)
	ButtonSkin.apply(enter_shelter_button)
	bottom_bar.add_child(enter_shelter_button)


# 顶部资源条 (挂在 HUD 通栏内): 每资源一格 "名称 当前数/库存上限" (纯 UI 展示, S2 ResourceSystem 接管)
func _build_resource_bar(parent: Node) -> void:
	var bar := HBoxContainer.new()
	bar.name = "ResourceBar"
	bar.add_theme_constant_override("separation", 16)
	parent.add_child(bar)

	for item: Dictionary in ConfigManager.get_resource_display_items():
		var key := str(item.get("key", ""))
		var panel := PanelContainer.new()
		panel.name = "ResourceItem_%s" % key
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.05, 0.07, 0.1, 0.85)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		style.content_margin_left = 20
		style.content_margin_right = 20
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		panel.add_theme_stylebox_override("panel", style)
		bar.add_child(panel)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		panel.add_child(row)

		var name_label := Label.new()
		name_label.name = "ResourceName_%s" % key
		name_label.text = str(item.get("name", key))
		name_label.add_theme_font_size_override("font_size", 22)
		row.add_child(name_label)

		var value_label := Label.new()
		value_label.name = "ResourceValue_%s" % key
		value_label.add_theme_font_size_override("font_size", 22)
		row.add_child(value_label)
		_resource_value_labels[key] = value_label


func _refresh_resource_bar() -> void:
	var init: Dictionary = ConfigManager.get_initial_state()
	var stats: Dictionary = _shelter.get_level_stats()
	var capacity_bonus: int = int(stats.get("storage_bonus", 0))
	for item: Dictionary in ConfigManager.get_resource_display_items():
		var key := str(item.get("key", ""))
		var label := _resource_value_labels.get(key) as Label
		if label == null:
			continue
		var amount: int = int(init.get("initial_resource_%s" % key, 0))
		var capacity: int = int(item.get("base_capacity", 0)) + capacity_bonus
		label.text = "%d/%d" % [amount, capacity]


# ---------------- 刷新 ----------------

# 登录点"进入游戏"后主场景底图: assets/map/first_scene.png (恒定世界图, 不随等级变)
# 缺图回退 blank_lv1 并打警告 (回退效果=旧图, 先跑 godot --headless --import)
func _map_bg_texture() -> Texture2D:
	var path := "res://assets/map/first_scene.png"
	if not ResourceLoader.exists(path):
		push_warning("MAP BG: first_scene.png 缺失或未导入, 回退 blank_lv1 (请先 godot --headless --import)")
		path = "res://assets/blank_lv1_1920x1080.png"
	else:
		print("MAP BG: loaded ", path)
	return load(path) as Texture2D


# 庇护所图: assets/shelter/shelter_level%d.png 按等级取 (位置/大小在 main.tscn 编辑器里摆)
# 缺文件回退 shelter_level1, 仍缺则隐藏 (用户后续重新生成覆盖)
func _shelter_overlay_texture() -> Texture2D:
	var path := "res://assets/shelter/shelter_level%d.png" % _shelter.current_level
	if not ResourceLoader.exists(path):
		path = "res://assets/shelter/shelter_level1.png"
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _refresh() -> void:
	_shelter_layer.texture = _shelter_overlay_texture()
	_shelter_layer.visible = _shelter_layer.texture != null
	_refresh_resource_bar()
	_level_label.text = "Lv%d %s" % [_shelter.current_level, _shelter.get_level_name()]
	_time_label.text = TimeManager.get_time_text()


# ---------------- 交互 ----------------

func _on_placeholder_pressed(what: String) -> void:
	_status_label.text = "后续版本开放: %s" % what


func _on_task_pressed() -> void:
	TaskPanel.open(self)


func _on_settings_pressed() -> void:
	SettingsOverlay.open(self, true)


func _on_enter_shelter_pressed() -> void:
	get_tree().change_scene_to_file(INTERIOR_SCENE)


func _on_level_changed(_new_level: int) -> void:
	_refresh()
