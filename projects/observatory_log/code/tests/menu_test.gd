extends Node
## Save / continue / pause / restart-day round trip.
##   godot --path . res://tests/menu_test.tscn

var main: Node
var fails := 0


func ok(c: bool, what: String) -> void:
	print(("ok    " if c else "FAIL  ") + what)
	if not c:
		fails += 1


func _f(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func key(code: int) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = true
	Input.parse_input_event(e)
	await _f(2)
	var r := InputEventKey.new()
	r.keycode = code
	r.physical_keycode = code
	r.pressed = false
	Input.parse_input_event(r)
	await _f(2)


func _ready() -> void:
	Engine.time_scale = 6.0
	G.erase_save()
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _f(5)
	ok(main.menu.page == "warn", "boot: content warning first")
	await _f(10)
	await key(KEY_E)
	ok(main.menu.page == "title", "warning -> title")
	ok(main.menu.items[0][0] == "new", "no save: New Game is first")
	# jump straight into day 3 and leave a save behind
	main.menu.close()
	G.new_game()
	await main.flow.start_day(3)
	ok(G.has_save() and G.day == 3, "day 3 saved")
	await key(KEY_ESCAPE)
	ok(main.menu.page == "pause" and get_tree().paused, "Esc opens pause and pauses")
	await key(KEY_ESCAPE)
	ok(main.menu.page == "" and not get_tree().paused, "Esc closes pause")
	await key(KEY_ESCAPE)
	main.menu.sel = 1   # restart day
	await key(KEY_E)
	await _f(30)
	var t := 0.0
	while (main.mode != "world" or G.day != 3 or main.flow.busy) and t < 20.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	ok(main.mode == "world" and G.day == 3 and not main.flow.busy, "restart day -> day 3 again")
	main.flow.to_title()
	await _f(5)
	ok(main.menu.page == "title" and main.menu.items[0][0] == "continue", "title offers Continue")
	await key(KEY_E)
	t = 0.0
	while (main.mode != "world" or main.flow.busy) and t < 20.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	ok(G.day == 3 and main.mode == "world" and not main.flow.busy, "continue -> day 3")
	G.erase_save()
	print("MENU %s" % ("PASS" if fails == 0 else "FAIL"))
	get_tree().quit(0 if fails == 0 else 1)
