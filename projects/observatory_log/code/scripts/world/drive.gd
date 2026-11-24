class_name Drive
extends Node2D
## Prologue: the pickup drives right along a mountain road. The truck stays
## at the centre of the screen and the world flows left past it, the same
## trick the minigame uses for the boat.

signal stopped

var cam_x := 0.0
var speed := 72.0
var target_speed := 72.0
var t := 0.0
var _truck: Texture2D
var _fir: Array = []
var _backdrop: Texture2D
var _stopping := false


func _ready() -> void:
	_truck = load("res://assets/art/world/truck.png")
	_backdrop = load("res://assets/art/world/backdrop.png")
	for i in 7:
		_fir.append(load("res://assets/art/world/fir_%d.png" % i))


func stop_soon() -> void:
	_stopping = true
	target_speed = 0.0


func _process(dt: float) -> void:
	t += dt
	speed = move_toward(speed, target_speed, (24.0 if _stopping else 40.0) * dt)
	cam_x += speed * dt
	if _stopping and speed <= 0.01:
		_stopping = false
		stopped.emit()
	queue_redraw()


func _layer_x(p: float, x: float) -> float:
	return cam_x * (1.0 - p) + x


func _draw() -> void:
	var left := cam_x - 160.0
	# far ridge, slow
	var p := 0.08
	var off := fposmod(cam_x * p, 320.0)
	for k in range(-1, 2):
		draw_texture(_backdrop, Vector2(left - off + k * 320.0, 74))
	# lake glimpses between the trees
	var lake_base := 141.0
	for seg in range(-1, 4):
		var s := floorf((cam_x * 0.3) / 520.0) + seg
		if PixelFont._hash(int(s), 3) > 0.45:
			var lx := s * 520.0 - cam_x * 0.3 + cam_x - 160.0 + 90.0
			draw_rect(Rect2(lx, lake_base, 260, 6), Color8(56, 80, 110))
			draw_rect(Rect2(lx + 20, lake_base + 1, 60, 1), Color8(150, 180, 210, 160))
	# mid treeline (parallax 0.45)
	_trees(0.45, 18.0, 4, 6, 146.0, 0.72, 11)
	# near trees (1.0), sparse, with gaps for the view
	_trees(1.0, 34.0, 0, 3, 148.0, 0.95, 23)
	# snow bank and road
	draw_rect(Rect2(left, 146, 320, 5), Color8(222, 230, 238))
	draw_rect(Rect2(left, 151, 320, 17), Color8(58, 62, 72))
	draw_rect(Rect2(left, 151, 320, 1), Color8(110, 116, 126))
	draw_rect(Rect2(left, 167, 320, 1), Color8(36, 40, 48))
	var dash := fposmod(cam_x, 40.0)
	for k in range(-1, 10):
		draw_rect(Rect2(left - dash + k * 40.0, 159, 18, 1), Color8(220, 200, 120))
	draw_rect(Rect2(left, 168, 320, 12), Color8(200, 210, 222))
	for y in range(170, 180, 3):
		draw_rect(Rect2(left, y, 320, 1), Color8(170, 182, 198))
	# guard rail
	var post := fposmod(cam_x, 46.0)
	draw_rect(Rect2(left, 166, 320, 2), Color8(150, 156, 166))
	for k in range(-1, 9):
		draw_rect(Rect2(left - post + k * 46.0, 166, 2, 7), Color8(90, 94, 104))
	# the truck, pinned to the centre, with a little road bounce
	var bounce := 1.0 if (int(t * 7.0) % 5 == 0 and speed > 5.0) else 0.0
	draw_texture(_truck, Vector2(roundf(cam_x - 35.0), 134.0 - bounce))
	# exhaust
	if speed > 1.0:
		for i in 4:
			var k := fposmod(t * 2.0 + i * 0.25, 1.0)
			draw_rect(Rect2(roundf(cam_x - 36.0 - k * 14.0), 156.0 - k * 4.0, 2 + k * 3.0, 2), Color(0.8, 0.82, 0.88, 0.35 * (1.0 - k)))


func _trees(p: float, spacing: float, v0: int, v1: int, base: float, shade: float, salt: int) -> void:
	var lx := cam_x * p
	var first := floorf((lx - 200.0) / spacing)
	for k in range(int(first), int(first) + int(560.0 / spacing) + 2):
		var h := PixelFont._hash(k, salt)
		if p >= 1.0 and h < 0.35:
			continue
		var v := v0 + int(PixelFont._hash(k, salt + 1) * float(v1 - v0 + 1))
		v = clampi(v, 0, 6)
		var tex: Texture2D = _fir[v]
		var wx := k * spacing + PixelFont._hash(k, salt + 2) * spacing * 0.6
		var sx := wx - lx + cam_x - tex.get_width() * 0.5
		draw_texture(tex, Vector2(roundf(sx), base - tex.get_height() + 1), Color(shade, shade, shade * 1.04))
