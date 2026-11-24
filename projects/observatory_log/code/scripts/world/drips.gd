class_name Drips
extends Node2D
## Day 5 on: something dark drips from the ceiling above the bed.

var active := false
var t := 0.0
const XS := [258.0, 271.0, 289.0]


func _process(dt: float) -> void:
	t += dt
	visible = active
	if active:
		queue_redraw()


func _draw() -> void:
	for i in XS.size():
		var x: float = XS[i]
		var period := 2.2 + i * 0.7
		var k := fposmod(t + i * 0.9, period) / period
		draw_rect(Rect2(x, 27, 1, 2), Color8(106, 20, 32))
		if k < 0.55:
			var grow := k / 0.55
			draw_rect(Rect2(x - 1, 28, 3, 1 + int(grow * 2.0)), Color8(168, 42, 51))
		else:
			var f := (k - 0.55) / 0.45
			var y := 30.0 + f * f * 110.0
			if y < 140.0:
				draw_rect(Rect2(x, floorf(y), 1, 3), Color8(168, 42, 51))
		draw_rect(Rect2(x - 3, 150, 7, 1), Color8(70, 14, 22, 200))
