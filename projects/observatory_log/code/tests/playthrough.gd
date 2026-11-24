extends Node
## End-to-end script test: plays the whole game the way a player would --
## walking to each object, pressing E, using the desktop programs -- and
## asserts the script beats after each step. Runs time-accelerated.
##   godot --path . --resolution 1280x720 res://tests/playthrough.tscn
## Optional user args: answers=ynynyyy (Day 1..7 report answers), shots=1,
## route=bad|normal|good (docs/MYSTERY_BIBLE.md §6):
##   bad     few clues; the seventh report; walked to the shore (sacrifice)
##   normal  six clues, no number; finds the plug and fixes the truck anyway --
##           the road comes back round to the site (sacrifice)
##   good    all clues and the number; the plug, the leads, the road out (escape)
## (assimilation -- caught in the shed on Day 5 -- is tests/day5_test.gd)

var main: Node
var flow: Flow
var world: World
var desk: Desktop
var fails := 0
var checks := 0
var answers := "ynnnyyy"
var route := "bad"
var take_shots := false
var _log: Array = []


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("answers="):
			answers = a.substr(8)
		if a.begins_with("lang="):
			G.set_lang(a.substr(5))
		if a.begins_with("route="):
			route = a.substr(6)
		if a == "shots=1":
			take_shots = true
	G.settings["assist"] = 2 if route == "good" else 0
	G.erase_save()
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	flow = main.flow
	world = main.world
	desk = main.desktop
	await _f(5)
	Engine.time_scale = 8.0
	await _run()
	Engine.time_scale = 1.0
	print("PLAYTHROUGH %s | route %s | %d checks, %d fails" % ["PASS" if fails == 0 else "FAIL", route, checks, fails])
	get_tree().quit(0 if fails == 0 else 1)


func ok(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		fails += 1
		print("FAIL  Day %d: %s" % [G.day, what])
	else:
		print("ok    Day %d: %s" % [G.day, what])


func _f(n: int = 1) -> void:
	for i in n:
		await get_tree().process_frame


func until(cond: Callable, timeout: float = 30.0) -> bool:
	var t := 0.0
	while not cond.call():
		await get_tree().process_frame
		t += get_process_delta_time()
		if t > timeout:
			return false
	return true


func shot(name: String) -> void:
	if not take_shots:
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://tests/_shots/pt_%s.png" % name))


# ------------------------------------------------------------ player verbs
func walk_to(x: float) -> void:
	await until(func(): return main.mode == "world" and not flow.busy, 30.0)
	world.player.position.x = x
	await _f(3)


func press(id: String) -> void:
	await until(func(): return main.mode == "world" and not flow.busy, 30.0)
	world.player.position.x = world.interact_x(id)
	await _f(3)
	if world.focus.get("id", "") != id:
		ok(false, "focus on '%s' (got '%s')" % [id, world.focus.get("id", "")])
		return
	flow.interact(id)
	await _f(4)


func go(loc: String) -> void:
	# travel between locations through the doors and up / down the trail
	if world.loc == loc:
		return
	if world.loc == "cab":
		await press("cab_door")
	elif world.loc == "shed":
		await press("shed_exit")
	elif world.loc == "peak":
		await press("trail_down")
	elif world.loc == "boathouse":
		await press("shore_back")
	await until(func(): return world.loc == "outdoor" and not flow.busy and main.mode == "world", 60.0)
	if loc == "cab":
		await press("tower_door")
	elif loc == "shed":
		await press("shed_door")
	elif loc == "peak":
		await press("trail_up")
	elif loc == "boathouse":
		await press("shore_path")
	await until(func(): return world.loc == loc and not flow.busy and main.mode == "world", 60.0)


func hold_until_done() -> void:
	Input.action_press("interact")
	await until(func(): return flow._hold == "", 20.0)
	Input.action_release("interact")
	await _f(2)


func mash_until_done() -> void:
	var n := 0
	while flow._hold != "" and n < 200:
		flow._mash()
		n += 1
		await _f(2)
	await _f(2)


func open_pc() -> void:
	await go("cab")
	await press("computer")
	await until(func(): return main.mode == "desktop", 10.0)
	await until(func(): return desk.boot_t < 0.0, 10.0)


func app(id: String) -> DeskApp:
	for w in desk.wins:
		if w["id"] == id:
			return w["app"]
	return null


func leave_pc() -> void:
	desk.request_exit()
	await until(func(): return main.mode == "world", 10.0)
	await until(func(): return not flow.busy, 10.0)


# ------------------------------------------------------------------- run
func _run() -> void:
	main.menu.close()
	flow.new_game()
	ok(await until(func(): return main.mode == "cutscene" and world.loc == "road", 10.0), "prologue: on the road")
	await until(func(): return main.overlay.subtitle != "", 30.0)
	ok(main.overlay.subtitle == Txt.phone()[0], "voicemail line 1 plays")
	await shot("prologue")
	ok(await until(func(): return main.overlay.subtitle == Txt.phone()[2], 120.0), "voicemail: the rumour of the red lights")
	ok(await until(func(): return main.mode == "world" and G.day == 1, 120.0), "prologue ends in Day 1")
	for d in range(1, 8):
		await _day(d)
		if fails > 12:
			return
	var want: String = {"bad": "sacrifice", "normal": "sacrifice", "good": "epilogue"}[route]
	if route == "normal":
		ok(await until(func(): return main.mode == "cutscene" and world.loc == "road", 60.0), "the truck goes")
		ok(await until(func(): return world.loc == "outdoor" and main.overlay.red_bottom == Txt.red("d7_move"), 90.0), "the road comes back to the site")
		await shot("loop_back")
	if route == "good":
		ok(await until(func(): return main.mode == "cutscene" and world.loc == "road", 60.0), "escape: driving away")
		await until(func(): return world.phase < 1.5, 30.0)
		ok(world.sky.aurora < 0.9, "the red lights fade behind the truck")
		await shot("escape_road")
	else:
		ok(await until(func(): return main.mode == "ending", 180.0), "ending starts")
		ok(main.ending.kind == want, "ending is '%s' (got '%s')" % [want, main.ending.kind])
		await until(func(): return main.ending.t > 26.0, 60.0)
		await shot("ending_" + route)
	ok(await until(func(): return main.overlay.title_text == Txt.red("title"), 180.0), "the title")
	ok(await until(func(): return main.overlay.credits.size() > 1 and main.overlay.credits[1] == "GLM 5.3 Flash", 60.0), "credits: AI members")
	ok(main.overlay.credits.has("Claude Opus 5.5") and main.overlay.credits.has("ChatGPT 6.1 Sol") and main.overlay.credits.has("DeepSeek V4.1 Flash"), "credits: all four AI members")
	match route:
		"good":
			ok(await until(func(): return main.mode == "ending" and main.ending.kind == "epilogue", 60.0), "thirteen years later")
			ok(main.overlay.caption == Txt.red("later"), "caption: thirteen years later")
			await until(func(): return main.ending.t > 16.0, 30.0)
			await shot("epilogue")
			ok(main.ending.hiker(0)[1] == false, "the hikers stop at the site")
	var cg_name: String = "escape" if route == "good" else want
	ok(await until(func(): return main.overlay.cg != null and main.overlay.cg_a > 0.5, 90.0), "the closing illustration")
	ok(main.overlay.cg != null and main.overlay.cg.resource_path.ends_with("cg_%s.png" % cg_name), "it is the %s illustration" % cg_name)
	await shot("cg_" + cg_name)
	ok(await until(func(): return main.menu.page == "title", 240.0), "back at the title")
	ok(bool(G.persist.get("finished", false)), "finished flag saved")
	ok(String(G.persist.get("last_ending", "")) == ("escape" if route == "good" else want), "ending recorded")
	ok(not G.has_save(), "run save cleared after the ending")


func _day(d: int) -> void:
	await until(func(): return G.day == d and main.mode == "world" and not flow.busy, 60.0)
	ok(G.day == d, "day %d started" % d)
	ok(world.loc == ("outdoor" if d == 1 else "cab"), "wakes in the right place")
	ok(G.has_save(), "autosaved at day start")
	var ans := "yes" if answers.substr(d - 1, 1) == "y" else "no"
	if d == 7:
		ans = "no"
	await shot("d%d_start" % d)
	if d == 1:
		# out of order: the generator before the notice
		await go("shed")
		await press("generator")
		ok(flow.step == Flow.S.NOTICE, "generator refused before the notice")
		await open_pc()
		ok(not desk.icons.any(func(i): return i["id"] == "game"), "Day 1 desktop has no game icon")
		desk.launch("notice")
		ok(app("notice") != null, "notice.txt opens")
		desk.close_app(app("notice"))
		ok(flow.step == Flow.S.FUEL, "reading the notice unlocks flow 1")
		ok(desk.icons.any(func(i): return i["id"] == "notes") and desk.icons.any(func(i): return i["id"] == "archive"), "notes and archive on the desktop")
		await leave_pc()
	if d == 2:
		await open_pc()
		ok(desk.icons.any(func(i): return i["id"] == "game"), "Day 2: the game icon is simply there")
		await leave_pc()
	await _world_clues(d)
	if d < 7:
		await _flow1(d)
		await _flow2(d)
	else:
		ok(G.tod == "night" and world.phase >= 1.99, "Day 7 starts at night")
		ok(G.can_escape() == (route == "good"), "Day 7: the road out holds only on the good route (%d clues)" % G.clue_count())
		if route != "bad":
			await _day7_escape()
			return
	await _antenna(d)
	if d == 5:
		await until(func(): return not world.power, 10.0)
		ok(flow.step == Flow.S.OUTAGE and not world.power, "Day 5: the blizzard kills the power")
		ok(not flow.radio_active(), "the radio is silent before the power is back")
		await go("shed")
		await press("generator")
		ok(await until(func(): return world.nodes.has("intruder"), 10.0), "Day 5: the shed door opens while cranking")
		await shot("d5_intruder")
		await mash_until_done()
		ok(world.power and flow.step == Flow.S.CHART, "Day 5: cranked back to life")
		ok(flow.radio_active(), "Day 5: the radio starts sending")
		ok(G.f.get("cranked", false) and not world.nodes.has("intruder"), "power back: whatever came in is gone")
		if route == "good":
			await _radio()
	await _chart(d)
	await _report(d, ans)
	if d == 7:
		await _day7()
		return
	await _after_report(d, ans)
	await go("cab")
	await press("bed")
	if d == 5:
		ok(await until(func(): return main.mode == "dream", 90.0), "Day 5 sleep -> the dream")
		await _dream()


func _flow1(d: int) -> void:
	await go("shed")
	await press("generator")
	ok(flow._hold == "", "no diesel can in hand: refused")
	await press("can")
	ok(G.f.get("has_can", false), "picked up the diesel")
	await press("generator")
	ok(flow._hold == "pour", "pouring")
	await hold_until_done()
	ok(G.f.get("fueled", false), "tank full")
	await press("generator")
	ok(flow._hold == "pull", "pull the starter cord")
	await mash_until_done()
	ok(world.gen_running, "generator running")
	await until(func(): return flow.step == Flow.S.SURVEY, 10.0)
	ok(G.tod == "dusk", "flow 1 -> dusk")


func _flow2(d: int) -> void:
	await go("outdoor")
	await press("trail_up")
	ok(flow.step == Flow.S.SURVEY and world.loc == "outdoor", "the trail is refused before the survey")
	if d == 1:
		await press("hole")
		ok(main.overlay.panel != "sonar", "no echo sounder yet: refused")
		await go("shed")
		await press("receiver")
		ok(G.persist.get("has_receiver", false), "took the echo sounder")
	for id in ["stake_boat", "hole"]:
		await go("boathouse" if id == "stake_boat" else "outdoor")
		await press(id)
		if id == "hole" and d == 2:
			ok(main.overlay.panel == "" and G.f.get("need_axe", false), "Day 2: the water hole is frozen")
			await go("shed")
			await press("axe")
			ok(G.f.get("has_axe", false), "took the axe")
			await go("outdoor")
			await press("hole")
			ok(flow._hold == "chop", "chopping the ice")
			await mash_until_done()
			ok(G.f.get("ice_broken", false), "ice broken")
			await press("hole")
		ok(main.overlay.panel == "sonar", "sounder open at %s" % id)
		main.overlay.sonar["az"] = flow.survey_bearing(id) + 30.0
		flow.sonar_ping()
		await _f(3)
		ok(not main.overlay.sonar.get("logged", false), "%s: an off-bearing ping logs nothing" % id)
		await until(func(): return flow._sonar_cool <= 0.0, 5.0)
		main.overlay.sonar["az"] = flow.survey_bearing(id) + 2.0
		flow.sonar_ping()
		await until(func(): return main.overlay.panel == "", 10.0)
		ok((G.f.get("survey", {}) as Dictionary).has(id), "%s: echo logged" % id)
	ok(G.f.get("survey_done", false), "survey complete")
	ok(is_equal_approx(float(G.persist["surveys"][-1]["depth"]), G.source_depth()), "structure top %.1f m saved" % G.source_depth())
	await shot("d%d_survey" % d)
	ok(world.phase < 1.99, "still dusk after the survey: night falls on the hill")


func _antenna(d: int) -> void:
	await go("peak")
	ok(world.loc == "peak" and world.phase >= 1.99 and G.tod == "night", "up the trail: fully dark on the hilltop")
	ok(world.ground_at(320.0) <= World.PEAK_TOP and world.ground_at(60.0) == World.GROUND, "the trail end is low, the antenna stands on the summit")
	await shot("d%d_peak" % d)
	if d == 1:
		# the fence: the view swings out over the lake, and back
		world.player.position.x = World.FENCE_X - 8.0
		await _f(90)
		ok(world.cam_off > 60.0, "at the fence the camera looks out over the lake")
		ok(main.overlay.vista_a > 0.8 and main.overlay.vista.resource_path.ends_with("vista_1.png"), "the view from the fence (vista 1)")
		await shot("d1_vista")
		ok(flow.wants_esc(), "Esc closes the view, not the pause menu")
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		flow.world_input(click)
		await _f(30)
		ok(main.overlay.vista_a < 0.2 and world.cam_off > 60.0, "a click closes the view (still at the fence)")
		world.player.position.x = 320.0
		await _f(60)
		ok(world.cam_off < 20.0, "away from the fence it comes back")
		ok(main.overlay.vista_a < 0.2, "the view fades away")
		world.player.position.x = World.FENCE_X - 8.0
		await _f(90)
		ok(main.overlay.vista_a > 0.8, "back at the fence: the view again")
		world.player.position.x = 320.0
		await _f(60)
	await press("antenna")
	if d == 3:
		ok(G.f.get("cable_loose", false), "Day 3: no signal, cable loose")
		await until(func(): return not flow.busy, 10.0)
		await press("junction")
		ok(main.overlay.panel == "wire", "junction box opens")
		var order: Array = flow._wire["order"]
		for target in 3:
			flow._wire["sel"] = order[target]
			flow._wire["target"] = target
			var ev := InputEventAction.new()
			ev.action = "interact"
			ev.pressed = true
			flow._wire_input(ev)
			await _f(30)
		await until(func(): return G.f.get("cable_fixed", false), 10.0)
		ok(G.f.get("cable_fixed", false), "wires reconnected")
		await until(func(): return main.overlay.panel == "", 10.0)
		await press("antenna")
	ok(flow._aiming, "aiming panel open")
	var target: float = G.f["antenna_target"]
	ok(absf(wrapf(float(G.f["antenna_start"]) - target, -180, 180)) >= 60.0, "starts at least 60 deg off")
	var ev2 := InputEventAction.new()
	ev2.action = "interact"
	ev2.pressed = true
	flow._aim_input(ev2)
	ok(flow._aim_locked_t < 0.0, "wrong angle is not accepted")
	flow._aim_az = target + 1.5
	flow._aim_input(ev2)
	await until(func(): return not flow._aiming, 10.0)
	ok(G.f.get("aimed", false), "antenna locked")
	await shot("d%d_antenna" % d)


func _chart(d: int) -> void:
	await open_pc()
	await _desk_clues(d)
	desk.launch("chart")
	var c: AppChart = app("chart")
	ok(c != null and c._state() == "ready", "star chart ready")
	await _f(5)
	if d >= 3:
		# mark the unknown object on Days 3 and 4
		var an := c.anomaly(c._last_area)
		if d <= 4 and not an.is_empty():
			var rel := ((an["pos"] as Vector2) - c._last_area.position) / c._last_area.size
			c.marks.append([rel.x, rel.y])
	c._press("record")
	await until(func(): return flow.step == Flow.S.REPORT, 20.0)
	ok(flow.step == Flow.S.REPORT, "chart recorded")
	if d in [3, 4]:
		ok(G.f.get("marked", false), "the mark found the object")
		ok(G.has_clue("red_body"), "clue: the red body")
	await shot("d%d_chart" % d)


func _report(d: int, ans: String) -> void:
	desk.launch("report")
	var r: AppReport = app("report")
	ok(r != null, "report opens")
	if d >= 6:
		# reporting the anomaly is not accepted any more
		r.text = "yes"
		r._submit()
		ok(r.forcing and main.overlay.red_center == Txt.red("forced"), "Day %d: Yes refused, 'Type No' in red" % d)
		await shot("d%d_typeno" % d)
		r.text = "No"
		r._submit()
		ok(not r.forcing and main.overlay.red_center != Txt.red("forced"), "No accepted, red text gone")
	else:
		r.text = "maybe"
		r._submit()
		ok(not r.submitted, "nonsense answer rejected")
		r.text = ans
		r._submit()
	ok(r.submitted, "report submitted (%s)" % ans)


func _after_report(d: int, ans: String) -> void:
	match d:
		2:
			ok(not flow.desk_can_close(), "Day 2: desktop locked for 5 s")
			await until(func(): return flow.overlay.cur.get("id", "") == "d2_game_hint", 30.0)
			ok(true, "game hint line after 5 s")
			# play three games: the third forces us out
			for i in 3:
				desk.launch("game")
				await _f(3)
				main.mg._begin_run()
				main.mg._crash()
				await _f(3)
				if i < 2:
					main.mg.stop()
					desk._end_game()
			ok(await until(func(): return main.mode == "world", 40.0), "third game over -> forced to rest")
		3:
			if ans == "no":
				ok(flow.step == Flow.S.EXTRA, "Day 3 No: inspect the antenna first")
				await leave_pc()
				await go("cab")
				await press("bed")
				ok(main.mode == "world" and G.day == 3 and flow._bed_ask, "bed before inspection: it asks first")
				var esc := InputEventAction.new()
				esc.action = "pause"
				esc.pressed = true
				flow.world_input(esc)
				await _f(3)
				ok(not flow._bed_ask and world.can_move, "Esc: not yet")
				await go("peak")
				await press("antenna")
				await until(func(): return flow.step == Flow.S.SLEEP, 20.0)
				ok(flow.step == Flow.S.SLEEP, "inspection: nothing wrong")
			else:
				await leave_pc()
		4:
			if ans == "no":
				ok(await until(func(): return main.mode == "world", 40.0), "Day 4 No: wipe, then out of the desktop")
				ok(flow.step == Flow.S.EXTRA, "pills required")
				await go("cab")
				await press("pills")
				await until(func(): return flow.step == Flow.S.SLEEP, 10.0)
				ok(flow.step == Flow.S.SLEEP, "took a sleeping pill")
			else:
				await leave_pc()
		5:
			await leave_pc()
			ok(flow.step == Flow.S.EXTRA, "Day 5: check the antenna")
			await go("peak")
			await press("antenna")
			await until(func(): return (world.nodes["dish_mat"] as ShaderMaterial).get_shader_parameter("amount") > 0.5, 15.0)
			ok(true, "the antenna is covered in flesh")
			await shot("d5_flesh")
			await until(func(): return flow.step == Flow.S.SLEEP and not flow.busy, 30.0)
			ok(flow.step == Flow.S.SLEEP, "back to normal; time to sleep")
		_:
			if main.mode == "desktop":
				await until(func(): return flow.desk_can_close(), 10.0)
				await leave_pc()


func _dream() -> void:
	var mg: MiniGame = main.mg
	ok(mg.dream and mg.mode == "title", "dream title")
	ok(not mg._close_rect().has_point(Vector2(305, 5)) or mg.dream, "no close box in the dream")
	mg._begin_run()
	ok(mg.blood, "blood reefs")
	var t0 := 0.0
	while mg.mode != "temple" and t0 < 120.0:
		await get_tree().process_frame
		t0 += get_process_delta_time()
	ok(mg.mode == "temple" and t0 >= 17.0 and t0 <= 24.0, "the dream reaches the church in ~20 s, however it is played (%.1f s)" % t0)
	await shot("dream_temple")
	mg.fig_k = 1.0
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	mg.handle(ev)
	ok(await until(func(): return G.day == 6, 60.0), "the door -> Day 6")


func _day7() -> void:
	ok(flow.step == Flow.S.END, "Day 7 report starts the end")
	await until(func(): return main.overlay.red_center == Txt.red("d7_desktop"), 30.0)
	ok(true, "BEHOLD HER THRONE, LAMB")
	ok(not flow.desk_can_close(), "cannot leave the desktop")
	await shot("d7_black")
	await until(func(): return main.mode == "world", 60.0)
	ok(world.loc == "cab", "back in the room")
	await press("bed")
	ok(main.mode == "world", "the bed will not take him")
	await until(func(): return main.overlay.red_bottom == Txt.red("d7_move"), 60.0)
	ok(true, "SHE HAS DESCENDED red line after 30 s")
	ok(not world.can_move, "no control during the march")
	await shot("d7_march")


# ------------------------------------------------------------ the mystery
## Which clues each route goes looking for (MYSTERY_BIBLE §3). "red_body" is
## always found by the chart marking on Days 3-4; the bad route stops there.
func wants(clue: String) -> bool:
	match route:
		"good":
			return true
		"normal":
			return clue in ["rumor", "not_weather", "footprints", "echo_hollow", "future_log"]
	return false


func read_doc_at(id: String, clue: String) -> void:
	var loc := "outdoor"
	if id in ["binder", "coats"]:
		loc = "cab"
	elif id == "locker":
		loc = "boathouse"
	await go(loc)
	await press(id)
	ok(main.overlay.panel == "doc" and main.overlay.doc.get("lines", []).size() > 0, "%s: a document" % id)
	await shot("doc_" + id)
	flow.close_doc()
	await _f(3)
	ok(G.has_clue(clue) and main.overlay.panel == "", "clue saved: %s" % clue)


func _world_clues(d: int) -> void:
	if d == 1:
		if wants("rumor"):
			await read_doc_at("sign", "rumor")
			ok(Txt.clue_note("rumor").contains(str(G.cycle_year(1))), "the rumour names the last cycle year")
		if wants("not_weather"):
			await read_doc_at("binder", "not_weather")
	if d == 2 and wants("footprints"):
		await go("outdoor")
		ok(world.has_interact("footprints"), "Day 2: footprints from the lake")
		await press("footprints")
		ok(G.has_clue("footprints"), "clue saved: footprints")
	if d == 4 and wants("prev_notes"):
		await read_doc_at("locker", "prev_notes")
		await press("boat")
		ok(not G.f.get("has_plug", false), "Day 4: the boat is frozen into the ice")
	if d == 6 and wants("last_record"):
		await read_doc_at("coats", "last_record")


func open_file(action: String, day: int = -1) -> bool:
	desk.launch("mydocs")
	var fo: AppFolder = app("mydocs")
	var hit := false
	for it in fo.items:
		if it["action"] == action and (day < 0 or int(it.get("day", 0)) == day):
			fo._open(it)
			hit = true
			break
	desk.close_app(fo)
	await _f(3)
	return hit


func _desk_clues(d: int) -> void:
	if d == 1 and wants("echo_hollow"):
		ok(await open_file("survey", 1), "survey_*.map in My Documents")
		ok(G.has_clue("echo_hollow"), "clue saved: echo_hollow")
	if d == 3 and wants("future_log"):
		ok(await open_file("obslog"), "a log dated thirteen years ahead")
		var lines: Array = desk.future_log_lines()
		ok(String(lines[-3]).contains(Desktop.future_date(7)), "cycle 05 ends on day 7, %s" % Desktop.future_date(7))
		ok(G.has_clue("future_log"), "clue saved: future_log")
	if d == 5 and route == "good":
		ok(await open_file("survey", 5), "night 5 survey record")
		ok(G.has_clue("echo_aurora"), "clue saved: echo_aurora")
		# the archive: the format is on the page, the number came from the radio
		desk.launch("archive")
		var ar: AppArchive = app("archive")
		ok(ar.rows().size() == 3 and String(ar.rows()[2][0]).begins_with(str(G.cycle_year(1))), "three records: %d, %d, %d (sealed)" % [G.cycle_year(3), G.cycle_year(2), G.cycle_year(1)])
		ar.text = G.sealed_id().substr(0, 14) + "1"
		ar.submit()
		ok(not G.persist.get("morse_solved", false) and ar.msg != "", "a wrong number opens nothing")
		ar.text = flow.radio_shown(flow._radio_len, 2)
		ar.submit()
		ok(G.persist.get("morse_solved", false) and app("sealed") != null, "the radio's number opens the sealed record")
	if d == 6 and route == "good":
		desk.launch("log")
		ok(G.has_clue("autocorrect"), "clue saved: autocorrect (Day 6 log)")
		ok((app("log") as AppText).lines_src[-1] == Txt.ui("log.confirmations") % G.answers().size(), "the log counts confirmations")
		desk.launch("notes")
		var nt: AppText = app("notes")
		ok(nt.lines_src[0] == Txt.ui("notes.count") % G.clue_count(), "notes show how many records are saved")
		ok(G.clue_count() == G.CLUES.size(), "all ten clues saved")
		ok(nt.lines_src.any(func(line): return line == Txt.ui("notes.links")), "notes show cross-checks")


func _radio() -> void:
	await go("cab")
	await press("radio")
	ok(main.overlay.panel == "radio", "the receiver opens")
	var want := G.sealed_id().replace("-", " ")
	ok(flow.radio_shown(flow._radio_len, 2) == want, "digits assist: %s" % want)
	ok(flow.radio_shown(flow._radio_len, 1).begins_with("..--- ----- ") and flow.radio_shown(flow._radio_len, 1).count("/") == 3, "signals assist: dots and dashes in 4 groups")
	ok(flow.radio_shown(flow._radio_len, 0) == "", "no assist: nothing written for you")
	var lamp_seen := [false]
	var cond := func() -> bool:
		if flow._radio_lamp:
			lamp_seen[0] = true
		return bool(G.persist.get("morse_heard", false))
	var ok_heard: bool = await until(cond, flow._radio_len + 10.0)
	ok(ok_heard and lamp_seen[0], "listened to the whole message; the lamp keeps time")
	await shot("radio")
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	flow._radio_input(ev)
	await _f(3)
	ok(main.overlay.panel == "", "receiver closed")


func _day7_escape() -> void:
	# the truck first: no plug, no start
	await go("outdoor")
	await press("truck")
	ok(main.overlay.panel == "" and flow.step != Flow.S.ESCAPE, "without the plug the truck will not start")
	# the boat at the boathouse: on Day 7 the ice round it is tissue
	await go("boathouse")
	await shot("d7_boathouse")
	await press("boat")
	ok(await until(func(): return G.f.get("has_plug", false) and not flow.busy, 10.0), "Day 7: the boat comes free; the spare spark plug")
	await go("outdoor")
	await press("truck")
	ok(main.overlay.panel == "wire" and flow._wire.get("purpose", "") == "truck", "the hood: ignition leads")
	await shot("d7_ignition")
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	# a wrong socket first: a spark, nothing connected
	var order: Array = flow._wire["order"]
	flow._wire["sel"] = order[0]
	flow._wire["target"] = 1
	flow._wire_input(ev)
	await _f(3)
	ok((flow._wire["links"] as Array).count(-1) == 3, "a lead in the wrong socket does not hold")
	for target in 3:
		flow._wire["sel"] = order[target]
		flow._wire["target"] = target
		flow._wire_input(ev)
		await _f(30)
	ok(await until(func(): return flow.step == Flow.S.ESCAPE, 10.0), "all three leads: it starts")
