class_name BtnRecruit
extends Button
# ============================================================
# 招募按钮 + NPC 招募介绍面板 (木板卡片三选一)
# 挂载: 作为主界面 BottomBar 的 "招募" 按钮 (节点名 Btn_Recruit)
# 交互: 点击按钮 开/关 面板 (默认隐藏); 点击全屏遮罩关闭; 每卡"招募"按钮选人入队 → 面板关闭 → 成功弹窗
#   锁定后 (已选 1 名) 仍可开面板查看三人资料, 三个招募按钮全禁用 (选中卡文案"已招募"); 整卡点击无效
# 素材: res://assets/npc_recruit/ (board.png 木板 / diamond_purple.png 紫钻 / bar_*.png 属性条, 占位可覆盖)
# NPC_DATA 字典 = 唯一数据源: 改数值/换钻石/改文案只动字典 (id 对应 configs/npcs/*.conf)
# 已选状态: 归 NpcSystem (单一数据源, 存 config_id); 本层为"姓名门面"兼容旧接口
#   - 有 /root/NpcSystem: 静态函数透传 NpcSystem (recruit/set_state/new_game)
#   - 无 NpcSystem (navtest/settest 等): 降级用静态 _picked 姓名缓存
# 存档字段: npc.picked=config_id (主) + recruit.picked=姓名镜像 (兼容)
# ============================================================

const BOARD_TEXTURE := "res://assets/npc_recruit/board.png"
const BAR_UNDER_TEXTURE := "res://assets/npc_recruit/bar_under.png"
const BAR_FILL_TEXTURE := "res://assets/npc_recruit/bar_fill.png"
const ATTR_MAX := 10.0

const BROWN_DARK := Color(0.28, 0.18, 0.08)
const BROWN_TEXT := Color(0.32, 0.22, 0.12)

# 三名候选同伴 (顺序即卡片顺序; attrs 最多 3 条, 数值上限 ATTR_MAX=10)
const NPC_DATA := [
	{
		"id": "npc.veteran_01",
		"name": "唐文轩",
		"title": "老兵",
		"familiarity": 35,
		"attrs": [["体力", 8], ["生存", 7], ["智慧", 4]],
		"desc": "曾经驻守边疆的老兵, 灾难爆发后带领小队逃到避难所。熟悉野外搜寻与物资保存, 做事沉稳可靠, 擅长外出搜集食物资源。",
		"passive_title": "【觅食专长】",
		"passive_desc": "提升全队获取食物的速度。",
		"active_title": "【紧急搜刮】",
		"active_desc": "一次性获得一定数量食物。",
		"diamond": "res://assets/npc_recruit/diamond_purple.png",
	},
	{
		"id": "npc.medic_01",
		"name": "张睿",
		"title": "医师",
		"familiarity": 35,
		"attrs": [["体力", 4], ["生存", 6], ["智慧", 9]],
		"desc": "灾前在公立医院任职外科医师, 灾难后跟随幸存者小队四处转移。精通急救与创伤处理, 能有效降低行动中的人员损失。",
		"passive_title": "【应急救护】",
		"passive_desc": "减少外出任务里幸存者的伤亡概率。",
		"active_title": "【集中救治】",
		"active_desc": "一次性治疗一定数量受伤幸存者。",
		"diamond": "res://assets/npc_recruit/diamond_purple.png",
	},
	{
		"id": "npc.engineer_01",
		"name": "吴齐越",
		"title": "工程师",
		"familiarity": 35,
		"attrs": [["体力", 5], ["生存", 5], ["智慧", 10]],
		"desc": "灾前从事机械与自动化设备研发, 灾难爆发后留守在城市废墟, 擅长维修、改造防御设施与机械装置。",
		"passive_title": "【城防强化】",
		"passive_desc": "提升据点城防的攻击威力。",
		"active_title": "【机械守卫】",
		"active_desc": "召唤一台具备攻击力的机器人, 协助参与战斗。",
		"diamond": "res://assets/npc_recruit/diamond_purple.png",
	},
]

# 已选同伴降级缓存 (存中文姓名; 无 NpcSystem 时用, 静态 = 跨场景保留)
static var _picked := ""


# 取 NpcSystem (boot.gd 实例化于 /root/NpcSystem); 拿不到返回 null (navtest/settest 无此系统)
static func _sys() -> NpcSystem:
	var ml := Engine.get_main_loop()
	if ml == null:
		return null
	var sys := (ml as SceneTree).root.get_node_or_null("NpcSystem") as NpcSystem
	return sys


static func get_picked() -> String:
	var sys := _sys()
	if sys != null:
		return sys.get_picked_name()
	return _picked


static func set_picked(npc_name: String) -> void:
	var sys := _sys()
	if sys != null:
		sys.set_state({"picked": npc_name})
		return
	_picked = npc_name


static func reset() -> void:
	var sys := _sys()
	if sys != null:
		sys.new_game()
	_picked = ""


static func is_picked(npc_name: String) -> bool:
	return get_picked_name() == npc_name and npc_name != ""


static func get_picked_name() -> String:
	var sys := _sys()
	if sys != null:
		return sys.get_picked_name()
	return _picked


static func get_picked_id() -> String:
	var sys := _sys()
	if sys != null:
		return sys.get_picked_id()
	return ""


# ---------------- 面板 ----------------

var _panel: Control
var _card_styles: Array[StyleBoxFlat] = []
var _recruit_buttons: Array[Button] = []


func _ready() -> void:
	_panel = _build_panel()
	_panel.visible = false
	_find_scene_root().add_child(_panel)
	pressed.connect(_on_button_pressed)


func _find_scene_root() -> Node:
	var node: Node = self
	while node.get_parent() != null and not (node.get_parent() is Window):
		node = node.get_parent()
	return node


func _on_button_pressed() -> void:
	_panel.visible = not _panel.visible


func _on_mask_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_panel.visible = false


func _on_recruit_pressed(index: int) -> void:
	# 一次性锁定: 已选不可换
	if get_picked_name() != "":
		return
	var npc: Dictionary = NPC_DATA[index]
	var picked_name := str(npc.get("name", ""))
	var sys := _sys()
	if sys != null:
		if not sys.recruit(str(npc.get("id", ""))):
			return
	else:
		set_picked(picked_name)
	_refresh_picked()
	_panel.visible = false
	_show_success_popup(picked_name)


func _refresh_picked() -> void:
	var picked_name := get_picked_name()
	for i in _card_styles.size():
		var picked := picked_name == str(NPC_DATA[i].get("name", "")) and picked_name != ""
		_card_styles[i].border_color = BROWN_DARK if picked else Color(0, 0, 0, 0)
		if i < _recruit_buttons.size():
			var btn := _recruit_buttons[i]
			btn.disabled = picked_name != ""
			btn.text = "已招募" if picked else "招募"


# ---------------- 成功弹窗 ----------------

func _show_success_popup(npc_name: String) -> void:
	var panel := Control.new()
	panel.name = "RecruitSuccessPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var mask := ColorRect.new()
	mask.name = "RecruitSuccessMask"
	mask.color = Color(0, 0, 0, 0.55)
	mask.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(mask)

	var center := CenterContainer.new()
	center.name = "RecruitSuccessCenter"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(center)

	var box := PanelContainer.new()
	box.name = "RecruitSuccessBox"
	box.custom_minimum_size = Vector2(520, 240)
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

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	box.add_child(v)

	var label := Label.new()
	label.name = "RecruitSuccessLabel"
	label.text = "成功招募 %s！可在庇护所内查看详细信息" % npc_name
	label.add_theme_font_size_override("font_size", 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(label)

	var ok_button := Button.new()
	ok_button.name = "RecruitSuccessOkButton"
	ok_button.text = "确定"
	ok_button.custom_minimum_size = Vector2(200, 52)
	ButtonSkin.apply(ok_button)
	ok_button.pressed.connect(panel.queue_free)
	v.add_child(ok_button)

	_find_scene_root().add_child(panel)


# ---------------- UI 构建 ----------------

func _build_panel() -> Control:
	var root := Control.new()
	root.name = "RecruitPanel"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)

	var mask := ColorRect.new()
	mask.name = "Mask"
	mask.color = Color(0, 0, 0, 0.55)
	mask.set_anchors_preset(Control.PRESET_FULL_RECT)
	mask.gui_input.connect(_on_mask_input)
	root.add_child(mask)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var box := PanelContainer.new()
	box.name = "RecruitBox"
	box.custom_minimum_size = Vector2(1400, 760)
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = Color(0.08, 0.1, 0.14, 0.97)
	box_style.corner_radius_top_left = 12
	box_style.corner_radius_top_right = 12
	box_style.corner_radius_bottom_left = 12
	box_style.corner_radius_bottom_right = 12
	box_style.content_margin_left = 36
	box_style.content_margin_right = 36
	box_style.content_margin_top = 28
	box_style.content_margin_bottom = 28
	box.add_theme_stylebox_override("panel", box_style)
	center.add_child(box)

	var row := HBoxContainer.new()
	row.name = "CardRow"
	row.add_theme_constant_override("separation", 30)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)

	for i in NPC_DATA.size():
		row.add_child(_build_card(i))
	_refresh_picked()
	return root


func _build_card(index: int) -> PanelContainer:
	var npc: Dictionary = NPC_DATA[index]
	var slot := index + 1

	var card := PanelContainer.new()
	card.name = "NpcCard_%d" % slot
	card.custom_minimum_size = Vector2(380, 680)
	var card_style := StyleBoxFlat.new()
	card_style.border_width_left = 3
	card_style.border_width_top = 3
	card_style.border_width_right = 3
	card_style.border_width_bottom = 3
	card_style.border_color = Color(0, 0, 0, 0)
	card_style.content_margin_left = 3
	card_style.content_margin_right = 3
	card_style.content_margin_top = 3
	card_style.content_margin_bottom = 3
	card.add_theme_stylebox_override("panel", card_style)
	_card_styles.append(card_style)

	# 木板底层 (铺满卡片; 与内容层同占 PanelContainer 内容区)
	var board := TextureRect.new()
	board.name = "BoardBg"
	if ResourceLoader.exists(BOARD_TEXTURE):
		board.texture = load(BOARD_TEXTURE)
	board.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	board.stretch_mode = TextureRect.STRETCH_SCALE
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(board)

	var margin := MarginContainer.new()
	margin.name = "CardContent"
	for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 25)
	card.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(v)

	# ① 钻石 (顶部居中 80×80, 资源路径来自字典)
	var diamond := TextureRect.new()
	diamond.name = "Diamond_%d" % slot
	var diamond_path := str(npc.get("diamond", ""))
	if ResourceLoader.exists(diamond_path):
		diamond.texture = load(diamond_path)
	diamond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	diamond.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	diamond.custom_minimum_size = Vector2(80, 80)
	diamond.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	diamond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(diamond)

	# ② 姓名 (大号) + 职业 (中号)
	var name_label := Label.new()
	name_label.name = "NpcName_%d" % slot
	name_label.text = str(npc.get("name", ""))
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", BROWN_DARK)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(name_label)

	var title_label := Label.new()
	title_label.name = "NpcTitle_%d" % slot
	title_label.text = str(npc.get("title", ""))
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", BROWN_TEXT)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title_label)

	# ③ 熟悉度 (中号)
	var fam_label := Label.new()
	fam_label.name = "Familiarity_%d" % slot
	fam_label.text = "熟悉度: %d" % int(npc.get("familiarity", 0))
	fam_label.add_theme_font_size_override("font_size", 22)
	fam_label.add_theme_color_override("font_color", BROWN_TEXT)
	fam_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(fam_label)

	# ④ 属性条 (最多 3 条, TextureProgressBar max=10)
	var attrs: Array = npc.get("attrs", [])
	for i in mini(attrs.size(), 3):
		v.add_child(_build_attr_row(slot, i, attrs[i]))

	# ⑤ 背景描述 (小号多行自动换行)
	var desc_label := Label.new()
	desc_label.name = "Desc_%d" % slot
	desc_label.text = str(npc.get("desc", ""))
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", BROWN_TEXT)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(desc_label)

	# ⑥ 被动技能 + 主动技能 (标题 + 描述)
	v.add_child(_build_skill_block("PassiveTitle_%d" % slot, "PassiveDesc_%d" % slot,
		str(npc.get("passive_title", "")), str(npc.get("passive_desc", ""))))
	v.add_child(_build_skill_block("ActiveTitle_%d" % slot, "ActiveDesc_%d" % slot,
		str(npc.get("active_title", "")), str(npc.get("active_desc", ""))))

	var recruit_button := Button.new()
	recruit_button.name = "RecruitButton_%d" % slot
	recruit_button.text = "招募"
	recruit_button.custom_minimum_size = Vector2(0, 48)
	recruit_button.pressed.connect(_on_recruit_pressed.bind(index))
	ButtonSkin.apply(recruit_button)
	v.add_child(recruit_button)
	_recruit_buttons.append(recruit_button)

	return card


func _build_attr_row(slot: int, attr_index: int, attr: Variant) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "AttrRow_%d_%d" % [slot, attr_index + 1]
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var attr_name := Label.new()
	attr_name.name = "AttrName_%d_%d" % [slot, attr_index + 1]
	attr_name.text = str(attr[0])
	attr_name.add_theme_font_size_override("font_size", 18)
	attr_name.add_theme_color_override("font_color", BROWN_TEXT)
	attr_name.custom_minimum_size = Vector2(52, 26)
	row.add_child(attr_name)

	var bar := TextureProgressBar.new()
	bar.name = "AttrBar_%d_%d" % [slot, attr_index + 1]
	bar.min_value = 0.0
	bar.max_value = ATTR_MAX
	bar.value = float(attr[1])
	bar.custom_minimum_size = Vector2(180, 22)
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
	value_label.name = "AttrValue_%d_%d" % [slot, attr_index + 1]
	value_label.text = str(int(attr[1]))
	value_label.add_theme_font_size_override("font_size", 18)
	value_label.add_theme_color_override("font_color", BROWN_TEXT)
	value_label.custom_minimum_size = Vector2(32, 26)
	row.add_child(value_label)

	return row


func _build_skill_block(title_name: String, desc_name: String, title_text: String, desc_text: String) -> VBoxContainer:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 2)
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var title := Label.new()
	title.name = title_name
	title.text = title_text
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", BROWN_DARK)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	block.add_child(title)

	var desc := Label.new()
	desc.name = desc_name
	desc.text = desc_text
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", BROWN_TEXT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	block.add_child(desc)

	return block
