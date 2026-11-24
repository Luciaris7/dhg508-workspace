class_name Desktop
extends Node2D
## First-person Windows XP desktop at 640x360: wallpaper, icons, taskbar,
## start menu, draggable windows, the cursor -- and the things a desktop
## should not do (the icon nobody installed, the close button that will
## not, the screen that goes black by itself).

signal wipe_finished

var flow: Node
var wins: Array = []           # [{id, app, rect, min}]
var icons: Array = []          # [{id, label, tex, pos}]
var mouse := Vector2(320, 180)
var _drag: Dictionary = {}
var _drag_off := Vector2.ZERO
var sel_icon := ""
var _last_click := {"id": "", "t": -10.0}
var boot_t := -1.0
var _booted_day := 0
var blackout := 0.0
var wipe_t := -1.0
var _wipe_target := Vector2(400, 120)
var start_open := false
var game_on := false
var games_today := 0
var _games_day := 0
var t := 0.0
var _tex := {}
var _hand: Texture2D
var _wall: Texture2D
var _wall_dark: Texture2D


func _ready() -> void:
	for n in ["notice", "chart", "report", "game", "mycomputer", "bin", "mydocs", "log", "drive", "floppy", "image", "flag"]:
		var p := "res://assets/art/desk/icon_%s.png" % n
		if ResourceLoader.exists(p):
			_tex[n] = load(p)
	_tex["notes"] = _tex.get("log")
	_tex["archive"] = _tex.get("drive")
	_tex["survey"] = _tex.get("chart")
	_wall = load("res://assets/art/desk/wallpaper.png")
	_wall_dark = load("res://assets/art/desk/wallpaper_6.png")
	_hand = load("res://assets/art/desk/hand.png")


func icon_tex(n: String) -> Texture2D:
	return _tex.get(n, null)


func game_running() -> bool:
	return game_on


# =========================================================== lifecycle
func open_for_today() -> void:
	wins.clear()
	_drag = {}
	start_open = false
	blackout = 0.0
	wipe_t = -1.0
	sel_icon = ""
	if _games_day != G.day:
		_games_day = G.day
		games_today = 0
	refresh_icons()
	if _booted_day != G.day:
		_booted_day = G.day
		boot_t = 0.0
		Sfx.play("crt_on", -6.0)
		Sfx.play("hdd", -10.0)
	else:
		boot_t = -1.0
		Sfx.play("crt_on", -10.0)
	mouse = Vector2(320, 200)


func refresh_icons() -> void:
	icons.clear()
	var col1 := [["mycomputer", Txt.ui("icon.mycomputer")], ["mydocs", Txt.ui("icon.mydocs")], ["bin", Txt.ui("icon.bin")],
		["notes", Txt.ui("icon.notes")], ["archive", Txt.ui("icon.archive")]]
	var col2 := [["notice", Txt.ui("icon.notice")], ["chart", Txt.ui("icon.chart")], ["report", Txt.ui("icon.report")]]
	# Day 2 on: it is simply there. No install, no explanation. Gone on Day 7.
	if G.day >= 2 and G.day <= 6:
		col2.append(["game", Txt.ui("icon.game")])
	if (G.persist["answers"] as Array).size() >= 1:
		col2.append(["log", Txt.ui("icon.log")])
	var step := 36 + 2 * G.font.line_h()
	for i in col1.size():
		icons.append({"id": col1[i][0], "label": col1[i][1], "pos": Vector2(10, 8 + i * step)})
	for i in col2.size():
		icons.append({"id": col2[i][0], "label": col2[i][1], "pos": Vector2(74, 8 + i * step)})


func request_exit() -> void:
	if game_on or blackout > 0.0:
		return
	if not flow.desk_can_close():
		Sfx.play("error_ding", -8.0)
		return
	for w in wins:
		if not (w["app"] as DeskApp).can_close():
			Sfx.play("error_ding", -8.0)
			return
	_close_all()
	Sfx.play("crt_off", -8.0)
	flow.desktop_closed()


func force_close() -> void:
	if game_on:
		_end_game()
	show_type_yes(false)
	_close_all()
	blackout = 0.0
	Sfx.play("crt_off", -8.0)
	flow.desktop_closed()


func _close_all() -> void:
	for w in wins.duplicate():
		_on_closed(w)
	wins.clear()


func begin_blackout() -> void:
	var tw := create_tween()
	tw.tween_property(self, "blackout", 1.0, 7.0)


# ============================================================== windows
func open_app(app: DeskApp, id: String) -> void:
	for w in wins:
		if w["id"] == id:
			w["min"] = false
			_focus(w)
			return
	app.desk = self
	app.id = id
	var sz := app.size + Vector2(6, 23)
	var n := wins.size()
	var pos := Vector2(roundf((640 - sz.x) * 0.5) + 30 + n * 14, roundf((340 - sz.y) * 0.5) + n * 12)
	pos.x = clampf(pos.x, 0, 640 - sz.x)
	pos.y = clampf(pos.y, 0, 340 - sz.y)
	var w := {"id": id, "app": app, "rect": Rect2(pos, sz), "min": false}
	wins.append(w)
	Sfx.play("win_open", -12.0)
	app.on_open()


func close_app(app: DeskApp) -> void:
	for w in wins:
		if w["app"] == app:
			_close_win(w)
			return


func _close_win(w: Dictionary) -> void:
	if not (w["app"] as DeskApp).can_close():
		Sfx.play("error_ding", -8.0)
		return
	wins.erase(w)
	_on_closed(w)
	Sfx.play("win_close", -12.0)


func _on_closed(w: Dictionary) -> void:
	(w["app"] as DeskApp).on_close()
	if w["id"] == "notice":
		flow.on_notice_closed()


func _focus(w: Dictionary) -> void:
	wins.erase(w)
	wins.append(w)


func _top() -> Dictionary:
	for i in range(wins.size() - 1, -1, -1):
		if not wins[i]["min"]:
			return wins[i]
	return {}


func client(w: Dictionary) -> Rect2:
	var r: Rect2 = w["rect"]
	return Rect2(r.position.x + 3, r.position.y + 20, r.size.x - 6, r.size.y - 23)


func msgbox(title: String, body: String) -> void:
	open_app(AppMsg.new(title, body), "msg_%d" % Time.get_ticks_msec())


func launch(id: String) -> void:
	match id:
		"notice":
			open_app(AppText.new(Txt.ui("notice.title"), Txt.notice()), "notice")
			flow.on_notice_opened()
		"chart":
			open_app(AppChart.new(), "chart")
		"report":
			open_app(AppReport.new(), "report")
		"game":
			_start_game()
		"mycomputer", "bin", "mydocs":
			open_app(AppFolder.new(id), id)
		"log":
			open_app(AppText.new(Txt.ui("log.title"), _log_lines(), Vector2(280, 170)), "log")
			if G.day >= 6:
				flow.found("autocorrect", false)
		"notes":
			open_app(AppText.new(Txt.ui("notes.title"), notes_lines(), Vector2(380, 280)), "notes")
		"archive":
			open_app(AppArchive.new(), "archive")


func _log_lines() -> Array:
	var out := [Txt.ui("log.header"), "-----------------------------"]
	var a: Array = G.persist["answers"]
	# every Yes (an anomaly) is rewritten as No; from Day 6 the log no longer pretends
	var corrected: bool = G.persist.get("corrected", false) or G.day >= 6
	for i in a.size():
		var date := AppChart._date_str(float(G.day_unix(i + 1))).substr(0, 10)
		var ans := Txt.ui("log.yes") if a[i] == "yes" else Txt.ui("log.no")
		if corrected and a[i] == "yes":
			out.append("%s    %s   %s" % [date, Txt.ui("log.no"), Txt.ui("log.corrected")])
		else:
			out.append("%s    %s" % [date, ans])
	if G.day >= 6:
		out.append("-----------------------------")
		out.append(Txt.ui("log.confirmations") % a.size())
	return out


## The player's own notebook: every saved clue, the radio, the sealed record.
func notes_lines() -> Array:
	var out := [Txt.ui("notes.count") % G.clue_count(), "------------------------------------------", ""]
	var clues: Dictionary = G.persist["clues"]
	for id in G.CLUES:
		if clues.has(id):
			out.append("[%s] %s" % [Txt.ui("notes.day") % int(clues[id]), Txt.clue_note(id)])
			out.append("")
	var links := _notes_links(clues)
	if not links.is_empty():
		out.append(Txt.ui("notes.links"))
		out.append("")
		for link in links:
			out.append(link)
			out.append("")
	if G.persist.get("morse_solved", false):
		out.append(Txt.ui("notes.sealed") % G.sealed_id())
	if clues.is_empty():
		out.append(Txt.ui("notes.empty"))
	return out


func _notes_links(clues: Dictionary) -> Array:
	var out: Array = []
	if clues.has("rumor") and clues.has("echo_hollow"):
		out.append(Txt.ui("notes.link1"))
	if clues.has("red_body") and clues.has("echo_aurora"):
		out.append(Txt.ui("notes.link2"))
	if clues.has("future_log") and clues.has("autocorrect"):
		out.append(Txt.ui("notes.link3"))
	if clues.has("prev_notes") and clues.has("last_record"):
		out.append(Txt.ui("notes.link4"))
	if clues.has("not_weather") and clues.has("prev_notes"):
		out.append(Txt.ui("notes.link5"))
	return out


## obslog_<date + 13 years>.txt: cycle 05's log, already written, in your answers.
func future_log_lines() -> Array:
	var times := ["22:14", "21:51", "22:36", "23:02", "23:18", "23:27"]
	var a: Array = G.persist["answers"]
	var out := [Txt.ui("obslog.head"), ""]
	for d in range(1, 7):
		var ans := "No"
		if d - 1 < a.size():
			ans = "Yes" if a[d - 1] == "yes" else "No"
		out.append(Txt.ui("obslog.day") % [future_date(d), d, times[d - 1], ans])
	out.append(Txt.ui("obslog.last") % future_date(7))
	out.append("")
	out.append(Txt.ui("obslog.observer"))
	return out


static func future_date(d: int) -> String:
	var dt := Time.get_datetime_dict_from_unix_time(G.day_unix(d))
	return "%04d-%02d-%02d" % [int(dt["year"]) + 13, dt["month"], dt["day"]]


# ================================================================ game
func _start_game() -> void:
	var mg: MiniGame = flow.main.mg
	if not mg.quit.is_connected(_end_game):
		mg.quit.connect(_end_game)
		mg.game_over.connect(_on_game_over)
	game_on = true
	flow.main.show_minigame_layer(true, true)
	mg.start_desktop()
	Sfx.muffle(true)


func _end_game() -> void:
	game_on = false
	var mg: MiniGame = flow.main.mg
	mg.stop()
	flow.main.show_minigame_layer(false, true)


func _on_game_over(score: int) -> void:
	games_today += 1
	if score > int(G.persist.get("best", 0)):
		G.persist["best"] = score
		G.save_meta()
	flow.on_game_over(score, games_today)


# ============================================================== Day 4
func play_wipe() -> void:
	var chart: AppChart = null
	for w in wins:
		if w["id"] == "chart":
			chart = w["app"]
			w["min"] = false
			_focus(w)
	if chart == null:
		launch("chart")
		chart = _top()["app"]
	var w2: Dictionary = _top()
	var area := chart._area(client(w2))
	var an := chart.anomaly(area)
	_wipe_target = an.get("pos", area.get_center())
	wipe_t = 0.0
	Sfx.loop("wipe", "wipe_squeak", -8.0, 0.1, "SFX")
	var tw := create_tween()
	tw.tween_property(chart, "smudge", 1.0, 2.8)
	await get_tree().create_timer(3.0, false).timeout
	Sfx.stop_loop("wipe", 0.2)
	wipe_t = -1.0


func show_type_yes(on: bool) -> void:
	var ov: Overlay = flow.overlay
	if on:
		ov.red_center = Txt.red("forced")
		ov.red_center_a = 1.0
		flow.on_type_yes_shown()
		if G.today_once("type_yes_line"):
			ov.say("d6_type_yes", 1)
	elif ov.red_center == Txt.red("forced"):
		ov.red_center = ""
		ov.red_center_a = 0.0


# ================================================================ input
func handle(e: InputEvent) -> void:
	if e is InputEventMouse:
		mouse = (e as InputEventMouse).position.clamp(Vector2.ZERO, Vector2(639, 359))
	if boot_t >= 0.0:
		return
	if wipe_t >= 0.0 or blackout > 0.01:
		return
	if e is InputEventKey:
		var k := e as InputEventKey
		if k.pressed and k.keycode == KEY_ESCAPE:
			if start_open:
				start_open = false
			else:
				request_exit()
			return
		var top := _top()
		if not top.is_empty():
			(top["app"] as DeskApp).key(k)
		return
	if e is InputEventMouseMotion:
		if not _drag.is_empty():
			var r: Rect2 = _drag["rect"]
			r.position = (mouse - _drag_off).round()
			r.position.x = clampf(r.position.x, -r.size.x + 40, 600)
			r.position.y = clampf(r.position.y, 0, 330)
			_drag["rect"] = r
			return
		var top := _top()
		if not top.is_empty():
			(top["app"] as DeskApp).mouse(e, mouse - client(top).position, client(top))
		return
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if not mb.pressed:
			_drag = {}
			var top := _top()
			if not top.is_empty():
				(top["app"] as DeskApp).mouse(e, mouse - client(top).position, client(top))
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var w := _win_at(mouse)
			if not w.is_empty():
				(w["app"] as DeskApp).mouse(e, mouse - client(w).position, client(w))
			return
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		_click(mb)


func _win_at(p: Vector2) -> Dictionary:
	for i in range(wins.size() - 1, -1, -1):
		var w: Dictionary = wins[i]
		if not w["min"] and (w["rect"] as Rect2).has_point(p):
			return w
	return {}


func _click(mb: InputEventMouseButton) -> void:
	var p := mouse
	if start_open:
		start_open = false
		if _start_menu_rect().has_point(p):
			_start_menu_click(p)
			return
	if p.y >= 340:
		_taskbar_click(p)
		return
	var w := _win_at(p)
	if not w.is_empty():
		_focus(w)
		var r: Rect2 = w["rect"]
		if p.y < r.position.y + 20:
			var close := Rect2(r.end.x - 20, r.position.y + 2, 17, 16)
			var mini := Rect2(r.end.x - 39, r.position.y + 2, 17, 16)
			if close.has_point(p):
				_close_win(w)
			elif mini.has_point(p) and not (w["app"] is AppMsg):
				w["min"] = true
				Sfx.play("click", -14.0)
			else:
				_drag = w
				_drag_off = p - r.position
			return
		(w["app"] as DeskApp).mouse(mb, p - client(w).position, client(w))
		return
	# icons
	for ic in icons:
		var ir := Rect2(ic["pos"], Vector2(60, 34 + 2 * G.font.line_h()))
		if ir.has_point(p):
			var now := t
			if _last_click["id"] == ic["id"] and now - float(_last_click["t"]) < 0.45:
				_last_click = {"id": "", "t": -10.0}
				launch(String(ic["id"]))
			else:
				_last_click = {"id": ic["id"], "t": now}
			sel_icon = ic["id"]
			Sfx.play("click", -16.0)
			return
	sel_icon = ""


func _taskbar_click(p: Vector2) -> void:
	if p.x < 78:
		start_open = not start_open
		Sfx.play("click", -12.0)
		return
	var x := 84.0
	for w in wins:
		var br := Rect2(x, 343, 118, 15)
		if br.has_point(p):
			if w == _top() and not w["min"]:
				w["min"] = true
			else:
				w["min"] = false
				_focus(w)
			Sfx.play("click", -14.0)
			return
		x += 122.0


func _start_menu_rect() -> Rect2:
	return Rect2(0, 340 - 196, 190, 196)


func _start_items() -> Array:
	var items := [["notice", Txt.ui("icon.notice")], ["chart", Txt.ui("icon.chart")], ["report", Txt.ui("icon.report")]]
	if G.day >= 2 and G.day <= 6:
		items.append(["game", Txt.ui("icon.game")])
	items.append(["mydocs", Txt.ui("icon.mydocs")])
	items.append(["mycomputer", Txt.ui("icon.mycomputer")])
	return items


func _start_menu_click(p: Vector2) -> void:
	var r := _start_menu_rect()
	var items := _start_items()
	for i in items.size():
		var ir := Rect2(r.position.x + 4, r.position.y + 30 + i * 22, r.size.x - 8, 20)
		if ir.has_point(p):
			launch(String(items[i][0]))
			return
	var off := Rect2(r.end.x - 92, r.end.y - 22, 88, 18)
	if off.has_point(p):
		request_exit()


# ================================================================= tick
func _process(dt: float) -> void:
	t += dt
	if boot_t >= 0.0:
		boot_t += dt
		if boot_t > 3.2:
			boot_t = -1.0
			Sfx.play("startup", -8.0)
	for w in wins:
		(w["app"] as DeskApp).tick(dt)
	if wipe_t >= 0.0:
		wipe_t += dt
	queue_redraw()


# ================================================================= draw
func _draw() -> void:
	var f: PixelFont = G.font
	if boot_t >= 0.0:
		_draw_boot()
		return
	draw_texture(_wall_dark if G.day >= 6 else _wall, Vector2.ZERO)
	# icons
	for ic in icons:
		var pos: Vector2 = ic["pos"]
		var tex: Texture2D = _tex.get(ic["id"], null)
		var selected: bool = sel_icon == ic["id"]
		if tex:
			draw_texture(tex, pos + Vector2(14, 0), Color(0.6, 0.7, 1.0) if selected else Color.WHITE)
		var lines := f.wrap(String(ic["label"]), 60, 1)
		var y := pos.y + 35
		for ln in lines:
			var w := f.width(ln)
			var lx := roundf(pos.x + 30 - w * 0.5)
			if selected:
				draw_rect(Rect2(lx - 2, y - 1, w + 4, f.cell_h + 2), XP.SEL)
			else:
				f.draw(self, Vector2(lx + 1, y + 1), ln, Color(0, 0, 0, 0.8), 1)
			f.draw(self, Vector2(lx, y), ln, Color.WHITE, 1)
			y += f.line_h()
	# windows
	for w in wins:
		if w["min"]:
			continue
		var app: DeskApp = w["app"]
		var active: bool = w == _top()
		XP.window_frame(self, w["rect"], app.title, active, _tex.get(_icon_for(w["id"]), null), not (app is AppMsg), app.can_close())
		app.draw(self, client(w))
	_draw_taskbar()
	if start_open:
		_draw_start_menu()
	if wipe_t >= 0.0:
		_draw_hand()
	if blackout > 0.0:
		draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, blackout))
	if not game_on and blackout < 0.98 and wipe_t < 0.0:
		XP.cursor(self, mouse.floor(), false)


func _icon_for(id: String) -> String:
	if id.begins_with("record"):
		return "image"
	if id.begins_with("survey"):
		return "survey"
	if id.begins_with("rec_") or id == "sealed" or id == "obslog":
		return "log"
	if id.begins_with("msg"):
		return ""
	return id


func _draw_taskbar() -> void:
	var f: PixelFont = G.font
	var tb := Rect2(0, 340, 640, 20)
	XP.vgrad3(self, tb, XP.TASK_TOP, XP.TASK_MID, XP.TASK_BOT, 0.2)
	draw_rect(Rect2(0, 340, 640, 1), Color8(80, 150, 255))
	# start button
	var sb := Rect2(0, 340, 76, 20)
	XP.vgrad3(self, sb, Color8(100, 190, 100), XP.START_G1, XP.START_G2, 0.3)
	draw_rect(Rect2(sb.end.x - 1, 340, 1, 20), Color8(30, 90, 30))
	if _tex.has("flag"):
		draw_texture(_tex["flag"], Vector2(6, 342))
	var sy := 340 + f.vcenter(20, G.bs)
	f.draw(self, Vector2(26, sy + 1), Txt.ui("start"), Color(0, 0, 0, 0.4), G.bs)
	f.draw(self, Vector2(25, sy), Txt.ui("start"), Color.WHITE, G.bs)
	# window buttons
	var x := 84.0
	for w in wins:
		var br := Rect2(x, 343, 118, 15)
		var active: bool = w == _top() and not w["min"]
		draw_rect(br, Color8(30, 70, 180) if active else Color8(60, 130, 240))
		draw_rect(Rect2(br.position.x + 1, br.position.y + 1, br.size.x - 2, 1), Color8(100, 160, 255))
		var ttl: String = (w["app"] as DeskApp).title
		while f.width(ttl) > 100 and ttl.length() > 3:
			ttl = ttl.substr(0, ttl.length() - 1)
		f.draw(self, br.position + Vector2(6, f.vcenter(15)), ttl, Color.WHITE, 1)
		x += 122.0
	# tray
	var tr := Rect2(560, 340, 80, 20)
	XP.vgrad(self, tr, Color8(24, 150, 236), Color8(12, 120, 210))
	draw_rect(Rect2(560, 340, 1, 20), Color8(8, 80, 170))
	# the station's time, the same clock the star chart uses -- not the real one
	var clock := G.clock_str()
	f.draw(self, Vector2(634 - f.width(clock), 340 + f.vcenter(20)), clock, Color.WHITE, 1)
	draw_rect(Rect2(567, 346, 6, 7), Color8(220, 220, 220))
	draw_rect(Rect2(568, 347, 4, 3), Color8(60, 120, 200))
	draw_rect(Rect2(577, 347, 3, 6), Color8(200, 200, 200))
	draw_rect(Rect2(580, 345, 2, 10), Color8(200, 200, 200))


func _draw_start_menu() -> void:
	var f: PixelFont = G.font
	var r := _start_menu_rect()
	draw_rect(r, Color8(0, 72, 200))
	XP.vgrad(self, Rect2(r.position, Vector2(r.size.x, 26)), Color8(30, 110, 230), Color8(10, 80, 210))
	draw_rect(Rect2(r.position.x + 5, r.position.y + 4, 18, 18), Color8(240, 200, 120))
	draw_rect(Rect2(r.position.x + 6, r.position.y + 5, 16, 16), Color8(90, 140, 190))
	XP.bold(self, r.position + Vector2(30, f.vcenter(26)), Txt.ui("start.user"), Color.WHITE)
	var body := Rect2(r.position.x + 2, r.position.y + 26, r.size.x - 4, r.size.y - 50)
	draw_rect(body, Color.WHITE)
	var items := _start_items()
	for i in items.size():
		var ir := Rect2(r.position.x + 4, r.position.y + 30 + i * 22, r.size.x - 8, 20)
		if ir.has_point(mouse):
			draw_rect(ir, XP.SEL)
		var tex: Texture2D = _tex.get(items[i][0], null)
		if tex:
			draw_texture_rect(tex, Rect2(ir.position.x + 2, ir.position.y + 2, 16, 16), false)
		f.draw(self, ir.position + Vector2(24, f.vcenter(20)), String(items[i][1]), Color.WHITE if ir.has_point(mouse) else XP.TEXT, 1)
	var bot := Rect2(r.position.x, r.end.y - 24, r.size.x, 24)
	XP.vgrad(self, bot, Color8(30, 110, 230), Color8(10, 80, 210))
	var off := Rect2(r.end.x - 92, r.end.y - 22, 88, 18)
	draw_rect(Rect2(off.position.x, off.position.y + 2, 14, 14), Color8(220, 70, 40))
	draw_rect(Rect2(off.position.x + 6, off.position.y + 4, 2, 6), Color.WHITE)
	f.draw(self, off.position + Vector2(18, f.vcenter(18)), Txt.ui("start.off"), Color.WHITE, 1)


func _draw_hand() -> void:
	if _hand == null:
		return
	var k := wipe_t / 3.0
	var sway := sin(wipe_t * 7.5) * 26.0
	var enter := clampf(wipe_t / 0.4, 0.0, 1.0) * clampf((3.0 - wipe_t) / 0.4, 0.0, 1.0)
	var pos := _wipe_target + Vector2(sway - 20.0, -6.0 + (1.0 - enter) * 160.0 + sin(wipe_t * 15.0) * 3.0)
	draw_texture(_hand, pos.round())
	if k < 0.0:
		pass


func _draw_boot() -> void:
	var f: PixelFont = G.font
	draw_rect(Rect2(0, 0, 640, 360), Color.BLACK)
	if boot_t < 1.5:
		var lines := [Txt.ui("boot.1"), "", Txt.ui("boot.2"), Txt.ui("boot.3"), "", Txt.ui("boot.4")]
		var n := int(boot_t / 0.22)
		for i in mini(n, lines.size()):
			f.draw(self, Vector2(16, 16 + i * f.line_h()), String(lines[i]), Color8(190, 190, 190), 1)
		if int(boot_t * 4.0) % 2 == 0:
			draw_rect(Rect2(16, 16 + mini(n, lines.size()) * f.line_h(), 6, 8), Color8(190, 190, 190))
		return
	# loading screen
	var title := Txt.ui("boot.name")
	if _tex.has("flag"):
		draw_texture_rect(_tex["flag"], Rect2(268, 128, 32, 32), false)
	XP.bold(self, Vector2(308, 138), title, Color.WHITE)
	f.draw(self, Vector2(308, 142 + f.line_h()), Txt.ui("boot.os"), Color8(200, 200, 200), 1)
	var bar := Rect2(270, 196, 100, 10)
	draw_rect(bar, Color8(180, 180, 180), false, 1.0)
	var off := fposmod((boot_t - 1.5) * 90.0, 130.0) - 30.0
	for i in 3:
		var x := bar.position.x + off + i * 9
		if x > bar.position.x and x < bar.end.x - 8:
			XP.vgrad(self, Rect2(x, bar.position.y + 2, 7, 6), Color8(120, 170, 255), Color8(30, 80, 200))
	f.draw(self, Vector2(16, 340), Txt.ui("boot.copy"), Color8(120, 120, 120), 1)
