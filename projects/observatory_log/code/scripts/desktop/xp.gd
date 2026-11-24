class_name XP
extends RefCounted
## Luna-style drawing helpers for the desktop (640x360, pixel-exact).

const BLUE_TOP := Color8(0, 88, 238)
const BLUE_MID := Color8(61, 149, 255)
const BLUE_BOT := Color8(0, 72, 200)
const INACTIVE := Color8(122, 150, 223)
const FACE := Color8(236, 233, 216)
const FACE_DK := Color8(172, 168, 153)
const FACE_LT := Color8(255, 255, 255)
const TEXT := Color8(0, 0, 0)
const SEL := Color8(49, 106, 197)
const TASK_TOP := Color8(56, 130, 240)
const TASK_MID := Color8(36, 94, 220)
const TASK_BOT := Color8(30, 76, 190)
const START_G1 := Color8(64, 170, 64)
const START_G2 := Color8(42, 130, 42)
const TRAY := Color8(14, 138, 230)
const CLOSE_R := Color8(224, 82, 52)


static func vgrad(ci: CanvasItem, r: Rect2, top: Color, bot: Color, steps: int = 0) -> void:
	var h := int(r.size.y)
	if steps <= 0:
		steps = h
	for i in h:
		var k := float(i) / maxf(1.0, h - 1.0)
		ci.draw_rect(Rect2(r.position.x, r.position.y + i, r.size.x, 1), top.lerp(bot, k))


static func vgrad3(ci: CanvasItem, r: Rect2, top: Color, mid: Color, bot: Color, split: float = 0.35) -> void:
	var h := int(r.size.y)
	for i in h:
		var k := float(i) / maxf(1.0, h - 1.0)
		var c := top.lerp(mid, k / split) if k < split else mid.lerp(bot, (k - split) / (1.0 - split))
		ci.draw_rect(Rect2(r.position.x, r.position.y + i, r.size.x, 1), c)


static func bevel(ci: CanvasItem, r: Rect2, sunken: bool = false) -> void:
	var lt := FACE_LT if not sunken else FACE_DK
	var dk := FACE_DK if not sunken else FACE_LT
	ci.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 1), lt)
	ci.draw_rect(Rect2(r.position.x, r.position.y, 1, r.size.y), lt)
	ci.draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), dk)
	ci.draw_rect(Rect2(r.end.x - 1, r.position.y, 1, r.size.y), dk)


static func button(ci: CanvasItem, r: Rect2, label: String, pressed: bool = false, enabled: bool = true, hot: bool = false) -> void:
	ci.draw_rect(r, Color8(0, 60, 116))
	var inner := r.grow(-1)
	vgrad(ci, inner, Color8(255, 255, 255) if not pressed else Color8(220, 218, 206), Color8(236, 235, 230) if not pressed else Color8(240, 239, 232))
	ci.draw_rect(Rect2(inner.position.x, inner.end.y - 2, inner.size.x, 2), Color8(214, 208, 197) if not pressed else Color8(240, 239, 232))
	if hot:
		ci.draw_rect(Rect2(inner.position.x, inner.position.y, inner.size.x, 1), Color8(255, 240, 207))
		ci.draw_rect(Rect2(inner.position.x, inner.end.y - 1, inner.size.x, 1), Color8(229, 151, 0))
	var f: PixelFont = G.font
	var w := f.width(label, 1)
	var col := TEXT if enabled else Color8(161, 161, 146)
	f.draw(ci, Vector2(roundf(r.position.x + (r.size.x - w) * 0.5), r.position.y + f.vcenter(r.size.y) + (1 if pressed else 0)), label, col, 1)


static func text_box(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(r, Color8(127, 157, 185))
	ci.draw_rect(r.grow(-1), Color8(255, 255, 255))


static func bold(ci: CanvasItem, pos: Vector2, text: String, col: Color) -> void:
	var f: PixelFont = G.font
	f.draw(ci, pos, text, col, 1)
	f.draw(ci, pos + Vector2(1, 0), text, col, 1)


static func window_frame(ci: CanvasItem, r: Rect2, title: String, active: bool, icon: Texture2D, can_min: bool = true, close_ok: bool = true) -> void:
	var top := BLUE_TOP if active else INACTIVE
	var mid := BLUE_MID if active else Color8(150, 175, 235)
	var bot := BLUE_BOT if active else Color8(110, 138, 214)
	# frame
	ci.draw_rect(r, bot)
	ci.draw_rect(Rect2(r.position.x + 3, r.position.y + 20, r.size.x - 6, r.size.y - 23), FACE)
	# title bar with rounded top corners
	var tb := Rect2(r.position.x, r.position.y, r.size.x, 20)
	vgrad3(ci, tb, mid, top, bot, 0.25)
	ci.draw_rect(Rect2(tb.position.x, tb.position.y, 2, 1), Color(0, 0, 0, 0))
	ci.draw_rect(Rect2(tb.position.x + 1, tb.position.y + 1, tb.size.x - 2, 1), mid.lerp(Color.WHITE, 0.35))
	if icon:
		ci.draw_texture_rect(icon, Rect2(tb.position.x + 4, tb.position.y + 2, 16, 16), false)
	var f: PixelFont = G.font
	var ty := tb.position.y + f.vcenter(20)
	f.draw(ci, Vector2(tb.position.x + 24, ty + 1), title, Color(0, 0, 0, 0.35), 1)
	bold(ci, Vector2(tb.position.x + 23, ty), title, Color.WHITE)
	# buttons
	var bx := tb.end.x - 20
	_cap_button(ci, Rect2(bx, tb.position.y + 2, 17, 16), "x", true, close_ok)
	if can_min:
		_cap_button(ci, Rect2(bx - 19, tb.position.y + 2, 17, 16), "_", false, true)


static func _cap_button(ci: CanvasItem, r: Rect2, kind: String, red: bool, enabled: bool) -> void:
	ci.draw_rect(r, Color8(255, 255, 255))
	var a := CLOSE_R if red else Color8(58, 128, 243)
	var b := Color8(196, 60, 30) if red else Color8(32, 92, 214)
	if not enabled:
		a = a.lerp(Color(0.6, 0.6, 0.6), 0.6)
		b = b.lerp(Color(0.5, 0.5, 0.5), 0.6)
	vgrad(ci, r.grow(-1), a.lerp(Color.WHITE, 0.25), b)
	var c := r.get_center()
	if kind == "x":
		for i in range(-3, 4):
			ci.draw_rect(Rect2(c.x + i - 1, c.y + i - 1, 2, 2), Color.WHITE)
			ci.draw_rect(Rect2(c.x - i - 1, c.y + i - 1, 2, 2), Color.WHITE)
	else:
		ci.draw_rect(Rect2(c.x - 4, c.y + 2, 6, 2), Color.WHITE)


static func cursor(ci: CanvasItem, p: Vector2, busy: bool = false) -> void:
	const ROWS := [
		"X",
		"XX",
		"X.X",
		"X..X",
		"X...X",
		"X....X",
		"X.....X",
		"X......X",
		"X.......X",
		"X........X",
		"X.....XXXXX",
		"X..X..X",
		"X.X X..X",
		"XX  X..X",
		"X    X..X",
		"     X..X",
		"      XX",
	]
	for y in ROWS.size():
		var row: String = ROWS[y]
		for x in row.length():
			var ch := row[x]
			if ch == "X":
				ci.draw_rect(Rect2(p.x + x, p.y + y, 1, 1), Color.BLACK)
			elif ch == ".":
				ci.draw_rect(Rect2(p.x + x, p.y + y, 1, 1), Color.WHITE)
	if busy:
		ci.draw_rect(Rect2(p.x + 10, p.y + 12, 7, 9), Color.BLACK)
		ci.draw_rect(Rect2(p.x + 11, p.y + 13, 5, 7), Color8(255, 255, 255))
		ci.draw_rect(Rect2(p.x + 12, p.y + 17, 3, 2), Color8(30, 90, 200))
