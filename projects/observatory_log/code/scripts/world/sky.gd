class_name SkyLayer
extends Node2D
## Screen-fixed sky: gradient, sun, moon, stars, clouds, storm, the far
## ridge (no parallax -- user rule: the far layer stays put, everything
## else moves 1:1), and the thing in the sky from Day 5 on.

var phase := 0.0          # 0 day, 1 dusk, 2 night (continuous)
var storm := false
var sun_y := 40.0         # screen y of the sun centre (hidden when > 160)
var moon_y := 220.0
var object_size := 0.0    # radius of the thing in the sky, 0 = none
var object_pos := Vector2(246, 34)
var flash := 0.0
var t := 0.0
var show_backdrop := true
var show_moon := true
var aurora := 0.0         # the red lights over the lake (night only)

var _stars: Array = []
var _clouds: Array = []
var _backdrop: Sprite2D
var _star_node: ColorRect
var _eyes_tex: Texture2D

const DAY_TOP := Color8(77, 127, 179)
const DAY_BOT := Color8(160, 196, 226)
const DUSK_TOP := Color8(58, 40, 82)
const DUSK_MID := Color8(184, 86, 106)
const DUSK_BOT := Color8(240, 150, 96)
const NIGHT_TOP := Color8(6, 7, 11)
const NIGHT_BOT := Color8(34, 44, 64)
const STORM_TOP := Color8(22, 26, 36)
const STORM_BOT := Color8(64, 76, 96)


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 90:
		_stars.append([rng.randf_range(0, 320), rng.randf_range(0, 120), rng.randf(), rng.randf_range(0.3, 1.0)])
	for i in 7:
		_clouds.append([rng.randf_range(0, 360), rng.randf_range(14, 70), rng.randf_range(18, 46), rng.randf_range(2.0, 5.0)])
	_backdrop = Sprite2D.new()
	_backdrop.texture = load("res://assets/art/world/backdrop.png")
	_backdrop.centered = false
	_backdrop.position = Vector2(0, 80)
	add_child(_backdrop)
	_star_node = ColorRect.new()
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/bloodstar.gdshader")
	_star_node.material = m
	_star_node.visible = false
	add_child(_star_node)


func _process(dt: float) -> void:
	t += dt
	queue_redraw()
	_backdrop.visible = show_backdrop
	_backdrop.modulate = backdrop_tint()
	_backdrop.z_index = 1
	if object_size > 6.0:
		_star_node.visible = true
		var r := object_size
		_star_node.position = object_pos - Vector2(r * 1.4, r * 1.4)
		_star_node.size = Vector2(r * 2.8, r * 2.8)
		_star_node.z_index = 0
	else:
		_star_node.visible = false


func backdrop_tint() -> Color:
	var c := _lerp3(Color(0.92, 0.95, 1.0), Color(0.78, 0.55, 0.62), Color(0.30, 0.34, 0.48), phase)
	if storm:
		c = c.lerp(Color(0.42, 0.46, 0.54), 0.75)
	return c.lerp(Color(1.4, 1.4, 1.5), flash * 0.6)


static func _lerp3(a: Color, b: Color, c: Color, p: float) -> Color:
	if p <= 1.0:
		return a.lerp(b, clampf(p, 0.0, 1.0))
	return b.lerp(c, clampf(p - 1.0, 0.0, 1.0))


func _draw() -> void:
	var top := _lerp3(DAY_TOP, DUSK_TOP, NIGHT_TOP, phase)
	var bot := _lerp3(DAY_BOT, DUSK_BOT, NIGHT_BOT, phase)
	var mid := _lerp3(DAY_BOT.lerp(DAY_TOP, 0.5), DUSK_MID, NIGHT_BOT.lerp(NIGHT_TOP, 0.4), phase)
	if storm:
		top = top.lerp(STORM_TOP, 0.85)
		bot = bot.lerp(STORM_BOT, 0.85)
		mid = mid.lerp(STORM_TOP.lerp(STORM_BOT, 0.5), 0.85)
	for y in range(0, 180, 2):
		var k := y / 150.0
		var c: Color = top.lerp(mid, clampf(k * 2.0, 0.0, 1.0)) if k < 0.5 else mid.lerp(bot, clampf((k - 0.5) * 2.0, 0.0, 1.0))
		c = c.lerp(Color(1, 1, 1), flash * 0.7)
		draw_rect(Rect2(0, y, 320, 2), c)
	# stars
	var night := clampf(phase - 1.15, 0.0, 0.85) / 0.85
	if night > 0.01 and not storm:
		for s in _stars:
			var tw := 0.6 + 0.4 * sin(t * (1.0 + s[2] * 2.0) + s[2] * 40.0)
			var a: float = night * s[3] * tw
			draw_rect(Rect2(floorf(s[0]), floorf(s[1]), 1, 1), Color(0.85, 0.9, 1.0, a))
	# the red aurora: slow curtains, brightest toward the lake (screen right)
	var au := aurora * clampf(phase - 1.3, 0.0, 0.7) / 0.7
	if au > 0.01:
		draw_aurora(self, au, t, 320.0, 1.0)
	# sun
	if sun_y < 170.0 and not storm:
		var sc := Color8(255, 236, 180).lerp(Color8(255, 150, 90), clampf(phase, 0.0, 1.0))
		_glow(Vector2(160, sun_y), 30.0, Color(sc.r, sc.g * 0.9, sc.b * 0.7, 0.18))
		_glow(Vector2(160, sun_y), 18.0, Color(sc.r, sc.g, sc.b, 0.25))
		_disc(Vector2(160, sun_y), 9.0, sc)
	# moon
	if moon_y < 170.0 and not storm and show_moon:
		_glow(Vector2(160, moon_y), 26.0, Color(0.7, 0.8, 1.0, 0.12))
		_disc(Vector2(160, moon_y), 8.0, Color8(226, 232, 240))
		draw_rect(Rect2(156, moon_y - 3, 3, 2), Color8(180, 190, 205))
		draw_rect(Rect2(162, moon_y + 1, 2, 3), Color8(190, 198, 210))
		draw_rect(Rect2(158, moon_y + 3, 2, 1), Color8(180, 190, 205))
	# clouds
	var cl := _lerp3(Color(1, 1, 1, 0.55), Color(1.0, 0.7, 0.7, 0.4), Color(0.4, 0.45, 0.6, 0.25), phase)
	if storm:
		cl = Color(0.12, 0.14, 0.18, 0.85).lerp(Color(0.9, 0.9, 1.0, 0.9), flash)
		for i in 14:
			var x := fposmod(i * 37.0 + t * 6.0, 380.0) - 40.0
			draw_rect(Rect2(x, 6 + (i % 4) * 9, 70, 10 + (i % 3) * 4), cl)
	else:
		for c in _clouds:
			var x := fposmod(float(c[0]) + t * float(c[3]), 380.0) - 40.0
			draw_rect(Rect2(floorf(x), c[1], c[2], 3), cl)
			draw_rect(Rect2(floorf(x) + 6, float(c[1]) - 2, float(c[2]) * 0.5, 2), cl)
	# the thing in the sky (small: a red point; large: the shader sphere)
	if object_size > 0.0 and object_size <= 6.0:
		var pulse := 0.75 + 0.25 * sin(t * 5.0)
		_glow(object_pos, object_size * 3.0, Color(0.8, 0.1, 0.1, 0.25 * pulse))
		_disc(object_pos, maxf(0.7, object_size * 0.5), Color(0.85, 0.15, 0.15, pulse))


## Shared with the ending: vertical red curtains across a strip `w` wide, scaled by `s`.
static func draw_aurora(ci: CanvasItem, k: float, time: float, w: float, s: float) -> void:
	var step := 2.0 * s
	var x := 0.0
	while x < w:
		var u := x / w
		var top := (12.0 + 10.0 * sin(u * 9.0 + time * 0.31) + 6.0 * sin(u * 23.0 - time * 0.53)) * s
		var h := (34.0 + 18.0 * sin(u * 5.0 - time * 0.22) + 10.0 * sin(u * 17.0 + time * 0.7)) * s
		var a := k * (0.28 + 0.3 * (0.5 + 0.5 * sin(u * 31.0 + time * 0.9))) * (0.5 + 0.5 * u)
		var bands := 5
		for b in bands:
			var bk := float(b) / bands
			var c := Color(0.95, 0.12 + 0.12 * (1.0 - bk), 0.16, a * (1.0 - bk * 0.85))
			ci.draw_rect(Rect2(floorf(x), floorf(top + h * bk), step, ceilf(h / bands)), c)
		x += step


func _disc(c: Vector2, r: float, col: Color) -> void:
	var ri := int(ceil(r))
	for y in range(-ri, ri + 1):
		var w := sqrt(maxf(0.0, r * r - y * y))
		draw_rect(Rect2(floorf(c.x - w), floorf(c.y + y), ceilf(w * 2.0), 1), col)


func _glow(c: Vector2, r: float, col: Color) -> void:
	for i in 4:
		var rr := r * (1.0 - i * 0.22)
		_disc(c, rr, Color(col.r, col.g, col.b, col.a * 0.5))
