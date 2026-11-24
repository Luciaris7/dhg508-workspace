extends Node
## Developer shortcut: F1..F7 start that day immediately (main.gd debug_jump).
##   godot --path . res://tests/cheat_test.tscn
##
## What this guards: the keys exist, they bypass the earlier days, they reset the
## run instead of inheriting a half-played save, and day 7 still starts at night.

var main: Node
var fails := 0


func ok(c: bool, what: String) -> void:
	print(("ok    " if c else "FAIL  ") + what)
	if not c:
		fails += 1


func _f(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func press(code: int) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = true
	Input.parse_input_event(e)
	await _f(2)


func wait_world(day: int) -> bool:
	var t := 0.0
	while (main.mode != "world" or G.day != day or main.flow.busy) and t < 25.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	return main.mode == "world" and G.day == day and not main.flow.busy


func _ready() -> void:
	Engine.time_scale = 6.0
	G.erase_save()
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _f(5)
	ok(main.menu.page == "warn", "boot: content warning first")
	await _f(20)                 # the warning page ignores input for a moment
	await press(KEY_E)
	await _f(10)
	ok(main.menu.page == "title", "warning -> title")
	ok(not G.has_save(), "no save before the first jump")

	# F5 from the title: day 5 straight away, on a fresh run
	await press(KEY_F5)
	ok(await wait_world(5), "F5 starts day 5 without playing days 1-4")
	ok(G.persist["answers"] is Array and (G.persist["answers"] as Array).is_empty(), "the jump resets the run")
	ok(G.has_save(), "the jump leaves a save behind")

	# F7: endgame parameters
	await press(KEY_F7)
	ok(await wait_world(7), "F7 starts day 7")
	ok(G.tod == "night", "day 7 starts at night")

	# F1: back to the beginning
	await press(KEY_F1)
	ok(await wait_world(1), "F1 starts day 1")
	ok(G.tod == "day", "day 1 starts in daylight")

	# the keys must not fire while the menu is open... they do by design, but a
	# jump must close the menu instead of leaving it on screen over the world
	main.menu.open_pause()
	await _f(2)
	await press(KEY_F3)
	ok(await wait_world(3), "F3 from the pause menu starts day 3")
	ok(not main.menu.is_open(), "the jump closes the menu")

	print("CHEAT " + ("PASS" if fails == 0 else "FAIL"))
	get_tree().quit(0 if fails == 0 else 1)
