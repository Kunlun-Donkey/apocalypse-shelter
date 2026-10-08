extends Control
# ============================================================
# Login — 登录/开始界面 (背景 assets/blank_login_1920x1080.png, 后续填实际 UI 资源)
# 菜单垂直居中: 继续游戏(最近存档) / 新的游戏 / 读取存档(槽位弹层) / 设置 / 退出游戏
# ============================================================

const MAIN_SCENE := "res://src/scenes/main.tscn"

var _status_label: Label
var _continue_button: Button
var _slot_panel: Control
var _slot_buttons: Array[Button] = []


func _ready() -> void:
	_build_ui()
	_refresh_slots()


func _build_ui() -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://assets/blank_login_1920x1080.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	center.add_child(box)

	var title := Label.new()
	title.text = "末日庇护所"
	title.add_theme_font_size_override("font_size", 72)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Apocalypse Shelter"
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.modulate = Color(1, 1, 1, 0.7)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)

	_continue_button = _make_menu_button("ContinueGameButton", "继续游戏", _on_continue_game)
	box.add_child(_continue_button)

	var new_button := _make_menu_button("NewGameButton", "新的游戏", _on_new_game)
	box.add_child(new_button)

	var load_button := _make_menu_button("LoadGameButton", "读取存档", _on_load_pressed)
	box.add_child(load_button)

	if ConfigManager.is_enabled("settings"):
		var settings_button := _make_menu_button("SettingsButton", "设置", _on_settings_pressed)
		box.add_child(settings_button)

	var quit_button := _make_menu_button("QuitGameButton", "退出游戏", _on_quit_game)
	box.add_child(quit_button)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 20)
	box.add_child(_status_label)

	_build_slot_panel()


func _make_menu_button(node_name: String, text: String, handler: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = Vector2(360, 64)
	button.add_theme_font_size_override("font_size", 28)
	button.pressed.connect(handler)
	ButtonSkin.apply(button)
	return button


# ---------------- 存档槽位弹层 ----------------

func _build_slot_panel() -> void:
	_slot_panel = Control.new()
	_slot_panel.name = "SlotPanel"
	_slot_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_slot_panel.visible = false
	add_child(_slot_panel)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_slot_panel.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_slot_panel.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	center.add_child(box)

	var panel_title := Label.new()
	panel_title.text = "选择存档"
	panel_title.add_theme_font_size_override("font_size", 40)
	panel_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(panel_title)

	for slot in range(1, SaveManager.get_slot_count() + 1):
		var slot_button := _make_menu_button(
			"SlotButton_%d" % slot, "存档 %d" % slot,
			_on_slot_button_pressed.bind(slot))
		_slot_buttons.append(slot_button)
		box.add_child(slot_button)

	var back_button := _make_menu_button("SlotBackButton", "返回", _on_slot_back_pressed)
	box.add_child(back_button)


func _refresh_slots() -> void:
	_continue_button.disabled = SaveManager.find_latest_slot() == 0
	for slot in range(1, SaveManager.get_slot_count() + 1):
		var button: Button = _slot_buttons[slot - 1]
		var suffix := " (空)" if not SaveManager.has_save(slot) else " (有存档)"
		button.text = "存档 %d%s" % [slot, suffix]
		button.disabled = not SaveManager.has_save(slot)


# ---------------- 交互 ----------------

func _on_continue_game() -> void:
	var slot := SaveManager.find_latest_slot()
	if slot == 0:
		_status_label.text = "没有可继续的存档"
		return
	_load_slot(slot)


func _on_new_game() -> void:
	var shelter := get_node("/root/ShelterSystem") as ShelterSystem
	shelter.new_game()
	TimeManager.new_game()
	TaskPanel.reset()
	BtnRecruit.reset()
	get_tree().change_scene_to_file(MAIN_SCENE)


func _on_load_pressed() -> void:
	_refresh_slots()
	_slot_panel.visible = true


func _on_slot_button_pressed(slot: int) -> void:
	_slot_panel.visible = false
	_load_slot(slot)


func _on_slot_back_pressed() -> void:
	_slot_panel.visible = false


func _load_slot(slot: int) -> void:
	var data := SaveManager.load_game(slot)
	if data.is_empty():
		_status_label.text = "读档失败: 存档损坏或为空"
		return
	var shelter := get_node("/root/ShelterSystem") as ShelterSystem
	shelter.set_state(data.get("shelter", {}))
	TimeManager.set_state(data.get("time", {}))
	var quest: Dictionary = data.get("quest", {})
	TaskPanel.set_accepted(quest.get("accepted", []))
	var recruit: Dictionary = data.get("recruit", {})
	BtnRecruit.set_picked(str(recruit.get("picked", "")))
	get_tree().change_scene_to_file(MAIN_SCENE)


func _on_settings_pressed() -> void:
	SettingsOverlay.open(self)


func _on_quit_game() -> void:
	get_tree().quit()
