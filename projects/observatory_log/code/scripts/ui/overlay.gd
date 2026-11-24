class_name Overlay
extends Node2D
## Everything drawn over the world at 640x360: inner monologue, interaction
## prompts, the phone subtitles, red ritual text, day cards, fades and the
## small task panels (antenna, junction box, gauges).

signal line_finished(id: String)

var world: World
var font: PixelFont:
	get:
		return G.font
var tip := ""
var tip_t := 0.0
var tip_world := true
var desk_mode := false

# monologue
var _queue: Array = []
var cur: Dictionary = {}
var _typed := 0.0
var _hold := 0.0
var mono_enabled := true

# visual state
var fade := 0.0              # black over everything (below menus)
var white := 0.0
var show_prompt := true
var show_hud := false
var subtitle := ""
var subtitle_tag := ""
var red_center := ""
var red_center_a := 0.0
var red_bottom := ""
var red_bottom_a := 0.0
var card_day := 0            # >0: draw the "Day x" card
var card_a := 0.0
var title_text := ""
var title_a := 0.0
var gauge_label := ""
var gauge := -1.0            # <0 hidden
var gauge_hint := ""
var panel := ""              # "", "aim", "wire", "doc", "sonar", "radio"
var aim := {}
var wire := {}
var doc := {}                # {title, lines, scroll}
var sonar := {}              # see Flow._sonar_*
var radio := {}              # {lamp, heard}
var credits: Array = []      # one page: [heading, lines...]
var credits_a := 0.0
var caption := ""
var caption_a := 0.0
var black := 0.0             # black under everything on this layer (subtitles stay readable)
var cg: Texture2D            # the closing illustration of an ending (640x360)
var cg_a := 0.0
var vista: Texture2D         # the view from the hilltop fence (640x360)
var vista_a := 0.0

const MORSE := {"0": "-----", "1": ".----", "2": "..---", "3": "...--", "4": "....-",
	"5": ".....", "6": "-....", "7": "--...", "8": "---..", "9": "----."}
var t := 0.0
var hint_e := ""             # small helper text next to the prompt
var mono_hint := ""          # keys for a pinned question, over the monologue box
var world_mode := false       # set by Main: HUD and prompts only in the world


# ============================================================ monologue
func say(id: String, prio: int = 1) -> void:
	var text := Txt.mono(id)
	if text == "":
		text = id if id.contains(" ") else ""
	if text == "" or not mono_enabled:
		return
	for q in _queue:
		if q["id"] == id:
			return
	if not cur.is_empty() and cur["id"] == id:
		return
	var item := {"id": id, "text": text, "prio": prio}
	if prio >= 2 and not cur.is_empty() and int(cur["prio"]) < 2:
		_queue.push_front(cur)
		_start(item)
		return
	if cur.is_empty():
		_start(item)
	else:
		var i := 0
		while i < _queue.size() and int(_queue[i]["prio"]) >= prio:
			i += 1
		_queue.insert(i, item)


func _start(item: Dictionary) -> void:
	cur = item
	_typed = 0.0
	_hold = maxf(1.8, Flow.read_time(String(item["text"])) + 1.0)


func speaking() -> bool:
	return not cur.is_empty() or not _queue.is_empty()


func accelerate() -> bool:
	if cur.is_empty():
		return false
	var n := String(cur["text"]).length()
	if _typed < n:
		_typed = n
		return true
	_hold = minf(_hold, 0.25)
	return true


func clear_mono() -> void:
	_queue.clear()
	cur = {}
	mono_hint = ""


func wait_line(id: String) -> void:
	## Await until `id` has been shown and finished (or was never queued).
	var safety := 0.0
	while (not cur.is_empty() and cur["id"] == id) or _queue.any(func(q): return q["id"] == id):
		await get_tree().process_frame
		safety += get_process_delta_time()
		if safety > 40.0:
			break


func wait_quiet() -> void:
	var safety := 0.0
	while speaking():
		await get_tree().process_frame
		safety += get_process_delta_time()
		if safety > 60.0:
			break


func show_tip(text: String, secs: float = 8.0, in_world: bool = true) -> void:
	tip = text
	tip_t = secs
	tip_world = in_world


func _process(dt: float) -> void:
	t += dt
	tip_t = maxf(0.0, tip_t - dt)
	if not cur.is_empty():
		var n := String(cur["text"]).length()
		if _typed < n:
			_typed += dt * 38.0 * float(G.settings.get("text_speed", 1.0))
			if int(_typed) % 3 == 0 and _typed < n:
				pass
		else:
			_hold -= dt
			if _hold <= 0.0:
				var id: String = cur["id"]
				cur = {}
				line_finished.emit(id)
				if not _queue.is_empty():
					_start(_queue.pop_front())
	queue_redraw()


# ================================================================= draw
func _draw() -> void:
	if black > 0.0:
		draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, black))
	if cg != null and cg_a > 0.0:
		draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 1))
		draw_texture(cg, Vector2.ZERO, Color(1, 1, 1, cg_a))
	if vista != null and vista_a > 0.0 and world_mode:
		draw_texture(vista, Vector2.ZERO, Color(1, 1, 1, vista_a))
		if vista_a > 0.8 and cur.is_empty():
			var vh := Txt.ui("vista.exit")
			var vw := font.width(vh)
			draw_rect(Rect2(320 - vw / 2 - 10, 330, vw + 20, font.cell_h + 8), Color(0.02, 0.02, 0.04, 0.6 * vista_a))
			font.draw(self, Vector2(320 - vw / 2, 334), vh, Color(0.92, 0.94, 0.96, (0.7 + 0.25 * sin(t * 3.0)) * vista_a), 1)
	if show_hud and world_mode and world and world.loc != "road":
		font.draw_shadowed(self, Vector2(10, 8), Txt.ui("hud.day") % G.day, Color(0.85, 0.88, 0.92, 0.75), 1)
	if show_prompt and world_mode and world and not world.focus.is_empty() and world.player.visible:
		_draw_prompt()
	match panel:
		"aim":
			_draw_aim()
		"wire":
			_draw_wire()
		"doc":
			_draw_doc()
		"sonar":
			_draw_sonar()
		"radio":
			_draw_radio()
	if gauge >= 0.0:
		_draw_gauge()
	if subtitle != "":
		_draw_subtitle()
	if not cur.is_empty():
		_draw_mono()
	if red_bottom != "" and red_bottom_a > 0.0:
		var bs: int = G.bs
		var lh := font.line_h(bs)
		var lines := font.wrap(red_bottom, 600, bs)
		var y := 318 - (lines.size() - 1) * lh
		for ln in lines:
			var w := font.width(ln, bs)
			font.draw(self, Vector2(320 - w / 2 + 1, y + 1), ln, Color(0, 0, 0, red_bottom_a), bs)
			font.draw(self, Vector2(320 - w / 2, y), ln, Color(0.86, 0.12, 0.14, red_bottom_a), bs, 0.6, int(t * 10.0))
			y += lh
	if fade > 0.0:
		draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, fade))
	if red_center != "" and red_center_a > 0.0:
		var df: PixelFont = G.day_font(maxi(G.day, 5))
		var lines := df.wrap(red_center, 600, 1)
		var lh := df.line_h(1)
		var y := 180.0 - (lines.size() - 1) * lh * 0.5
		for ln in lines:
			df.draw_centered(self, Vector2(320, y), ln, Color(1, 1, 1, red_center_a), 1, 1.0 if G.day >= 4 else 0.0, int(t * 8.0))
			y += lh
	if card_day > 0 and card_a > 0.0:
		_draw_card()
	if title_text != "" and title_a > 0.0:
		_draw_title()
	if credits.size() > 0 and credits_a > 0.0:
		_draw_credits()
	if caption != "" and caption_a > 0.0:
		G.day_font(1).draw_centered(self, Vector2(320, 60), caption, Color(1, 1, 1, caption_a), 1)
	if tip != "" and tip_t > 0.0 and ((tip_world and world_mode) or (not tip_world and desk_mode)):
		var ta := clampf(tip_t, 0.0, 1.0)
		var tw := font.width(tip)
		draw_rect(Rect2(620 - tw - 8, 8 - 4, tw + 12, font.cell_h + 8), Color(0, 0, 0, 0.5 * ta))
		font.draw(self, Vector2(620 - tw - 2, 8), tip, Color(0.85, 0.87, 0.9, 0.85 * ta), 1)
	if white > 0.0:
		draw_rect(Rect2(0, 0, 640, 360), Color(1, 1, 1, white))


func _draw_prompt() -> void:
	var it: Dictionary = world.focus
	var p := world.to_screen(Vector2(float(it["x"]), World.GROUND - float(it["lift"])))
	var bob := 0.0
	var r := Rect2(roundf(p.x - 8), roundf(p.y - 16 + bob), 16, 16)
	draw_rect(Rect2(r.position + Vector2(0, 2), r.size), Color(0, 0, 0, 0.55))
	draw_rect(r, Color8(214, 220, 228))
	draw_rect(Rect2(r.position + Vector2(1, 1), r.size - Vector2(2, 2)), Color8(236, 240, 244))
	draw_rect(Rect2(r.position.x + 1, r.end.y - 3, r.size.x - 2, 2), Color8(160, 170, 184))
	G.font_en.draw(self, r.position + Vector2(4, 3), "E", Color8(30, 34, 44), 2)
	if hint_e != "":
		font.draw_shadowed(self, Vector2(r.end.x + 4, r.position.y + 4), hint_e, Color(0.9, 0.92, 0.95, 0.9), 1)


func _draw_mono() -> void:
	var text: String = cur["text"]
	var shown := text.substr(0, int(_typed))
	var bs: int = G.bs
	var lh := font.line_h(bs)
	var lines := font.wrap(text, 560, bs)
	var h := lines.size() * lh + 12
	var y0 := 352 - h
	draw_rect(Rect2(0, y0, 640, h + 8), Color(0.02, 0.02, 0.04, 0.62))
	var y := y0 + 8
	var left := shown.length()
	var col := Color(0.93, 0.92, 0.88)
	if G.day >= 6:
		col = Color(0.95, 0.8, 0.78)
	for ln in lines:
		var part := ln.substr(0, clampi(left, 0, ln.length()))
		left -= ln.length() + 1
		var w := font.width(ln, bs)
		font.draw(self, Vector2(320 - w / 2 + 1, y + 1), part, Color(0, 0, 0, 0.8), bs)
		font.draw(self, Vector2(320 - w / 2, y), part, col, bs)
		y += lh
	if mono_hint != "" and _typed >= text.length():
		font.draw(self, Vector2(632 - font.width(mono_hint), y0 - font.line_h() - 2), mono_hint, Color(0.85, 0.87, 0.9, 0.85), 1)


## A question that waits for an answer: shown even with monologue off, kept up
## until cleared, with its keys over the box.
func ask(id: String, keys: String) -> void:
	_queue.clear()
	_start({"id": id, "text": Txt.mono(id), "prio": 3})
	_hold = 1.0e9
	mono_hint = keys


func _draw_subtitle() -> void:
	var bs: int = G.bs
	var lh := font.line_h(bs)
	var lines := font.wrap(subtitle, 540, bs)
	var y := 44
	draw_rect(Rect2(36, y - 26, 568, lines.size() * lh + 34), Color(0.02, 0.02, 0.04, 0.55))
	if subtitle_tag != "":
		font.draw_shadowed(self, Vector2(52, y - 18), subtitle_tag, Color(0.95, 0.72, 0.36, 0.9), 1)
	for ln in lines:
		font.draw(self, Vector2(52 + 1, y + 1), ln, Color(0, 0, 0, 0.85), bs)
		font.draw(self, Vector2(52, y), ln, Color8(246, 214, 150), bs)
		y += lh


func _draw_card() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, card_a))
	var df: PixelFont = G.day_font(card_day)
	var txt := Txt.ui("card.day") % card_day
	var jit := 0.0
	if card_day == 4:
		jit = 2.0
	elif card_day >= 6:
		jit = 0.4
	var seed := int(t * 14.0)
	var c := Color(1, 1, 1, card_a)
	df.draw_centered(self, Vector2(320, 176), txt, c, 2, jit, seed)
	if card_day == 4 and int(t * 9.0) % 7 == 0:
		df.draw_centered(self, Vector2(323, 176), txt, Color(0.6, 0.9, 1.0, card_a * 0.4), 2, 3.0, seed + 5)


func _draw_title() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 1.0))
	var df: PixelFont = G.day_font(7)
	var a := title_a * (0.92 + 0.08 * sin(t * 50.0))
	# CRT glow: soft red bloom under the letters
	for i in 3:
		var o := float(i + 1)
		df.draw_centered(self, Vector2(320 + o, 180), title_text, Color(1, 0.2, 0.2, a * 0.08), 2)
		df.draw_centered(self, Vector2(320 - o, 180), title_text, Color(1, 0.2, 0.2, a * 0.08), 2)
	df.draw_centered(self, Vector2(320, 180), title_text, Color(1, 1, 1, a), 2)
	var sub := Txt.red("title_sub")
	if sub != "":
		G.day_fonts_en[7].draw_centered(self, Vector2(320, 232), sub, Color(1, 1, 1, a * 0.8), 1)
	for y in range(0, 360, 2):
		draw_rect(Rect2(0, y, 640, 1), Color(0, 0, 0, 0.35))


func _draw_gauge() -> void:
	var r := Rect2(220, 236, 200, 10)
	if gauge_label != "":
		font.draw_shadowed(self, Vector2(r.position.x, r.position.y - font.line_h() - 2), gauge_label, Color(0.9, 0.92, 0.95, 0.9), 1)
	draw_rect(r.grow(2), Color(0, 0, 0, 0.7))
	draw_rect(r, Color8(40, 46, 58))
	draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(gauge, 0.0, 1.0), r.size.y)), Color8(214, 180, 110))
	if gauge_hint != "":
		var w := font.width(gauge_hint, 1)
		font.draw_shadowed(self, Vector2(r.end.x - w, r.end.y + 6), gauge_hint, Color(0.9, 0.92, 0.95, 0.9), 1)


func _draw_aim() -> void:
	var r := Rect2(200, 40, 240, 120)
	draw_rect(r.grow(3), Color(0, 0, 0, 0.75))
	draw_rect(r, Color8(20, 26, 34))
	draw_rect(Rect2(r.position, Vector2(r.size.x, font.cell_h + 4)), Color8(40, 52, 66))
	font.draw(self, r.position + Vector2(6, 2), Txt.ui("antenna.title"), Color8(200, 214, 226), 1)
	var az: float = aim.get("az", 0.0)
	var err: float = aim.get("err", 180.0)
	var locked: bool = aim.get("locked", false)
	var state_col := Color8(200, 60, 60)
	if absf(err) <= 3.0:
		state_col = Color8(110, 210, 120)
	elif absf(err) <= 30.0:
		state_col = Color8(230, 200, 90)
	# compass dial
	var c := r.position + Vector2(60, 66)
	for a in range(0, 360, 15):
		var rad := deg_to_rad(float(a) - 90.0)
		var ln := 4.0 if a % 45 == 0 else 2.0
		var p0 := c + Vector2(cos(rad), sin(rad)) * 38.0
		var p1 := c + Vector2(cos(rad), sin(rad)) * (38.0 - ln)
		draw_line(p0, p1, Color8(110, 126, 146), 1.0)
	var nr := deg_to_rad(az - 90.0)
	draw_line(c, c + Vector2(cos(nr), sin(nr)) * 32.0, state_col, 2.0)
	draw_rect(Rect2(c - Vector2(2, 2), Vector2(4, 4)), Color8(200, 214, 226))
	font.draw(self, c + Vector2(-3, -50), Txt.ui("antenna.north"), Color8(140, 156, 176), 1)
	# readout + signal bars
	var rx := r.position.x + 120
	font.draw(self, Vector2(rx, r.position.y + 26), Txt.ui("antenna.angle") % int(roundf(az)), Color8(200, 214, 226), 1)
	font.draw(self, Vector2(rx, r.position.y + 44), Txt.ui("antenna.signal"), Color8(140, 156, 176), 1)
	var strength := clampf(1.0 - absf(err) / 90.0, 0.0, 1.0)
	for i in 10:
		var on := float(i) / 10.0 < strength + sin(t * 30.0 + i) * 0.04
		var h := 4 + i * 2
		draw_rect(Rect2(rx + i * 10, r.position.y + 80 - h, 7, h), state_col if on else Color8(40, 48, 60))
	# noise strip: the image coming in
	for x in range(0, 100, 2):
		var n := PixelFont._hash(x + int(t * 30.0), int(t * 60.0)) * (1.0 - strength)
		draw_rect(Rect2(rx + x, r.position.y + 88, 2, 8), Color(0.3 + n, 0.35 + n, 0.4 + n) if not locked else Color8(110, 210, 120))
	var hint := Txt.ui("antenna.locked") if locked else Txt.ui("antenna.hint")
	font.draw(self, Vector2(rx, r.position.y + 104), hint, state_col if locked else Color8(170, 184, 200), 1)


func _draw_wire() -> void:
	var r := Rect2(190, 40, 260, 140)
	draw_rect(r.grow(3), Color(0, 0, 0, 0.75))
	draw_rect(r, Color8(60, 66, 76))
	draw_rect(Rect2(r.position + Vector2(4, 18), r.size - Vector2(8, 22)), Color8(34, 38, 46))
	font.draw(self, r.position + Vector2(6, 5), String(wire.get("title", Txt.ui("wire.title"))), Color8(220, 226, 232), 1)
	var cols: Array = wire.get("colors", [])
	var sockets: Array = wire.get("sockets", [])
	var links: Array = wire.get("links", [-1, -1, -1])
	var sel: int = wire.get("sel", 0)
	var target: int = wire.get("target", 0)
	var flesh: bool = wire.get("flesh", false)
	var cut: bool = wire.get("cut", false)
	for i in 3:
		var y := r.position.y + 40 + i * 30
		var wc: Color = cols[i]
		if flesh:
			wc = wc.lerp(Color8(150, 30, 40), 0.6 + 0.2 * sin(t * 6.0 + i))
		var lx := r.position.x + 30
		draw_rect(Rect2(lx - 20, y - 2, 20, 4), wc)
		if links[i] >= 0:
			var ty := r.position.y + 40 + int(links[i]) * 30
			draw_line(Vector2(lx, y), Vector2(r.position.x + 200, ty), wc, 3.0)
		elif i == sel:
			var ty2 := r.position.y + 40 + target * 30
			draw_line(Vector2(lx, y), Vector2(lx + 70, (y + ty2) * 0.5 + sin(t * 4.0) * 3.0), wc, 3.0)
		else:
			draw_line(Vector2(lx, y), Vector2(lx + 24, y + 10), wc, 3.0)
		if i == sel and (links[i] < 0 or cut):
			draw_rect(Rect2(lx - 24, y - 6, 28, 12), Color(1, 1, 1, 0.25 + 0.2 * sin(t * 8.0)), false, 1.0)
		var sy := r.position.y + 40 + i * 30
		var sx := r.position.x + 200
		var scol: Color = sockets[i]
		draw_rect(Rect2(sx, sy - 6, 14, 12), Color8(20, 22, 28))
		draw_rect(Rect2(sx, sy - 6, 14, 12), scol, false, 2.0)
		draw_rect(Rect2(sx + 4, sy - 2, 6, 4), Color8(10, 10, 12))
		if i == target and links[sel] < 0 and not cut:
			draw_rect(Rect2(sx - 3, sy - 9, 20, 18), Color(1, 1, 1, 0.3 + 0.2 * sin(t * 8.0)), false, 1.0)
	font.draw(self, Vector2(r.position.x + 6, r.end.y - font.line_h() - 1), Txt.ui("wire.hint"), Color8(170, 184, 200), 1)


# ============================================================ documents
func doc_rect() -> Rect2:
	return Rect2(100, 22, 440, 304)


func doc_visible_lines() -> int:
	return int((doc_rect().size.y - 34 - font.line_h() * 2) / font.line_h())


func doc_wrapped() -> PackedStringArray:
	return font.wrap("\n".join(PackedStringArray(doc.get("lines", []))), int(doc_rect().size.x - 40), 1)


func _draw_doc() -> void:
	var r := doc_rect()
	draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.6))
	draw_rect(r, Color8(214, 206, 186))
	draw_rect(r.grow(-6), Color8(226, 220, 202))
	for y in range(int(r.position.y) + 30, int(r.end.y) - 20, font.line_h()):
		draw_rect(Rect2(r.position.x + 14, y + font.cell_h + 1, r.size.x - 28, 1), Color8(200, 196, 184))
	var ink := Color8(40, 36, 44)
	var title := String(doc.get("title", ""))
	if title != "":
		font.draw(self, r.position + Vector2(20, 12), title, Color8(120, 40, 36), 1)
		font.draw(self, r.position + Vector2(21, 12), title, Color8(120, 40, 36), 1)
	var lines := doc_wrapped()
	var vis := doc_visible_lines()
	var sc := clampi(int(doc.get("scroll", 0)), 0, maxi(0, lines.size() - vis))
	doc["scroll"] = sc
	for i in vis:
		if sc + i >= lines.size():
			break
		font.draw(self, r.position + Vector2(20, 30 + i * font.line_h()), lines[sc + i], ink, 1)
	if lines.size() > vis:
		var k := float(sc) / maxf(1.0, lines.size() - vis)
		draw_rect(Rect2(r.end.x - 10, r.position.y + 30 + k * (r.size.y - 70), 3, 10), Color8(150, 140, 120))
	var hint := Txt.ui("doc.hint")
	font.draw(self, Vector2(r.end.x - font.width(hint) - 14, r.end.y - font.line_h() - 4), hint, Color8(110, 104, 96), 1)


# ============================================================ echo sounder
func _draw_sonar() -> void:
	var r := Rect2(150, 26, 340, 200)
	draw_rect(r.grow(3), Color(0, 0, 0, 0.78))
	draw_rect(r, Color8(16, 24, 22))
	draw_rect(Rect2(r.position, Vector2(r.size.x, font.cell_h + 4)), Color8(34, 52, 46))
	var pt := Txt.ui("sonar.point") % String(sonar.get("point", "A"))
	font.draw(self, r.position + Vector2(6, 2), Txt.ui("sonar.title"), Color8(170, 220, 190), 1)
	font.draw(self, Vector2(r.end.x - font.width(pt) - 6, r.position.y + 2), pt, Color8(170, 220, 190), 1)
	var green := Color8(90, 220, 140)
	var dim := Color8(30, 70, 50)
	# fan: the lake seen from above, the shore along the bottom
	var c := r.position + Vector2(86, 154)
	for rad in [24.0, 48.0, 72.0]:
		for i in 60:
			var a := PI * i / 59.0
			var p: Vector2 = c + Vector2(cos(a), -sin(a)) * rad
			draw_rect(Rect2(floorf(p.x), floorf(p.y), 1, 1), dim)
	draw_rect(Rect2(c.x - 76, c.y + 1, 152, 1), Color8(60, 110, 80))
	font.draw(self, Vector2(c.x - 76, c.y + 4), Txt.ui("survey.shore"), Color8(60, 110, 80), 1)
	for pg in sonar.get("pings", []):
		var a := deg_to_rad(float(pg[0]))
		var s := float(pg[1])
		var p: Vector2 = c + Vector2(cos(a), -sin(a)) * 60.0
		var sz := 1.0 + s * 3.0
		draw_rect(Rect2(p.x - sz * 0.5, p.y - sz * 0.5, sz, sz), Color(0.35, 0.86, 0.55, 0.25 + 0.75 * s))
	var az := float(sonar.get("az", 90.0))
	var ar := deg_to_rad(az)
	var logged: bool = sonar.get("logged", false)
	draw_line(c, c + Vector2(cos(ar), -sin(ar)) * 74.0, Color8(230, 200, 90) if logged else green, 1.0)
	draw_rect(Rect2(c - Vector2(2, 2), Vector2(4, 4)), Color8(200, 230, 210))
	# trace: transmit, silence, the return (and on later nights, what is under it)
	var tr := Rect2(r.position.x + 182, r.position.y + 24, 148, 56)
	draw_rect(tr, Color8(8, 14, 12))
	draw_rect(tr, dim, false, 1.0)
	var mid := tr.position.y + tr.size.y * 0.5
	var trace: Dictionary = sonar.get("trace", {})
	if not trace.is_empty():
		var prog := clampf(float(trace["t"]) / 0.9, 0.0, 1.0)
		var str_k := float(trace["s"])
		var ex := 16.0 + float(trace["range"]) / 260.0 * 104.0
		var lim := tr.position.x + 2 + prog * (tr.size.x - 4)
		var prev := Vector2(tr.position.x + 2, mid)
		var x := tr.position.x + 2
		while x < lim:
			var lx := x - tr.position.x
			var v := (PixelFont._hash(int(x), int(trace["seed"])) - 0.5) * 3.0
			if lx < 8.0:
				v += -18.0 * (1.0 - lx / 8.0)
			var d := absf(lx - ex)
			if d < 4.0:
				v += -24.0 * str_k * (1.0 - d / 4.0)
			if bool(trace.get("struct", false)) and str_k > 0.5:
				for k in range(1, 5):
					var dk := absf(lx - ex - k * 6.0)
					if dk < 2.0:
						v += -10.0 * str_k * (1.0 - dk / 2.0) / k
			var p := Vector2(x, mid + v)
			draw_line(prev, p, green, 1.0)
			prev = p
			x += 1.0
	else:
		draw_rect(Rect2(tr.position.x + 2, mid, tr.size.x - 4, 1), dim)
	var ty := tr.end.y + 6
	var rng_s := "---"
	var dep_s := "---"
	if logged:
		rng_s = "%d m" % int(sonar.get("range", 0))
		dep_s = "%.1f m" % float(sonar.get("depth", 0.0))
	font.draw(self, Vector2(tr.position.x, ty), Txt.ui("sonar.bearing") % int(roundf(az)), Color8(170, 220, 190), 1)
	font.draw(self, Vector2(tr.position.x, ty + font.line_h()), Txt.ui("sonar.range") % rng_s, Color8(170, 220, 190), 1)
	font.draw(self, Vector2(tr.position.x, ty + font.line_h() * 2), Txt.ui("sonar.depth") % dep_s, Color8(170, 220, 190), 1)
	var hint := Txt.ui("sonar.logged") if logged else Txt.ui("sonar.hint")
	font.draw(self, Vector2(r.position.x + 6, r.end.y - font.line_h() - 1), hint, Color8(230, 200, 90) if logged else Color8(120, 160, 140), 1)


# ============================================================ radio
func _draw_radio() -> void:
	var r := Rect2(160, 40, 320, 168)
	draw_rect(r.grow(3), Color(0, 0, 0, 0.78))
	draw_rect(r, Color8(40, 34, 30))
	draw_rect(Rect2(r.position, Vector2(r.size.x, font.cell_h + 4)), Color8(64, 54, 46))
	font.draw(self, r.position + Vector2(6, 2), Txt.ui("radio.title"), Color8(230, 200, 150), 1)
	# dial
	var dial := Rect2(r.position.x + 12, r.position.y + 24, 150, 22)
	draw_rect(dial, Color8(20, 16, 12))
	for i in 30:
		var x := dial.position.x + 4 + i * 5
		draw_rect(Rect2(x, dial.position.y + (3 if i % 5 == 0 else 6), 1, 4 if i % 5 == 0 else 2), Color8(150, 120, 80))
	draw_rect(Rect2(dial.position.x + 102, dial.position.y + 2, 1, dial.size.y - 4), Color8(220, 60, 40))
	# the lamp, in time with the tones
	var lamp: bool = radio.get("lamp", false)
	var lc := r.position + Vector2(40, 82)
	_disc(lc, 10.0, Color8(30, 20, 16))
	_disc(lc, 8.0, Color8(255, 170, 60) if lamp else Color8(70, 40, 20))
	if lamp:
		_disc(lc, 14.0, Color(1.0, 0.6, 0.2, 0.15))
	# what assist shows (nothing, the dots and dashes, or the digits)
	var shown := String(radio.get("shown", ""))
	if shown != "":
		var lines := font.wrap(shown, 140, 1)
		var y := r.position.y + 104
		for ln in lines:
			font.draw(self, Vector2(r.position.x + 12, y), ln, Color8(255, 200, 120), 1)
			y += font.line_h()
	# the card taped to the set
	var card := Rect2(r.position.x + 176, r.position.y + 22, 132, 124)
	draw_rect(card, Color8(220, 212, 186))
	font.draw(self, card.position + Vector2(6, 4), Txt.ui("radio.card"), Color8(90, 40, 30), 1)
	for i in 10:
		var dg := str((i + 1) % 10)
		var col := int(i / 5.0)
		var row := i % 5
		var p := card.position + Vector2(8 + col * 64, 22 + row * 19)
		G.font_en.draw(self, p, dg, Color8(40, 36, 40), 1)
		var code: String = MORSE[dg]
		var x := p.x + 10
		for ch in code:
			if ch == ".":
				draw_rect(Rect2(x, p.y + 3, 2, 2), Color8(40, 36, 40))
				x += 5
			else:
				draw_rect(Rect2(x, p.y + 3, 7, 2), Color8(40, 36, 40))
				x += 10
	var hint := Txt.ui("radio.hint")
	font.draw(self, Vector2(r.end.x - font.width(hint) - 8, r.end.y - font.line_h() - 1), hint, Color8(170, 150, 120), 1)


func _disc(c: Vector2, rad: float, col: Color) -> void:
	var ri := int(ceil(rad))
	for y in range(-ri, ri + 1):
		var w := sqrt(maxf(0.0, rad * rad - y * y))
		draw_rect(Rect2(floorf(c.x - w), floorf(c.y + y), ceilf(w * 2.0), 1), col)


# ============================================================ credits
func _draw_credits() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 1.0))
	var bs: int = G.bs
	var lh := font.line_h(bs) + 6
	var n := credits.size()
	var y := 180.0 - (n - 1) * lh * 0.5
	for i in n:
		var s := String(credits[i])
		if s != "":
			var col := Color(0.86, 0.14, 0.16, credits_a) if i == 0 else Color(0.85, 0.85, 0.88, credits_a)
			font.draw_centered(self, Vector2(320, y), s, col, bs)
		y += lh
