class_name AppText
extends DeskApp
## Notepad: a read-only text file with word wrap and a scroll bar.
## Used for notice.txt and reports.log.

var lines_src: Array = []
var _wrapped := PackedStringArray()
var _wrap_w := -1
var scroll := 0
var _drag := false
var _drag_off := 0.0
const MENU := ["menu.file", "menu.edit", "menu.format", "menu.view", "menu.help"]
var LH: int:
	get:
		return G.font.line_h()
var MB: int:
	get:
		return G.font.cell_h + 6


func _init(t: String, src: Array, sz: Vector2 = Vector2(372, 276)) -> void:
	title = t
	lines_src = src
	size = sz


func _body(r: Rect2) -> Rect2:
	return Rect2(r.position.x + 1, r.position.y + MB, r.size.x - 2, r.size.y - MB - 1)


var _wrap_lang := ""


func _ensure(w: int) -> void:
	if w == _wrap_w and _wrap_lang == G._loaded_lang:
		return
	_wrap_w = w
	_wrap_lang = G._loaded_lang
	_wrapped = G.font.wrap("\n".join(PackedStringArray(lines_src)), w, 1)


func _visible_lines(b: Rect2) -> int:
	return int((b.size.y - 6) / LH)


func draw(ci: CanvasItem, r: Rect2) -> void:
	var f: PixelFont = G.font
	# menu bar
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, MB)), XP.FACE)
	var x := r.position.x + 6
	for mk in MENU:
		var m := Txt.ui(mk)
		f.draw(ci, Vector2(x, r.position.y + 3), m, XP.TEXT, 1)
		x += f.width(m, 1) + 12
	var b := _body(r)
	ci.draw_rect(b, Color8(127, 157, 185))
	var inner := b.grow(-1)
	ci.draw_rect(inner, Color.WHITE)
	var text_w := int(inner.size.x - 20)
	_ensure(text_w)
	var vis := _visible_lines(inner)
	scroll = clampi(scroll, 0, maxi(0, _wrapped.size() - vis))
	for i in vis:
		var li := scroll + i
		if li >= _wrapped.size():
			break
		var s: String = _wrapped[li]
		var col := XP.TEXT
		if s.ends_with(Txt.ui("log.corrected")):
			col = Color8(150, 20, 24)
		f.draw(ci, Vector2(inner.position.x + 4, inner.position.y + 3 + i * LH), s, col, 1)
	# scroll bar
	var sb := Rect2(inner.end.x - 15, inner.position.y, 15, inner.size.y)
	ci.draw_rect(sb, Color8(243, 241, 236))
	XP.button(ci, Rect2(sb.position.x, sb.position.y, 15, 15), "^")
	XP.button(ci, Rect2(sb.position.x, sb.end.y - 15, 15, 15), "v")
	var track := Rect2(sb.position.x, sb.position.y + 15, 15, sb.size.y - 30)
	var total := maxi(1, _wrapped.size())
	var th := maxf(14.0, track.size.y * minf(1.0, float(vis) / total))
	var maxs := maxi(1, total - vis)
	var ty := track.position.y + (track.size.y - th) * (float(scroll) / maxs if total > vis else 0.0)
	XP.button(ci, Rect2(track.position.x, ty, 15, th), "")


func _thumb(r: Rect2) -> Array:
	var inner := _body(r).grow(-1)
	var sb := Rect2(inner.end.x - 15, inner.position.y, 15, inner.size.y)
	var track := Rect2(sb.position.x, sb.position.y + 15, 15, sb.size.y - 30)
	var vis := _visible_lines(inner)
	var total := maxi(1, _wrapped.size())
	var th := maxf(14.0, track.size.y * minf(1.0, float(vis) / total))
	var maxs := maxi(1, total - vis)
	var ty := track.position.y + (track.size.y - th) * (float(scroll) / maxs if total > vis else 0.0)
	return [sb, track, Rect2(track.position.x, ty, 15, th), maxs]


func mouse(e: InputEvent, local: Vector2, r: Rect2) -> bool:
	var p := local + r.position
	var th := _thumb(r)
	var sb: Rect2 = th[0]
	var track: Rect2 = th[1]
	var thumb: Rect2 = th[2]
	var maxs: int = th[3]
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll -= 3
			return true
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll += 3
			return true
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if thumb.has_point(p):
					_drag = true
					_drag_off = p.y - thumb.position.y
					return true
				if sb.has_point(p):
					if p.y < track.position.y:
						scroll -= 1
					elif p.y > track.end.y:
						scroll += 1
					elif p.y < thumb.position.y:
						scroll -= 10
					else:
						scroll += 10
					Sfx.play("ui_tick", -16.0)
					return true
			else:
				_drag = false
	elif e is InputEventMouseMotion and _drag:
		var k := (p.y - _drag_off - track.position.y) / maxf(1.0, track.size.y - thumb.size.y)
		scroll = int(roundf(clampf(k, 0.0, 1.0) * maxs))
		return true
	return false


func key(e: InputEventKey) -> bool:
	if not e.pressed:
		return false
	match e.keycode:
		KEY_UP, KEY_W:
			scroll -= 1
		KEY_DOWN, KEY_S:
			scroll += 1
		KEY_PAGEUP:
			scroll -= 12
		KEY_PAGEDOWN:
			scroll += 12
		_:
			return false
	return true
