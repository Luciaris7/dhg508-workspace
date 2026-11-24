class_name AppFolder
extends DeskApp
## Explorer-style folder: My Computer, Recycle Bin, My Documents.

var kind := ""
var items: Array = []       # [{label, icon, action}]
var sel := -1
var _last_click := -1.0
var note := ""
const ROW := 18


func _init(k: String) -> void:
	kind = k
	size = Vector2(300, 190)
	match k:
		"mycomputer":
			title = Txt.ui("mycomputer.title")
		"bin":
			title = Txt.ui("bin.title")
		"mydocs":
			title = Txt.ui("mydocs.title")
			size = Vector2(380, 300)


func on_open() -> void:
	items.clear()
	match kind:
		"mycomputer":
			items.append({"label": Txt.ui("mycomputer.c"), "icon": "drive", "action": "err.access"})
			items.append({"label": Txt.ui("mycomputer.a"), "icon": "floppy", "action": "floppy"})
		"bin":
			note = Txt.ui("bin.empty")
		"mydocs":
			for rec in G.persist["records"]:
				var d := int(rec["day"])
				var date := AppChart._date_str(float(G.day_unix(d))).substr(0, 10)
				items.append({"label": "chart_%s.bmp" % date, "icon": "image", "action": "record", "day": d, "marks": rec["marks"]})
			for sv in G.persist.get("surveys", []):
				var d := int(sv["day"])
				var date := AppChart._date_str(float(G.day_unix(d))).substr(0, 10)
				items.append({"label": "survey_%s.map" % date, "icon": "survey", "action": "survey", "day": d, "depth": float(sv["depth"])})
			# Day 3 on: a log nobody here wrote, dated one cycle ahead
			if G.day >= 3:
				items.append({"label": "obslog_%s.txt" % Desktop.future_date(1), "icon": "log", "action": "obslog"})
			if items.is_empty():
				note = Txt.ui("mydocs.empty")


func draw(ci: CanvasItem, r: Rect2) -> void:
	var f: PixelFont = G.font
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 14)), XP.FACE)
	var x := r.position.x + 6
	for mk in ["menu.file", "menu.edit", "menu.view", "menu.fav", "menu.tools", "menu.help"]:
		var m := Txt.ui(mk)
		f.draw(ci, Vector2(x, r.position.y + 1), m, XP.TEXT, 1)
		x += f.width(m) + 11
	var side := Rect2(r.position.x + 1, r.position.y + 15, 86, r.size.y - 16)
	XP.vgrad(ci, side, Color8(122, 160, 225), Color8(99, 117, 214))
	ci.draw_rect(Rect2(side.position.x + 6, side.position.y + 8, side.size.x - 12, 40), Color8(214, 223, 247))
	XP.bold(ci, side.position + Vector2(10, 11), Txt.ui("folder.tasks"), Color8(33, 93, 198))
	f.draw(ci, side.position + Vector2(10, 11 + f.line_h() + 2), Txt.ui("folder.details"), Color8(33, 93, 198), 1)
	var body := Rect2(side.end.x + 1, side.position.y, r.end.x - side.end.x - 2, side.size.y)
	ci.draw_rect(body, Color.WHITE)
	if items.is_empty() and note != "":
		f.draw(ci, body.position + Vector2(10, 10), note, XP.TEXT, 1)
	for i in items.size():
		var it: Dictionary = items[i]
		var ir := Rect2(body.position.x + 8, body.position.y + 8 + i * ROW, body.size.x - 16, ROW - 1)
		if i == sel:
			ci.draw_rect(ir, XP.SEL)
		var ic: Texture2D = desk.icon_tex(String(it["icon"]))
		if ic:
			ci.draw_texture_rect(ic, Rect2(ir.position.x + 2, ir.position.y + 2, 16, 16), false)
		f.draw(ci, ir.position + Vector2(24, f.vcenter(ROW - 1)), String(it["label"]), Color.WHITE if i == sel else XP.TEXT, 1)


func mouse(e: InputEvent, local: Vector2, r: Rect2) -> bool:
	if not (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		return false
	var p := local + r.position
	var body_x := r.position.x + 88
	for i in items.size():
		var ir := Rect2(body_x + 8, r.position.y + 15 + 8 + i * ROW, r.size.x - 104, ROW - 1)
		if ir.has_point(p):
			var now := Time.get_ticks_msec() / 1000.0
			if sel == i and now - _last_click < 0.45:
				_open(items[i])
			sel = i
			_last_click = now
			Sfx.play("click", -14.0)
			return true
	sel = -1
	return true


func _open(it: Dictionary) -> void:
	match String(it["action"]):
		"err.access":
			desk.msgbox(Txt.ui("err.title"), Txt.ui("err.access"))
		"floppy":
			Sfx.play("floppy", -6.0)
			desk.msgbox("A:\\", Txt.ui("err.floppy"))
		"record":
			desk.open_app(AppChart.new(int(it["day"]), it["marks"]), "record_%d" % int(it["day"]))
		"survey":
			var d := int(it["day"])
			desk.open_app(AppSurvey.new(d, float(it["depth"])), "survey_%d" % d)
			desk.flow.found("echo_hollow", false)
			if d >= 5:
				desk.flow.found("echo_aurora", false)
		"obslog":
			desk.open_app(AppText.new(Txt.ui("obslog.title") % Desktop.future_date(1), desk.future_log_lines(), Vector2(400, 220)), "obslog")
			desk.flow.found("future_log", false)
