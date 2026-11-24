class_name AppArchive
extends DeskApp
## SITE 7 ARCHIVE: one record for each of the three observers before this one
## (13, 26 and 39 years back) and a box that opens a record by its number.
## The first two are purged; the last, left thirteen years ago tonight, is
## sealed: its number (YYYY-MM-DD-HHMM) is what the radio sends on night 5.

var text := ""
var msg := ""
var caret_t := 0.0


func _init() -> void:
	title = Txt.ui("archive.title")
	size = Vector2(360, 290)


func rows() -> Array:
	return [
		["%d-**-**-****" % G.cycle_year(3), Txt.ui("archive.purged")],
		["%d-**-**-****" % G.cycle_year(2), Txt.ui("archive.purged")],
		["%d-**-**-****" % G.cycle_year(1), "%s   %s" % [Txt.ui("archive.confirm"), Txt.ui("archive.sealed")]],
	]


func tick(dt: float) -> void:
	caret_t += dt


func _field(r: Rect2) -> Rect2:
	return Rect2(r.position.x + 12 + G.font.width(Txt.ui("archive.field")) + 8, r.end.y - 40, 120, 17)


func _open_btn(r: Rect2) -> Rect2:
	var f := _field(r)
	return Rect2(f.end.x + 6, f.position.y, maxf(52.0, G.font.width(Txt.ui("archive.open")) + 16.0), 17)


func draw(ci: CanvasItem, r: Rect2) -> void:
	var f: PixelFont = G.font
	ci.draw_rect(r, Color.WHITE)
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 22)), Color8(52, 58, 70))
	XP.bold(ci, r.position + Vector2(8, f.vcenter(22)), Txt.ui("archive.title"), Color8(230, 230, 236))
	# no legend: the numbers explain themselves, or they do not (user, 2026-11-16)
	var y := r.position.y + 30
	ci.draw_rect(Rect2(r.position.x + 8, y - 2, r.size.x - 16, 1), Color8(200, 200, 200))
	var all := rows()
	for ri in all.size():
		var row: Array = all[ri]
		var sealed: bool = ri == all.size() - 1
		var col := Color8(150, 20, 24) if sealed else XP.TEXT
		G.font_en.draw(ci, Vector2(r.position.x + 12, y + 1), String(row[0]), col, 1)
		f.draw(ci, Vector2(r.position.x + 110, y), String(row[1]), col, 1)
		y += f.line_h()
	var fr := _field(r)
	f.draw(ci, Vector2(r.position.x + 12, fr.position.y + f.vcenter(17)), Txt.ui("archive.field"), XP.TEXT, 1)
	XP.text_box(ci, fr)
	G.font_en.draw(ci, fr.position + Vector2(4, 5), text, XP.TEXT, 1)
	if int(caret_t * 2.0) % 2 == 0:
		ci.draw_rect(Rect2(fr.position.x + 5 + G.font_en.width(text) + 1, fr.position.y + 3, 1, 11), XP.TEXT)
	XP.button(ci, _open_btn(r), Txt.ui("archive.open"))
	if msg != "":
		f.draw(ci, Vector2(r.position.x + 12, r.end.y - 18), msg, Color8(190, 30, 30), 1)


func mouse(e: InputEvent, local: Vector2, r: Rect2) -> bool:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		if _open_btn(r).has_point(local + r.position):
			submit()
			return true
	return false


func key(e: InputEventKey) -> bool:
	if not e.pressed:
		return false
	if e.keycode == KEY_ENTER or e.keycode == KEY_KP_ENTER:
		submit()
		return true
	if e.keycode == KEY_BACKSPACE:
		text = text.substr(0, maxi(0, text.length() - 1))
		Sfx.play_var("key", 4, -14.0)
		return true
	var u := e.unicode
	if ((u >= 48 and u <= 57) or u == 45 or u == 32 or u == 58) and text.length() < 16:
		text += char(u)
		Sfx.play_var("key", 4, -14.0)
		return true
	return u != 0


static func digits(s: String) -> String:
	var out := ""
	for ch in s:
		if ch >= "0" and ch <= "9":
			out += ch
	return out


func submit() -> void:
	Sfx.play("click", -10.0)
	var n := digits(text)
	if n == G.morse_code():
		msg = ""
		var first: bool = not G.persist.get("morse_solved", false)
		G.persist["morse_solved"] = true
		Sfx.play("hdd", -6.0)
		desk.open_app(AppText.new(Txt.ui("archive.rec_title") % G.sealed_id(), Txt.doc("sealed"), Vector2(400, 290)), "sealed")
		if first:
			desk.flow.on_sealed_opened()
		return
	msg = Txt.ui("archive.none")
	Sfx.play("error_ding", -8.0)
