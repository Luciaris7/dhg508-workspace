extends Node
## The Day 5 dream in real time: reefs for DREAM_T seconds whether or not one
## is touched, then the church. Measures both the game clock and the wall clock.
##   godot --path . res://tests/dream_test.tscn      (windowed: real frame times)

var main: Node
var fails := 0


func ok(c: bool, what: String) -> void:
	print(("ok    " if c else "FAIL  ") + what)
	if not c:
		fails += 1


func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.menu.close()
	var mg: MiniGame = main.mg
	for touch in [false, true]:
		mg.start_dream()
		main.set_mode("dream")
		main.show_minigame_layer(true, false)
		mg._begin_run()
		var wall0 := Time.get_ticks_msec()
		var hits := 0
		var game_t := 0.0
		while mg.mode == "run" or mg.mode == "sail":
			await get_tree().process_frame
			game_t += get_process_delta_time()
			if touch:
				# steer into every reef
				for r in mg.rocks:
					if absf(float(r[0]) - MiniGame.BOAT_X) < 40.0:
						mg.lane = int(r[1])
						mg.lane_from = mg.lane
						mg.lane_k = 1.0
			else:
				# dodge: never sit in a lane with a reef close by
				var bad := {}
				for r in mg.rocks:
					if float(r[0]) - MiniGame.BOAT_X < 60.0 and float(r[0]) > MiniGame.BOAT_X - 20.0:
						bad[int(r[1])] = true
				if bad.has(mg.lane):
					for ln in 3:
						if not bad.has(ln):
							mg.lane = ln
							mg.lane_from = ln
							mg.lane_k = 1.0
							break
			hits = maxi(hits, 1 if mg.hit_flash > 0.9 else 0)
		var wall := (Time.get_ticks_msec() - wall0) / 1000.0
		print("DREAM touch=%s  reefs %.1f s  to the church %.1f s (wall %.1f s)  mode=%s" % [touch, mg.run_t, game_t, wall, mg.mode])
		ok(mg.mode == "temple", "reaches the church (touch=%s)" % touch)
		ok(game_t >= 17.0 and game_t <= 24.0, "the church at ~20 s (touch=%s): %.1f s" % [touch, game_t])
		if not touch:
			# hold D: along to the foot of the church, a dim, then at the door
			Input.action_press("right")
			var dimmed := false
			var wt := 0.0
			while mg.fig_k < 1.0 and wt < 10.0:
				await get_tree().process_frame
				wt += get_process_delta_time()
				dimmed = dimmed or mg.climb_t >= 0.0
			Input.action_release("right")
			ok(mg.fig_k >= 1.0 and dimmed and wt < 4.0, "walks to the foot, dims, at the door (%.1f s)" % wt)
			ok(mg.fig.is_equal_approx(mg._path()[2]), "standing at the door")
		mg.stop()
	# HOMEWARD on the desktop: 2000 -> the church; its door does not open; back to the title
	G.day = 3
	mg.start_desktop()
	mg._begin_run()
	mg.score = MiniGame.GOAL - MiniGame.POINTS
	var tt := 0.0
	while mg.mode != "temple" and tt < 120.0:
		await get_tree().process_frame
		tt += get_process_delta_time()
		# keep out of the way of the reefs
		var bad := {}
		for r in mg.rocks:
			if float(r[0]) - MiniGame.BOAT_X < 60.0 and float(r[0]) > MiniGame.BOAT_X - 20.0:
				bad[int(r[1])] = true
		if mg.mode == "over":
			mg._begin_run()
			mg.score = MiniGame.GOAL - MiniGame.POINTS
		elif bad.has(mg.lane):
			for ln in 3:
				if not bad.has(ln):
					mg.lane = ln
					mg.lane_from = ln
					mg.lane_k = 1.0
					break
	ok(mg.mode == "temple" and mg.score >= MiniGame.GOAL, "desktop: %d points -> the church" % MiniGame.GOAL)
	mg.fig_k = 1.0
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	mg.handle(ev)
	var t2 := 0.0
	while mg.mode == "temple" and t2 < 10.0:
		await get_tree().process_frame
		t2 += get_process_delta_time()
	ok(mg.mode == "title" and main.overlay.red_center == "", "the door stays shut: back to the title, nothing said")
	mg.stop()
	print("DREAM %s" % ("PASS" if fails == 0 else "FAIL"))
	get_tree().quit(0 if fails == 0 else 1)
