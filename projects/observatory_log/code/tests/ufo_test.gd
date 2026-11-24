extends Node
## The bed before the day's work is done: it asks (E sleep / Esc back). Four
## days slept through like that by the sixth night: the UFO ending, two
## illustrations, and the game is over. Three: Day 7 as usual.
##   godot --headless --path . res://tests/ufo_test.tscn

var main: Node
var flow: Flow
var fails := 0


func ok(c: bool, what: String) -> void:
	print(("ok    " if c else "FAIL  ") + what)
	if not c:
		fails += 1


func until(cond: Callable, timeout: float) -> bool:
	var t := 0.0
	while not cond.call():
		await get_tree().process_frame
		t += get_process_delta_time()
		if t > timeout:
			return false
	return true


## Game seconds until cond holds.
func timed(cond: Callable) -> float:
	var t := 0.0
	while not cond.call() and t < 30.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	return t


func key(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	flow.world_input(ev)
	await get_tree().process_frame


func to_bed(day: int, skipped: int) -> void:
	G.new_game()
	G.persist["skipped_days"] = skipped
	await flow.start_day(day)
	await until(func(): return main.mode == "world" and not flow.busy, 60.0)
	await flow._travel("cab", 275.0, 1)
	await until(func(): return not flow.busy, 10.0)
	flow.interact("bed")
	await get_tree().process_frame


func _ready() -> void:
	G.erase_save()
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	Engine.time_scale = 8.0
	flow = main.flow
	main.menu.close()

	# Day 2, nothing done: it asks; Esc goes back
	await to_bed(2, 0)
	ok(flow._bed_ask and main.overlay.cur.get("id", "") == "bed_unfinished", "unfinished: the bed asks")
	ok(main.overlay.mono_hint == Txt.ui("bed.ask") and not main.world.can_move, "E / Esc shown; he stands still")
	await get_tree().create_timer(3.0).timeout
	ok(main.overlay.cur.get("id", "") == "bed_unfinished", "the question stays up")
	ok(not main.overlay.show_prompt, "no E marker on the bed while it asks")
	ok(flow.wants_esc(), "Esc belongs to the question, not the pause menu")
	await key("pause")
	ok(not flow._bed_ask and main.overlay.cur.is_empty() and main.world.can_move and G.day == 2, "Esc: back to the day")
	# ask again, E: sleeps, counted
	flow.interact("bed")
	await get_tree().process_frame
	await key("interact")
	ok(await until(func(): return G.day == 3 and main.mode == "world", 60.0), "E: asleep, Day 3")
	ok(int(G.persist.get("skipped_days", 0)) == 1, "the day is counted")

	# three by the sixth night: Day 7 as usual
	await to_bed(6, 2)
	await key("interact")
	ok(await until(func(): return G.day == 7, 60.0), "three days slept through: Day 7")

	# four: the UFO ending
	await to_bed(6, 3)
	await key("interact")
	ok(await until(func(): return main.overlay.title_text == Txt.red("title"), 60.0), "four days: the game ends (title)")
	ok(await until(func(): return main.overlay.credits.size() > 0, 60.0), "credits")
	ok(await until(func(): return main.overlay.cg != null and main.overlay.cg.resource_path.ends_with("cg_ufo_1.png"), 120.0), "the first illustration: the roof, the beam")
	var t1 := await timed(func(): return main.overlay.cg != null and main.overlay.cg.resource_path.ends_with("cg_ufo_2.png"))
	ok(absf(t1 - 5.0) < 0.3, "then the saucer past the red body, after 5 s (%.2f)" % t1)
	var t2 := await timed(func(): return main.overlay.cg == null)
	ok(absf(t2 - 3.0) < 0.3, "the second one for 3 s, and it ends (%.2f)" % t2)
	ok(await until(func(): return main.menu.page == "title", 30.0), "back at the title")
	ok(G.persist.get("last_ending", "") == "ufo" and not G.has_save(), "recorded; the run is over")
	Engine.time_scale = 1.0
	G.erase_save()
	print("UFO %s" % ("PASS" if fails == 0 else "FAIL"))
	get_tree().quit(0 if fails == 0 else 1)
