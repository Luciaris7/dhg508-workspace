extends Node
## Day 5, the shed: crank too slowly and the red figure reaches you ->
## the assimilation ending at once (the only way there) -> the title offers
## Day 5 again -> it works.
##   godot --headless --path . res://tests/day5_test.tscn

var main: Node
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


func _ready() -> void:
	G.erase_save()
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	Engine.time_scale = 1.0 if OS.get_cmdline_user_args().has("real") else 8.0
	var flow: Flow = main.flow
	main.menu.close()
	G.new_game()
	G.persist["clues"] = {"rumor": 1, "not_weather": 1}
	await flow.start_day(5)
	ok(G.has_save() and G.day == 5, "day 5 saved")
	main.world.goto("outdoor", 700.0, 1)
	ok(main.world.weather.mode == "blizzard", "day 5 uses blizzard weather")
	# the storm took the power; into the shed
	flow.step = Flow.S.OUTAGE
	main.world.set_power(false)
	main.world.set_generator(false)
	await flow._travel("shed", 232.0, 1)
	flow.interact("generator")
	ok(flow._hold == "crank", "cranking in the dark")
	ok(await until(func(): return main.world.nodes.has("intruder"), 10.0), "the door opens; something comes in")
	# ... and he does nothing
	ok(await until(func(): return main.mode != "world", 30.0), "it reaches him")
	ok(await until(func(): return main.mode == "ending" and main.ending.kind == "assimilate", 60.0), "taken in: the assimilation ending")
	ok(await until(func(): return main.overlay.fade < 0.05, 10.0), "and it can be seen (not a black screen)")
	if OS.get_cmdline_user_args().has("real"):
		for at in [10.0, 30.0]:
			await until(func(): return main.ending.t >= at, 60.0)
			get_viewport().get_texture().get_image().save_png("res://tests/_shots/d5_caught_%d.png" % int(at))
	ok(await until(func(): return main.overlay.red_center == Txt.red("end_cycle"), 120.0), "observer received")
	ok(await until(func(): return main.overlay.cg != null, 120.0), "the closing illustration")
	ok(main.overlay.cg.resource_path.ends_with("cg_assimilate.png"), "the assimilation illustration")
	ok(await until(func(): return main.overlay.subtitle == Txt.phone()[0], 60.0), "a voicemail for the next one")
	ok(G.persist.get("last_ending", "") == "assimilate", "recorded as assimilation")
	ok(await until(func(): return main.menu.page == "title", 120.0), "back at the title")
	ok(G.has_save(), "Day 5's save is kept")
	ok(main.menu.items[0][1] == Txt.ui("menu.retry") % 5, "the title offers: start again from Day 5")
	main.menu.close()
	main.flow.continue_game()
	ok(await until(func(): return G.day == 5 and main.mode == "world" and not flow.busy, 60.0), "Day 5 again")
	ok(G.clue_count() == 2, "with what was found before")
	ok(int(G.persist.get("retry_day", 0)) == 0, "the retry offer is cleared")
	Engine.time_scale = 1.0
	G.erase_save()
	print("DAY5 %s" % ("PASS" if fails == 0 else "FAIL"))
	get_tree().quit(0 if fails == 0 else 1)
