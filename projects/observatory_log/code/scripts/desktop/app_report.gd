class_name AppReport
extends DeskApp
## The report "web page": one question, one input box, one SUBMIT button.
## Day 6-7 only accept No; anything else puts a red "Type No" in the
## middle of the screen until the player complies. From Day 6 the typed text
## is red.

var text := ""
var focused := true
var replies: Array = []
var error := ""
var submitted := false
var caret_t := 0.0
var forcing := false


func _init() -> void:
	title = Txt.ui("report.title")
	size = Vector2(352, 236)


func on_open() -> void:
	submitted = desk.flow.report_state() == "done"
	if submitted and replies.is_empty():
		replies = [Txt.ui("report.done")]
	desk.flow.on_report_opened()


func tick(dt: float) -> void:
	caret_t += dt


func can_close() -> bool:
	return not forcing


func _page(r: Rect2) -> Rect2:
	return Rect2(r.position.x + 2, r.position.y + 40, r.size.x - 4, r.size.y - 56)


func _input_rect(r: Rect2) -> Rect2:
	var p := _page(r)
	return Rect2(p.position.x + 24, p.position.y + 78, 150, 17)


func _submit_rect(r: Rect2) -> Rect2:
	var p := _page(r)
	return Rect2(p.position.x + 24, p.position.y + 102, 62, 18)


func draw(ci: CanvasItem, r: Rect2) -> void:
	var f: PixelFont = G.font
	# menu + toolbar + address bar
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 40)), XP.FACE)
	var x := r.position.x + 6
	for mk in ["menu.file", "menu.edit", "menu.view", "menu.fav", "menu.tools", "menu.help"]:
		var m := Txt.ui(mk)
		f.draw(ci, Vector2(x, r.position.y + 1), m, XP.TEXT, 1)
		x += f.width(m) + 11
	ci.draw_rect(Rect2(r.position.x, r.position.y + 13, r.size.x, 1), XP.FACE_DK)
	var ab := Rect2(r.position.x + 46, r.position.y + 22, r.size.x - 86, 16)
	f.draw(ci, Vector2(r.position.x + 6, ab.position.y + f.vcenter(16)), Txt.ui("report.addr"), Color8(90, 90, 90), 1)
	XP.text_box(ci, ab)
	ci.draw_rect(Rect2(ab.position.x + 3, ab.position.y + 3, 9, 9), Color8(60, 130, 220))
	f.draw(ci, ab.position + Vector2(16, f.vcenter(16)), Txt.ui("report.address"), XP.TEXT, 1)
	XP.button(ci, Rect2(ab.end.x + 4, ab.position.y, 30, 16), Txt.ui("report.go"))
	# page
	var p := _page(r)
	ci.draw_rect(p, Color.WHITE)
	ci.draw_rect(Rect2(p.position, Vector2(p.size.x, 22)), Color8(38, 62, 110))
	XP.bold(ci, p.position + Vector2(10, f.vcenter(22)), Txt.ui("report.header"), Color.WHITE)
	var date := AppChart._date_str(float(G.day_unix())).substr(0, 10)
	f.draw(ci, Vector2(p.end.x - f.width(date) - 10, p.position.y + f.vcenter(22)), date, Color8(190, 205, 230), 1)
	var q := f.wrap(Txt.ui("report.question"), int(p.size.x - 40), 1)
	var y := p.position.y + 38
	for ln in q:
		f.draw(ci, Vector2(p.position.x + 24, y), ln, XP.TEXT, 1)
		y += f.line_h()
	var ir := _input_rect(r)
	XP.text_box(ci, ir)
	var tcol := XP.TEXT if G.day < 6 else Color8(200, 16, 20)
	f.draw(ci, ir.position + Vector2(4, f.vcenter(ir.size.y)), text, tcol, 1)
	if focused and not submitted and int(caret_t * 2.0) % 2 == 0:
		ci.draw_rect(Rect2(ir.position.x + 5 + f.width(text) + 1, ir.position.y + 3, 1, ir.size.y - 6), XP.TEXT)
	XP.button(ci, _submit_rect(r), Txt.ui("report.submit"), false, not submitted)
	y = p.position.y + 128
	if error != "":
		f.draw(ci, Vector2(p.position.x + 24, y), error, Color8(190, 30, 30), 1)
		y += f.line_h() + 1
	for ln in replies:
		f.draw(ci, Vector2(p.position.x + 24, y), String(ln), Color8(40, 70, 120), 1)
		y += f.line_h()
	# IE status bar
	var sb := Rect2(r.position.x, r.end.y - 15, r.size.x, 15)
	ci.draw_rect(sb, XP.FACE)
	f.draw(ci, sb.position + Vector2(6, f.vcenter(15)), Txt.ui("report.done_status"), XP.TEXT, 1)
	var zone := Txt.ui("report.zone")
	f.draw(ci, Vector2(sb.end.x - f.width(zone) - 8, sb.position.y + f.vcenter(15)), zone, XP.TEXT, 1)


func mouse(e: InputEvent, local: Vector2, r: Rect2) -> bool:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var p := local + r.position
		if _input_rect(r).has_point(p):
			focused = true
			return true
		if _submit_rect(r).has_point(p):
			_submit()
			return true
		focused = false
	return false


func key(e: InputEventKey) -> bool:
	if not e.pressed or submitted:
		return false
	if e.keycode == KEY_ENTER or e.keycode == KEY_KP_ENTER:
		_submit()
		return true
	if not focused:
		return false
	if e.keycode == KEY_BACKSPACE:
		if text.length() > 0:
			text = text.substr(0, text.length() - 1)
		Sfx.play_var("key", 4, -14.0)
		return true
	var u := e.unicode
	if u >= 32 and u < 127 and text.length() < 14:
		text += char(u)
		Sfx.play_var("key", 4, -14.0)
		return true
	return u != 0


func _submit() -> void:
	if submitted:
		return
	Sfx.play("click", -10.0)
	var st: String = desk.flow.report_state()
	if st == "need_chart":
		error = Txt.ui("report.need_chart")
		Sfx.play("error_ding", -8.0)
		return
	var a := text.strip_edges().to_lower()
	if G.day >= 6 and a != "no":
		forcing = true
		error = ""
		desk.show_type_yes(true)
		Sfx.play("red_sting", -6.0)
		text = ""
		return
	if a != "yes" and a != "no":
		error = Txt.ui("report.bad")
		Sfx.play("error_ding", -8.0)
		return
	error = ""
	if forcing:
		forcing = false
		desk.show_type_yes(false)
	submitted = true
	focused = false
	Sfx.play("hdd", -8.0)
	replies = desk.flow.on_report_submitted(a)
	desk.refresh_icons()
