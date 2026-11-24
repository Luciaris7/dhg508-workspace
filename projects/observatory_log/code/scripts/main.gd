extends Node
## Root. Builds the render stack and routes input by mode.
##
##  layer 0  world      SubViewport 320x180 -> x2, palette/dither post shader
##  layer 1  desktop    SubViewport 640x360 -> CRT shader (first person)
##  layer 2  minigame   SubViewport 320x180 -> x2, post shader (+CRT on the monitor)
##  layer 3  ending     SubViewport 640x360 -> post shader at 640
##  layer 5  overlay    monologue, prompts, cards, red text, fades
##  layer 8  fx         full-screen tear / shake (reads the composited screen)
##  layer 10 menu       title / pause / settings (never distorted)

## Developer shortcut: F1..F7 restart the run at that day. Set to false to
## remove the keys entirely (they are also listed in README and AGENTS.md).
const CHEATS := true

var world_vp: SubViewport
var world: World
var world_rect: TextureRect
var post_mat: ShaderMaterial

var desk_layer: CanvasLayer
var desk_vp: SubViewport
var desktop: Desktop
var desk_rect: TextureRect
var crt_mat: ShaderMaterial

var mg_layer: CanvasLayer
var mg_vp: SubViewport
var mg: MiniGame
var mg_rect: TextureRect
var mg_mat: ShaderMaterial

var end_layer: CanvasLayer
var end_vp: SubViewport
var ending: Ending
var end_rect: TextureRect
var end_mat: ShaderMaterial

var overlay: Overlay
var fx_rect: ColorRect
var fx_mat: ShaderMaterial
var menu: Menu
var flow: Flow

var mode := "boot"   # menu, world, desktop, dream, ending, cutscene
var _palette: Texture2D
var tear := 0.0
var shake := 0.0
var _t := 0.0


func _ready() -> void:
	_palette = load("res://assets/art/palette.png")
	# --- world
	var wl := CanvasLayer.new()
	wl.layer = 0
	add_child(wl)
	world_vp = _make_vp(Vector2i(320, 180))
	wl.add_child(world_vp)
	world = World.new()
	world_vp.add_child(world)
	post_mat = _make_post(Vector2(320, 180))
	world_rect = _make_rect(world_vp, Vector2(640, 360), post_mat)
	wl.add_child(world_rect)
	# --- desktop
	desk_layer = CanvasLayer.new()
	desk_layer.layer = 1
	add_child(desk_layer)
	desk_vp = _make_vp(Vector2i(640, 360))
	desk_layer.add_child(desk_vp)
	desktop = Desktop.new()
	desk_vp.add_child(desktop)
	crt_mat = ShaderMaterial.new()
	crt_mat.shader = load("res://shaders/crt.gdshader")
	desk_rect = _make_rect(desk_vp, Vector2(640, 360), crt_mat)
	desk_layer.add_child(desk_rect)
	desk_layer.visible = false
	# --- minigame
	mg_layer = CanvasLayer.new()
	mg_layer.layer = 2
	add_child(mg_layer)
	mg_vp = _make_vp(Vector2i(320, 180))
	mg_layer.add_child(mg_vp)
	mg = MiniGame.new()
	mg_vp.add_child(mg)
	mg_mat = _make_post(Vector2(320, 180))
	mg_rect = _make_rect(mg_vp, Vector2(640, 360), mg_mat)
	mg_layer.add_child(mg_rect)
	mg_layer.visible = false
	# --- ending
	end_layer = CanvasLayer.new()
	end_layer.layer = 3
	add_child(end_layer)
	end_vp = _make_vp(Vector2i(640, 360))
	end_layer.add_child(end_vp)
	ending = Ending.new()
	end_vp.add_child(ending)
	end_mat = _make_post(Vector2(640, 360))
	end_rect = _make_rect(end_vp, Vector2(640, 360), end_mat)
	end_layer.add_child(end_rect)
	end_layer.visible = false
	# --- overlay
	var ol := CanvasLayer.new()
	ol.layer = 5
	add_child(ol)
	overlay = Overlay.new()
	overlay.world = world
	ol.add_child(overlay)
	# --- fx
	var fl := CanvasLayer.new()
	fl.layer = 8
	add_child(fl)
	fx_mat = ShaderMaterial.new()
	fx_mat.shader = load("res://shaders/fx.gdshader")
	fx_rect = ColorRect.new()
	fx_rect.size = Vector2(640, 360)
	fx_rect.material = fx_mat
	fx_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_rect.visible = false
	fl.add_child(fx_rect)
	# --- menu
	var ml := CanvasLayer.new()
	ml.layer = 10
	add_child(ml)
	menu = Menu.new()
	menu.main = self
	ml.add_child(menu)
	# --- flow
	flow = Flow.new()
	flow.main = self
	add_child(flow)
	desktop.flow = flow
	mg.flow = flow
	# Main keeps routing input while paused (so the pause menu can close);
	# everything that is the game itself stops.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in [world_vp, desk_vp, mg_vp, end_vp, overlay, flow]:
		n.process_mode = Node.PROCESS_MODE_PAUSABLE
	get_tree().root.size_changed.connect(_on_resize)
	set_mode("menu")
	menu.open_title(true)


func _make_vp(sz: Vector2i) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = sz
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.snap_2d_transforms_to_pixel = true
	return vp


func _make_rect(vp: SubViewport, sz: Vector2, mat: ShaderMaterial) -> TextureRect:
	var r := TextureRect.new()
	r.texture = vp.get_texture()
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.size = sz
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.material = mat
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _make_post(res: Vector2) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/post.gdshader")
	m.set_shader_parameter("palette", _palette)
	m.set_shader_parameter("res", res)
	return m


func _on_resize() -> void:
	pass


func set_mode(m: String) -> void:
	mode = m
	desk_layer.visible = m == "desktop"
	mg_layer.visible = m == "dream" or (m == "desktop" and desktop.game_running())
	end_layer.visible = m == "ending"
	overlay.world_mode = m == "world"
	overlay.desk_mode = m == "desktop"
	world.process_mode = Node.PROCESS_MODE_INHERIT if m in ["world", "cutscene", "desktop"] else Node.PROCESS_MODE_INHERIT
	_update_cursor()


func _update_cursor() -> void:
	if menu and menu.is_open():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif mode == "desktop":
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	else:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func show_minigame_layer(on: bool, on_monitor: bool) -> void:
	mg_layer.visible = on
	mg_mat.set_shader_parameter("scan", 0.12 if on_monitor else 0.0)
	mg_mat.set_shader_parameter("vignette", 0.6 if on_monitor else 0.45)


# ================================================================ input
func _input(event: InputEvent) -> void:
	# Developer shortcut: F1..F7 restart the run at that day (see debug_jump).
	# Set CHEATS to false before shipping if the keys should not exist at all.
	if CHEATS and event is InputEventKey and event.pressed and not event.echo:
		var code: int = (event as InputEventKey).keycode
		if code >= KEY_F1 and code <= KEY_F7:
			debug_jump(code - KEY_F1 + 1)
			get_viewport().set_input_as_handled()
			return
	if menu.is_open():
		menu.handle(event)
		get_viewport().set_input_as_handled()
		return
	match mode:
		"desktop":
			if desktop.game_running():
				mg.handle(event)
			else:
				desktop.handle(event)
			get_viewport().set_input_as_handled()
		"dream":
			mg.handle(event)
			get_viewport().set_input_as_handled()
		"world":
			if event.is_action_pressed("pause") and not flow.wants_esc():
				menu.open_pause()
				get_viewport().set_input_as_handled()
				return
			flow.world_input(event)
		"cutscene", "ending":
			if event.is_action_pressed("interact"):
				overlay.accelerate()
				flow.cutscene_input(event)
			elif event.is_action_pressed("pause") and mode == "cutscene" and flow.pausable_cutscene:
				menu.open_pause()


## F1..F7 -> start that day from a fresh run. Reviewing day 5 should not mean
## playing days 1..4, and the seven nights are the part that needs checking.
var _jumping := false


func debug_jump(n: int) -> void:
	if _jumping:
		return
	_jumping = true
	await flow.debug_jump(n)
	_jumping = false


# ============================================================ per-frame
func _process(dt: float) -> void:
	_t += dt
	var tear_on: bool = G.settings["tear"]
	var tv := tear if tear_on else tear * 0.15
	var sh := Vector2.ZERO
	if shake > 0.0:
		shake = maxf(0.0, shake - dt * 2.5)
		sh = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake * 0.006
	fx_rect.visible = tv > 0.001 or shake > 0.0
	fx_mat.set_shader_parameter("tear", tv)
	fx_mat.set_shader_parameter("t", _t)
	fx_mat.set_shader_parameter("shake", sh)


func set_grade(day: int) -> void:
	var grade := Vector3(1, 1, 1)
	var lift := Vector3.ZERO
	var sat := 1.0
	var contrast := 1.0
	var red := 0.0
	match day:
		1:
			grade = Vector3(1.02, 1.0, 0.96)
		2:
			grade = Vector3(0.95, 0.99, 1.06)
		3:
			grade = Vector3(0.93, 1.02, 1.01)
			sat = 0.92
		4:
			grade = Vector3(0.99, 0.94, 1.03)
			sat = 0.78
		5:
			grade = Vector3(0.95, 0.96, 0.99)
			sat = 0.62
		6:
			grade = Vector3(1.03, 0.94, 0.94)
			sat = 0.88
			red = 0.04
		7:
			grade = Vector3(1.0, 0.88, 0.89)
			sat = 0.8
			contrast = 1.08
			red = 0.07
	for m in [post_mat, end_mat]:
		m.set_shader_parameter("grade", grade)
		m.set_shader_parameter("lift", lift)
		m.set_shader_parameter("sat", sat)
		m.set_shader_parameter("contrast", contrast)
		m.set_shader_parameter("red_shift", red)
	crt_mat.set_shader_parameter("red", 0.0)
