class_name AppChart
extends DeskApp
## SITE 7 STARCHART: an Earth-centred chart of the real sky -- the Sun, the
## Moon and Mercury..Neptune at their true geocentric ecliptic longitudes for
## the in-game date (the real date of the first session + one day per game
## day), with the major moons when zoomed in. The unknown object is injected
## by day and does not come from the ephemeris.

var date_off := 0
var zoom := 1.0
var marking := false
var marks: Array = []
var rec_t := -1.0
var msg := ""
var msg_t := 0.0
var smudge := 0.0
var t := 0.0
var _pos := {}
var _sat := {}
var _ut := -1e9
var view_day := -1          # >0: a saved record (read-only)
var record_marks: Array = []

const COLORS := {
	"Sun": Color8(255, 214, 120), "Moon": Color8(200, 204, 210), "Mercury": Color8(160, 150, 140),
	"Venus": Color8(236, 220, 170), "Mars": Color8(224, 110, 70), "Jupiter": Color8(214, 184, 140),
	"Saturn": Color8(226, 200, 130), "Uranus": Color8(150, 220, 226), "Neptune": Color8(100, 140, 236),
}
const SIZES := {"Sun": 4.0, "Moon": 2.0, "Mercury": 1.5, "Venus": 2.0, "Mars": 2.0, "Jupiter": 3.0, "Saturn": 3.0, "Uranus": 2.5, "Neptune": 2.5}
const ANOM_ANGLE := 38.0


func _init(record_day: int = -1, rmarks: Array = []) -> void:
	view_day = record_day
	record_marks = rmarks
	if record_day > 0:
		title = Txt.ui("record.title") % _date_str(G.day_unix(record_day)).substr(0, 10)
		size = Vector2(340, 250)
	else:
		title = Txt.ui("chart.title")
		size = Vector2(424, 296)


func on_open() -> void:
	if view_day < 0:
		desk.flow.on_chart_opened()


func tick(dt: float) -> void:
	t += dt
	if msg_t > 0.0:
		msg_t -= dt
	if rec_t >= 0.0:
		rec_t += dt
		if rec_t >= 1.6:
			rec_t = -1.0
			msg = Txt.ui("chart.recorded")
			msg_t = 3.0
			Sfx.play("ui_ding", -8.0)
			var hit := _marks_hit()
			desk.flow.on_chart_recorded(hit, marks.duplicate(true))


func _day() -> int:
	return view_day if view_day > 0 else G.day


func _unix() -> float:
	# live chart: the station clock (same as the taskbar); a saved record: its day
	var base := G.world_unix() if view_day < 0 else G.day_unix(_day())
	return float(base + date_off * 86400)


static func _date_str(unix: float) -> String:
	var d := Time.get_datetime_dict_from_unix_time(int(unix))
	return "%04d-%02d-%02d %02d:%02d" % [d["year"], d["month"], d["day"], d["hour"], d["minute"]]


func _update_positions() -> void:
	var ut := Ephemeris.ut_from_unix(_unix())
	if absf(ut - _ut) < 0.0001:
		return
	_ut = ut
	_pos = Ephemeris.positions(ut)
	_sat = Ephemeris.satellites(ut)


func _state() -> String:
	if view_day > 0:
		return "recorded"
	return desk.flow.chart_state()


# --------------------------------------------------------------- layout
func _toolbar_buttons(r: Rect2) -> Array:
	var y := r.position.y + 3
	var x := r.position.x + 4
	var out := []
	if view_day > 0:
		return out
	var f: PixelFont = G.font
	var h := 15.0
	var items := [["prev", "<", 0], ["date", "", 0], ["next", ">", 4], ["today", Txt.ui("chart.today"), 6],
		["zout", "-", 0], ["zin", "+", 6], ["mark", Txt.ui("chart.mark"), 2], ["clear", Txt.ui("chart.clear"), 0]]
	for it in items:
		var w := maxf(14.0, f.width(String(it[1])) + 12.0)
		if it[0] == "date":
			w = f.width(_date_str(_unix())) + 10.0
		out.append([it[0], Rect2(x, y, w, h), it[1]])
		x += w + 2 + int(it[2])
	var rw := maxf(48.0, f.width(Txt.ui("chart.record")) + 16.0)
	out.append(["record", Rect2(r.end.x - rw - 4, y, rw, h), Txt.ui("chart.record")])
	return out


func _area(r: Rect2) -> Rect2:
	var top := 21 if view_day < 0 else 2
	return Rect2(r.position.x + 3, r.position.y + top, r.size.x - 6, r.size.y - top - 18)


func radius(d: float, area: Rect2) -> float:
	var k := area.size.y / 230.0
	return (12.0 + 88.0 * log(1.0 + d) / log(32.0)) * zoom * k


func anomaly(area: Rect2) -> Dictionary:
	var day := _day()
	if day < 3:
		return {}
	var c := area.get_center()
	var rr := 0.0
	var sz := 1.0
	var dist := {3: 38.0, 4: 24.0, 5: 19.2, 6: 9.0, 7: 4.6}
	# kept in proportion with the ending illustrations: large, never the whole chart
	var sizes := {3: 0.9, 4: 1.5, 5: 3.5, 6: 6.0, 7: 10.0}
	rr = radius(float(dist[day]), area)
	sz = float(sizes[day]) * (area.size.y / 230.0) * zoom
	var a := deg_to_rad(ANOM_ANGLE)
	return {"pos": c + Vector2(cos(a), -sin(a)) * rr, "size": sz}


var _last_area := Rect2(0, 0, 400, 240)


func _marks_hit() -> bool:
	var area := _last_area
	var z := zoom
	zoom = 1.0
	var an := anomaly(area)
	zoom = z
	if an.is_empty():
		return false
	for m in marks:
		var mp := area.position + Vector2(m[0], m[1]) * area.size
		if mp.distance_to(an["pos"]) <= float(an["size"]) + 8.0:
			return true
	return false


# ------------------------------------------------------------------ draw
func draw(ci: CanvasItem, r: Rect2) -> void:
	var f: PixelFont = G.font
	_update_positions()
	if view_day < 0:
		ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 21)), XP.FACE)
		var st := _state()
		for b in _toolbar_buttons(r):
			var rr: Rect2 = b[1]
			if b[0] == "date":
				XP.text_box(ci, rr)
				f.draw(ci, rr.position + Vector2(4, f.vcenter(rr.size.y)), _date_str(_unix()), XP.TEXT, 1)
				continue
			var enabled := true
			if b[0] == "record":
				enabled = st == "ready" and rec_t < 0.0
			XP.button(ci, rr, b[2], b[0] == "mark" and marking, enabled, b[0] == "mark" and marking)
	var area := _area(r)
	draw_chart(ci, area)
	# status bar
	var sb := Rect2(r.position.x, r.end.y - 16, r.size.x, 16)
	ci.draw_rect(sb, XP.FACE)
	XP.bevel(ci, Rect2(sb.position.x + 2, sb.position.y + 1, sb.size.x - 4, 14), true)
	var status := Txt.ui("chart.scale")
	if rec_t >= 0.0:
		status = Txt.ui("chart.recording")
	elif msg_t > 0.0:
		status = msg
	elif view_day < 0 and _state() == "recorded":
		status = Txt.ui("chart.already")
	f.draw(ci, sb.position + Vector2(6, f.vcenter(16)), status, XP.TEXT, 1)
	var mtxt := Txt.ui("chart.marks") % (marks.size() if view_day < 0 else record_marks.size())
	f.draw(ci, Vector2(sb.end.x - f.width(mtxt, 1) - 8, sb.position.y + f.vcenter(16)), mtxt, XP.TEXT, 1)
	if rec_t >= 0.0:
		var pr := Rect2(sb.position.x + 150, sb.position.y + 3, 120, 7)
		ci.draw_rect(pr, Color8(255, 255, 255))
		var n := int(rec_t / 1.6 * 14.0)
		for i in n:
			ci.draw_rect(Rect2(pr.position.x + 1 + i * 8.5, pr.position.y + 1, 7, 5), Color8(40, 170, 60))


func draw_chart(ci: CanvasItem, area: Rect2) -> void:
	var f: PixelFont = G.font
	_last_area = area
	ci.draw_rect(area, Color8(4, 8, 16))
	var c := area.get_center()
	var st := _state()
	if st == "no_signal" and view_day < 0:
		for i in 900:
			var x := area.position.x + PixelFont._hash(i, int(t * 30.0)) * area.size.x
			var y := area.position.y + PixelFont._hash(i + 7, int(t * 30.0)) * area.size.y
			var v := PixelFont._hash(i, 3 + int(t * 60.0))
			ci.draw_rect(Rect2(floorf(x), floorf(y), 2, 1), Color(v, v, v, 0.6))
		var s := Txt.ui("chart.no_signal")
		ci.draw_rect(Rect2(c.x - f.width(s) / 2 - 6, c.y - f.cell_h / 2 - 4, f.width(s) + 12, f.cell_h + 8), Color8(0, 0, 0))
		f.draw(ci, Vector2(c.x - f.width(s) / 2, c.y - f.cell_h / 2), s, Color8(230, 230, 230), 1)
		return
	# grid
	for d in [0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 30.0]:
		_ring(ci, c, radius(d, area), Color8(22, 34, 56), area, 3)
	for a in range(0, 360, 30):
		var rad := deg_to_rad(float(a))
		var p1 := c + Vector2(cos(rad), -sin(rad)) * 400.0
		_clip_line(ci, c, p1, area, Color8(14, 24, 40))
	for a in range(0, 360, 90):
		var rad := deg_to_rad(float(a))
		var lp := c + Vector2(cos(rad), -sin(rad)) * (area.size.y * 0.47)
		if area.has_point(lp):
			f.draw(ci, lp - Vector2(6, 4), "%d" % a, Color8(50, 70, 100), 1)
	# orbits of the bodies at their present distance
	for n in Ephemeris.NAMES:
		if n == "Moon":
			continue
		var p: Vector2 = _pos[n]
		_ring(ci, c, radius(p.y, area), Color8(30, 46, 74), area, 2)
	# bodies
	for n in Ephemeris.NAMES:
		var p: Vector2 = _pos[n]
		var rr := radius(p.y, area) if n != "Moon" else 9.0 * zoom * area.size.y / 230.0
		var a := deg_to_rad(p.x)
		var bp := c + Vector2(cos(a), -sin(a)) * rr
		if not area.grow(-2).has_point(bp):
			continue
		var s: float = SIZES[n]
		_disc(ci, bp, s, COLORS[n])
		if n == "Saturn":
			ci.draw_rect(Rect2(bp.x - 5, bp.y, 11, 1), Color8(200, 180, 120))
		if n == "Sun":
			_disc(ci, bp, s + 3, Color(1, 0.85, 0.5, 0.15))
		var lab: String = Txt.body(n)
		var lp := bp + Vector2(5, -3)
		if lp.x + f.width(lab) < area.end.x and lp.y > area.position.y and lp.y < area.end.y - 8:
			f.draw(ci, lp, lab, Color8(110, 130, 160), 1)
		if zoom >= 2.0 and (n == "Jupiter" or n == "Saturn"):
			for sn in (["Io", "Europa", "Ganymede", "Callisto"] if n == "Jupiter" else ["Titan"]):
				var sp: Vector2 = _sat[sn]
				var spp := bp + sp * (zoom / 2.0)
				if area.has_point(spp):
					ci.draw_rect(Rect2(floorf(spp.x), floorf(spp.y), 1, 1), Color8(220, 220, 220))
					if zoom >= 3.0:
						f.draw(ci, spp + Vector2(2, 2), Txt.body(sn), Color8(80, 96, 120), 1)
	# Earth at the centre
	_disc(ci, c, 3.0, Color8(70, 150, 210))
	ci.draw_rect(Rect2(c.x - 1, c.y - 2, 2, 1), Color8(80, 170, 90))
	f.draw(ci, c + Vector2(5, 3), Txt.body("Earth"), Color8(110, 150, 190), 1)
	# the unknown object
	var an := anomaly(area)
	if not an.is_empty():
		_draw_anomaly(ci, an["pos"], an["size"], area)
	# marks
	var ms: Array = record_marks if view_day > 0 else marks
	if zoom > 1.01:
		ms = []
	for m in ms:
		var mp := area.position + Vector2(m[0], m[1]) * area.size
		_ring(ci, mp, 6.0, Color8(230, 40, 40), area, 1)
		_ring(ci, mp, 7.0, Color8(230, 40, 40), area, 1)
	if smudge > 0.0 and not an.is_empty():
		var sp: Vector2 = an["pos"]
		for i in 9:
			var y := sp.y - 10 + i * 2.5
			ci.draw_rect(Rect2(sp.x - 24 + sin(i * 1.7) * 4.0, y, 48, 2), Color(0.75, 0.72, 0.68, 0.10 * smudge))
	ci.draw_rect(area, Color8(127, 157, 185), false, 1.0)


func _draw_anomaly(ci: CanvasItem, p: Vector2, s: float, area: Rect2) -> void:
	var day := _day()
	if day == 3:
		ci.draw_rect(Rect2(floorf(p.x), floorf(p.y), 1, 1), Color8(120, 44, 44))
		return
	if day == 4:
		ci.draw_rect(Rect2(floorf(p.x), floorf(p.y), 2, 2), Color8(150, 40, 42))
		ci.draw_rect(Rect2(floorf(p.x) + 1, floorf(p.y), 1, 1), Color8(190, 70, 70))
		return
	var beat := pow(0.5 + 0.5 * sin(t * 6.0), 4.0)
	_disc(ci, p, s + 3.0, Color(0.7, 0.05, 0.08, 0.18 + 0.08 * beat))
	_disc(ci, p, s, Color8(150, 26, 34))
	_disc(ci, p + Vector2(-s * 0.25, -s * 0.25), s * 0.6, Color8(176, 40, 48))
	if day >= 6:
		var n := 6 if day == 6 else 14
		for i in n:
			var a0 := PixelFont._hash(i, 5) * TAU
			var q := p
			for k in 6:
				a0 += (PixelFont._hash(i, k) - 0.5) * 1.4
				var q2 := q + Vector2(cos(a0), sin(a0)) * s * 0.22
				if q2.distance_to(p) < s - 1.0:
					ci.draw_line(q, q2, Color8(70, 8, 16).lerp(Color8(220, 40, 50), beat), 1.0)
				q = q2



func _disc(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var ri := int(ceil(r))
	for y in range(-ri, ri + 1):
		var w := sqrt(maxf(0.0, r * r - y * y))
		if w > 0.0:
			ci.draw_rect(Rect2(floorf(c.x - w), floorf(c.y + y), maxf(1.0, ceilf(w * 2.0)), 1), col)


func _ring(ci: CanvasItem, c: Vector2, r: float, col: Color, area: Rect2, dash: int) -> void:
	var n := int(clampf(r * 1.6, 12.0, 260.0))
	for i in n:
		if dash > 1 and i % dash != 0:
			continue
		var a := TAU * i / n
		var p := c + Vector2(cos(a), sin(a)) * r
		if area.has_point(p):
			ci.draw_rect(Rect2(floorf(p.x), floorf(p.y), 1, 1), col)


func _clip_line(ci: CanvasItem, a: Vector2, b: Vector2, area: Rect2, col: Color) -> void:
	var n := 80
	for i in n:
		var p := a.lerp(b, float(i) / n)
		if not area.has_point(p):
			break
		if i % 2 == 0:
			ci.draw_rect(Rect2(floorf(p.x), floorf(p.y), 1, 1), col)


# ----------------------------------------------------------------- input
func mouse(e: InputEvent, local: Vector2, r: Rect2) -> bool:
	if not (e is InputEventMouseButton):
		return false
	var mb := e as InputEventMouseButton
	if not mb.pressed:
		return false
	var p := local + r.position
	if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoom = minf(4.0, zoom * 1.25)
		marking = false
		return true
	if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoom = maxf(1.0, zoom / 1.25)
		return true
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return false
	for b in _toolbar_buttons(r):
		if (b[1] as Rect2).has_point(p):
			_press(String(b[0]))
			return true
	var area := _area(r)
	if area.has_point(p) and marking and view_day < 0 and _state() == "ready":
		var rel := (p - area.position) / area.size
		for i in marks.size():
			var mp := area.position + Vector2(marks[i][0], marks[i][1]) * area.size
			if mp.distance_to(p) < 8.0:
				marks.remove_at(i)
				Sfx.play("ui_tick", -10.0)
				return true
		if marks.size() < 5:
			marks.append([rel.x, rel.y])
			Sfx.play("mark", -8.0)
		return true
	return false


func _press(b: String) -> void:
	Sfx.play("click", -10.0)
	match b:
		"prev":
			date_off -= 1
		"next":
			date_off += 1
		"today":
			date_off = 0
		"zin":
			zoom = minf(4.0, zoom * 1.5)
			marking = false
		"zout":
			zoom = maxf(1.0, zoom / 1.5)
			marking = false
		"mark":
			marking = not marking
			zoom = 1.0
		"clear":
			marks.clear()
		"record":
			if _state() != "ready":
				if _state() == "no_signal":
					msg = Txt.ui("chart.no_signal")
				else:
					msg = Txt.ui("chart.already")
				msg_t = 2.5
				Sfx.play("error_ding", -8.0)
				return
			if rec_t >= 0.0:
				return
			date_off = 0
			zoom = 1.0
			rec_t = 0.0
			Sfx.play("hdd", -8.0)
