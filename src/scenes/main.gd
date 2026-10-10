extends Control
# ============================================================
# Main — Dev-S1 世界界面 (顶部资源条 + 底部功能按钮, 逻辑书 B4)
# 顶部 HUD 通栏: 资源条 + 人口/天气面板 + spacer + 等级 LevelLabel + 日夜图标 + 时间 + 设置
# 底部一排 6 功能按钮 BottomBar + 其上提示行 StatusLabel
#   升级/存读档已移出 main: 升级只在庇护所室内 (interior), 存读档/返回标题在设置弹层 game_menu 段
#   level_changed 仍是读档/升级后刷新楼体+等级的唯一通道
# 中央 = main.tscn 实体节点 MapBackground (first_scene.png 世界底图) + ShelterLayer (庇护所图 shelter_level%d.png)
#   庇护所图位置/大小在 Godot 编辑器里拖拽摆位, 存 tscn 即定稿 (用户后续生成覆盖)
# ============================================================

const INTERIOR_SCENE := "res://src/scenes/shelter_interior.tscn"

# 天气占位轮换表 (按游戏日确定; 天气系统未开, 纯 UI 壳, S2+ 天气系统接管)
const WEATHERS := ["晴", "多云", "小雨", "雾"]
const DAY_ICON := "res://assets/hud/day_icon.png"
const NIGHT_ICON := "res://assets/hud/night_icon.png"
const HOUSE_ICON := "res://assets/hud/house_icon.svg"
const DAY_START_HOUR := 6.0
const DAY_END_HOUR := 18.0

var _shelter: ShelterSystem

var _bg: TextureRect
var _shelter_layer: TextureRect
var _level_label: Label
var _time_label: Label
var _status_label: Label
var _resource_value_labels: Dictionary = {}  # key -> Label
var _population_label: Label
var _weather_label: Label
var _day_night_icon: TextureRect
var _day_texture: Texture2D
var _night_texture: Texture2D
var _house_button: Button


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
	_weather_label.text = _weather_text()
	_refresh_day_night()


# ---------------- UI ----------------

func _build_ui() -> void:
	# UI 骨架 = main.tscn 实体节点 (TopHud/StatusLabel/BottomBar 等, 编辑器可见可调);
	# 代码只做: 贴皮 (StyleBox/ButtonSkin) + 接线 (信号) + 动态内容 (资源条按 CONF 生成)
	# ---- 顶部 HUD 通栏: 左资源条 + 右等级/时间/设置 ----
	var hud := get_node("TopHud") as PanelContainer
	var hud_style := StyleBoxFlat.new()
	hud_style.bg_color = Color(0.05, 0.07, 0.1, 0.72)
	hud_style.content_margin_left = 32
	hud_style.content_margin_right = 32
	hud_style.content_margin_top = 14
	hud_style.content_margin_bottom = 14
	hud.add_theme_stylebox_override("panel", hud_style)

	var hud_row := get_node("TopHud/HudRow") as HBoxContainer

	_build_resource_bar(hud_row.get_node("ResourceBar") as HBoxContainer)
	_build_population_panel(hud_row.get_node("PopulationPanel") as PanelContainer)
	_build_weather_panel(hud_row.get_node("WeatherPanel") as PanelContainer)
	_level_label = hud_row.get_node("LevelLabel") as Label
	_build_house_button(hud_row.get_node("HouseButton") as Button)
	_build_day_night_icon(hud_row.get_node("DayNightIcon") as TextureRect)
	_time_label = hud_row.get_node("TimeLabel") as Label

	if ConfigManager.is_enabled("settings"):
		var settings_button := hud_row.get_node("SettingsButton") as Button
		settings_button.pressed.connect(_on_settings_pressed)
		ButtonSkin.apply(settings_button)
	else:
		hud_row.get_node("SettingsButton").visible = false

	# ---- 底部提示行 (BottomBar 上方) ----
	_status_label = get_node("StatusLabel") as Label

	# ---- 底部一排 6 功能按钮 (等分; 任务=卷轴面板, 进入=室内, 其余占位提示) ----
	# 六按钮 → 系统映射 (system.conf 全 OFF, 除任务面板为 UI 壳外零逻辑):
	#   任务=quest (TaskPanel 卷轴, 内容占位) / 仓库=resource(+building 容量) / 出城=map+location /
	#   探索=exploration+loot / 招募=npc+survivor / 进入=shelter (已开)
	var task_button := get_node("BottomBar/TaskButton") as Button
	task_button.pressed.connect(_on_task_pressed)
	ButtonSkin.apply(task_button)

	for btn_name: String in ["WarehouseButton", "OutCityButton", "ExploreButton"]:
		var btn := get_node("BottomBar/" + btn_name) as Button
		btn.pressed.connect(_on_placeholder_pressed.bind(btn.text))
		ButtonSkin.apply(btn)

	var recruit_button := get_node("BottomBar/Btn_Recruit") as BtnRecruit
	ButtonSkin.apply(recruit_button)

	var enter_shelter_button := get_node("BottomBar/EnterShelterButton") as Button
	enter_shelter_button.pressed.connect(_on_enter_shelter_pressed)
	ButtonSkin.apply(enter_shelter_button)


# 顶部资源条 (ResourceBar = tscn 节点, 挂 HUD 通栏内): 每资源一格 "名称 当前数/库存上限" (纯 UI 展示, S2 ResourceSystem 接管)
func _build_resource_bar(bar: HBoxContainer) -> void:
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


# 人口面板 (纯 UI 展示): "人口: 当前/上限" — 当前=initial_population, 上限=等级 population_cap
# survivor 系统开启后接管 (S1 零初始化, 不建 SurvivorSystem)
func _build_population_panel(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", _hud_chip_style())
	_population_label = panel.get_node("PopulationLabel") as Label


# 天气面板 (纯 UI 壳): "天气: X" — 按游戏日轮换 WEATHERS 占位, 天气系统未开
func _build_weather_panel(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", _hud_chip_style())
	_weather_label = panel.get_node("WeatherLabel") as Label


# 日夜图标 (时间旁): 6:00~18:00 白天 day_icon.png, 其余夜晚 night_icon.png (占位可覆盖)
func _build_day_night_icon(icon: TextureRect) -> void:
	_day_night_icon = icon
	_day_texture = _load_icon(DAY_ICON)
	_night_texture = _load_icon(NIGHT_ICON)


func _hud_chip_style() -> StyleBoxFlat:
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
	return style


func _load_icon(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


# 房子图标按钮 (HouseButton = tscn 节点): 点击向下展开庇护所状态面板 (生命/攻击/防御/恢复, 逻辑书 B4.3)
func _build_house_button(button: Button) -> void:
	_house_button = button
	_house_button.icon = _load_icon(HOUSE_ICON)
	if _house_button.icon != null:
		_house_button.expand_icon = true
	else:
		_house_button.text = "房屋"  # 缺图回退, 不崩
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(1, 1, 1, 0.08)
	hover_style.corner_radius_top_left = 8
	hover_style.corner_radius_top_right = 8
	hover_style.corner_radius_bottom_left = 8
	hover_style.corner_radius_bottom_right = 8
	_house_button.add_theme_stylebox_override("hover", hover_style)
	_house_button.add_theme_stylebox_override("pressed", hover_style)
	_house_button.pressed.connect(_on_house_pressed)


func _weather_text() -> String:
	return "天气: %s" % WEATHERS[(TimeManager.get_game_day() - 1) % WEATHERS.size()]


func _refresh_population() -> void:
	var init: Dictionary = ConfigManager.get_initial_state()
	var stats: Dictionary = _shelter.get_level_stats()
	var current: int = int(init.get("initial_population", 0))
	var cap: int = int(stats.get("population_cap", 0))
	_population_label.text = "人口: %d/%d" % [current, cap]


func _refresh_day_night() -> void:
	var hour := TimeManager.get_hour_of_day()
	var is_day := hour >= DAY_START_HOUR and hour < DAY_END_HOUR
	_day_night_icon.texture = _day_texture if is_day else _night_texture


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
	_refresh_population()
	_level_label.text = "Lv%d %s" % [_shelter.current_level, _shelter.get_level_name()]
	_time_label.text = TimeManager.get_time_text()
	_weather_label.text = _weather_text()
	_refresh_day_night()


# ---------------- 交互 ----------------

func _on_placeholder_pressed(what: String) -> void:
	_status_label.text = "后续版本开放: %s" % what


func _on_task_pressed() -> void:
	TaskPanel.open(self)


func _on_settings_pressed() -> void:
	SettingsOverlay.open(self, true)


func _on_house_pressed() -> void:
	ShelterStatusPanel.toggle(self, _house_button)


func _on_enter_shelter_pressed() -> void:
	get_tree().change_scene_to_file(INTERIOR_SCENE)


func _on_level_changed(_new_level: int) -> void:
	_refresh()
