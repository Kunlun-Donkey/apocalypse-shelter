extends Control
# ============================================================
# Login — 登录/开始界面 (背景 assets/blank_login_1920x1080.png, 后续填实际 UI 资源)
# 新游戏 = Lv1 开局; 读取存档 = 载入所选槽位后进 Main
# ============================================================

const MAIN_SCENE := "res://src/scenes/main.tscn"

var _slot_option: OptionButton
var _load_button: Button
var _status_label: Label


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

	var new_button := Button.new()
	new_button.name = "NewGameButton"
	new_button.text = "开始新游戏"
	new_button.custom_minimum_size = Vector2(360, 64)
	new_button.add_theme_font_size_override("font_size", 28)
	new_button.pressed.connect(_on_new_game)
	ButtonSkin.apply(new_button)
	box.add_child(new_button)

	var load_row := HBoxContainer.new()
	load_row.add_theme_constant_override("separation", 16)
	load_row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(load_row)

	_slot_option = OptionButton.new()
	_slot_option.name = "SlotOption"
	_slot_option.custom_minimum_size = Vector2(160, 64)
	_slot_option.add_theme_font_size_override("font_size", 24)
	_slot_option.item_selected.connect(_on_slot_selected)
	load_row.add_child(_slot_option)

	_load_button = Button.new()
	_load_button.name = "LoadGameButton"
	_load_button.text = "读取存档"
	_load_button.custom_minimum_size = Vector2(184, 64)
	_load_button.add_theme_font_size_override("font_size", 28)
	_load_button.pressed.connect(_on_load_game)
	ButtonSkin.apply(_load_button)
	load_row.add_child(_load_button)

	if ConfigManager.is_enabled("settings"):
		var settings_button := Button.new()
		settings_button.name = "SettingsButton"
		settings_button.text = "设置"
		settings_button.custom_minimum_size = Vector2(360, 52)
		settings_button.add_theme_font_size_override("font_size", 24)
		settings_button.pressed.connect(_on_settings_pressed)
		ButtonSkin.apply(settings_button)
		box.add_child(settings_button)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 20)
	box.add_child(_status_label)


func _refresh_slots() -> void:
	_slot_option.clear()
	for slot in range(1, SaveManager.get_slot_count() + 1):
		var suffix := " (空)" if not SaveManager.has_save(slot) else " (有存档)"
		_slot_option.add_item("存档 %d%s" % [slot, suffix], slot)
	_slot_option.select(0)
	_on_slot_selected(0)


func _selected_slot() -> int:
	if _slot_option.get_item_count() == 0:
		return 1
	return _slot_option.get_selected_id()


func _on_slot_selected(_index: int) -> void:
	var slot := _selected_slot()
	_load_button.disabled = not SaveManager.has_save(slot)
	_status_label.text = "" if not _load_button.disabled else "该槽位没有存档"


func _on_settings_pressed() -> void:
	SettingsOverlay.open(self)


func _on_new_game() -> void:
	var shelter := get_node("/root/ShelterSystem") as ShelterSystem
	shelter.new_game()
	TimeManager.new_game()
	get_tree().change_scene_to_file(MAIN_SCENE)


func _on_load_game() -> void:
	var slot := _selected_slot()
	var data := SaveManager.load_game(slot)
	if data.is_empty():
		_status_label.text = "读档失败: 存档损坏或为空"
		return
	var shelter := get_node("/root/ShelterSystem") as ShelterSystem
	shelter.set_state(data.get("shelter", {}))
	TimeManager.set_state(data.get("time", {}))
	get_tree().change_scene_to_file(MAIN_SCENE)
