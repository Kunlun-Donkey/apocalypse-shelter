class_name InteriorTileGrid
extends GridContainer
# ============================================================
# 庇护所室内瓦片网格 (2.5D 侧剖面, 逻辑书 B5 / AGENTS §13.0)
# build(cols, rows, stage) 双层循环铺 TextureRect 单元格
# 布局规则确定性: 顶行天花板 / 底行地板 / 墙行 左右边+中门+奇数窗
# 贴图兜底链: 等级目录 → cabin → 降级映射 → blank → 代码纯色, 每格独立不崩
# ============================================================

const TILES_ROOT := "res://assets/shelter/tiles"
const BLANK_TILE := "res://assets/shelter/tiles/blank_tile_256x256.png"
const GENERATED_SIZE := 256

# 降级映射: 细节组件缺图时退到基础件 (cabin 阶段下再找一次)
const DEGRADE_MAP := {
	"tile_wall_window": "tile_wall",
	"tile_wall_door": "tile_wall",
	"tile_wall_doorway": "tile_wall",
	"tile_stair": "tile_wall",
	"tile_column": "tile_wall",
	"tile_wall_side_left": "tile_wall",
	"tile_wall_side_right": "tile_wall",
	"tile_base": "tile_floor",
	"tile_ceiling": "tile_wall",
}


func build(cols: int, rows: int, stage: String) -> void:
	# 清空已有子节点 (重复 build 支持, 等级变化重建); 立即 free 防同名冲突
	for child in get_children():
		remove_child(child)
		child.free()
	columns = cols
	var cell_size: Vector2 = _cell_size(stage)
	for r in range(rows):
		for c in range(cols):
			var comp: String = _component_for(c, r, cols, rows)
			var cell := TextureRect.new()
			cell.name = "TileCell_%d_%d" % [c, r]
			cell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			cell.stretch_mode = TextureRect.STRETCH_SCALE
			cell.custom_minimum_size = cell_size
			cell.texture = _tile_texture(stage, comp)
			cell.set_meta("tile_component", comp)
			cell.set_meta("grid_col", c)
			cell.set_meta("grid_row", r)
			add_child(cell)
	set_meta("grid_cols", cols)
	set_meta("grid_rows", rows)
	custom_minimum_size = Vector2(cols, rows) * cell_size


# 布局规则 (确定性, 坐标推导, 禁写死): 顶行天花板 / 底行地板 / 其余墙行
func _component_for(c: int, r: int, cols: int, rows: int) -> String:
	if r == 0:
		return "tile_ceiling"
	if r == rows - 1:
		return "tile_floor"
	if c == 0:
		return "tile_wall_side_left"
	if c == cols - 1:
		return "tile_wall_side_right"
	if c == cols / 2:
		return "tile_wall_door"
	if c % 2 == 1:
		return "tile_wall_window"
	return "tile_wall"


# 贴图兜底链 (每格独立, 不崩):
# 1 等级目录 2 cabin 目录 3 降级映射备用件(cabin) 4 blank 占位 5 代码纯色
func _tile_texture(stage: String, comp: String) -> Texture2D:
	var tex: Texture2D = _load_tile("%s/%s/%s.png" % [TILES_ROOT, stage, comp])
	if tex != null:
		return tex
	tex = _load_tile("%s/cabin/%s.png" % [TILES_ROOT, comp])
	if tex != null:
		return tex
	if DEGRADE_MAP.has(comp):
		var alt: String = str(DEGRADE_MAP[comp])
		tex = _load_tile("%s/cabin/%s.png" % [TILES_ROOT, alt])
		if tex != null:
			return tex
	tex = _load_tile(BLANK_TILE)
	if tex != null:
		return tex
	return _generated_tile(comp)


func _load_tile(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _generated_tile(component: String) -> Texture2D:
	var img: Image = Image.create(GENERATED_SIZE, GENERATED_SIZE, false, Image.FORMAT_RGBA8)

	# DEBUG: 所有格子纯红，确认网格可见性
	img.fill(Color(1.0, 0.0, 0.0))
	return ImageTexture.create_from_image(img)


func _cell_size(stage: String) -> Vector2:
	var cfg: int = int(ConfigManager.get_shelter_base().get("tile_cell_size", 0))
	if cfg > 0:
		return Vector2(cfg, cfg)
	var floor_tex: Texture2D = _tile_texture(stage, "tile_floor")
	if floor_tex != null and floor_tex.get_size().x > 0.0:
		return floor_tex.get_size()
	var blank_tex: Texture2D = _load_tile(BLANK_TILE)
	if blank_tex != null and blank_tex.get_size().x > 0.0:
		return blank_tex.get_size()
	return Vector2(GENERATED_SIZE, GENERATED_SIZE)
