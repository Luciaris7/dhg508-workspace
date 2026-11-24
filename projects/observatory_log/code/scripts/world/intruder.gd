class_name Intruder
extends Node2D
## Day 5, the shed in the dark: the door opens and something red comes in
## while the observer is cranking the generator. Drawn unlit (no material),
## so it is the one thing you can see clearly.

var t := 0.0
var walk := 0.0


func _process(dt: float) -> void:
	t += dt
	queue_redraw()


func _draw() -> void:
	var bob := absf(sin(walk * 3.2)) * 1.0
	var jit := Vector2(round(sin(t * 37.0) * 0.6), 0) if fmod(t, 1.7) < 0.12 else Vector2.ZERO
	var o := jit + Vector2(0, -bob)
	var dark := Color8(70, 6, 14)
	var mid := Color8(150, 18, 30)
	var lit := Color8(200, 46, 54)
	# a faint red haze around it
	for i in 4:
		var r := 16.0 + i * 5.0
		draw_rect(Rect2(o.x - r * 0.5, o.y - 40 - i * 2, r, 44 + i * 3), Color(0.6, 0.05, 0.08, 0.05))
	# legs, long and thin
	var step := sin(walk * 3.2) * 2.0
	draw_rect(Rect2(o.x - 3 + step, o.y - 14, 2, 14), dark)
	draw_rect(Rect2(o.x + 1 - step, o.y - 14, 2, 14), mid)
	# body, too narrow, too tall
	draw_rect(Rect2(o.x - 4, o.y - 30, 8, 17), mid)
	draw_rect(Rect2(o.x - 4, o.y - 30, 2, 17), dark)
	draw_rect(Rect2(o.x + 2, o.y - 29, 1, 15), lit)
	# arms hanging past the knees, reaching a little forward (toward -x)
	draw_rect(Rect2(o.x - 6, o.y - 28, 2, 20), dark)
	draw_rect(Rect2(o.x - 7, o.y - 9, 2, 3), mid)
	draw_rect(Rect2(o.x + 4, o.y - 28, 2, 18), mid)
	# head: no face
	draw_rect(Rect2(o.x - 3, o.y - 37, 6, 7), mid)
	draw_rect(Rect2(o.x - 3, o.y - 37, 2, 7), dark)
	draw_rect(Rect2(o.x + 1, o.y - 36, 1, 4), lit)
	# veins
	draw_rect(Rect2(o.x - 1, o.y - 26, 1, 9), dark)
	draw_rect(Rect2(o.x, o.y - 20, 2, 1), dark)
