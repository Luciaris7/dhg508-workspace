class_name AppMsg
extends DeskApp
## A modal-looking message box with one OK button.

var text := ""


func _init(t: String, body: String) -> void:
	title = t
	text = body
	size = Vector2(maxf(200.0, G.font.width(body) + 70.0), 74)


func on_open() -> void:
	Sfx.play("error_ding", -6.0)


func _ok(r: Rect2) -> Rect2:
	return Rect2(r.get_center().x - 30, r.end.y - 22, 60, 17)


func draw(ci: CanvasItem, r: Rect2) -> void:
	var c := Vector2(r.position.x + 22, r.position.y + 18)
	for y in range(-9, 10):
		var w := sqrt(maxf(0.0, 81.0 - y * y))
		ci.draw_rect(Rect2(c.x - w, c.y + y, w * 2.0, 1), Color8(210, 40, 30))
	for i in range(-4, 5):
		ci.draw_rect(Rect2(c.x + i - 1, c.y + i - 1, 2, 2), Color.WHITE)
		ci.draw_rect(Rect2(c.x - i - 1, c.y + i - 1, 2, 2), Color.WHITE)
	G.font.draw(ci, Vector2(r.position.x + 44, r.position.y + 14), text, XP.TEXT, 1)
	XP.button(ci, _ok(r), Txt.ui("ok"))


func mouse(e: InputEvent, local: Vector2, r: Rect2) -> bool:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		if _ok(r).has_point(local + r.position):
			desk.close_app(self)
			return true
	return false


func key(e: InputEventKey) -> bool:
	if e.pressed and (e.keycode == KEY_ENTER or e.keycode == KEY_SPACE):
		desk.close_app(self)
		return true
	return false
