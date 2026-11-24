class_name AppSurvey
extends DeskApp
## survey_DATE.map: the lake from above, the three survey points, their
## bearing lines -- which all meet over the same spot in the middle -- and the
## readings. Nothing on it says what is down there.

var day := 1
var depth := 12.0


func _init(d: int, dep: float) -> void:
	day = d
	depth = dep
	title = Txt.ui("survey.title") % AppChart._date_str(float(G.day_unix(d))).substr(0, 10)
	size = Vector2(430, 318)


## Map metres -> pixels inside the plot rectangle.
func _to(p: Vector2, plot: Rect2) -> Vector2:
	var kx := (p.x + 140.0) / 300.0
	var ky := 1.0 - (p.y + 20.0) / 280.0
	return plot.position + Vector2(kx * plot.size.x, ky * plot.size.y)


func draw(ci: CanvasItem, r: Rect2) -> void:
	var f: PixelFont = G.font
	ci.draw_rect(r, Color.WHITE)
	var plot := Rect2(r.position.x + 6, r.position.y + 6, 220, r.size.y - 12)
	ci.draw_rect(plot, Color8(232, 238, 244))
	# the lake: a rough oval out from the shore
	var c := _to(Vector2(10, 140), plot)
	var rx := 100.0 / 300.0 * plot.size.x
	var ry := 130.0 / 280.0 * plot.size.y
	for y in range(int(-ry), int(ry) + 1):
		var w := rx * sqrt(maxf(0.0, 1.0 - float(y * y) / (ry * ry)))
		ci.draw_rect(Rect2(c.x - w, c.y + y, w * 2.0, 1), Color8(196, 214, 232))
	var shore_y := _to(Vector2(0, 0), plot).y
	ci.draw_rect(Rect2(plot.position.x, shore_y, plot.size.x, 1), Color8(120, 110, 90))
	f.draw(ci, Vector2(plot.position.x + 4, shore_y + 3), Txt.ui("survey.shore"), Color8(120, 110, 90), 1)
	for gx in range(-120, 160, 40):
		var p := _to(Vector2(gx, 0), plot)
		for yy in range(int(plot.position.y), int(plot.end.y), 4):
			ci.draw_rect(Rect2(p.x, yy, 1, 1), Color8(210, 216, 226))
	# bearing lines from the points, drawn on through the source and beyond
	var src := _to(Flow.SOURCE, plot)
	for id in Flow.SURVEY_POINTS.keys():
		var sp: Vector2 = Flow.SURVEY_POINTS[id][1]
		var a := _to(sp, plot)
		var far := a + (src - a) * 1.12
		far.y = maxf(far.y, plot.position.y + 1)
		ci.draw_line(a, far, Color8(60, 110, 180), 1.0)
		ci.draw_rect(Rect2(a - Vector2(2, 2), Vector2(4, 4)), Color8(30, 30, 40))
		G.font_en.draw(ci, a + Vector2(-2, 4), String(Flow.SURVEY_POINTS[id][0]), Color8(30, 30, 40), 1)
	for i in range(-4, 5):
		ci.draw_rect(Rect2(src.x + i, src.y + i, 1, 1), Color8(190, 30, 30))
		ci.draw_rect(Rect2(src.x + i, src.y - i, 1, 1), Color8(190, 30, 30))
	ci.draw_rect(plot, Color8(127, 157, 185), false, 1.0)
	# readings
	var tx := plot.end.x + 10
	var y := r.position.y + 8
	var lines := [Txt.ui("survey.lake"), "", Txt.ui("survey.chart"), Txt.ui("survey.source") % depth, ""]
	for id in Flow.SURVEY_POINTS.keys():
		var sp: Vector2 = Flow.SURVEY_POINTS[id][1]
		var b := rad_to_deg(atan2(Flow.SOURCE.y - sp.y, Flow.SOURCE.x - sp.x))
		lines.append(Txt.ui("survey.row") % [String(Flow.SURVEY_POINTS[id][0]), int(roundf(b)), int(roundf(sp.distance_to(Flow.SOURCE)))])
	if day >= 3:
		lines.append("")
		lines.append(Txt.ui("survey.struct"))
	if day >= 5:
		lines.append("")
		lines.append(Txt.ui("survey.pulse"))
	var tw := int(r.end.x - tx - 6)
	for ln in lines:
		for w in f.wrap(String(ln), tw, 1):
			var col := XP.TEXT
			if String(ln) == Txt.ui("survey.source") % depth:
				col = Color8(150, 20, 24)
			f.draw(ci, Vector2(tx, y), w, col, 1)
			y += f.line_h()
	_draw_section(ci, Rect2(tx, r.end.y - 78, r.end.x - tx - 8, 70))


## Side section through the lake centre: surface, the 12 m bottom, and the
## structure standing on it -- with the earlier surveys' tops dotted in.
func _draw_section(ci: CanvasItem, s: Rect2) -> void:
	var f: PixelFont = G.font
	f.draw(ci, s.position, Txt.ui("survey.section"), Color8(90, 90, 90), 1)
	var box := Rect2(s.position.x, s.position.y + f.line_h() + 2, s.size.x, s.size.y - f.line_h() - 2)
	ci.draw_rect(box, Color8(196, 214, 232))
	var bottom := box.end.y - 8.0
	var ytop := func(dep: float) -> float: return box.position.y + (bottom - box.position.y) * dep / G.LAKE_DEPTH
	ci.draw_rect(Rect2(box.position.x, bottom, box.size.x, box.end.y - bottom), Color8(120, 110, 90))
	ci.draw_rect(Rect2(box.position.x, box.position.y, box.size.x, 1), Color8(60, 110, 180))
	var cx := box.get_center().x
	# earlier surveys
	for sv in G.persist.get("surveys", []):
		if int(sv["day"]) >= day:
			continue
		var yy: float = ytop.call(float(sv["depth"]))
		for x in range(int(cx - 14), int(cx + 15), 3):
			ci.draw_rect(Rect2(x, yy, 1, 1), Color8(150, 60, 60))
	# the structure: a tower and a gable on a plinth, top at today's depth
	var top: float = ytop.call(depth)
	var h := bottom - top
	if h > 1.0:
		ci.draw_rect(Rect2(cx - 12, top + h * 0.45, 24, h * 0.55), Color8(120, 30, 36))
		ci.draw_rect(Rect2(cx - 3, top, 6, h * 0.5), Color8(120, 30, 36))
		ci.draw_rect(Rect2(cx - 1, top, 2, 1), Color8(190, 30, 30))
	ci.draw_rect(box, Color8(127, 157, 185), false, 1.0)
