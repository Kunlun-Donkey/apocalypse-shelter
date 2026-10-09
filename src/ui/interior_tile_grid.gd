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

	match component:
		"tile_floor":
			# 暖褐地板，俯视感
			img.fill(Color(0.72, 0.60, 0.44))
			# 顶部深色渐变（透视远端）
			var band_h: int = GENERATED_SIZE / 5
			for py in range(band_h):
				var t: float = float(py) / float(band_h)
				var row_color: Color = Color(0.55, 0.45, 0.32).lerp(Color(0.72, 0.60, 0.44), t)
				for px in range(GENERATED_SIZE):
					img.set_pixel(px, py, row_color)
			# 两条水平木纹线
			for line_y: int in [GENERATED_SIZE / 3, (GENERATED_SIZE * 2) / 3]:
				for px in range(GENERATED_SIZE):
					img.set_pixel(px, line_y, Color(0.48, 0.38, 0.26))

		"tile_ceiling":
			# 深炭灰天花板，仰视感
			img.fill(Color(0.22, 0.22, 0.24))
			# 三条竖向梁纹
			for beam_x: int in [GENERATED_SIZE / 4, GENERATED_SIZE / 2, (GENERATED_SIZE * 3) / 4]:
				for py in range(GENERATED_SIZE):
					img.set_pixel(beam_x, py, Color(0.30, 0.30, 0.32))
					if beam_x + 1 < GENERATED_SIZE:
						img.set_pixel(beam_x + 1, py, Color(0.28, 0.28, 0.30))

		"tile_wall":
			# 中性灰墙面
			img.fill(Color(0.52, 0.50, 0.48))
			var step: int = GENERATED_SIZE / 8
			for i in range(1, 8):
				for px in range(GENERATED_SIZE):
					img.set_pixel(px, i * step, Color(0.38, 0.36, 0.34))

		"tile_wall_window":
			# 墙面 + 窗口
			img.fill(Color(0.52, 0.50, 0.48))
			var step: int = GENERATED_SIZE / 8
			for i in range(1, 8):
				for px in range(GENERATED_SIZE):
					img.set_pixel(px, i * step, Color(0.38, 0.36, 0.34))
			# 窗口矩形（居中 40%×30%）
			var wx: int = (GENERATED_SIZE * 3) / 10
			var wy: int = (GENERATED_SIZE * 3) / 10
			var ww: int = (GENERATED_SIZE * 4) / 10
			var wh: int = (GENERATED_SIZE * 3) / 10
			for py in range(wy, wy + wh):
				for px in range(wx, wx + ww):
					img.set_pixel(px, py, Color(0.75, 0.85, 0.95))
			# 2px 深色窗框
			for px in range(max(0, wx - 2), min(GENERATED_SIZE, wx + ww + 2)):
				for b in range(2):
					if wy - 1 - b >= 0:
						img.set_pixel(px, wy - 1 - b, Color(0.28, 0.24, 0.20))
					if wy + wh + b < GENERATED_SIZE:
						img.set_pixel(px, wy + wh + b, Color(0.28, 0.24, 0.20))
			for py in range(max(0, wy - 2), min(GENERATED_SIZE, wy + wh + 2)):
				for b in range(2):
					if wx - 1 - b >= 0:
						img.set_pixel(wx - 1 - b, py, Color(0.28, 0.24, 0.20))
					if wx + ww + b < GENERATED_SIZE:
						img.set_pixel(wx + ww + b, py, Color(0.28, 0.24, 0.20))

		"tile_wall_door":
			# 墙面 + 门洞
			img.fill(Color(0.52, 0.50, 0.48))
			var step: int = GENERATED_SIZE / 8
			for i in range(1, 8):
				for px in range(GENERATED_SIZE):
					img.set_pixel(px, i * step, Color(0.38, 0.36, 0.34))
			# 门洞（居中 40% 宽，下65% 高）
			var dx: int = (GENERATED_SIZE * 3) / 10
			var dy: int = (GENERATED_SIZE * 35) / 100
			var dw: int = (GENERATED_SIZE * 4) / 10
			for py in range(dy, GENERATED_SIZE):
				for px in range(dx, dx + dw):
					img.set_pixel(px, py, Color(0.12, 0.10, 0.09))
			# 3px 木色门框（左右上）
			for py in range(dy, GENERATED_SIZE):
				for b in range(3):
					if dx - 1 - b >= 0:
						img.set_pixel(dx - 1 - b, py, Color(0.45, 0.32, 0.18))
					if dx + dw + b < GENERATED_SIZE:
						img.set_pixel(dx + dw + b, py, Color(0.45, 0.32, 0.18))
			for px in range(max(0, dx - 2), min(GENERATED_SIZE, dx + dw + 3)):
				for b in range(3):
					if dy - 1 - b >= 0:
						img.set_pixel(px, dy - 1 - b, Color(0.45, 0.32, 0.18))

		"tile_wall_side_left":
			# 较暗左侧墙，右侧亮缝
			img.fill(Color(0.38, 0.36, 0.34))
			for py in range(GENERATED_SIZE):
				img.set_pixel(GENERATED_SIZE - 1, py, Color(0.55, 0.52, 0.50))
				img.set_pixel(GENERATED_SIZE - 2, py, Color(0.50, 0.48, 0.46))
			var step: int = GENERATED_SIZE / 8
			for i in range(1, 8):
				for px in range(GENERATED_SIZE):
					img.set_pixel(px, i * step, Color(0.28, 0.26, 0.24))

		"tile_wall_side_right":
			# 较暗右侧墙，左侧亮缝
			img.fill(Color(0.38, 0.36, 0.34))
			for py in range(GENERATED_SIZE):
				img.set_pixel(0, py, Color(0.55, 0.52, 0.50))
				img.set_pixel(1, py, Color(0.50, 0.48, 0.46))
			var step: int = GENERATED_SIZE / 8
			for i in range(1, 8):
				for px in range(GENERATED_SIZE):
					img.set_pixel(px, i * step, Color(0.28, 0.26, 0.24))

		_:
			# 未知组件 fallback
			img.fill(Color(0.5, 0.5, 0.5))

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
