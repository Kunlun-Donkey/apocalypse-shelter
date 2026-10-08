class_name ShelterStatusPanel
extends Control
# ============================================================
# 庇护所状态面板 (非模态下拉): 房子按钮点击向下展开
# 显示 生命(HP条 当前/上限) / 攻击 / 防御 / 恢复 (逻辑书 B4.3)
# 数据源 = ShelterSystem (建筑加成本期恒 0, S2/S3 接聚合)
# 关闭: 点面板外 (DismissCatcher) / 再点房子按钮 / Esc
# 节点名 Status* 前缀 (测试契约, 防与其他面板撞名)
# ============================================================

const BOX_SIZE := Vector2(460, 330)

const TEXT_MAIN := Color(0.93, 0.91, 0.87)
const TEXT_SUB := Color(0.8, 0.78, 0.74)

static var _current: ShelterStatusPanel = null

var _anchor: Control = null
var _status_box: PanelContainer = null
var _title_label: Label = null
var _hp_bar: ProgressBar = null
var _hp_value: Label = null
var _attack_value: Label = null
var _defense_value: Label = null
var _recovery_value: Label = null
var _shelter: Node = null


static func toggle(parent: Node, anchor: Control) -> void:
	if _current != null and is_instance_valid(_current):
		_current.close()
		return
	var panel := ShelterStatusPanel.new()
	panel.name = "ShelterStatusPanel"
	panel._anchor = anchor  # 必须在 add_child 之前赋值 (_ready 会读它定位)
	_current = panel
	parent.add_child(panel)


func close() -> void:
	_current = null
	queue_free()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	_shelter = get_node_or_null("/root/ShelterSystem")
	if _shelter != null:
		if not _shelter.hp_changed.is_connected(_on_stats_changed):
			_shelter.hp_changed.connect(_on_stats_changed)
		if not _shelter.level_changed.is_connected(_on_stats_changed):
			_shelter.level_changed.connect(_on_stats_changed)
	refresh()
	_place_box()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()


func _on_dismiss_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()


func _on_stats_changed(_a: Variant = null, _b: Variant = null) -> void:
	refresh()


# ---------------- 数据刷新 ----------------

func refresh() -> void:
	if _shelter == null:
		return
	var hp: int = int(_shelter.current_hp)
	var hp_max: int = int(_shelter.get_hp_max())
	_hp_bar.max_value = hp_max
	_hp_bar.value = hp
	_hp_value.text = "%d/%d" % [hp, hp_max]
	_title_label.text = "%s · Lv%d" % [str(_shelter.get_level_name()), int(_shelter.current_level)]
	_attack_value.text = "基础 %d + 建筑 %d" % [
		int(_shelter.get_attack_base()), int(_shelter.get_building_attack_bonus())]
	_defense_value.text = "基础 %d + 建筑 %d" % [
		int(_shelter.get_defense_base()), int(_shelter.get_building_defense_bonus())]
	_recovery_value.text = "%d / 游戏时" % int(_shelter.get_recovery())


# ---------------- UI 构建 ----------------

func _build_ui() -> void:
	var catcher := ColorRect.new()
	catcher.name = "DismissCatcher"
	catcher.color = Color(0, 0, 0, 0)
	catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	catcher.gui_input.connect(_on_dismiss_input)
	add_child(catcher)

	_status_box = PanelContainer.new()
	_status_box.name = "StatusBox"
	_status_box.custom_minimum_size = BOX_SIZE
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = Color(0.08, 0.1, 0.14, 0.97)
	box_style.corner_radius_top_left = 12
	box_style.corner_radius_top_right = 12
	box_style.corner_radius_bottom_left = 12
	box_style.corner_radius_bottom_right = 12
	box_style.content_margin_left = 28
	box_style.content_margin_right = 28
	box_style.content_margin_top = 24
	box_style.content_margin_bottom = 24
	_status_box.add_theme_stylebox_override("panel", box_style)
	_status_box.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_status_box)

	var v := VBoxContainer.new()
	v.name = "StatusVBox"
	v.add_theme_constant_override("separation", 14)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_box.add_child(v)

	_title_label = Label.new()
	_title_label.name = "StatusTitle"
	_title_label.add_theme_font_size_override("font_size", 26)
	_title_label.add_theme_color_override("font_color", TEXT_MAIN)
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_title_label)

	var hp_row := HBoxContainer.new()
	hp_row.name = "StatusHpRow"
	hp_row.add_theme_constant_override("separation", 12)
	hp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(hp_row)
	hp_row.add_child(_make_name_label("StatusHpLabel", "生命"))
	_hp_bar = ProgressBar.new()
	_hp_bar.name = "StatusHpBar"
	_hp_bar.min_value = 0
	_hp_bar.show_percentage = false
	_hp_bar.custom_minimum_size = Vector2(180, 22)
	_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.16, 0.18, 0.22)
	bar_bg.corner_radius_top_left = 6
	bar_bg.corner_radius_top_right = 6
	bar_bg.corner_radius_bottom_left = 6
	bar_bg.corner_radius_bottom_right = 6
	_hp_bar.add_theme_stylebox_override("background", bar_bg)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.72, 0.25, 0.2)
	bar_fill.corner_radius_top_left = 6
	bar_fill.corner_radius_top_right = 6
	bar_fill.corner_radius_bottom_left = 6
	bar_fill.corner_radius_bottom_right = 6
	_hp_bar.add_theme_stylebox_override("fill", bar_fill)
	hp_row.add_child(_hp_bar)
	_hp_value = _make_value_label("StatusHpValue")
	hp_row.add_child(_hp_value)

	_attack_value = _build_stat_row(v, "StatusAttackRow", "StatusAttackLabel", "攻击", "StatusAttackValue")
	_defense_value = _build_stat_row(v, "StatusDefenseRow", "StatusDefenseLabel", "防御", "StatusDefenseValue")
	_recovery_value = _build_stat_row(v, "StatusRecoveryRow", "StatusRecoveryLabel", "恢复", "StatusRecoveryValue")


func _build_stat_row(parent: Node, row_name: String, label_name: String, label_text: String, value_name: String) -> Label:
	var row := HBoxContainer.new()
	row.name = row_name
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(row)
	row.add_child(_make_name_label(label_name, label_text))
	var value := _make_value_label(value_name)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)
	return value


func _make_name_label(label_name: String, text: String) -> Label:
	var label := Label.new()
	label.name = label_name
	label.text = text
	label.custom_minimum_size = Vector2(64, 0)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", TEXT_SUB)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_value_label(value_name: String) -> Label:
	var label := Label.new()
	label.name = value_name
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", TEXT_MAIN)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


# 面板定位于锚点 (房子按钮) 右下, 并 clamp 进视口
func _place_box() -> void:
	if _anchor == null or _status_box == null:
		return
	var anchor_rect: Rect2 = _anchor.get_global_rect()
	var viewport_size: Vector2 = get_viewport_rect().size
	var pos := Vector2(anchor_rect.end.x - BOX_SIZE.x, anchor_rect.end.y + 8)
	pos.x = clampf(pos.x, 8, maxf(8, viewport_size.x - BOX_SIZE.x - 8))
	pos.y = clampf(pos.y, 8, maxf(8, viewport_size.y - BOX_SIZE.y - 8))
	_status_box.global_position = pos
