class_name Menu
extends Node2D
## Title, pause and settings screens. Keyboard (W/S, A/D, E/Enter, Esc) and mouse.

var main: Node
var page := ""            # "", warn, title, pause, settings, confirm
var _back_page := ""
var items: Array = []
var sel := 0
var t := 0.0
var _flakes: Array = []
var _tower: Texture2D
var _warn_t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_tower = load("res://assets/art/world/tower.png")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 120:
		_flakes.append([rng.randf_range(0, 640), rng.randf_range(0, 360), rng.randf_range(0.4, 1.0)])


func is_open() -> bool:
	return page != ""


func open_title(first: bool) -> void:
	get_tree().paused = false
	page = "warn" if first else "title"
	_warn_t = 0.0
	_build()
	Sfx.music("music_menu", -6.0, 2.0)
	main._update_cursor()


func open_pause() -> void:
	page = "pause"
	get_tree().paused = true
	_build()
	Sfx.play("ui_open", -10.0)
	main._update_cursor()


func close() -> void:
	page = ""
	get_tree().paused = false
	main._update_cursor()


func _build() -> void:
	sel = 0
	match page:
		"title":
			items = []
			if G.has_save():
				var d := _save_day()
				# after the shed on Day 5 took him: offer that day again, plainly
				var key := "menu.retry" if int(G.persist.get("retry_day", 0)) == d else "menu.continue"
				items.append(["continue", Txt.ui(key) % d])
			items.append(["new", Txt.ui("menu.new")])
			items.append(["settings", Txt.ui("menu.settings")])
			items.append(["quit", Txt.ui("menu.quit")])
		"pause":
			items = [["resume", Txt.ui("menu.resume")], ["restart", Txt.ui("menu.restart_day")],
				["settings", Txt.ui("menu.settings")], ["title", Txt.ui("menu.to_title")]]
		"settings":
			items = [["lang", Txt.ui("set.lang")], ["master", Txt.ui("set.master")], ["music", Txt.ui("set.music")], ["sfx", Txt.ui("set.sfx")],
				["amb", Txt.ui("set.amb")], ["flash", Txt.ui("set.flash")], ["tear", Txt.ui("set.tear")],
				["assist", Txt.ui("set.assist")], ["fullscreen", Txt.ui("set.fullscreen")], ["back", Txt.ui("menu.back")]]
		"confirm":
			items = [["no", Txt.ui("menu.no")], ["yes", Txt.ui("menu.yes")]]


func _save_day() -> int:
	if FileAccess.file_exists(G.SAVE_PATH):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(G.SAVE_PATH))
		if typeof(d) == TYPE_DICTIONARY:
			return int(d.get("day", 1))
	return 1


func _item_rect(i: int) -> Rect2:
	var y0 := 200 if page == "title" else 116
	if page == "confirm":
		y0 = 190
	return Rect2(220, y0 + i * 22, 200, 18)


# ================================================================ input
func handle(e: InputEvent) -> void:
	if page == "warn":
		if (e is InputEventKey and e.pressed) or (e is InputEventMouseButton and e.pressed):
			if _warn_t > 0.6:
				page = "title"
				_build()
		return
	if e is InputEventMouseMotion:
		for i in items.size():
			if _item_rect(i).has_point(e.position):
				if sel != i:
					sel = i
					Sfx.play("ui_tick", -14.0)
		return
	if e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_LEFT:
			for i in items.size():
				if _item_rect(i).has_point(e.position):
					sel = i
					_activate(0)
		return
	if not (e is InputEventKey and e.pressed):
		return
	if e.is_action_pressed("up"):
		sel = posmod(sel - 1, items.size())
		Sfx.play("ui_tick", -12.0)
	elif e.is_action_pressed("down"):
		sel = posmod(sel + 1, items.size())
		Sfx.play("ui_tick", -12.0)
	elif e.is_action_pressed("left"):
		_activate(-1)
	elif e.is_action_pressed("right"):
		_activate(1)
	elif e.is_action_pressed("interact"):
		_activate(0)
	elif e.is_action_pressed("pause"):
		match page:
			"pause":
				close()
			"settings", "confirm":
				page = _back_page
				_build()
				Sfx.play("ui_back", -10.0)


func _activate(dir: int) -> void:
	var id: String = items[sel][0]
	if page == "settings":
		_setting(id, dir)
		return
	if dir != 0:
		return
	Sfx.play("ui_ok", -8.0)
	match id:
		"continue":
			close()
			Sfx.music("", 0.0, 1.5)
			main.flow.continue_game()
		"new":
			if G.has_save():
				_back_page = page
				page = "confirm"
				_build()
			else:
				_start_new()
		"yes":
			_start_new()
		"no":
			page = _back_page
			_build()
		"settings":
			_back_page = page
			page = "settings"
			_build()
		"quit":
			get_tree().quit()
		"resume":
			close()
		"restart":
			close()
			main.flow.restart_day()
		"title":
			close()
			main.flow.to_title()


func _start_new() -> void:
	close()
	Sfx.music("", 0.0, 1.5)
	main.flow.new_game()


func _setting(id: String, dir: int) -> void:
	var s: Dictionary = G.settings
	match id:
		"master", "music", "sfx", "amb":
			var v := float(s[id])
			if dir == 0:
				dir = 1 if v < 1.0 else -10
			s[id] = clampf(roundf((v + dir * 0.1) * 10.0) / 10.0, 0.0, 1.0)
		"flash", "tear", "fullscreen":
			s[id] = not bool(s[id])
		"assist":
			s[id] = posmod(int(s.get(id, 0)) + (dir if dir != 0 else 1), 3)
		"lang":
			G.set_lang("en" if String(s.get("lang", "en")) == "zh" else "zh")
			var keep := sel
			_build()
			sel = keep
			Sfx.play("ui_tick", -10.0)
			return
		"back":
			if dir == 0:
				page = _back_page
				_build()
				Sfx.play("ui_back", -10.0)
			return
	Sfx.play("ui_tick", -10.0)
	G.save_settings()


# ================================================================= draw
func _process(dt: float) -> void:
	t += dt
	_warn_t += dt
	if page != "":
		queue_redraw()
	elif visible:
		queue_redraw()


func _draw() -> void:
	if page == "":
		return
	var f: PixelFont = G.font
	if page == "warn":
		draw_rect(Rect2(0, 0, 640, 360), Color.BLACK)
		for i in 3:
			f.draw_centered(self, Vector2(320, 150 + i * 22), Txt.ui("warn.%d" % (i + 1)), Color(0.8, 0.8, 0.8), 1)
		return
	if page == "title" or (page in ["settings", "confirm"] and _back_page == "title"):
		_draw_title_bg()
	else:
		draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.72))
	match page:
		"title":
			if G.persist.get("finished", false):
				var df: PixelFont = G.day_font(7)
				df.draw_centered(self, Vector2(320, 120), Txt.red("title"), Color(1, 1, 1, 0.92), 2)
				if Txt.red("title_sub") != "":
					G.day_fonts_en[7].draw_centered(self, Vector2(320, 162), Txt.red("title_sub"), Color(1, 1, 1, 0.7), 1)
		"pause":
			G.font.draw_centered(self, Vector2(320, 90), Txt.ui("hud.day") % G.day, Color(0.8, 0.82, 0.86), G.bs)
		"settings":
			G.font.draw_centered(self, Vector2(320, 90), Txt.ui("menu.settings"), Color(0.8, 0.82, 0.86), G.bs)
		"confirm":
			G.font.draw_centered(self, Vector2(320, 160), Txt.ui("menu.confirm_new"), Color(0.85, 0.85, 0.85), 1)
	for i in items.size():
		var r := _item_rect(i)
		var on := i == sel
		var label: String = items[i][1]
		var col := Color(0.95, 0.93, 0.88) if on else Color(0.55, 0.58, 0.64)
		if page == "settings":
			var id: String = items[i][0]
			f.draw(self, Vector2(r.position.x - 60, r.position.y + f.vcenter(18)), label, col, 1)
			var val := ""
			match id:
				"master", "music", "sfx", "amb":
					var v := int(roundf(float(G.settings[id]) * 10.0))
					for k in 10:
						draw_rect(Rect2(r.position.x + 120 + k * 8, r.position.y + 4, 6, 8), col if k < v else Color(0.25, 0.27, 0.3))
				"flash", "tear":
					val = Txt.ui("set.on") if G.settings[id] else Txt.ui("set.reduced")
				"fullscreen":
					val = Txt.ui("set.on") if G.settings[id] else Txt.ui("set.off")
				"assist":
					val = Txt.ui("set.assist%d" % int(G.settings.get("assist", 0)))
				"lang":
					val = String(Txt.ZH.LANG_NAMES[String(G.settings.get("lang", "en"))])
			if val != "":
				f.draw(self, Vector2(r.position.x + 120, r.position.y + f.vcenter(18)), val, col, 1)
			if on:
				f.draw(self, Vector2(r.position.x - 72, r.position.y + f.vcenter(18)), ">", col, 1)
		else:
			var w := f.width(label, G.bs)
			var ty := r.position.y + f.vcenter(18, G.bs)
			f.draw(self, Vector2(320 - w / 2, ty), label, col, G.bs)
			if on:
				f.draw(self, Vector2(320 - w / 2 - 16, ty), ">", col, G.bs)
	if page == "title":
		f.draw(self, Vector2(10, 350 - f.cell_h), Txt.ui("controls"), Color(0.4, 0.42, 0.48), 1)


func _draw_title_bg() -> void:
	for y in range(0, 360, 4):
		var k := y / 360.0
		draw_rect(Rect2(0, y, 640, 4), Color8(4, 6, 10).lerp(Color8(20, 26, 40), k))
	if G.persist.get("finished", false):
		var p := 0.7 + 0.3 * sin(t * 2.0)
		draw_rect(Rect2(506, 62, 2, 2), Color(0.8, 0.1, 0.1, p))
		draw_rect(Rect2(505, 61, 4, 4), Color(0.8, 0.1, 0.1, 0.2 * p))
	draw_rect(Rect2(0, 300, 640, 60), Color8(10, 12, 18))
	if _tower:
		draw_texture_rect(_tower, Rect2(430, 300 - 296, 192, 296), false, Color(0.13, 0.15, 0.2))
		var glow := 0.55 + 0.1 * sin(t * 1.7)
		draw_rect(Rect2(468, 60, 104, 24), Color(1.0, 0.72, 0.4, 0.18 * glow))
		for x in range(476, 566, 20):
			draw_rect(Rect2(x, 64, 14, 18), Color(1.0, 0.78, 0.45, 0.55 * glow))
	for fl in _flakes:
		var y := fposmod(float(fl[1]) + t * 14.0 * float(fl[2]), 360.0)
		var x := fposmod(float(fl[0]) + sin(t + float(fl[1])) * 8.0 - t * 5.0, 640.0)
		draw_rect(Rect2(floorf(x), floorf(y), 1, 1), Color(0.9, 0.93, 1.0, 0.25 + 0.4 * float(fl[2])))
