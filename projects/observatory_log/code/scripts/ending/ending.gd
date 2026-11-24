class_name Ending
extends Node2D
## Day 7, the lake. Starts as the familiar shore at the world's 2x scale,
## then the camera pulls back: the blood-red church stands in the middle of
## the lake (the one from the dream), and the sky is mostly her -- a vast
## red sphere of folded flesh and pulsing veins (no eyes: user, 2026-11-16).
## Drawn at 640x360 and quantised by the same post shader as the world.
##
## Three cuts (MYSTERY_BIBLE §6):
##   sacrifice   the sphere swells over the lake, then the burst.
##   assimilate  the aurora comes down, the church rises, the observer walks
##               out to it, kneels, and goes under with it.
##   epilogue    thirteen years later: hikers find the site in the snow.

signal finished

const HORIZON := 236.0
const PLAYER := Vector2(170, 334)
const LENGTH := {"sacrifice": 50.0, "assimilate": 49.0, "epilogue": 23.0}

var kind := "sacrifice"
var t := -1.0
var cam: Camera2D
var star: ColorRect
var star_c := Vector2(420, 120)
var star_r := 40.0
var zoom := 2.0
var _church: Texture2D
var _backdrop: Texture2D
var _shore: Texture2D
var _ice: Texture2D
var _player: Texture2D
var _firs: Array = []
var _burst := 0.0
var _sky_layer: DrawLayer
var _front: DrawLayer


var _tower: Texture2D
var _hikers: Texture2D
var _fir_green: Array = []
var _bells := {}


func _draw_sky(ci: Node2D) -> void:
	if kind == "epilogue":
		_draw_epilogue_sky(ci)
		return
	for y in range(-200, int(HORIZON), 4):
		var k := clampf((y + 200.0) / (HORIZON + 200.0), 0.0, 1.0)
		ci.draw_rect(Rect2(-400, y, 1440, 4), Color8(4, 2, 4).lerp(Color8(70, 10, 16), k * k))
	if kind == "assimilate":
		var au := clampf(t / 4.0, 0.0, 1.0) * (1.0 - clampf((t - 39.0) / 7.0, 0.0, 1.0))
		if au > 0.01:
			ci.draw_set_transform(Vector2(-400, -150), 0.0, Vector2.ONE)
			SkyLayer.draw_aurora(ci, au * 1.6, t, 1440.0, 3.0)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _ready() -> void:
	cam = Camera2D.new()
	cam.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	add_child(cam)
	_sky_layer = DrawLayer.new()
	_sky_layer.cb = _draw_sky
	add_child(_sky_layer)
	star = ColorRect.new()
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/bloodstar.gdshader")
	m.set_shader_parameter("spin", 0.015)
	m.set_shader_parameter("beat_rate", 0.75)
	m.set_shader_parameter("light_dir", Vector2(-0.3, 0.6))
	star.material = m
	add_child(star)
	_front = DrawLayer.new()
	_front.cb = _draw_front
	add_child(_front)
	_church = load("res://assets/art/mini/church.png")
	_backdrop = load("res://assets/art/world/backdrop.png")
	_shore = load("res://assets/art/world/lake_shore.png")
	_ice = load("res://assets/art/world/lake_ice_blood.png")
	_player = load("res://assets/art/char/player.png")
	for i in 7:
		_firs.append(load("res://assets/art/world/fir_bare_%d.png" % i))
		_fir_green.append(load("res://assets/art/world/fir_%d.png" % i))
	_tower = load("res://assets/art/world/tower.png")
	_hikers = load("res://assets/art/char/hikers.png")
	set_process(false)
	visible = false


func play(_world: Node, k: String = "sacrifice") -> void:
	kind = k
	t = 0.0
	zoom = 2.0
	_burst = 0.0
	_bells = {}
	visible = true
	set_process(true)
	cam.make_current()
	star.visible = kind != "epilogue"
	Sfx.stop_all_loops(1.0)
	match kind:
		"sacrifice":
			Sfx.music("music_ending", 0.0, 0.5)
			Sfx.loop("end_flesh", "amb_flesh", -12.0, 3.0, "Amb")
		"assimilate":
			Sfx.loop("end_flesh", "amb_flesh", -16.0, 3.0, "Amb")
			Sfx.loop("end_drone", "amb_drone", -10.0, 4.0, "Amb")
		"epilogue":
			Sfx.loop("end_wind", "amb_wind", -10.0, 2.0, "Amb")


## Once-per-run sound cues on the timeline.
func _cue(at: float, id: String, vol: float) -> void:
	if t >= at and not _bells.has(at):
		_bells[at] = true
		Sfx.play(id, vol)


func _finish() -> void:
	set_process(false)
	visible = false
	Sfx.stop_loop("end_flesh", 0.5)
	Sfx.stop_loop("end_drone", 0.5)
	Sfx.stop_loop("end_wind", 0.5)
	finished.emit()


func _process(dt: float) -> void:
	t += dt
	if kind == "epilogue":
		cam.zoom = Vector2(2, 2)
		cam.position = Vector2(160, 90)
		_cue(15.0, "phone_beep", -8.0)
		_sky_layer.queue_redraw()
		_front.queue_redraw()
		if t >= LENGTH["epilogue"]:
			_finish()
		return
	if kind == "assimilate":
		_cue(3.0, "ice_groan", -4.0)
		_cue(33.5, "deep_bell", -2.0)
		_cue(36.5, "ice_groan", -2.0)
		_cue(40.0, "deep_bell", -8.0)
	# camera: hold on the shore, then a long continuous pull back
	var k := _ease(clampf((t - 5.0) / 16.0, 0.0, 1.0))
	zoom = lerpf(2.0, 1.0, k)
	var start_c := PLAYER + Vector2(10, -64)
	cam.zoom = Vector2(zoom, zoom)
	cam.position = start_c.lerp(Vector2(320, 180), k).round()
	# the star swells until it holds most of the sky
	var g := _ease(clampf((t - 3.0) / 30.0, 0.0, 1.0))
	if kind == "assimilate":
		# it stays small and far: it does not need to come any closer
		star_r = lerpf(60.0, 44.0, g) * (1.0 - 0.6 * clampf((t - 38.0) / 8.0, 0.0, 1.0))
		star_c = Vector2(470.0, 60.0)
	else:
		star_r = lerpf(60.0, 300.0, g)
		star_c = Vector2(lerpf(400.0, 360.0, g), lerpf(110.0, 120.0, g))
	star.position = star_c - Vector2(star_r, star_r) * 1.4
	star.size = Vector2(star_r, star_r) * 2.8
	if kind == "sacrifice" and t > 43.0 and _burst == 0.0:
		_burst = 1.0
	if _burst > 0.0:
		_burst = maxf(0.001, _burst - dt * 0.4)
	_sky_layer.queue_redraw()
	_front.queue_redraw()
	if t >= float(LENGTH[kind]):
		_finish()


static func _ease(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)


func _draw_front(ci: Node2D) -> void:
	if kind == "epilogue":
		_draw_epilogue(ci)
		return
	if kind == "assimilate":
		_draw_assimilate(ci)
		return

	# far ridge and dead treeline
	for i in range(-2, 4):
		ci.draw_texture_rect(_backdrop, Rect2(i * 320 - 40, HORIZON - 70, 320, 72), false, Color(0.26, 0.10, 0.12))
	# lake
	for i in range(-1, 2):
		ci.draw_texture_rect(_ice, Rect2(i * 760 - 60, HORIZON, 760, 140), false, Color(0.34, 0.16, 0.18))
	# the star's reflection
	for i in 40:
		var y := HORIZON + 3 + i * 3.5
		var w := (star_r * 0.9) * (1.0 - i / 46.0) * (0.7 + 0.3 * sin(t * 1.3 + i))
		ci.draw_rect(Rect2(star_c.x - w * 0.5 + sin(t + i) * 6.0, y, w, 1), Color(0.75, 0.12, 0.14, 0.35 * (1.0 - i / 40.0)))
	# the church in the middle of the lake, on a mound of tissue
	var cpos := Vector2(380, HORIZON + 26 - _church.get_height())
	ci.draw_rect(Rect2(cpos.x - 20, HORIZON + 16, _church.get_width() + 40, 12), Color8(90, 16, 24))
	ci.draw_rect(Rect2(cpos.x - 8, HORIZON + 12, _church.get_width() + 16, 6), Color8(130, 30, 40))
	ci.draw_texture(_church, cpos.round(), Color(0.95, 0.75, 0.75))
	for i in 18:
		var y := HORIZON + 28 + i * 3
		ci.draw_texture_rect_region(_church, Rect2(cpos.x, y, _church.get_width(), 3), Rect2(0, _church.get_height() - 4 - i * 6, _church.get_width(), 3), Color(0.7, 0.2, 0.2, 0.28 * (1.0 - i / 18.0)))
	# shore: dead trees, rocks, the post, the observer
	for i in 9:
		var tex: Texture2D = _firs[(i * 3) % 7]
		ci.draw_texture(tex, Vector2(-60 + i * 26, PLAYER.y - 6 - tex.get_height()), Color(0.35, 0.12, 0.14))
	ci.draw_rect(Rect2(-400, PLAYER.y - 6, 640, 120), Color8(40, 14, 18))
	ci.draw_rect(Rect2(-400, PLAYER.y - 6, 640, 2), Color8(90, 30, 36))
	ci.draw_rect(Rect2(240, PLAYER.y - 4, 30, 120), Color8(30, 8, 12))
	ci.draw_texture(_shore, Vector2(PLAYER.x - 34, PLAYER.y - 11), Color(0.55, 0.3, 0.32))
	var f := 0
	ci.draw_texture_rect_region(_player, Rect2(PLAYER.x - 12, PLAYER.y - 34, 24, 34), Rect2(f * 24, 0, 24, 34), Color(0.75, 0.55, 0.58))
	if _burst > 0.0:
		ci.draw_rect(Rect2(-400, -300, 1440, 900), Color(1.0, 0.85, 0.8, clampf(_burst, 0.0, 1.0) * (1.0 if G.settings["flash"] else 0.3)))
	if t > 46.0:
		ci.draw_rect(Rect2(-400, -300, 1440, 900), Color(0, 0, 0, clampf((t - 46.0) / 2.5, 0.0, 1.0)))


func _disc(ci: Node2D, c: Vector2, r: float, col: Color) -> void:
	var ri := int(ceil(r))
	for y in range(-ri, ri + 1):
		var w := sqrt(maxf(0.0, r * r - y * y))
		if w > 0.0:
			ci.draw_rect(Rect2(c.x - w, c.y + y, w * 2.0, 1), col)


# ================================================================ assimilate
const CHURCH_X := 380.0


## How much of the church is above the ice (0..height): it rises, then goes back under.
func church_visible() -> float:
	var h := float(_church.get_height())
	var rise := _ease(clampf((t - 3.0) / 12.0, 0.0, 1.0))
	var sink := _ease(clampf((t - 37.0) / 8.0, 0.0, 1.0))
	return clampf(h * rise - h * sink, 0.0, h)


## The church sprite (front view, tools/art_mini.py): foot of the plinth and the door, local.
const PLINTH_FOOT := Vector2(36, 180)
const DOOR := Rect2(98, 76, 16, 36)


## Where the observer is: on the shore, out over the ice to the foot of the
## church; it goes dim round him and he is at the door; kneeling, gone.
func observer_state() -> Dictionary:
	var top := HORIZON + 26.0 - float(_church.get_height())
	var foot := Vector2(CHURCH_X, top) + PLINTH_FOOT
	var door := Vector2(CHURCH_X + DOOR.get_center().x, top + DOOR.end.y)
	var k1 := _ease(clampf((t - 18.0) / 10.0, 0.0, 1.0))
	var k2 := clampf((t - 28.0) / 3.0, 0.0, 1.0)
	var frame := 0
	if t >= 18.0 and t < 28.0:
		frame = 2 + int(t * 8.0) % 6
	elif t >= 33.0:
		frame = 14
	var pos := door if k2 >= 0.5 else PLAYER.lerp(foot, k1)
	var a := absf(k2 * 2.0 - 1.0) if t >= 28.0 and k2 < 1.0 else 1.0
	return {"pos": pos, "scale": lerpf(1.0, 0.5, k1), "frame": frame, "alpha": a, "gone": t >= 36.2}


func _draw_assimilate(ci: Node2D) -> void:
	for i in range(-2, 4):
		ci.draw_texture_rect(_backdrop, Rect2(i * 320 - 40, HORIZON - 70, 320, 72), false, Color(0.24, 0.10, 0.13))
	for i in range(-1, 2):
		ci.draw_texture_rect(_ice, Rect2(i * 760 - 60, HORIZON, 760, 140), false, Color(0.30, 0.16, 0.20))
	var cw := float(_church.get_width())
	var base := HORIZON + 26.0
	var vis := church_visible()
	# the aurora on the ice
	var au := clampf(t / 4.0, 0.0, 1.0) * (1.0 - clampf((t - 39.0) / 7.0, 0.0, 1.0))
	for i in 30:
		var y := HORIZON + 4 + i * 4.0
		var w := 300.0 * (1.0 - i / 34.0) * (0.7 + 0.3 * sin(t * 0.9 + i * 0.7))
		ci.draw_rect(Rect2(CHURCH_X + cw * 0.5 - w * 0.5 + sin(t * 0.6 + i) * 10.0, y, w, 1), Color(0.8, 0.1, 0.14, 0.22 * au * (1.0 - i / 30.0)))
	# the opening in the ice, the church coming up through it
	var hole_w := cw + 40.0
	var open_k := clampf(t / 3.0, 0.0, 1.0) * (1.0 - clampf((t - 43.0) / 4.0, 0.0, 1.0))
	ci.draw_rect(Rect2(CHURCH_X - 20, base - 4, hole_w, 10), Color8(30, 6, 10) * Color(1, 1, 1, open_k))
	if vis > 0.5:
		ci.draw_texture_rect_region(_church, Rect2(CHURCH_X, base - vis, cw, vis), Rect2(0, 0, cw, vis), Color(0.92, 0.72, 0.74))
		# the door, opening for him
		var door_k := clampf((t - 32.0) / 2.5, 0.0, 1.0)
		var door_top := base - vis + DOOR.position.y
		var dcx := CHURCH_X + DOOR.get_center().x
		if door_k > 0.0 and door_top < base - 2.0:
			var dw := DOOR.size.x * door_k
			ci.draw_rect(Rect2(dcx - dw * 0.5, door_top, dw, minf(DOOR.size.y, base - door_top)), Color8(8, 0, 2))
			ci.draw_rect(Rect2(dcx - dw * 0.25, door_top + 6, dw * 0.5, minf(DOOR.size.y - 6, base - door_top - 6)), Color(0.6, 0.05, 0.08, 0.5 * door_k))
		for i in 14:
			var y := base + 2 + i * 3
			var sy := vis - 4.0 - i * 6.0
			if sy <= 0.0:
				break
			ci.draw_texture_rect_region(_church, Rect2(CHURCH_X, y, cw, 3), Rect2(0, sy, cw, 3), Color(0.7, 0.2, 0.2, 0.24 * (1.0 - i / 14.0)))
	# rings where it went down
	if t > 37.0:
		var rc := Vector2(CHURCH_X + cw * 0.5, base + 2)
		for i in 4:
			var rk := fposmod((t - 37.0) * 0.35 + i * 0.25, 1.0)
			var rw := 20.0 + rk * 180.0
			var a := 0.4 * (1.0 - rk) * (1.0 - clampf((t - 44.0) / 3.0, 0.0, 1.0))
			for s in 48:
				var ang := TAU * s / 48.0
				ci.draw_rect(Rect2(rc.x + cos(ang) * rw, rc.y + sin(ang) * rw * 0.12, 2, 1), Color(0.75, 0.35, 0.4, a))
	# the shore he leaves
	for i in 9:
		var tex: Texture2D = _firs[(i * 3) % 7]
		ci.draw_texture(tex, Vector2(-60 + i * 26, PLAYER.y - 6 - tex.get_height()), Color(0.32, 0.12, 0.15))
	ci.draw_rect(Rect2(-400, PLAYER.y - 6, 640, 120), Color8(38, 14, 18))
	ci.draw_rect(Rect2(-400, PLAYER.y - 6, 640, 2), Color8(86, 30, 36))
	ci.draw_texture(_shore, Vector2(PLAYER.x - 34, PLAYER.y - 11), Color(0.5, 0.3, 0.32))
	var ob := observer_state()
	if not ob["gone"]:
		var s := float(ob["scale"])
		var p: Vector2 = ob["pos"]
		ci.draw_texture_rect_region(_player, Rect2(p.x - 12.0 * s, p.y - 34.0 * s, 24.0 * s, 34.0 * s), Rect2(int(ob["frame"]) * 24, 0, 24, 34), Color(0.75, 0.55, 0.58, float(ob["alpha"])))
	if t > 46.0:
		ci.draw_rect(Rect2(-400, -300, 1440, 900), Color(0, 0, 0, clampf((t - 46.0) / 2.5, 0.0, 1.0)))


# ================================================================ epilogue
## Thirteen years later, in daylight: drawn in 320x180 world units (camera zoom 2).
func _draw_epilogue_sky(ci: Node2D) -> void:
	for y in range(0, 152, 2):
		var k := y / 152.0
		ci.draw_rect(Rect2(0, y, 320, 2), Color8(110, 150, 196).lerp(Color8(214, 226, 238), k))


const HIKERS := 4


## x of hiker i at the current time, and whether he is still walking.
func hiker(i: int) -> Array:
	var stop := 150.0 - i * 15.0
	var x := -24.0 - i * 18.0 + 13.0 * minf(t, 30.0)
	return [minf(x, stop), x < stop]


func _draw_epilogue(ci: Node2D) -> void:
	ci.draw_texture(_backdrop, Vector2(0, 78), Color(0.9, 0.94, 1.0))
	for i in 12:
		var tex: Texture2D = _fir_green[(i * 5) % 7]
		ci.draw_texture(tex, Vector2(-10 + i * 19, 141 - tex.get_height()), Color(0.62, 0.68, 0.74))
	# the lake beyond the site, and the site itself
	ci.draw_rect(Rect2(196, 138, 124, 12), Color8(196, 212, 228))
	ci.draw_rect(Rect2(196, 140, 124, 1), Color8(232, 240, 248))
	var tx := 262.0
	var top := 151.0 - _tower.get_height()
	ci.draw_texture(_tower, Vector2(tx - _tower.get_width() * 0.5, top), Color(0.9, 0.92, 1.0))
	var lit := clampf((t - 14.0) / 0.6, 0.0, 1.0)
	if lit > 0.0:
		# one pane lights, by itself
		ci.draw_rect(Rect2(tx - 4, top + 32, 9, 9), Color(1.0, 0.8, 0.45, 0.8 * lit))
		ci.draw_rect(Rect2(tx - 12, top + 26, 25, 20), Color(1.0, 0.75, 0.4, 0.12 * lit))
	ci.draw_rect(Rect2(0, 150, 320, 30), Color8(226, 232, 240))
	ci.draw_rect(Rect2(0, 150, 320, 1), Color8(244, 248, 252))
	for y in range(156, 180, 4):
		ci.draw_rect(Rect2(0, y, 320, 1), Color8(206, 214, 226))
	# the hikers (char/hikers.png: one row each, idle 0-1, walk 2-7)
	for i in HIKERS:
		var h := hiker(i)
		var frame := (2 + int(t * 9.0 + i) % 6) if bool(h[1]) else int(t * 1.2 + i) % 2
		ci.draw_texture_rect_region(_hikers, Rect2(roundf(float(h[0])) - 12, 152 - 34, 24, 34), Rect2(frame * 24, i * 34, 24, 34))
	# deep forest in front, left
	for i in 6:
		var tex: Texture2D = _fir_green[(i * 3 + 1) % 7]
		ci.draw_texture(tex, Vector2(-30 + i * 22 + int(PixelFont._hash(i, 4) * 8.0), 182 - tex.get_height()), Color(0.42, 0.48, 0.52))
	# snow
	for i in 70:
		var sx := fposmod(PixelFont._hash(i, 1) * 320.0 + sin(t * 0.7 + i) * 6.0 - t * 4.0, 320.0)
		var sy := fposmod(PixelFont._hash(i, 2) * 180.0 + t * (10.0 + PixelFont._hash(i, 3) * 10.0), 180.0)
		ci.draw_rect(Rect2(floorf(sx), floorf(sy), 1, 1), Color(1, 1, 1, 0.8))
	if t > 19.5:
		ci.draw_rect(Rect2(-10, -10, 340, 200), Color(0, 0, 0, clampf((t - 19.5) / 2.5, 0.0, 1.0)))
