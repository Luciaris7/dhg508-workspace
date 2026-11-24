class_name GroundMarks
extends Node2D
## Small things on the ground outdoors: the two survey stakes on the shore
## and, on Days 2-4, a line of bare footprints coming up from the lake.

## The survey stakes now stand at the boathouse; here only the trail marker.
const STAKES := []
const PRINTS_FROM := 962.0

## Telephone wires: pole tops (art_props.pole at x 196/430/640), the tower cab,
## the shed roof, the mast. [from, to, sag]
const WIRES := [[Vector2(196, 48), Vector2(332, 50), 7.0], [Vector2(332, 50), Vector2(430, 48), 6.0],
	[Vector2(430, 48), Vector2(510, 108), 4.0], [Vector2(570, 108), Vector2(640, 48), 4.0],
	[Vector2(640, 48), Vector2(765, 128), 5.0]]

var prints_to := 0.0      # 0: no footprints today
var logged := {}          # stake id -> true once today's reading is logged
var ravens := 0           # more every night; none in the storm
var t := 0.0
var _raven: Array = []


func _ready() -> void:
	_raven = [load("res://assets/art/props/raven_0.png"), load("res://assets/art/props/raven_1.png")]


func _process(dt: float) -> void:
	t += dt
	queue_redraw()


static func wire_point(w: Array, k: float) -> Vector2:
	var a: Vector2 = w[0]
	var b: Vector2 = w[1]
	return a.lerp(b, k) + Vector2(0, float(w[2]) * 4.0 * k * (1.0 - k))


func _draw() -> void:
	var g := float(World.GROUND)
	for w in WIRES:
		for side in [0.0, 3.0]:
			var prev: Vector2 = wire_point(w, 0.0) + Vector2(0, side)
			for i in range(1, 25):
				var p := wire_point(w, i / 24.0) + Vector2(0, side)
				draw_line(prev, p, Color8(26, 28, 36), 1.0)
				prev = p
	# ravens on the wires: they all face the lake
	for i in ravens:
		var w: Array = WIRES[i % WIRES.size()]
		var k := 0.18 + 0.64 * PixelFont._hash(i, 77)
		var p := wire_point(w, k).round()
		var fr := 1 if int(t * 0.7 + i * 1.3) % 5 == 0 else 0
		if _raven.size() == 2 and _raven[fr]:
			draw_texture(_raven[fr], p - Vector2(4, 6))
	if prints_to > 0.0:
		# Seen from the side, on the trodden band in front of everything: each
		# bare foot a dark hollow with a bright pushed-up rim. Day 4: red.
		var red := 1.0 if G.day >= 4 else 0.0
		var col := Color8(40, 48, 68).lerp(Color8(110, 22, 34), red)
		var rim := Color8(250, 252, 255)
		var x := PRINTS_FROM
		var i := 0
		while x > prints_to:
			var y := g + 8.0 + (0.0 if i % 2 == 0 else 3.0)
			draw_rect(Rect2(floorf(x) - 1, y - 1, 7, 1), rim)
			draw_rect(Rect2(floorf(x), y, 5, 2), col)
			draw_rect(Rect2(floorf(x) - 2, y, 1, 1), col)           # toes
			draw_rect(Rect2(floorf(x) - 2, y - 1, 1, 1), col.lightened(0.15))
			if red > 0.0 and i % 3 == 0:
				draw_rect(Rect2(floorf(x) + 1, y + 2, 2, 1), col.darkened(0.3))
			x -= 9.0
			i += 1
	for k in STAKES.size():
		var sx: float = STAKES[k]
		draw_rect(Rect2(sx, g - 16, 1, 17), Color8(70, 52, 40))
		draw_rect(Rect2(sx + 1, g - 16, 1, 17), Color8(40, 30, 24))
		var id := "stake_a" if k == 0 else "stake_b"
		var flag := Color8(200, 40, 36) if not logged.get(id, false) else Color8(90, 150, 90)
		var wave := 1.0 if int(t * 3.0 + k) % 2 == 0 else 0.0
		draw_rect(Rect2(sx + 2, g - 16, 5, 3 - wave), flag)
