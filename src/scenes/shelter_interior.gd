extends Control
# ============================================================
# ShelterInterior — 庇护所内部场景 (Dev-S1 极简 UI 壳, blank 占位图, 后续填实际 UI 资源)
# 一房一床极简 + 升级区: 只有 卧室(RoomPanel_1, 床 ×1) + 庇护所升级 (从 main 迁入)
# 同伴名牌: CompanionSlot 按钮显示已入队同伴 (BtnRecruit), 点击开 NpcDetailPanel 详情面板
# 其余房间/家具/建造/资源/入住等玩法系统后续版本开放
# ============================================================

const MAIN_SCENE := "res://src/scenes/main.tscn"

var _shelter: ShelterSystem

var _level_label: Label
var _upgrade_button: Button
var _cooldown_label: Label
var _upgrade_status_label: Label
var _companion_slot: Button


func _ready() -> void:
	_shelter = get_node("/root/ShelterSystem") as ShelterSystem
	_build_ui()
	_shelter.upgrade_started.connect(_on_upgrade_started)
	_shelter.upgrade_completed.connect(_on_upgrade_completed)
	_shelter.level_changed.connect(_on_level_changed)
	_refresh()
	_refresh_companion_slot()


func _process(_delta: float) -> void:
	if _shelter.upgrading:
		_cooldown_label.text = "升级中, 剩余 %.1f 秒" % _shelter.cooldown_remaining


# ---------------- UI ----------------

func _build_ui() -> void:
	# 根节点铺满窗口 (tscn 保持最小写法, 锚点在代码里设)
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := TextureRect.new()
	bg.texture = load(_interior_bg_path())
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

	grid.add_child(_build_room_panel())

	# ---- 升级区 (自 main 迁入) ----
	var upgrade_box := VBoxContainer.new()
	upgrade_box.name = "UpgradeBox"
	upgrade_box.add_theme_constant_override("separation", 10)
	upgrade_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mid_box.add_child(upgrade_box)

	_upgrade_button = Button.new()
	_upgrade_button.name = "UpgradeButton"
	_upgrade_button.text = "升级庇护所"
	_upgrade_button.custom_minimum_size = Vector2(360, 56)
	_upgrade_button.add_theme_font_size_override("font_size", 26)
	_upgrade_button.pressed.connect(_on_upgrade_pressed)
	ButtonSkin.apply(_upgrade_button)
	upgrade_box.add_child(_upgrade_button)

	_cooldown_label = Label.new()
	_cooldown_label.name = "CooldownLabel"
	_cooldown_label.add_theme_font_size_override("font_size", 18)
	_cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cooldown_label.modulate = Color(1, 0.9, 0.6, 0.9)
	upgrade_box.add_child(_cooldown_label)

	_upgrade_status_label = Label.new()
	_upgrade_status_label.name = "UpgradeStatusLabel"
	_upgrade_status_label.add_theme_font_size_override("font_size", 18)
	_upgrade_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_box.add_child(_upgrade_status_label)

	var back_button := Button.new()
	back_button.name = "BackButton"
	back_button.text = "返回主界面"
	back_button.custom_minimum_size = Vector2(360, 56)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.add_theme_font_size_override("font_size", 26)
	back_button.pressed.connect(_on_back_pressed)
	ButtonSkin.apply(back_button)
	root_box.add_child(back_button)


# 室内底图: 按庇护所等级找 shelter_leve%d_inside.png (2.5D 剖面场景图),
# 缺当前级回退 leve1, 仍缺回退 blank 占位 (命名对齐用户素材, 找不到不崩)
func _interior_bg_path() -> String:
	var path := "res://assets/shelter/shelter_leve%d_inside.png" % _shelter.current_level
	if ResourceLoader.exists(path):
		return path
	path = "res://assets/shelter/shelter_leve1_inside.png"
	if ResourceLoader.exists(path):
		return path
	return "res://assets/blank_interior_1920x1080.png"


# 房间面板: 一房一床极简 (占位纹理 + 房名 "卧室" + BedLabel "床 ×1" + "已启用")
# 其余房间/家具后续版本开放
func _build_room_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "RoomPanel_1"
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
	room_name_label.text = "卧室"
	room_name_label.add_theme_font_size_override("font_size", 26)
	room_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(room_name_label)

	var bed_label := Label.new()
	bed_label.name = "BedLabel"
	bed_label.text = "床 ×1"
	bed_label.add_theme_font_size_override("font_size", 22)
	bed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(bed_label)

	var companion_slot := Button.new()
	companion_slot.name = "CompanionSlot"
	companion_slot.custom_minimum_size = Vector2(0, 48)
	companion_slot.add_theme_font_size_override("font_size", 22)
	companion_slot.pressed.connect(_on_companion_slot_pressed)
	ButtonSkin.apply(companion_slot)
	box.add_child(companion_slot)
	_companion_slot = companion_slot

	var status_label := Label.new()
	status_label.text = "已启用"
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(status_label)
	return panel


# ---------------- 刷新 ----------------

func _refresh() -> void:
	_level_label.text = "Lv%d %s" % [_shelter.current_level, _shelter.get_level_name()]
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


# 同伴名牌刷新 (只读 BtnRecruit 状态; 不接信号不每帧, 由调用方按需刷新)
func _refresh_companion_slot() -> void:
	if _companion_slot == null:
		return
	var picked_id: String = BtnRecruit.get_picked_id()
	if picked_id.is_empty():
		_companion_slot.text = "同伴: 空 (未招募)"
		_companion_slot.disabled = true
		return
	var npc_name := ""
	var npc_title := ""
	for entry: Dictionary in BtnRecruit.NPC_DATA:
		if str(entry.get("id", "")) == picked_id:
			npc_name = str(entry.get("name", ""))
			npc_title = str(entry.get("title", ""))
			break
	_companion_slot.text = "同伴: %s · %s" % [npc_name, npc_title]
	_companion_slot.disabled = false


# ---------------- 交互 ----------------

func _on_upgrade_pressed() -> void:
	if _shelter.start_upgrade():
		_upgrade_status_label.text = "开始升级..."
		_refresh()
	else:
		_upgrade_status_label.text = "当前无法升级"
	_refresh()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE)


func _on_companion_slot_pressed() -> void:
	var picked_id: String = BtnRecruit.get_picked_id()
	if picked_id.is_empty():
		return
	NpcDetailPanel.open(self, picked_id)


func _on_upgrade_started(_cooldown: float) -> void:
	_refresh()


func _on_upgrade_completed(new_level: int) -> void:
	_upgrade_status_label.text = "升级完成: Lv%d %s" % [new_level, _shelter.get_level_name(new_level)]
	_refresh()


func _on_level_changed(_new_level: int) -> void:
	_refresh()
