class_name NpcDetailPanel
extends Control
# ============================================================
# NPC 详情面板 (同伴详情弹层): 查看已入队同伴的完整信息 (只读)
# 数据源 = BtnRecruit.NPC_DATA 常量字典 (按 id 匹配), 不建 NpcDetailSystem
# 用法: NpcDetailPanel.open(parent, npc_id); Esc / 点遮罩关闭
# 节点名 Detail* 前缀 (测试契约, 防与招募卡撞名)
# ============================================================

const BAR_UNDER_TEXTURE := "res://assets/npc_recruit/bar_under.png"
const BAR_FILL_TEXTURE := "res://assets/npc_recruit/bar_fill.png"
const ATTR_MAX := 10.0

const TEXT_MAIN := Color(0.93, 0.91, 0.87)
const TEXT_SUB := Color(0.8, 0.78, 0.74)

var _npc: Dictionary = {}


static func open(parent: Node, npc_id: String) -> NpcDetailPanel:
	var npc: Dictionary = _find_npc(npc_id)
	if npc.is_empty():
		push_warning("NpcDetailPanel: 未找到 NPC id=%s" % npc_id)
		return null
	var panel := NpcDetailPanel.new()
	panel.name = "NpcDetailPanel"
	panel._npc = npc  # 必须在 add_child 之前赋值 (_ready/_build_ui 会读它)
	parent.add_child(panel)
	return panel


static func _find_npc(npc_id: String) -> Dictionary:
	for entry: Dictionary in BtnRecruit.NPC_DATA:
		if str(entry.get("id", "")) == npc_id:
			return entry
	return {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		queue_free()


func _on_mask_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		queue_free()


# ---------------- UI 构建 ----------------

func _build_ui() -> void:
	var mask := ColorRect.new()
	mask.name = "DetailMask"
	mask.color = Color(0, 0, 0, 0.55)
	mask.set_anchors_preset(Control.PRESET_FULL_RECT)
	mask.mouse_filter = Control.MOUSE_FILTER_STOP
	mask.gui_input.connect(_on_mask_input)
	add_child(mask)

	var center := CenterContainer.new()
	center.name = "DetailCenter"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var box := PanelContainer.new()
	box.name = "DetailBox"
	box.custom_minimum_size = Vector2(680, 920)
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = Color(0.08, 0.1, 0.14, 0.97)
	box_style.corner_radius_top_left = 12
	box_style.corner_radius_top_right = 12
	box_style.corner_radius_bottom_left = 12
	box_style.corner_radius_bottom_right = 12
	box_style.content_margin_left = 32
	box_style.content_margin_right = 32
	box_style.content_margin_top = 32
	box_style.content_margin_bottom = 32
	box.add_theme_stylebox_override("panel", box_style)
	center.add_child(box)

	var margin := MarginContainer.new()
	margin.name = "DetailContent"
	box.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(v)

	# ① 钻石 (顶部居中 80×80, 资源路径来自字典)
	var diamond := TextureRect.new()
	diamond.name = "DetailDiamond"
	var diamond_path := str(_npc.get("diamond", ""))
	if ResourceLoader.exists(diamond_path):
		diamond.texture = load(diamond_path)
	diamond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	diamond.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	diamond.custom_minimum_size = Vector2(80, 80)
	diamond.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	diamond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(diamond)

	# ② 姓名 / 称号 / 熟悉度
	var name_label := Label.new()
	name_label.name = "DetailName"
	name_label.text = str(_npc.get("name", ""))
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", TEXT_MAIN)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(name_label)

	var title_label := Label.new()
	title_label.name = "DetailTitle"
	title_label.text = str(_npc.get("title", ""))
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", TEXT_SUB)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title_label)

	var fam_label := Label.new()
	fam_label.name = "DetailFamiliarity"
	fam_label.text = "熟悉度: %d" % int(_npc.get("familiarity", 0))
	fam_label.add_theme_font_size_override("font_size", 22)
	fam_label.add_theme_color_override("font_color", TEXT_SUB)
	fam_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(fam_label)

	# ③ 属性条 (N=1..attrs.size(), 最多 3 条)
	var attrs: Array = _npc.get("attrs", [])
	for i in mini(attrs.size(), 3):
		v.add_child(_build_attr_row(i + 1, attrs[i]))

	# ④ 背景描述 (小号多行自动换行, 撑满剩余高度)
	var desc_label := Label.new()
	desc_label.name = "DetailDesc"
	desc_label.text = str(_npc.get("desc", ""))
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", TEXT_SUB)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(desc_label)

	# ⑤ 被动技能 + 主动技能 (标题 + 描述)
	v.add_child(_build_skill_block("DetailPassiveTitle", "DetailPassiveDesc",
		str(_npc.get("passive_title", "")), str(_npc.get("passive_desc", ""))))
	v.add_child(_build_skill_block("DetailActiveTitle", "DetailActiveDesc",
		str(_npc.get("active_title", "")), str(_npc.get("active_desc", ""))))


# 属性行 (N=1 起; 写法照抄 btn_recruit.gd _build_attr_row)
func _build_attr_row(index: int, attr: Variant) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "DetailAttrRow_%d" % index
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var attr_name := Label.new()
	attr_name.name = "DetailAttrName_%d" % index
	attr_name.text = str(attr[0])
	attr_name.add_theme_font_size_override("font_size", 18)
	attr_name.add_theme_color_override("font_color", TEXT_SUB)
	attr_name.custom_minimum_size = Vector2(52, 26)
	row.add_child(attr_name)

	var bar := TextureProgressBar.new()
	bar.name = "DetailAttrBar_%d" % index
	bar.min_value = 0.0
	bar.max_value = ATTR_MAX
	bar.value = float(attr[1])
	bar.custom_minimum_size = Vector2(220, 22)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(BAR_UNDER_TEXTURE):
		bar.texture_under = load(BAR_UNDER_TEXTURE)
		bar.nine_patch_stretch = true
	if ResourceLoader.exists(BAR_FILL_TEXTURE):
		bar.texture_progress = load(BAR_FILL_TEXTURE)
		bar.texture_progress_offset = Vector2(2, 2)
	row.add_child(bar)

	var value_label := Label.new()
	value_label.name = "DetailAttrValue_%d" % index
	value_label.text = str(int(attr[1]))
	value_label.add_theme_font_size_override("font_size", 18)
	value_label.add_theme_color_override("font_color", TEXT_SUB)
	value_label.custom_minimum_size = Vector2(32, 26)
	row.add_child(value_label)

	return row


func _build_skill_block(title_name: String, desc_name: String, title_text: String, desc_text: String) -> VBoxContainer:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 2)
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var skill_title := Label.new()
	skill_title.name = title_name
	skill_title.text = title_text
	skill_title.add_theme_font_size_override("font_size", 18)
	skill_title.add_theme_color_override("font_color", TEXT_MAIN)
	skill_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	block.add_child(skill_title)

	var skill_desc := Label.new()
	skill_desc.name = desc_name
	skill_desc.text = desc_text
	skill_desc.add_theme_font_size_override("font_size", 15)
	skill_desc.add_theme_color_override("font_color", TEXT_SUB)
	skill_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	block.add_child(skill_desc)

	return block
