extends Control
# ============================================================
# ShelterInterior — 庇护所内部场景 (Dev-S1 纯 UI 壳, blank 占位图, 后续填实际 UI 资源)
# 房间剖面网格: 上层 卧室/储藏室/厨房, 下层 工作台/大门, 解锁状态只读展示 (按建筑位)
# 建造/资源/入住等玩法系统 OFF, 房间操作 S2 开放
# ============================================================

const MAIN_SCENE := "res://src/scenes/main.tscn"

const ROOM_COUNT := 5
const TOP_ROW_COUNT := 3
const ROOM_LABELS := ["卧室", "储藏室", "厨房", "工作台", "大门"]

var _shelter: ShelterSystem

var _level_label: Label
var _summary_label: Label
var _room_status_labels: Array[Label] = []


func _ready() -> void:
	_shelter = get_node("/root/ShelterSystem") as ShelterSystem
	_build_ui()
	_refresh()


# ---------------- UI ----------------

func _build_ui() -> void:
	# 根节点铺满窗口 (tscn 保持最小写法, 锚点在代码里设)
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := TextureRect.new()
	bg.texture = load("res://assets/blank_interior_1920x1080.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 24)
	root_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_box.offset_left = 48.0
	root_box.offset_top = 28.0
	root_box.offset_right = -48.0
	root_box.offset_bottom = -28.0
	add_child(root_box)

	var top_box := VBoxContainer.new()
	top_box.add_theme_constant_override("separation", 8)
	root_box.add_child(top_box)

	var title_label := Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "庇护所内部"
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_box.add_child(title_label)

	_level_label = Label.new()
	_level_label.name = "LevelLabel"
	_level_label.add_theme_font_size_override("font_size", 28)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_label.modulate = Color(1, 1, 1, 0.85)
	top_box.add_child(_level_label)

	var mid_box := VBoxContainer.new()
	mid_box.add_theme_constant_override("separation", 20)
	mid_box.alignment = BoxContainer.ALIGNMENT_CENTER
	mid_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(mid_box)

	var grid := VBoxContainer.new()
	grid.name = "RoomGrid"
	grid.add_theme_constant_override("separation", 20)
	mid_box.add_child(grid)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 24)
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	grid.add_child(top_row)
	for i: int in range(TOP_ROW_COUNT):
		top_row.add_child(_build_room_panel(i))

	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 24)
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	grid.add_child(bottom_row)
	for i: int in range(TOP_ROW_COUNT, ROOM_COUNT):
		bottom_row.add_child(_build_room_panel(i))

	_summary_label = Label.new()
	_summary_label.name = "RoomSummary"
	_summary_label.add_theme_font_size_override("font_size", 22)
	_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid_box.add_child(_summary_label)

	var back_button := Button.new()
	back_button.name = "BackButton"
	back_button.text = "返回主界面"
	back_button.custom_minimum_size = Vector2(360, 56)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.add_theme_font_size_override("font_size", 26)
	back_button.pressed.connect(_on_back_pressed)
	ButtonSkin.apply(back_button)
	root_box.add_child(back_button)


# 房间面板: 占位纹理 + 房间名 + 解锁状态 (只读, 房间操作 S2 开放)
func _build_room_panel(room_index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "RoomPanel_%d" % (room_index + 1)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.1, 0.85)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var room_texture := TextureRect.new()
	room_texture.texture = load("res://assets/blank_room_panel_512x512.png")
	room_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	room_texture.custom_minimum_size = Vector2(300, 220)
	room_texture.stretch_mode = TextureRect.STRETCH_SCALE
	box.add_child(room_texture)

	var room_name_label := Label.new()
	room_name_label.text = str(ROOM_LABELS[room_index])
	room_name_label.add_theme_font_size_override("font_size", 26)
	room_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(room_name_label)

	var status_label := Label.new()
	status_label.name = "RoomStatus_%d" % (room_index + 1)
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(status_label)
	_room_status_labels.append(status_label)
	return panel


# ---------------- 刷新 ----------------

# 只读展示: 等级 + 房间解锁状态 (房间序号 <= building_slots 视为已解锁)
func _refresh() -> void:
	_level_label.text = "Lv%d %s" % [_shelter.current_level, _shelter.get_level_name()]
	var stats: Dictionary = _shelter.get_level_stats()
	var slots: int = int(stats.get("building_slots", 0))
	var unlocked: int = 0
	for i: int in range(_room_status_labels.size()):
		var status_label: Label = _room_status_labels[i]
		if i + 1 <= slots:
			status_label.text = "已解锁 (S2 开放操作)"
			unlocked += 1
		else:
			status_label.text = "未解锁 (升级解锁)"
	_summary_label.text = "房间解锁 %d/5 | 升级庇护所解锁更多房间" % unlocked


# ---------------- 交互 ----------------

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE)
