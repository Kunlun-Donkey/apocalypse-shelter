extends Node3D
# ============================================================
# ShelterInterior — 庇护所内部场景 (Dev-S1)
# 根节点 Node3D, 编辑器 3D 视图可见可拖拽
# 2D UI 挂 CanvasLayer(UILayer), TileGrid 保留(测试契约, modulate.a=0)
# ============================================================

const MAIN_SCENE := "res://src/scenes/main.tscn"
const FLOOR_GLB_PATH := "res://assets/shelter/floor.glb"
const FLOOR_TILE_SPACING := 1.0

var _shelter: ShelterSystem

var _level_label: Label
var _upgrade_button: Button
var _cooldown_label: Label
var _upgrade_status_label: Label
var _companion_slot: Button
var _stage: Control
var _tile_grid: InteriorTileGrid
var _cell_h: float = 256.0

var _floor_grid_3d: Node3D
var _camera_3d: Camera3D
var _ui_layer: CanvasLayer


func _ready() -> void:
	_shelter = get_node("/root/ShelterSystem") as ShelterSystem
	# 3D 节点直接挂在场景根，路径简单
	_camera_3d = get_node_or_null("InteriorCamera") as Camera3D
	_floor_grid_3d = get_node_or_null("FloorGrid3D") as Node3D
	_ui_layer = get_node_or_null("UILayer") as CanvasLayer
	_build_ui()
	_build_floor_grid_3d()
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
	if _ui_layer == null:
		return
	_refresh_backdrop()

	var root_box := VBoxContainer.new()
	root_box.name = "RootBox"
	root_box.add_theme_constant_override("separation", 24)
	root_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_box.offset_left = 48.0
	root_box.offset_top = 28.0
	root_box.offset_right = -48.0
	root_box.offset_bottom = -28.0
	_ui_layer.add_child(root_box)

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

	# ---- 瓦片网格拼贴 (2.5D 侧剖面, InteriorStage/TileGrid, 逻辑书 B5) ----
	_stage = Control.new()
	_stage.name = "InteriorStage"
	_stage.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_stage.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mid_box.add_child(_stage)
	_build_tile_grid()
	# 2D TileGrid 保留供测试断言使用，视觉上隐藏
	if _tile_grid != null:
		_tile_grid.modulate.a = 0.0

	# 同伴名牌浮层: 挂 InteriorStage, 锚定瓦片网格左下 (地板行上方附近)
	var companion_slot := Button.new()
	companion_slot.name = "CompanionSlot"
	companion_slot.custom_minimum_size = Vector2(0, 48)
	companion_slot.add_theme_font_size_override("font_size", 22)
	companion_slot.pressed.connect(_on_companion_slot_pressed)
	ButtonSkin.apply(companion_slot)
	_stage.add_child(companion_slot)
	companion_slot.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	companion_slot.offset_left = 24.0
	companion_slot.offset_right = 384.0
	companion_slot.offset_top = -(_cell_h + 48.0)
	companion_slot.offset_bottom = -_cell_h
	_companion_slot = companion_slot

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


# 室内底图 = UILayer/InteriorBackdrop (编辑器可见可拖), 运行时按等级换贴图
func _refresh_backdrop() -> void:
	var backdrop := get_node_or_null("UILayer/InteriorBackdrop") as TextureRect
	if backdrop != null:
		backdrop.texture = load(_interior_bg_path())


# 瓦片网格拼贴: InteriorStage 内建 InteriorTileGrid (节点名 TileGrid, 测试契约)
# cols/rows 来自 shelter_levels.conf interior_grid, stage 来自 visual_stage
func _build_tile_grid() -> void:
	var lv: Dictionary = _shelter.get_level_stats()
	var g: Vector2i = Vector2i(lv.get("interior_grid", Vector2i(4, 3)))
	var stage_str: String = str(lv.get("visual_stage", "cabin"))
	var grid := InteriorTileGrid.new()
	grid.name = "TileGrid"
	_stage.add_child(grid)
	grid.build(g.x, g.y, stage_str)
	var needed: Vector2 = grid.custom_minimum_size
	grid.position = Vector2.ZERO
	grid.custom_minimum_size = needed
	_stage.custom_minimum_size = needed
	_tile_grid = grid
	if g.y > 0:
		_cell_h = needed.y / float(g.y)


# 等级变化 → 网格随级扩: 清掉旧 TileGrid, 按新等级重建
func _rebuild_tiles() -> void:
	if _stage == null:
		return
	if _tile_grid != null and is_instance_valid(_tile_grid):
		_stage.remove_child(_tile_grid)
		_tile_grid.free()
		_tile_grid = null
	_build_tile_grid()
	if _tile_grid != null:
		_tile_grid.modulate.a = 0.0
	_refresh_backdrop()
	_build_floor_grid_3d()


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
	NpcDetailPanel.open(_ui_layer, picked_id)


func _on_upgrade_started(_cooldown: float) -> void:
	_refresh()


func _on_upgrade_completed(new_level: int) -> void:
	_upgrade_status_label.text = "升级完成: Lv%d %s" % [new_level, _shelter.get_level_name(new_level)]
	_refresh()


func _on_level_changed(_new_level: int) -> void:
	_rebuild_tiles()
	_refresh()


# ---------------- 3D 室内场景 ----------------

func _build_floor_grid_3d() -> void:
	if _floor_grid_3d == null:
		return
	for child in _floor_grid_3d.get_children():
		_floor_grid_3d.remove_child(child)
		child.free()

	var lv: Dictionary = _shelter.get_level_stats()
	var g: Vector2i = Vector2i(lv.get("interior_grid", Vector2i(4, 3)))
	var cols: int = g.x
	var depth: int = g.y

	if ResourceLoader.exists(FLOOR_GLB_PATH):
		var floor_scene := load(FLOOR_GLB_PATH) as PackedScene
		if floor_scene != null:
			for row in range(depth):
				for col in range(cols):
					var tile: Node3D = floor_scene.instantiate()
					tile.name = "FloorTile3D_%d_%d" % [col, row]
					tile.position = Vector3(
						col * FLOOR_TILE_SPACING,
						0.0,
						row * FLOOR_TILE_SPACING
					)
					_floor_grid_3d.add_child(tile)
			_recenter_camera(cols, depth)
			return

	# fallback: PlaneMesh
	for row in range(depth):
		for col in range(cols):
			var mi := MeshInstance3D.new()
			mi.name = "FloorTile3D_%d_%d" % [col, row]
			var plane := PlaneMesh.new()
			plane.size = Vector2(FLOOR_TILE_SPACING * 0.96, FLOOR_TILE_SPACING * 0.96)
			mi.mesh = plane
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.35, 0.28, 0.22)
			mi.material_override = mat
			mi.position = Vector3(col * FLOOR_TILE_SPACING, 0.0, row * FLOOR_TILE_SPACING)
			_floor_grid_3d.add_child(mi)
	_recenter_camera(cols, depth)


func _recenter_camera(cols: int, depth: int) -> void:
	if _camera_3d == null:
		return
	var cx: float = (cols - 1) * FLOOR_TILE_SPACING * 0.5
	var cz: float = (depth - 1) * FLOOR_TILE_SPACING * 0.5
	var span: float = maxf(cols, depth) * FLOOR_TILE_SPACING
	_camera_3d.position = Vector3(cx, span * 1.6, cz + span * 1.4)
	_camera_3d.look_at(Vector3(cx, 0.0, cz), Vector3.UP)
