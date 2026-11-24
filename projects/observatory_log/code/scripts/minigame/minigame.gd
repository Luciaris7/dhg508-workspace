class_name MiniGame
extends Node2D
## HOMEWARD. A boat sails right across three lanes (far / mid / near); reefs
## come in from the right. Every reef passed is POINTS. Touching one ends the
## run. At GOAL the reefs stop, the boat sails on to the church; its door does
## not open, and touching it returns to the title. The Day 5 dream reuses all
## of it: there the reefs only flash, and the door opens.

signal quit
signal game_over(score: int)
signal dream_done

## Tuned with tools/sim_minigame.py (2026-11-16): an ordinary player reaches
## GOAL in about 70 % of runs; a run to GOAL lasts about half a minute.
const THRESH := [0, 400, 800, 1200, 1600]
const XRATE := [9.8, 12.6, 15.4, 18.2, 21.0]
const SAFE := [0.68, 0.57, 0.50, 0.43, 0.36]
const POINTS := 50
## The church comes at GOAL points (desktop); its door does not open.
const GOAL := 2000
## The Day 5 dream: reefs for this long (a touched reef only flashes), then
## about 4.5 s of sailing: the church at about 20 s, however it is played.
const DREAM_T := 13.0
const PASS_T := 2.67
const BOAT_X := 160.0
const SPAWN_X := 334.0
const SPEED := (SPAWN_X - BOAT_X) / PASS_T
const LANE_Y := [122.0, 141.0, 162.0]
const LANE_S := [0, 1, 2]           # sprite size index per lane
const SWITCH_T := 0.15
const HORIZON := 100.0

var flow: Node
var mode := "off"        # off, title, run, over, sail, temple, reject, black
var dream := false
var state := 1           # title screen state 1..5 by day
var blood := false
var score := 0
var level := 0
var t := 0.0
var run_t := 0.0
var lane := 2
var lane_from := 2
var lane_k := 1.0
var rocks: Array = []    # [x, lane, variant, arrival, scored]
var _next_spawn := 0.0
var _rng := RandomNumberGenerator.new()
var stop_spawn := false
var sail_t := 0.0
var church_x := 420.0
var fig := Vector2.ZERO
var fig_k := 0.0          # 1: at the door
var walk_k := 0.0         # along the foot of the church
var climb_t := -1.0       # the dim between the foot and the door
var door_t := -1.0
var hit_flash := 0.0
var over_t := 0.0
var _tex := {}
var _planet: ColorRect
var _player_tex: Texture2D
var _bob := 0.0
var _hover_start := false


func _ready() -> void:
	_rng.randomize()
	var names := ["boat_0", "boat_1", "title", "start_0", "start_1", "close", "church"]
	for k in 2:
		for v in 4:
			for s in 3:
				names.append("rock_%s_%d_%d" % ["blood" if k else "stone", v, s])
	for n in names:
		var p := "res://assets/art/mini/%s.png" % n
		if ResourceLoader.exists(p):
			_tex[n] = load(p)
	_player_tex = load("res://assets/art/char/player.png")
	_planet = ColorRect.new()
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/bloodstar.gdshader")
	_planet.material = m
	_planet.visible = false
	_planet.z_index = 0
	add_child(_planet)
	visible = false


# ============================================================== entry
func start_desktop() -> void:
	dream = false
	state = clampi(G.day - 1, 1, 5)
	blood = G.day == 5 or G.day == 6
	_to_title()
	visible = true


func start_dream() -> void:
	dream = true
	state = 4
	blood = true
	_to_title()
	visible = true
	Sfx.loop("mg_sea", "amb_sea", -10.0, 1.0)
	Sfx.music("music_dream", -10.0, 4.0)


func stop() -> void:
	mode = "off"
	visible = false
	Sfx.stop_loop("mg_sea", 0.3)


func _to_title() -> void:
	mode = "title"
	rocks.clear()
	score = 0
	level = 0
	t = 0.0
	if not dream:
		Sfx.loop("mg_sea", "amb_sea", -14.0, 0.6)


func _begin_run() -> void:
	mode = "run"
	score = 0
	level = 0
	run_t = 0.0
	lane = 1
	lane_from = 1
	lane_k = 1.0
	rocks.clear()
	stop_spawn = false
	_next_spawn = 1.2
	hit_flash = 0.0
	church_x = 420.0
	Sfx.play("mg_start", -6.0)


# ============================================================== input
func handle(e: InputEvent) -> void:
	var p := Vector2(-1, -1)
	if e is InputEventMouse:
		p = (e as InputEventMouse).position / 2.0
		_hover_start = _start_rect().has_point(p)
	match mode:
		"title":
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				if _start_rect().has_point(p):
					_begin_run()
				elif not dream and _close_rect().has_point(p):
					Sfx.play("click", -10.0)
					stop()
					quit.emit()
			elif e.is_action_pressed("interact") and not (e is InputEventMouseButton):
				_begin_run()
			elif e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE and not dream:
				stop()
				quit.emit()
		"run", "sail":
			if e.is_action_pressed("up"):
				_switch(-1)
			elif e.is_action_pressed("down"):
				_switch(1)
			elif not dream and e is InputEventMouseButton and e.pressed and _close_rect().has_point(p):
				stop()
				quit.emit()
			elif not dream and e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
				stop()
				quit.emit()
		"over":
			if over_t > 0.8 and ((e is InputEventMouseButton and e.pressed) or e.is_action_pressed("interact")):
				_to_title()
		"temple":
			if e.is_action_pressed("interact") and fig_k >= 1.0 and door_t < 0.0:
				door_t = 0.0
				Sfx.play("door_push" if dream else "ice_knock", -2.0)


func _switch(d: int) -> void:
	var nl := clampi(lane + d, 0, 2)
	if nl == lane:
		return
	lane_from = lane
	lane = nl
	lane_k = 0.0
	Sfx.play("mg_swish", -10.0, randf_range(0.95, 1.05))


func _boat_y() -> float:
	var k := clampf(lane_k, 0.0, 1.0)
	k = k * k * (3.0 - 2.0 * k)
	return lerpf(LANE_Y[lane_from], LANE_Y[lane], k)


func _boat_lane() -> int:
	return lane if lane_k >= 0.5 else lane_from


func _start_rect() -> Rect2:
	return Rect2(136, 112, 48, 18)


func _close_rect() -> Rect2:
	return Rect2(304, 3, 13, 12)


# ============================================================== update
func _process(dt: float) -> void:
	if mode == "off":
		return
	t += dt
	_bob += dt
	hit_flash = maxf(0.0, hit_flash - dt * 1.5)
	lane_k = minf(1.0, lane_k + dt / SWITCH_T)
	match mode:
		"run":
			_run(dt)
		"sail":
			_sail(dt)
		"temple":
			_temple(dt)
		"over":
			over_t += dt
		"reject":
			sail_t += dt
			if sail_t > 3.2:
				flow.overlay.red_center = ""
				_to_title()
	_update_planet()
	queue_redraw()


func _level_for(s: int) -> int:
	var lv := 0
	for i in THRESH.size():
		if s >= THRESH[i]:
			lv = i
	return lv


func _run(dt: float) -> void:
	run_t += dt
	level = 0 if dream else _level_for(score)
	if dream and run_t >= DREAM_T:
		stop_spawn = true
	if not stop_spawn:
		_next_spawn -= dt
		if _next_spawn <= 0.0:
			_spawn()
	for r in rocks:
		r[0] -= SPEED * dt
		if not r[4] and r[0] < BOAT_X - 10.0:
			r[4] = true
			if not dream:
				score += POINTS
				Sfx.play("mg_dodge", -12.0, 1.0 + level * 0.03)
				if score >= GOAL:
					stop_spawn = true
		elif not r[4] and int(r[1]) == _boat_lane() and absf(float(r[0]) - BOAT_X) < _half(int(r[1])) + 4.0 and lane_k > 0.35:
			if dream:
				r[4] = true
				r[5] = true
				hit_flash = 1.0
				Sfx.play("flesh_hit", -2.0)
			else:
				_crash()
				return
	rocks = rocks.filter(func(r): return r[0] > -30.0 and not r[5])
	# sail on as soon as the last reef is behind the boat
	if stop_spawn and rocks.all(func(r): return r[4]):
		mode = "sail"
		sail_t = 0.0
		church_x = 420.0


func _half(ln: int) -> float:
	return [5.0, 6.0, 8.0][ln]


func _spawn() -> void:
	var x: float = XRATE[level]
	var interval := 10.0 / x
	var jit := 0.2 if level >= 9 else 0.1
	var arr := run_t + PASS_T
	var w: float = SAFE[level]
	var lanes := [0, 1, 2]
	lanes.shuffle()
	var chosen := -1
	for ln in lanes:
		if _lane_ok(ln, arr, w):
			chosen = ln
			break
	if chosen < 0:
		_next_spawn = 0.05
		return
	rocks.append([SPAWN_X, chosen, _rng.randi_range(0, 3), arr, false, false])
	_next_spawn = interval * _rng.randf_range(1.0 - jit, 1.0 + jit)


## Fairness: never let all three lanes be blocked inside the safe window,
## and keep reefs in the same lane visually apart.
func _lane_ok(ln: int, arr: float, w: float) -> bool:
	var occ := 0.38
	var blocked := {}
	for r in rocks:
		var a: float = r[3]
		if int(r[1]) == ln and absf(a - arr) < 0.42:
			return false
		if absf(a - arr) < w + occ:
			blocked[int(r[1])] = true
	blocked[ln] = true
	return blocked.size() < 3


func _crash() -> void:
	mode = "over"
	over_t = 0.0
	hit_flash = 1.0
	Sfx.play("mg_crash", -2.0)
	Sfx.play("mg_over", -6.0)
	game_over.emit(score)


func _sail(dt: float) -> void:
	sail_t += dt
	for r in rocks:
		r[0] -= SPEED * dt
	rocks = rocks.filter(func(r): return r[0] > -30.0)
	var arrive := 10.0 if not dream else 0.0
	if sail_t > arrive:
		church_x = maxf(150.0, church_x - 60.0 * dt)
		if church_x <= 150.0:
			mode = "temple"
			fig_k = 0.0
			walk_k = 0.0
			climb_t = -1.0
			door_t = -1.0
			Sfx.play("mg_arrive", -4.0)
			if not dream:
				Sfx.music("music_dream", -14.0, 2.0)


## Off the boat, along to the foot of the plinth; there the screen dims and he
## is at the door (no stairs). Relative to the church sprite.
const CLIMB_T := 1.4


func _path() -> Array:
	var base := Vector2(church_x, 0)
	return [base + Vector2(14, 160), base + Vector2(36, 160), base + Vector2(96, 100)]


func _temple(dt: float) -> void:
	var p := _path()
	if fig_k >= 1.0:
		fig = p[2]
	elif climb_t >= 0.0:
		climb_t += dt
		fig = p[1] if climb_t < CLIMB_T * 0.5 else p[2]
		if climb_t >= CLIMB_T:
			fig_k = 1.0
	elif door_t < 0.0:
		var dir := Input.get_axis("left", "right")
		if dir > 0.1:
			walk_k = minf(1.0, walk_k + dt * 0.8)
			if int(t * 6.0) % 3 == 0 and Engine.get_process_frames() % 6 == 0:
				Sfx.play_var("step_stone", 3, -12.0)
		elif dir < -0.1:
			walk_k = maxf(0.0, walk_k - dt * 0.8)
		fig = (p[0] as Vector2).lerp(p[1], walk_k)
		if walk_k >= 1.0:
			climb_t = 0.0
	if door_t >= 0.0:
		door_t += dt
		# on the desktop the door does not give: a knock, and back to the title
		if not dream and door_t > 1.2:
			_to_title()
			return
		if door_t > 1.4:
			if dream:
				mode = "black"
				Sfx.music("", 0.0, 1.0)
				Sfx.stop_loop("mg_sea", 0.5)
				Sfx.play("low_boom", 0.0)
				await get_tree().create_timer(1.6, false).timeout
				stop()
				dream_done.emit()
			else:
				mode = "reject"
				sail_t = 0.0
				Sfx.music("", 0.0, 0.5)
				Sfx.play("red_sting", 0.0)
				flow.overlay.red_center = Txt.red("reject")
				flow.overlay.red_center_a = 1.0


func _update_planet() -> void:
	var r := 0.0
	var pos := Vector2(262, 30)
	match state:
		2: r = 6.0
		3: r = 11.0
		4: r = 18.0
		5: r = 28.0
	_planet.visible = r > 0.0 and mode != "black"
	if _planet.visible:
		_planet.position = pos - Vector2(r * 1.4, r * 1.4)
		_planet.size = Vector2(r * 2.8, r * 2.8)
		(_planet.material as ShaderMaterial).set_shader_parameter("beat_rate", 0.0 if state <= 2 else 1.0)


# ================================================================= draw
func _draw() -> void:
	if mode == "black":
		draw_rect(Rect2(0, 0, 320, 180), Color.BLACK)
		return
	_draw_sky()
	_draw_sea()
	if state == 5 and mode != "temple":
		_draw_church(Vector2(222, 64), 0.42)
	if mode in ["sail", "temple", "reject"]:
		_draw_church_big()
	for r in rocks:
		_draw_rock(r)
	if mode != "temple" and mode != "reject":
		_draw_boat(Vector2(BOAT_X, _boat_y()))
	else:
		_draw_boat(Vector2(church_x + 2, LANE_Y[2]))
		_draw_figure()
	match mode:
		"title":
			_draw_title()
		"run", "sail":
			_draw_hud()
		"over":
			_draw_hud()
			var df: PixelFont = G.day_font(5 if dream else G.day)
			draw_rect(Rect2(0, 70, 320, 40), Color(0, 0, 0, 0.55))
			df.draw_centered(self, Vector2(160, 86), Txt.ui("game.over"), Color.WHITE, 1, 1.5 if G.day == 4 else 0.0, int(t * 12.0))
			if over_t > 0.8:
				G.font.draw_centered(self, Vector2(160, 106), Txt.ui("game.click"), Color(0.9, 0.9, 0.9, 0.7 + 0.3 * sin(t * 4.0)), 1)
		"temple":
			if fig_k >= 1.0 and door_t < 0.0:
				var p := fig + Vector2(0, -44)
				draw_rect(Rect2(p.x - 5, p.y - 5, 10, 10), Color8(230, 230, 230))
				G.font_en.draw(self, p + Vector2(-2, -4), "E", Color8(20, 20, 20), 1)
			elif walk_k < 0.05 and climb_t < 0.0:
				G.font_en.draw_centered(self, Vector2(160, 172), "D", Color(1, 1, 1, 0.5 + 0.3 * sin(t * 4.0)), 1)
			if climb_t >= 0.0 and climb_t < CLIMB_T:
				draw_rect(Rect2(0, 0, 320, 180), Color(0, 0, 0, 1.0 - absf(climb_t / CLIMB_T * 2.0 - 1.0)))
	if hit_flash > 0.0:
		draw_rect(Rect2(0, 0, 320, 180), Color(0.6, 0.02, 0.05, hit_flash * 0.55))
	# the dream goes black at the door -- later, if it is showing its lights
	var fade_at := 0.6
	if mode == "temple" and door_t > fade_at:
		draw_rect(Rect2(0, 0, 320, 180), Color(0, 0, 0, clampf((door_t - fade_at) / 0.8, 0.0, 1.0) if dream else 0.0))


func _sky_colors() -> Array:
	match state:
		1, 2, 3:
			return [Color8(90, 150, 214), Color8(186, 216, 240)]
		4:
			return [Color8(60, 40, 60), Color8(190, 110, 110)]
		5:
			return [Color8(46, 10, 16), Color8(150, 40, 46)]
	return [Color8(90, 150, 214), Color8(186, 216, 240)]


func _draw_sky() -> void:
	var c: Array = _sky_colors()
	for y in range(0, int(HORIZON), 2):
		draw_rect(Rect2(0, y, 320, 2), (c[0] as Color).lerp(c[1], y / HORIZON))
	var cloud := Color(1, 1, 1, 0.75) if state <= 3 else Color(0.9, 0.6, 0.6, 0.35)
	for i in 4:
		var x := fposmod(i * 97.0 - t * (3.0 + i), 380.0) - 40.0
		var y := 16.0 + i * 13.0
		draw_rect(Rect2(floorf(x), y, 34 + i * 6, 4), cloud)
		draw_rect(Rect2(floorf(x) + 6, y - 3, 16 + i * 3, 3), cloud)


func _sea_colors() -> Array:
	if state >= 4:
		return [Color8(120, 20, 30), Color8(60, 8, 16), Color8(200, 80, 80)]
	return [Color8(60, 120, 180), Color8(26, 60, 110), Color8(200, 230, 245)]


func _draw_sea() -> void:
	var c: Array = _sea_colors()
	for y in range(int(HORIZON), 180):
		var k := (y - HORIZON) / (180.0 - HORIZON)
		draw_rect(Rect2(0, y, 320, 1), (c[0] as Color).lerp(c[1], k))
	draw_rect(Rect2(0, HORIZON, 320, 1), (c[2] as Color).lerp(c[0], 0.4))
	var spd := SPEED if mode in ["run", "sail"] else 8.0
	for i in 40:
		var row := i % 10
		var y := HORIZON + 3.0 + row * 8.0 + sin(t * 1.5 + i) * 1.0
		var depth := (y - HORIZON) / 80.0
		var w := 4.0 + depth * 14.0
		var x := fposmod(i * 71.0 - t * spd * (0.4 + depth * 0.8), 340.0) - 10.0
		draw_rect(Rect2(floorf(x), floorf(y), w, 1), Color(c[2].r, c[2].g, c[2].b, 0.35 + depth * 0.3))


func _draw_rock(r: Array) -> void:
	var ln: int = r[1]
	var n := "rock_%s_%d_%d" % ["blood" if blood else "stone", int(r[2]), ln]
	var tex: Texture2D = _tex.get(n, null)
	if tex == null:
		return
	var y: float = LANE_Y[ln] + 3.0
	var bob := sin(t * 2.0 + float(r[2])) * 0.5
	draw_texture(tex, Vector2(roundf(float(r[0]) - tex.get_width() * 0.5), roundf(y - tex.get_height() + bob)))


func _draw_boat(p: Vector2) -> void:
	var tex: Texture2D = _tex.get("boat_%d" % (int(_bob * 3.0) % 2), null)
	if tex == null:
		return
	var bob := roundf(sin(_bob * 2.6) * 1.0)
	draw_texture(tex, Vector2(roundf(p.x - tex.get_width() * 0.5), roundf(p.y - tex.get_height() + 3 + bob)))


func _draw_figure() -> void:
	if _player_tex == null:
		return
	var walking := absf(Input.get_axis("left", "right")) > 0.1 and climb_t < 0.0 and walk_k > 0.0 and walk_k < 1.0
	var frame := 2 + int(t * 9.0) % 6 if walking else 0
	if door_t >= 0.0:
		frame = 28 + int(door_t * 3.0) % 2
	var src := Rect2(frame * 24, 0, 24, 34)
	draw_texture_rect_region(_player_tex, Rect2(roundf(fig.x - 12), roundf(fig.y - 34), 24, 34), src)


func _draw_church(pos: Vector2, s: float) -> void:
	var tex: Texture2D = _tex.get("church", null)
	if tex:
		draw_texture_rect(tex, Rect2(pos, tex.get_size() * s), false, Color(0.8, 0.6, 0.6, 0.9))


func _draw_church_big() -> void:
	var tex: Texture2D = _tex.get("church", null)
	if tex == null:
		return
	var y := 180.0 - tex.get_height() + 8.0
	draw_texture(tex, Vector2(roundf(church_x), roundf(y)))
	# only the dream's door opens
	if mode == "temple" and door_t >= 0.0 and dream:
		var k := clampf(door_t / 1.0, 0.0, 1.0)
		draw_rect(Rect2(church_x + 98, y + 76, 16 * k, 36), Color(0, 0, 0, 1))


func _draw_title() -> void:
	var tt: Texture2D = _tex.get("title", null)
	if tt:
		draw_texture(tt, Vector2(roundf(160 - tt.get_width() * 0.5), 44))
	var st: Texture2D = _tex.get("start_%d" % (int(t * 1.5) % 2), null)
	if st:
		var sr := _start_rect()
		var lift := 1.0 if _hover_start else 0.0
		draw_texture(st, Vector2(roundf(sr.get_center().x - st.get_width() * 0.5), roundf(sr.get_center().y - st.get_height() * 0.5) - lift))
	if not dream:
		var cl: Texture2D = _tex.get("close", null)
		if cl:
			draw_texture(cl, _close_rect().position)
		var best := Txt.ui("game.best") % int(G.persist.get("best", 0))
		G.font.draw_shadowed(self, Vector2(6, 6), best, Color(1, 1, 1, 0.85), 1)
	G.font.draw_centered(self, Vector2(160, 150), Txt.ui("game.hint"), Color(1, 1, 1, 0.55), 1)


func _draw_hud() -> void:
	G.font.draw_shadowed(self, Vector2(6, 6), Txt.ui("game.score") % score, Color(1, 1, 1, 0.9), 1)
	if not dream:
		var cl: Texture2D = _tex.get("close", null)
		if cl:
			draw_texture(cl, _close_rect().position)
