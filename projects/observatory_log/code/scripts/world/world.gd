class_name World
extends Node2D
## The side-scrolling world, rendered at 320x180 inside a SubViewport.
## Builds the three locations (outdoor strip, lookout cab, generator shed)
## and the prologue road from generated sprites. The player is always at the
## horizontal centre of the screen; everything else moves 1:1 opposite.

signal location_changed(loc: String)

const GROUND := 153
const CAM_Y := 90

var loc := ""
var bounds := Vector2(40, 990)
var interactables: Array = []
var focus: Dictionary = {}
var nodes := {}
var lights := {}

var player: Player
var cam: Camera2D
var sky_layer: CanvasLayer
var sky: SkyLayer
var ambient := Color(1, 1, 1)
var plain_mat: ShaderMaterial
var dish_mat: ShaderMaterial
var prop_mat: ShaderMaterial      # things the player uses: corruption stays at their edges

## Per location: the sprites the player interacts with (see prop_mat).
const PROTECTED := {
	"outdoor": ["truck", "sign", "tower", "shed", "trail_sign", "path_sign", "hole", "bucket"],
	"cab": ["door", "bed", "computer", "pills", "plant", "coats", "bookshelf", "radio", "desk", "chair", "lamp"],
	"shed": ["door", "can1", "can2", "generator", "axe", "workbench", "receiver"],
	"peak": ["trail_sign"],
	"boathouse": ["boathouse", "rowboat"],
}
var root: Node2D
var weather: Weather
var drive: Node2D

var can_move := false
var auto_target := INF
var auto_speed := 44.0
var power := true
var gen_running := false
var antenna_az := 0.0
var phase := 0.0          # sky phase 0 day / 1 dusk / 2 night
var flash := 0.0
var interior_dim := 0.0   # extra darkness for "dread" nights
var t := 0.0
var _light_tex: Texture2D
var _breath_t := 0.0
var _flicker := {}
var cam_off := 0.0


func _ready() -> void:
	sky_layer = CanvasLayer.new()
	sky_layer.layer = -1
	add_child(sky_layer)
	sky = SkyLayer.new()
	sky_layer.add_child(sky)
	plain_mat = ShaderMaterial.new()
	plain_mat.shader = G.flesh_mat.shader
	dish_mat = ShaderMaterial.new()
	dish_mat.shader = G.flesh_mat.shader
	dish_mat.set_shader_parameter("protect", 1.0)
	prop_mat = ShaderMaterial.new()
	prop_mat.shader = G.flesh_mat.shader
	prop_mat.set_shader_parameter("protect", 1.0)
	root = Node2D.new()
	add_child(root)
	player = Player.new()
	player.z_index = 5
	player.material = plain_mat
	add_child(player)
	weather = Weather.new()
	weather.z_index = 8
	weather.material = plain_mat
	add_child(weather)
	cam = Camera2D.new()
	cam.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	add_child(cam)
	cam.make_current()


static func _make_light_tex() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.35, Color(1, 1, 1, 0.55))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 128
	gt.height = 128
	return gt


# ================================================================ helpers
func _tex(path: String) -> Texture2D:
	return load("res://assets/art/%s.png" % path)


## Place a sprite with its bottom-centre at (x, bottom).
func spr(name: String, path: String, x: float, bottom: float = GROUND, flesh: bool = true, z: int = 0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = _tex(path)
	s.centered = false
	s.position = Vector2(roundf(x - s.texture.get_width() * 0.5), roundf(bottom - s.texture.get_height()))
	s.z_index = z
	s.material = G.flesh_mat if flesh else plain_mat
	root.add_child(s)
	if name != "":
		nodes[name] = s
	return s


func spr_at(name: String, path: String, pos: Vector2, flesh: bool = true, z: int = 0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = _tex(path)
	s.centered = false
	s.position = pos
	s.z_index = z
	s.material = G.flesh_mat if flesh else plain_mat
	root.add_child(s)
	if name != "":
		nodes[name] = s
	return s


func light(name: String, pos: Vector2, radius: float, color: Color, energy: float = 1.0, flicker: float = 0.0) -> void:
	lights[name] = {"pos": pos, "r": radius, "col": color, "base": energy, "k": 1.0, "flicker": flicker}


func _push_lights() -> void:
	var arr := PackedVector4Array()
	var cols := PackedVector4Array()
	for n in lights.keys():
		var l: Dictionary = lights[n]
		var e: float = float(l["base"]) * float(l["k"])
		if l["flicker"] > 0.0:
			e *= 1.0 - float(l["flicker"]) * (0.5 + 0.5 * sin(t * 13.0 + sin(t * 7.3) * 3.0))
		if e <= 0.001:
			continue
		var p: Vector2 = l["pos"]
		arr.append(Vector4(p.x, p.y, float(l["r"]), e))
		var c: Color = l["col"]
		cols.append(Vector4(c.r, c.g, c.b, 1.0))
		if arr.size() >= 8:
			break
	while arr.size() < 8:
		arr.append(Vector4(0, 0, 1, 0))
		cols.append(Vector4(0, 0, 0, 0))
	var origin := cam.position - Vector2(160, 90)
	for m in [G.flesh_mat, plain_mat, dish_mat, prop_mat]:
		m.set_shader_parameter("cam_origin", origin)
		m.set_shader_parameter("ambient", Vector3(ambient.r, ambient.g, ambient.b))
		for i in 8:
			m.set_shader_parameter("l%d" % i, arr[i])
			m.set_shader_parameter("c%d" % i, Vector3(cols[i].x, cols[i].y, cols[i].z))


func add_interact(id: String, x: float, lift: float, r: float = 14.0) -> void:
	interactables.append({"id": id, "x": x, "lift": lift, "r": r, "on": true})


func set_interact(id: String, on: bool) -> void:
	for it in interactables:
		if it["id"] == id:
			it["on"] = on


func has_interact(id: String) -> bool:
	for it in interactables:
		if it["id"] == id and it["on"]:
			return true
	return false


func interact_x(id: String) -> float:
	for it in interactables:
		if it["id"] == id:
			return float(it["x"])
	return player.position.x


# ============================================================== locations
func goto(l: String, x: float, facing: int = 1) -> void:
	for c in root.get_children():
		c.queue_free()
	nodes.clear()
	lights.clear()
	interactables.clear()
	focus = {}
	loc = l
	weather.mode = ""
	player.visible = true
	sky.show_backdrop = true
	if drive:
		drive.queue_free()
		drive = null
	match l:
		"outdoor":
			_build_outdoor()
		"cab":
			_build_cab()
		"shed":
			_build_shed()
		"road":
			_build_road()
		"climb":
			_build_climb()
		"peak":
			_build_peak()
		"boathouse":
			_build_boathouse()
	cam_off = 0.0
	for n in PROTECTED.get(l, []):
		if nodes.has(n):
			(nodes[n] as CanvasItem).material = prop_mat
	player.position = Vector2(x, ground_at(x))
	player.facing = facing
	apply_env()
	apply_light()
	_update_cam()
	location_changed.emit(l)


func _build_outdoor() -> void:
	bounds = Vector2(40, 990)
	player.surface = "snow"
	var bare: bool = G.env("bare_trees")
	# trees behind everything, world-anchored, deterministic
	var x := -220.0
	var i := 0
	while x < 960.0:
		var h := PixelFont._hash(i, 5)
		var v := int(h * 7.0)
		if absf(x - 300.0) < 40.0 and v < 2:
			v = 3
		var base := GROUND - 1 - int(PixelFont._hash(i, 9) * 5.0)
		var s := spr("", ("world/fir_bare_%d" if bare else "world/fir_%d") % v, x, base, true, -2)
		var shade := 0.78 + PixelFont._hash(i, 11) * 0.22
		s.self_modulate = Color(shade, shade, shade * 1.03)
		x += 12.0 + PixelFont._hash(i, 13) * 26.0
		i += 1
	var g := spr("ground", "world/ground_slush" if G.env("slush") else "world/ground", 0, GROUND + 27, true, -1)
	g.position = Vector2(-220, GROUND)
	g.region_enabled = true
	g.region_rect = Rect2(0, 0, 1185, 27)
	_dress_outdoor()
	spr("truck", "world/truck", 70, GROUND + 1)
	spr("sign", "world/sign", 150, GROUND + 1)
	spr("tower", "world/tower", 300, GROUND + 1)
	spr("shed", "world/shed", 540, GROUND + 1)
	# the trail up to the antenna on the hill (the antenna itself is in "peak"),
	# and the path along the shore to the boathouse
	spr("trail_sign", "props/trail_sign", 764, GROUND + 1)
	spr("path_sign", "props/path_sign", 905, GROUND + 1)
	var ice := spr_at("lake_ice", "world/lake_ice", Vector2(880, 127), true, -3)
	var lake := Lake.new()
	lake.z_index = -2
	root.add_child(lake)
	nodes["lake"] = lake
	spr_at("hole", "world/hole_open", Vector2(989, 148), true, -2)
	spr_at("shore", "world/lake_shore", Vector2(940, 142), true, -1)
	spr("bucket", "world/bucket", 972, GROUND + 1)
	ice.z_index = -3
	lake.z_index = -3
	var marks := GroundMarks.new()
	marks.material = plain_mat
	marks.z_index = 1
	marks.ravens = [0, 0, 1, 2, 4, 0, 7, 12][clampi(G.day, 0, 7)]
	root.add_child(marks)
	nodes["marks"] = marks
	# in front of everything, the observer included
	for fx in [22.0, 470.0, 846.0]:
		var s := spr("", "props/fg_reeds", fx, float(GROUND + 12), true, 7)
		s.self_modulate = Color(0.55, 0.55, 0.6)
	# lights
	light("tower_win", Vector2(300, 38), 70, Color(1.0, 0.78, 0.45), 0.0)
	light("tower_porch", Vector2(340, 132), 30, Color(1.0, 0.8, 0.5), 0.0)
	light("shed_win", Vector2(560, 128), 26, Color(1.0, 0.25, 0.2), 0.0)
	add_interact("tower_door", 340, 44)
	add_interact("shed_door", 537, 46)
	add_interact("trail_up", 764, 36, 12.0)
	add_interact("truck", 70, 40)
	add_interact("sign", 150, 40, 12.0)
	add_interact("footprints", 0, 18, 10.0)
	add_interact("shore_path", 905, 30, 12.0)
	add_interact("hole", 984, 42)
	set_interact("footprints", false)
	weather.mode = "blizzard" if G.env("storm") else ("snow" if G.env("snow") else "")


## Set dressing outdoors (tools/art_props.py): lived in, then left.
func _dress_outdoor() -> void:
	var bare: bool = G.env("bare_trees")
	for b in [[186.0, 2], [236.0, 0], [458.0, 1], [604.0, 0], [700.0, 2], [872.0, 1], [-30.0, 1]]:
		var s := spr("", "props/birch_%d" % int(b[1]), float(b[0]), GROUND, true, -2)
		if bare:
			s.self_modulate = Color(0.8, 0.72, 0.72)
	for px in [196.0, 430.0, 640.0]:
		spr("", "props/pole", px, GROUND + 1, true, -1)
	spr("", "props/mailbox", 112, GROUND + 1)
	spr("", "props/woodpile", 384, GROUND + 1)
	spr("", "props/block", 412, GROUND + 1)
	spr("", "props/crates", 476, GROUND + 1)
	spr("", "props/drum_1", 594, GROUND + 1)
	spr("", "props/drum_0", 606, GROUND + 1)
	spr("", "props/fuel_tank", 662, GROUND + 1)
	spr("", "props/snowmobile", 708, GROUND + 1)
	spr("", "props/fence_0", 800, GROUND + 1)
	spr("", "props/fence_1", 842, GROUND + 1)
	spr("", "props/ice_sign", 884, GROUND + 1)
	spr("", "props/rock_1", 126, GROUND + 2, true, 1)
	spr("", "props/rock_0", 452, GROUND + 2, true, 1)
	spr("", "props/rock_2", 724, GROUND + 2, true, 1)
	spr("", "props/rock_0", 928, GROUND + 2, true, 1)
	if not G.env("slush"):
		for d in [[24.0, 1], [170.0, 0], [272.0, 1], [500.0, 0], [628.0, 1], [818.0, 0]]:
			spr("", "props/drift_%d" % int(d[1]), float(d[0]), GROUND + 3, true, 1)
	for i in 26:
		var gx := -150.0 + PixelFont._hash(i, 21) * 1080.0
		spr("", "props/grass_%d" % (i % 3), gx, GROUND + 2 + int(PixelFont._hash(i, 22) * 6.0), true, 1)


func _build_cab() -> void:
	bounds = Vector2(160, 470)
	player.surface = "wood"
	spr("shell", "interior/cab", 280, 180, true, -3)
	_end_wall(560, Color8(30, 22, 20))
	for k in range(4):
		var fr := spr_at("frost_%d" % k, "interior/frost_%d" % k, Vector2(300, 60), false, -2)
		fr.visible = false
	spr("stain", "interior/stain_0", 275, 128, false, -2).visible = false
	spr("kitchen", "interior/kitchen", 70)
	spr("door", "interior/door", 170, GROUND + 1)
	spr("coats", "interior/coats", 198, 150)
	spr("stove", "interior/stove", 232)
	spr("rug", "interior/rug", 275, 156, true, -1)
	spr("bed", "interior/bed", 275)
	spr("chair", "interior/chair", 362)
	spr("desk", "interior/desk", 378)
	spr("computer", "interior/computer", 372, 127)
	spr("lamp", "interior/lamp", 356, 127)
	spr("pills", "interior/pills", 392, 127)
	spr("mug", "interior/mug", 401, 127)
	spr("bookshelf", "interior/bookshelf", 440)
	spr("radio", "interior/radio", 440, 87)
	spr("calendar", "interior/calendar", 480, 100)
	spr("chart_paper", "interior/chart_paper", 515, 96)
	spr("plant", "interior/plant_0", 350, 113)
	spr("ceiling_lamp", "interior/ceiling_lamp", 275, 38)
	# clutter (tools/art_props.py)
	spr("", "props/shelf_tins", 112, 92)
	spr("", "props/clock", 255, 62)
	spr("", "props/photo", 250, 104)
	spr("", "props/boots", 188, GROUND + 1)
	spr("", "props/snowshoes", 212, 112)
	spr("", "props/lake_map", 412, 94)
	spr("", "props/papers", 470, 98)
	spr("", "props/radiator", 410, GROUND - 1)
	var drips := Drips.new()
	drips.material = plain_mat
	root.add_child(drips)
	nodes["drips"] = drips
	light("ceiling", Vector2(275, 50), 190, Color(1.0, 0.84, 0.6), 0.9)
	light("desk_lamp", Vector2(362, 116), 64, Color(1.0, 0.8, 0.5), 1.0)
	light("monitor", Vector2(372, 116), 44, Color(0.45, 0.85, 0.9), 0.8)
	light("stove", Vector2(232, 140), 56, Color(1.0, 0.5, 0.2), 1.1, 0.25)
	light("window_day", Vector2(330, 86), 150, Color(0.8, 0.88, 1.0), 0.8)
	light("radio", Vector2(440, 80), 34, Color(1.0, 0.62, 0.25), 0.9, 0.3)
	add_interact("cab_door", 170, 56)
	add_interact("bed", 275, 40)
	add_interact("computer", 372, 60)
	add_interact("pills", 392, 38, 9.0)
	add_interact("plant", 350, 48, 9.0)
	add_interact("stain", 262, 70, 10.0)
	add_interact("window", 322, 74, 9.0)
	add_interact("coats", 200, 50, 9.0)
	add_interact("binder", 430, 40, 9.0)
	add_interact("radio", 452, 82, 9.0)
	set_interact("coats", false)
	set_interact("pills", false)
	set_interact("stain", false)
	set_interact("window", false)


func _build_shed() -> void:
	bounds = Vector2(150, 352)
	player.surface = "metal"
	spr("shell", "interior/shed", 210, 180, true, -3)
	_end_wall(420, Color8(28, 30, 36))
	spr("shelves", "interior/shelves", 90)
	spr("door", "interior/door_metal", 165, GROUND + 1)
	spr("can1", "interior/jerrycan", 190)
	spr("can2", "interior/jerrycan", 203)
	spr("generator", "interior/generator_on" if gen_running else "interior/generator", 232)
	spr("axe", "interior/axe", 262, 122)
	spr("workbench", "interior/workbench", 330)
	var rcv := spr("receiver", "interior/radio", 312, 124)
	rcv.self_modulate = Color(0.85, 0.95, 0.8)
	rcv.visible = not G.persist.get("has_receiver", false)
	spr("bulb", "interior/bulb", 232, 74)
	spr("", "props/tarp_box", 112, GROUND + 1)
	spr("", "props/tyres", 136, GROUND + 1)
	spr("", "props/chain", 204, 76)
	spr("", "props/shovel", 278, GROUND + 1)
	spr("", "props/toolbox", 352, 124)
	spr("", "props/drum_1", 398, GROUND + 1)
	light("bulb", Vector2(232, 72), 150, Color(1.0, 0.85, 0.6), 1.2, 0.08)
	light("gen_lamp", Vector2(249, 119), 20, Color(1.0, 0.2, 0.15), 0.0)
	add_interact("shed_exit", 165, 58)
	add_interact("can", 196, 40)
	add_interact("generator", 232, 58)
	add_interact("axe", 262, 46, 10.0)
	add_interact("receiver", 312, 40, 10.0)
	set_interact("axe", false)


# ============================================================ the hill
## Ground height under x. Flat everywhere except on the way up and on top.
const PEAK_TOP := 128.0
const CLIMB_LEN := 680.0
const FENCE_X := 505.0


func ground_at(x: float) -> float:
	match loc:
		"climb":
			return GROUND - clampf(x, 0.0, CLIMB_LEN) * 0.075
		"peak":
			if x < 100.0:
				return GROUND
			if x < 260.0:
				return lerpf(GROUND, PEAK_TOP, smoothstep(100.0, 260.0, x))
			if x < 380.0:
				return PEAK_TOP
			return lerpf(PEAK_TOP, 140.0, smoothstep(380.0, 470.0, x))
	return GROUND


func _ground_layer(x0: float, x1: float, col: Color, z: int = -1) -> void:
	var g := DrawLayer.new()
	g.material = G.flesh_mat
	g.z_index = z
	g.cb = func(ci: Node2D) -> void:
		var x := x0
		while x < x1:
			var y := ground_at(x)
			ci.draw_rect(Rect2(x, y, 2, 200), col)
			ci.draw_rect(Rect2(x, y, 2, 1), Color(0.97, 0.98, 1.0))
			if PixelFont._hash(int(x), 3) < 0.25:
				ci.draw_rect(Rect2(x, y + 2 + PixelFont._hash(int(x), 4) * 10.0, 2, 1), col.darkened(0.12))
			x += 2.0
	root.add_child(g)


func _slope_trees(x0: float, x1: float, step: float, salt: int, bare: bool) -> void:
	var x := x0
	var i := 0
	while x < x1:
		var v := int(PixelFont._hash(i, salt) * 7.0)
		var s := spr("", ("world/fir_bare_%d" if bare else "world/fir_%d") % v, x, ground_at(x) + 1, true, -2)
		var shade := 0.7 + PixelFont._hash(i, salt + 1) * 0.25
		s.self_modulate = Color(shade, shade, shade * 1.03)
		x += step * (0.6 + PixelFont._hash(i, salt + 2) * 0.8)
		i += 1


func _build_climb() -> void:
	## Up through the snow forest: the slope rises, night falls on the way.
	bounds = Vector2(0, CLIMB_LEN)
	player.surface = "snow"
	var bare: bool = G.env("bare_trees")
	_slope_trees(-200, CLIMB_LEN + 220, 22.0, 31, bare)
	_slope_trees(-180, CLIMB_LEN + 200, 40.0, 37, bare)
	_ground_layer(-200, CLIMB_LEN + 220, Color(0.86, 0.9, 0.95))
	weather.mode = "blizzard" if G.env("storm") else "snow"


func _build_peak() -> void:
	## The hilltop: the trail on the left, the antenna on the summit, a fence
	## on the right over the drop, and below it the whole lake.
	bounds = Vector2(40, FENCE_X - 6.0)
	player.surface = "snow"
	var bare: bool = G.env("bare_trees")
	var vista := DrawLayer.new()
	vista.z_index = -3
	vista.material = G.flesh_mat
	vista.cb = _draw_vista
	root.add_child(vista)
	_slope_trees(-220, 230, 24.0, 41, bare)
	_slope_trees(400, 470, 30.0, 43, bare)
	_ground_layer(-220, FENCE_X + 14.0, Color(0.86, 0.9, 0.95))
	# the drop beyond the fence
	var cliff := DrawLayer.new()
	cliff.z_index = -1
	cliff.material = G.flesh_mat
	cliff.cb = func(ci: Node2D) -> void:
		ci.draw_rect(Rect2(FENCE_X + 14, 140, 6, 60), Color8(40, 46, 60))
		for y in range(140, 200, 3):
			ci.draw_rect(Rect2(FENCE_X + 14 + PixelFont._hash(y, 2) * 6.0, y, 3, 3), Color8(28, 32, 44))
	root.add_child(cliff)
	spr("trail_sign", "props/trail_sign_down", 52, GROUND + 1)
	spr("", "props/rock_2", 150, ground_at(150) + 2, true, 1)
	spr("", "props/rock_1", 420, ground_at(420) + 2, true, 1)
	spr("", "props/fence_0", FENCE_X - 4, ground_at(FENCE_X) + 1)
	spr("", "props/pole", 236, ground_at(236) + 1, true, -1)
	var sx := 336.0
	var gy := PEAK_TOP
	spr("mast", "world/mast", sx, gy + 1)
	var dish := spr_at("dish", "world/dish_00", Vector2(sx - 22, gy + 1 - 72))
	dish.material = dish_mat
	nodes["mast"].material = dish_mat
	nodes["dish_mat"] = dish_mat
	spr("junction", "world/junction", sx + 24, gy + 1)
	nodes["junction"].material = dish_mat
	light("beacon", Vector2(sx, gy - 70), 18, Color(1.0, 0.15, 0.1), 0.0)
	var lift := GROUND - gy
	add_interact("trail_down", 52, 36, 12.0)
	# he works the dish from beside the mast, not in front of it
	add_interact("antenna", sx - 18, 78 + lift)
	add_interact("junction", sx + 24, 42 + lift, 10.0)
	set_interact("junction", false)
	weather.mode = "blizzard" if G.env("storm") else ("snow" if G.env("snow") else "")
	set_antenna_az(antenna_az)


## The abandoned boathouse up the north shore: survey point A at the end of its
## jetty, a locker by the door, an overturned boat frozen into the shore ice
## (on Day 7 the ice round it has turned to tissue, and it can be lifted).
const BOAT_X := 128.0
const STAKE_BOAT_X := 384.0


func _build_boathouse() -> void:
	bounds = Vector2(40, 396)
	player.surface = "snow"
	var bare: bool = G.env("bare_trees")
	_slope_trees(-200, 200, 22.0, 61, bare)
	var ice := spr_at("lake_ice", "world/lake_ice", Vector2(150, 127), true, -3)
	ice.texture = _tex("world/lake_ice_blood" if float(G.env("water_red")) >= 0.6 else "world/lake_ice")
	var g := spr("ground", "world/ground_slush" if G.env("slush") else "world/ground", 0, GROUND + 27, true, -1)
	g.position = Vector2(-220, GROUND)
	g.region_enabled = true
	g.region_rect = Rect2(0, 0, 520, 27)
	spr("boathouse", "props/boathouse", 252, GROUND + 1)
	# the jetty out over the ice, and survey point A at its end
	var jetty := DrawLayer.new()
	jetty.material = G.flesh_mat
	jetty.cb = func(ci: Node2D) -> void:
		ci.draw_rect(Rect2(310, GROUND - 2, 92, 3), Color8(70, 52, 40))
		ci.draw_rect(Rect2(310, GROUND - 2, 92, 1), Color8(236, 240, 246))
		for px in range(316, 402, 14):
			ci.draw_rect(Rect2(px, GROUND + 1, 2, 10), Color8(40, 30, 24))
		for px in range(312, 400, 4):
			ci.draw_rect(Rect2(px, GROUND - 2, 1, 3), Color8(50, 36, 28))
		var sx := STAKE_BOAT_X
		ci.draw_rect(Rect2(sx, GROUND - 17, 1, 15), Color8(70, 52, 40))
		ci.draw_rect(Rect2(sx + 1, GROUND - 17, 1, 15), Color8(40, 30, 24))
		var logged := (G.f.get("survey", {}) as Dictionary).has("stake_boat")
		ci.draw_rect(Rect2(sx + 2, GROUND - 17, 5, 3), Color8(90, 150, 90) if logged else Color8(200, 40, 36))
		if G.day >= 7:
			# the ice under the boat is not ice any more
			ci.draw_rect(Rect2(BOAT_X - 34, GROUND, 68, 5), Color8(120, 24, 34))
			ci.draw_rect(Rect2(BOAT_X - 28, GROUND + 4, 56, 3), Color8(80, 12, 20))
			for k in 9:
				ci.draw_rect(Rect2(BOAT_X - 30 + k * 7, GROUND + 1 + (k % 3), 4, 1), Color8(190, 70, 76))
	root.add_child(jetty)
	var boat := spr("rowboat", "props/rowboat", BOAT_X, GROUND + 3)
	if G.day >= 7:
		boat.self_modulate = Color(1.0, 0.86, 0.86)
	spr("", "props/rock_1", 74, GROUND + 2, true, 1)
	spr("", "props/path_sign_back", 52, GROUND + 1)
	for gx in [60.0, 92.0, 172.0, 300.0]:
		spr("", "props/grass_%d" % (int(gx) % 3), gx, GROUND + 3, true, 1)
	spr("", "props/fg_reeds", 330.0, float(GROUND + 12), true, 7).self_modulate = Color(0.55, 0.55, 0.6)
	add_interact("shore_back", 52, 30, 12.0)
	add_interact("boat", BOAT_X, 26, 18.0)
	add_interact("locker", 208, 40, 9.0)
	add_interact("stake_boat", STAKE_BOAT_X, 30, 10.0)
	set_interact("locker", false)
	weather.mode = "blizzard" if G.env("storm") else ("snow" if G.env("snow") else "")


## The view from the fence: the lake far below, the forest round it, the site's
## tower on the shore -- and in the middle of the ice, what is coming up.
func _draw_vista(ci: Node2D) -> void:
	var x0 := FENCE_X - 40.0
	var w := 420.0
	var horizon := 112.0
	ci.draw_rect(Rect2(x0, horizon, w, 120), Color8(46, 60, 82))
	for k in 60:
		var fx := x0 + PixelFont._hash(k, 51) * w
		var fy := horizon + 4.0 + PixelFont._hash(k, 52) * 30.0
		var h := 4.0 + PixelFont._hash(k, 53) * 5.0
		for j in int(h):
			ci.draw_rect(Rect2(fx - j * 0.4, fy - h + j, 1.0 + j * 0.8, 1), Color8(24, 38, 40))
	# the lake: a long pale oval of ice
	var lc := Vector2(x0 + 230.0, horizon + 44.0)
	for y in range(-14, 15):
		var hw := 150.0 * sqrt(maxf(0.0, 1.0 - (y * y) / 196.0))
		var col := Color8(170, 188, 208).lerp(Color8(120, 40, 48), float(G.env("water_red")) * 0.7)
		ci.draw_rect(Rect2(lc.x - hw, lc.y + y, hw * 2.0, 1), col)
	# the ring in the middle, then the thing itself
	var dep := G.source_depth()
	if G.day >= 4:
		for a in 40:
			var ang := TAU * a / 40.0
			ci.draw_rect(Rect2(lc.x + cos(ang) * 10.0, lc.y + sin(ang) * 2.5, 1, 1), Color8(40, 30, 40))
	if dep < 4.0:
		var hgt := (4.0 - dep) * 3.0
		ci.draw_rect(Rect2(lc.x - 3, lc.y - hgt, 6, hgt), Color8(120, 24, 30))
		ci.draw_rect(Rect2(lc.x - 1, lc.y - hgt - 4, 2, 4), Color8(120, 24, 30))
	# the site on the near shore: the tower, its window
	var tx := x0 + 120.0
	var ty := horizon + 38.0
	ci.draw_rect(Rect2(tx, ty - 9, 1, 9), Color8(40, 30, 26))
	ci.draw_rect(Rect2(tx + 4, ty - 9, 1, 9), Color8(40, 30, 26))
	ci.draw_rect(Rect2(tx - 1, ty - 13, 7, 4), Color8(60, 44, 36))
	if phase > 1.6 and power:
		ci.draw_rect(Rect2(tx + 1, ty - 12, 3, 2), Color8(250, 210, 140))


## Past the right edge of an interior's art: the end wall in shadow, so the
## centred camera never looks out into the sky.
func _end_wall(x0: float, col: Color) -> void:
	var w := DrawLayer.new()
	w.material = plain_mat
	w.z_index = -3
	w.cb = func(ci: Node2D) -> void:
		ci.draw_rect(Rect2(x0 - 2, 0, 420, 180), col)
		ci.draw_rect(Rect2(x0 - 2, 0, 2, 180), col.lightened(0.15))
		ci.draw_rect(Rect2(x0 - 2, GROUND, 420, 27), col.darkened(0.35))
	root.add_child(w)


func _build_road() -> void:
	bounds = Vector2(-100000, 100000)
	player.visible = false
	sky.show_backdrop = false
	weather.mode = "snow"
	drive = Drive.new()
	drive.material = plain_mat
	root.add_child(drive)


# =================================================================== env
func apply_env() -> void:
	G.flesh_mat.set_shader_parameter("amount", float(G.env("flesh")))
	prop_mat.set_shader_parameter("amount", float(G.env("flesh")))
	sky.storm = G.env("storm")
	sky.show_moon = G.day < 7
	var obj: float = G.env("sky_object")
	if obj == 0.0 and G.day in [3, 4] and G.f.get("marked", false) and G.tod == "night":
		obj = 1.2
	sky.object_size = obj
	sky.object_pos = Vector2(246, 34) if G.day < 7 else Vector2(220, 52)
	sky.aurora = float(G.env("aurora"))
	if nodes.has("dish_mat"):
		(nodes["dish_mat"] as ShaderMaterial).set_shader_parameter("amount", float(G.env("flesh")))
	match loc:
		"cab":
			var pl: int = G.env("plant")
			(nodes["plant"] as Sprite2D).texture = _tex("interior/plant_%d" % mini(pl, 3))
			var fr: float = G.env("frost")
			for k in range(4):
				nodes["frost_%d" % k].visible = false
			if fr > 0.0:
				nodes["frost_%d" % clampi(int(fr * 3.99), 0, 3)].visible = true
			var st: float = G.env("stain")
			var s: Sprite2D = nodes["stain"]
			s.visible = st > 0.0
			if st > 0.0:
				s.texture = _tex("interior/stain_%d" % clampi(int(st * 2.99), 0, 2))
			set_interact("stain", st > 0.0 and G.day == 4)
			nodes["drips"].active = G.day >= 5
			nodes["pills"].visible = true
		"outdoor":
			var frozen: bool = G.env("ice")
			var broke: bool = G.f.get("ice_broken", false)
			var hole := "world/hole_open"
			if frozen:
				hole = "world/hole_broken" if broke else "world/hole_frozen"
			(nodes["hole"] as Sprite2D).texture = _tex(hole)
			(nodes["lake_ice"] as Sprite2D).texture = _tex("world/lake_ice_blood" if float(G.env("water_red")) >= 0.6 else "world/lake_ice")
			(nodes["lake"] as Lake).red = float(G.env("water_red"))
			(nodes["lake"] as Lake).frozen = frozen
			(nodes["lake"] as Lake).broken = broke
			(nodes["lake"] as Lake).storm = G.env("storm")
			var fp: float = G.env("footprints")
			(nodes["marks"] as GroundMarks).prints_to = fp
			for it in interactables:
				if it["id"] == "footprints":
					it["x"] = fp + 8.0
			set_interact("footprints", fp > 0.0)
		"shed":
			pass


## Lighting state for the current location from phase / power / generator.
func apply_light() -> void:
	var night := clampf(phase - 1.0, 0.0, 1.0)
	var dusk := clampf(phase, 0.0, 1.0) * (1.0 - night)
	match loc:
		"outdoor", "road", "climb", "peak", "boathouse":
			var day_c := Color(1, 1, 1)
			var dusk_c := Color(1.0, 0.76, 0.68)
			var night_c := Color(0.36, 0.41, 0.6)
			var c := day_c.lerp(dusk_c, clampf(phase, 0.0, 1.0)).lerp(night_c, night)
			if sky.storm:
				c = c * Color(0.62, 0.64, 0.72)
			if G.day >= 6:
				c = c * Color(1.0, 0.82, 0.82)
			ambient = c.lerp(Color(1.6, 1.6, 1.7), flash)
			if loc == "outdoor":
				var lit := night * (1.0 if power else 0.0)
				_set_light("tower_win", lit * 1.1)
				_set_light("tower_porch", lit * 0.9)
				_set_light("shed_win", (1.0 if gen_running else 0.0) * maxf(night, dusk * 0.6) * 0.9)
			if loc == "peak":
				_set_light("beacon", night * (1.0 if power else 0.0) * (0.5 + 0.5 * signf(sin(t * 2.0))))
		"cab":
			var dark := Color(0.2, 0.21, 0.27)
			var day_in := Color(0.55, 0.55, 0.6)
			var c := day_in.lerp(Color(0.42, 0.34, 0.36), dusk).lerp(dark, night)
			if not power:
				c = c * 0.55
			c = c * (1.0 - interior_dim * 0.4)
			ambient = c.lerp(Color(1.5, 1.5, 1.6), flash * 0.7)
			var on := 1.0 if power else 0.0
			_set_light("ceiling", on * (0.25 + 0.75 * maxf(night, dusk * 0.6)) * (1.0 - interior_dim * 0.5))
			_set_light("desk_lamp", on * (0.4 + 0.6 * night))
			_set_light("monitor", on)
			_set_light("stove", 1.0)
			_set_light("window_day", (1.0 - night) * (0.9 - dusk * 0.4) * (0.4 if sky.storm else 1.0))
			# the receiver's dial glows only on the one night it has something to say
			_set_light("radio", on * (1.0 if G.f.get("radio_on", false) else 0.0))
			if nodes.has("computer"):
				(nodes["computer"] as Sprite2D).texture = _tex("interior/computer" if power else "interior/computer_off")
		"shed":
			var c := Color(0.4, 0.41, 0.47) if power or gen_running else Color(0.14, 0.14, 0.18)
			ambient = c.lerp(Color(1.5, 1.5, 1.6), flash * 0.5)
			_set_light("bulb", 1.0 if (power or gen_running) else 0.0)
			_set_light("gen_lamp", 1.0 if gen_running else 0.0)


func _set_light(n: String, k: float) -> void:
	if lights.has(n):
		lights[n]["k"] = k


func set_generator(on: bool) -> void:
	gen_running = on
	if loc == "shed" and nodes.has("generator"):
		(nodes["generator"] as Sprite2D).texture = _tex("interior/generator_on" if on else "interior/generator")
	apply_light()


func set_power(on: bool) -> void:
	power = on
	apply_light()


func set_antenna_az(az: float) -> void:
	antenna_az = fposmod(az, 360.0)
	if nodes.has("dish"):
		var idx := int(roundf(antenna_az / 22.5)) % 16
		(nodes["dish"] as Sprite2D).texture = _tex("world/dish_%02d" % idx)


# ================================================================= sky
func set_phase(p: float, dur: float = 2.0) -> void:
	var tw := create_tween()
	tw.tween_method(_apply_phase, phase, p, maxf(dur, 0.01))


func _apply_phase(p: float) -> void:
	phase = p
	sky.phase = p
	# sun: centre at day, sinking through dusk, gone at night; moon rises
	if p <= 1.0:
		sky.sun_y = lerpf(40.0, 96.0, p)
		sky.moon_y = 220.0
	else:
		var k := p - 1.0
		sky.sun_y = lerpf(96.0, 175.0, clampf(k / 0.4, 0.0, 1.0))
		sky.moon_y = lerpf(190.0, 44.0, clampf((k - 0.4) / 0.6, 0.0, 1.0))
	apply_light()


func phase_for_tod(tod: String) -> float:
	match tod:
		"dusk": return 1.0
		"night": return 2.0
	return 0.0


func lightning(strength: float = 1.0) -> void:
	var s := strength if G.settings["flash"] else strength * 0.25
	var tw := create_tween()
	tw.tween_method(_set_flash, s, 0.0, 0.18)
	tw.tween_interval(0.08)
	tw.tween_method(_set_flash, s * 0.7, 0.0, 0.35)


func _set_flash(v: float) -> void:
	flash = v
	sky.flash = v
	apply_light()


# =============================================================== update
func _process(dt: float) -> void:
	t += dt
	if loc == "peak" and lights.has("beacon"):
		apply_light()
	_move(dt)
	_update_focus()
	_update_cam()
	_push_lights()
	if loc in ["outdoor", "peak", "climb", "boathouse"] and G.env("breath"):
		_breath_t += dt
		if _breath_t > 2.6:
			_breath_t = 0.0
			weather.puff(player.position + Vector2(player.facing * 5, -27), player.facing)


func _move(dt: float) -> void:
	var dir := 0.0
	if auto_target != INF:
		var d := auto_target - player.position.x
		dir = signf(d)
		# Clamp the step so a long frame cannot overshoot and oscillate.
		player.position.x = move_toward(player.position.x, auto_target, auto_speed * dt)
		player.position.y = ground_at(player.position.x)
		if player.position.x == auto_target:
			auto_target = INF
		player.step(dt, dir)
		return
	if can_move and player.pose == "":
		dir = Input.get_axis("left", "right")
	player.position.x = clampf(player.position.x + dir * Player.SPEED * dt, bounds.x, bounds.y)
	player.position.y = ground_at(player.position.x)
	if (player.position.x <= bounds.x and dir < 0) or (player.position.x >= bounds.y and dir > 0):
		dir = 0.0 if not can_move else dir
	player.step(dt, dir)


func _update_cam() -> void:
	var px := roundf(player.position.x)
	var cy := float(CAM_Y)
	if loc == "road" and drive:
		px = roundf(drive.get("cam_x"))
	if loc in ["climb", "peak"]:
		# follow the slope a little, so the hill reads as a hill
		cy = CAM_Y + (player.position.y - GROUND) * 0.6
	if loc == "peak":
		# at the fence the view swings out over the lake; away from it, back
		var want := 130.0 * smoothstep(FENCE_X - 90.0, FENCE_X - 20.0, player.position.x)
		cam_off = lerpf(cam_off, want, clampf(get_process_delta_time() * 2.5, 0.0, 1.0))
		px = roundf(px + cam_off)
	cam.position = Vector2(px, roundf(cy))
	weather.cam_x = px


func _update_focus() -> void:
	focus = {}
	if not player.visible:
		return
	var best := 1e9
	for it in interactables:
		if not it["on"]:
			continue
		var d := absf(float(it["x"]) - player.position.x)
		if d <= float(it["r"]) and d < best:
			best = d
			focus = it


## Screen position (640x360 space) of a world point.
func to_screen(p: Vector2) -> Vector2:
	return (p - cam.position + Vector2(160, 90)) * 2.0
