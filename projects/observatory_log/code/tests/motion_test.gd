extends Node
## Regression: the forced march must arrive even when one frame travels
## farther than the old one-pixel arrival tolerance.

var checks := 0
var fails := 0


func _ready() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	var world: World = main.world
	world.set_process(false)
	world.can_move = false
	world.auto_speed = 30.0
	for dt in [1.0 / 60.0, 1.0 / 30.0, 1.0 / 15.0, 8.0 / 60.0, 0.5, 2.0]:
		for leg in [["cab", 90.0, 170.0], ["shed", 60.0, 165.0],
			["outdoor", 340.0, 984.0], ["outdoor", 984.0, 340.0]]:
			world.goto(leg[0], leg[1])
			var start: float = leg[1]
			var target: float = leg[2]
			world.auto_target = target
			var frames := int(ceil(absf(target - start) / (30.0 * dt))) + 2
			var inside := true
			for i in frames:
				world._move(dt)
				inside = inside and world.player.position.x >= minf(start, target) and world.player.position.x <= maxf(start, target)
				if world.auto_target == INF:
					break
			check(inside and world.auto_target == INF and is_equal_approx(world.player.position.x, target),
				"%s %.0f -> %.0f, dt=%.4f" % [leg[0], start, target, dt])
	print("MOTION %s | %d checks, %d fails" % ["PASS" if fails == 0 else "FAIL", checks, fails])
	get_tree().quit(0 if fails == 0 else 1)


func check(passed: bool, label: String) -> void:
	checks += 1
	if not passed:
		fails += 1
		print("FAIL ", label)
