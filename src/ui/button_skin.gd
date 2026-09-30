class_name ButtonSkin
extends RefCounted
# ============================================================
# 按钮皮肤: 若 assets/ui/ 下存在 PNG 则自动贴到按钮上, 不存在用默认主题
#   btn_primary.png         按钮常态图 (必需)
#   btn_primary_hover.png   悬停态图 (可选, 缺省用常态图提亮模拟)
#   btn_primary_pressed.png 按下态图 (可选, 缺省用常态图压暗模拟)
# 图片会被拉伸到按钮实际尺寸, 建议按最大按钮 2 倍出图 (~1024x128 透明 PNG)
# ============================================================

const NORMAL_PATH := "res://assets/ui/btn_primary.png"
const HOVER_PATH := "res://assets/ui/btn_primary_hover.png"
const PRESSED_PATH := "res://assets/ui/btn_primary_pressed.png"


static func apply(button: Button) -> void:
	if not ResourceLoader.exists(NORMAL_PATH):
		return
	var normal_tex: Texture2D = load(NORMAL_PATH)
	var normal := _make_stylebox(normal_tex, button)

	# 悬停/按下: 有图用图, 没图复用常态图
	var hover_tex: Texture2D = normal_tex
	if ResourceLoader.exists(HOVER_PATH):
		hover_tex = load(HOVER_PATH)
	var pressed_tex: Texture2D = normal_tex
	if ResourceLoader.exists(PRESSED_PATH):
		pressed_tex = load(PRESSED_PATH)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", _make_stylebox(hover_tex, button))
	button.add_theme_stylebox_override("pressed", _make_stylebox(pressed_tex, button))
	button.add_theme_stylebox_override("disabled", normal)

	# 深色木板底 → 暖白文字 (悬停变亮, 按下变暗)
	button.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.9))
	button.add_theme_color_override("font_pressed_color", Color(0.85, 0.8, 0.7))
	button.add_theme_color_override("font_disabled_color", Color(0.6, 0.58, 0.52))


# 9-slice: 四角/边缘固定像素, 中段 TILE 采样 (不拉伸不变形)。
# 角部尺寸按按钮实际大小夹紧, 防止小按钮两边角比按钮还宽。
static func _make_stylebox(tex: Texture2D, button: Button) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	var tex_size := tex.get_size()
	var btn_size := button.custom_minimum_size
	if btn_size.x <= 0.0:
		btn_size = button.size
	var margin_x := clampi(roundi(tex_size.x * 0.10), 24, roundi(btn_size.x * 0.22))
	var margin_y := clampi(roundi(tex_size.y * 0.28), 12, roundi(btn_size.y * 0.30))
	sb.texture_margin_left = margin_x
	sb.texture_margin_right = margin_x
	sb.texture_margin_top = margin_y
	sb.texture_margin_bottom = margin_y
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	return sb