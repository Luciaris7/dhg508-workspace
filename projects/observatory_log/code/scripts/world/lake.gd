class_name Lake
extends Node2D
## The frozen lake at the east end of the site. The ice itself is a sprite
## (tools/art_world.py: lake_ice); this node draws the one patch of open
## water -- the hole beside the jetty where the observer draws water -- and
## the slow wind-blown snow skating across the ice.

const HOLE := Vector2(1004, 152)
var red := 0.0
var frozen := false
var broken := false
var storm := false
var t := 0.0


func _ready() -> void:
	material = G.flesh_mat


func _process(dt: float) -> void:
	t += dt
	queue_redraw()


func _draw() -> void:
	# open water in the hole (under the rim sprite, which is drawn above)
	if not frozen or broken:
		var deep := Color8(14, 22, 34).lerp(Color8(58, 8, 14), red)
		var mid := Color8(30, 46, 66).lerp(Color8(110, 18, 28), red)
		for y in range(-3, 4):
			var w := 10.5 * sqrt(maxf(0.0, 1.0 - (y * y) / 11.0))
			draw_rect(Rect2(floorf(HOLE.x - w), HOLE.y + y, ceilf(w * 2.0), 1), deep if y < 0 else mid)
		var ph := t * (2.4 if storm else 1.0)
		for i in 3:
			var k := fposmod(ph * 0.35 + i / 3.0, 1.0)
			var rw := 2.0 + k * 7.0
			draw_rect(Rect2(floorf(HOLE.x - rw), HOLE.y + 1 - floorf(k * 2.0), ceilf(rw * 2.0), 1), Color(0.75, 0.82, 0.9, 0.35 * (1.0 - k)).lerp(Color(0.9, 0.4, 0.4, 0.35 * (1.0 - k)), red))
	# loose snow skating over the ice in the wind
	var n := 26 if storm else 14
	for i in n:
		var sp := 14.0 + (i % 5) * 6.0
		var x := 960.0 + fposmod(i * 97.0 + t * sp * (2.0 if storm else 1.0), 700.0)
		var y := 140.0 + (i * 13) % 38
		draw_rect(Rect2(floorf(x), y, 2 + (i % 3), 1), Color(0.95, 0.97, 1.0, 0.35))
