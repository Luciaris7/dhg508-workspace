class_name Weather
extends Node2D
## Snow, blizzard, or rain, drawn around the camera in world space so it moves 1:1 with
## everything else when the player walks.

var mode := "snow"      # "", "snow", "blizzard", "rain"
var cam_x := 0.0
var t := 0.0
var _p: Array = []
var breath: Array = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for i in 140:
		_p.append([rng.randf_range(0, 360), rng.randf_range(0, 190), rng.randf_range(0.5, 1.0), rng.randf()])


func puff(at: Vector2, dir: int) -> void:
	breath.append([at, 0.0, dir])


func _process(dt: float) -> void:
	t += dt
	for b in breath:
		b[1] += dt
	breath = breath.filter(func(b): return b[1] < 1.4)
	queue_redraw()


func _draw() -> void:
	var left := cam_x - 180.0
	if mode == "snow" or mode == "blizzard":
		var blizzard := mode == "blizzard"
		for p in _p:
			var sp: float = p[2]
			var y_speed := 16.0 + sp * 22.0 if blizzard else 10.0 + sp * 14.0
			var x_speed := 15.0 + sp * 18.0 if blizzard else 4.0 * sp
			var y := fposmod(float(p[1]) + t * y_speed, 190.0) - 6.0
			var x := fposmod(float(p[0]) + sin(t * 0.8 + float(p[3]) * 6.0) * (10.0 if blizzard else 6.0) - t * x_speed - left, 360.0) + left - 20.0
			var a := 0.38 + sp * 0.5
			if blizzard:
				draw_line(Vector2(floorf(x), floorf(y)), Vector2(floorf(x) - 2.0, floorf(y) + 2.0), Color(0.95, 0.97, 1.0, a), 1.0)
			else:
				draw_rect(Rect2(floorf(x), floorf(y), 1, 1), Color(0.95, 0.97, 1.0, a))
				if sp > 0.9:
					draw_rect(Rect2(floorf(x) + 1, floorf(y), 1, 1), Color(0.95, 0.97, 1.0, a * 0.6))
	elif mode == "rain":
		for p in _p:
			var sp: float = p[2]
			var y := fposmod(float(p[1]) + t * (190.0 + sp * 120.0), 200.0) - 10.0
			var x := fposmod(float(p[0]) - t * 40.0 - left - y * 0.25, 360.0) + left - 20.0
			draw_line(Vector2(floorf(x), floorf(y)), Vector2(floorf(x) - 2, floorf(y) + 6), Color(0.65, 0.72, 0.85, 0.35 + sp * 0.3), 1.0)
	for b in breath:
		var k: float = b[1] / 1.4
		var pos: Vector2 = b[0] + Vector2(float(b[2]) * (3.0 + k * 8.0), -k * 6.0)
		var a := (1.0 - k) * 0.35
		var r := 1.0 + k * 3.0
		draw_rect(Rect2(floorf(pos.x - r * 0.5), floorf(pos.y - r * 0.5), ceilf(r), ceilf(r * 0.7)), Color(0.9, 0.93, 1.0, a))
