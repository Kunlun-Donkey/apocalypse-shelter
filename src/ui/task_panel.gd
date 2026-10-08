class_name TaskPanel
extends Control
# ============================================================
# 任务面板 (发黄卷轴弹层): 左任务列表 + 右详情 + 接受/放弃任务
# 卷轴底图 assets/blank_scroll_1400x900.png (纯色发黄占位, 用户覆盖同名文件换真卷轴图)
# 任务内容 = 下方 TASKS 常量数组占位 (quest 系统 OFF, 不建 QuestSystem; 用户后续修改内容)
# 已接受状态: 静态内存态 (跨场景保留) + 存档 quest.accepted 字段持久化
# ============================================================

const SCROLL_TEXTURE := "res://assets/blank_scroll_1400x900.png"

# 任务占位内容 (用户后续修改): id 规范 quest.<snake_case>, S2 起迁移 CONF-D quest/*.conf
const TASKS := [
	{"id": "quest.placeholder_01", "name": "任务1", "desc": "任务1 的描述占位, 后续修改。"},
	{"id": "quest.placeholder_02", "name": "任务2", "desc": "任务2 的描述占位, 后续修改。"},
	{"id": "quest.placeholder_03", "name": "任务3", "desc": "任务3 的描述占位, 后续修改。"},
	{"id": "quest.placeholder_04", "name": "任务4", "desc": "任务4 的描述占位, 后续修改。"},
	{"id": "quest.placeholder_05", "name": "任务5", "desc": "任务5 的描述占位, 后续修改。"},
	{"id": "quest.placeholder_06", "name": "任务6", "desc": "任务6 的描述占位, 后续修改。"},
	{"id": "quest.placeholder_07", "name": "任务7", "desc": "任务7 的描述占位, 后续修改。"},
	{"id": "quest.placeholder_08", "name": "任务8", "desc": "任务8 的描述占位, 后续修改。"},
	{"id": "quest.placeholder_09", "name": "任务9", "desc": "任务9 的描述占位, 后续修改。"},
	{"id": "quest.placeholder_10", "name": "任务10", "desc": "任务10 的描述占位, 后续修改。"},
]

# 已接受任务 id 集合 (静态 = 跨场景保留; quest 系统未开启, 仅 UI 层状态)
static var _accepted: Dictionary = {}


static func open(parent: Node) -> TaskPanel:
	var panel := TaskPanel.new()
	panel.name = "TaskPanel"
	parent.add_child(panel)
	return panel


static func get_accepted() -> Array:
	return _accepted.keys()


static func set_accepted(ids: Array) -> void:
	_accepted.clear()
	for id in ids:
		_accepted[str(id)] = true


static func reset() -> void:
	_accepted.clear()


static func is_accepted(id: String) -> bool:
	return _accepted.has(id)


static func accept(id: String) -> void:
	_accepted[id] = true


static func abandon(id: String) -> void:
	_accepted.erase(id)


# ---------------- UI ----------------

var _task_list: ItemList
var _title_label: Label
var _desc_label: Label
var _accept_button: Button
var _abandon_button: Button
var _status_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_refresh_list()
	if _task_list.item_count > 0:
		_task_list.select(0)
		_show_task(0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		queue_free()


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# 卷轴底图 + 内容层 (1400×900 居中)
	var scroll_root := Control.new()
	scroll_root.name = "ScrollRoot"
	scroll_root.custom_minimum_size = Vector2(1400, 900)
	center.add_child(scroll_root)

	var scroll_bg := TextureRect.new()
	scroll_bg.name = "ScrollBg"
	if ResourceLoader.exists(SCROLL_TEXTURE):
		scroll_bg.texture = load(SCROLL_TEXTURE)
	scroll_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scroll_bg.stretch_mode = TextureRect.STRETCH_SCALE
	scroll_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll_root.add_child(scroll_bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 90)
	margin.add_theme_constant_override("margin_right", 90)
	margin.add_theme_constant_override("margin_top", 110)
	margin.add_theme_constant_override("margin_bottom", 90)
	scroll_root.add_child(margin)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 48)
	margin.add_child(columns)

	# ---- 左: 任务列表 ----
	_task_list = ItemList.new()
	_task_list.name = "TaskList"
	_task_list.custom_minimum_size = Vector2(420, 640)
	_task_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_task_list.add_theme_font_size_override("font_size", 24)
	_task_list.item_selected.connect(_on_task_selected)
	columns.add_child(_task_list)

	# ---- 右: 详情 + 接受/放弃 ----
	var detail := VBoxContainer.new()
	detail.add_theme_constant_override("separation", 20)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(detail)

	_title_label = Label.new()
	_title_label.name = "TaskTitle"
	_title_label.add_theme_font_size_override("font_size", 36)
	_title_label.add_theme_color_override("font_color", Color(0.28, 0.18, 0.08))
	detail.add_child(_title_label)

	_desc_label = Label.new()
	_desc_label.name = "TaskDesc"
	_desc_label.add_theme_font_size_override("font_size", 24)
	_desc_label.add_theme_color_override("font_color", Color(0.32, 0.22, 0.12))
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_child(_desc_label)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 24)
	detail.add_child(button_row)

	_accept_button = _make_button("AcceptButton", "接受任务")
	_accept_button.pressed.connect(_on_accept_pressed)
	button_row.add_child(_accept_button)

	_abandon_button = _make_button("AbandonButton", "放弃任务")
	_abandon_button.pressed.connect(_on_abandon_pressed)
	button_row.add_child(_abandon_button)

	_status_label = Label.new()
	_status_label.name = "TaskStatusLabel"
	_status_label.add_theme_font_size_override("font_size", 20)
	_status_label.add_theme_color_override("font_color", Color(0.45, 0.2, 0.1))
	detail.add_child(_status_label)

	var close_button := _make_button("QuestCloseButton", "关闭")
	close_button.pressed.connect(queue_free)
	detail.add_child(close_button)


func _make_button(node_name: String, text: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = Vector2(220, 56)
	button.add_theme_font_size_override("font_size", 24)
	ButtonSkin.apply(button)
	return button


# ---------------- 刷新与交互 ----------------

func _refresh_list() -> void:
	_task_list.clear()
	for task: Dictionary in TASKS:
		var label := str(task.get("name", ""))
		if is_accepted(str(task.get("id", ""))):
			label += " (已接受)"
		_task_list.add_item(label)


func _selected_index() -> int:
	var selected := _task_list.get_selected_items()
	if selected.is_empty():
		return -1
	return selected[0]


func _task_at(index: int) -> Dictionary:
	if index < 0 or index >= TASKS.size():
		return {}
	return TASKS[index]


func _show_task(index: int) -> void:
	var task := _task_at(index)
	if task.is_empty():
		_title_label.text = ""
		_desc_label.text = ""
		_accept_button.disabled = true
		_abandon_button.disabled = true
		return
	var id := str(task.get("id", ""))
	_title_label.text = str(task.get("name", ""))
	_desc_label.text = str(task.get("desc", ""))
	var accepted := is_accepted(id)
	_accept_button.disabled = accepted
	_abandon_button.disabled = not accepted
	_status_label.text = "状态: 已接受" if accepted else "状态: 未接受"


func _on_task_selected(index: int) -> void:
	_show_task(index)


func _on_accept_pressed() -> void:
	var index := _selected_index()
	var task := _task_at(index)
	if task.is_empty():
		return
	var id := str(task.get("id", ""))
	accept(id)
	_status_label.text = "已接受: %s" % str(task.get("name", id))
	_refresh_list()
	if index >= 0:
		_task_list.select(index)
	_show_task(index)


func _on_abandon_pressed() -> void:
	var index := _selected_index()
	var task := _task_at(index)
	if task.is_empty():
		return
	var id := str(task.get("id", ""))
	abandon(id)
	_status_label.text = "已放弃: %s" % str(task.get("name", id))
	_refresh_list()
	if index >= 0:
		_task_list.select(index)
	_show_task(index)
