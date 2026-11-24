class_name Flow
extends Node
## The director. Owns the day's step, decides what every interaction means,
## and runs the scripted sequences (prologue, the Day 4 wipe, the Day 5
## outage / flash / dream, the Day 7 march and the ending).

enum S { NOTICE, FUEL, SURVEY, ANTENNA, OUTAGE, CHART, REPORT, EXTRA, SLEEP, END, ESCAPE }

## Lake echo survey (MYSTERY_BIBLE §5): top-down metres, the site's shore along
## y = 0. A: the boathouse jetty on the north-west shore. B: the water hole.
const SURVEY_POINTS := {"stake_boat": ["A", Vector2(-110, 120)], "hole": ["B", Vector2(40, 6)]}
const SOURCE := Vector2(30, 220)
## Morse: one unit in seconds; digits are sent in groups of 2-2-2-4.
const MORSE_UNIT := 0.12
const MORSE_GROUPS := [4, 2, 2, 4]

var main: Node
var world: World
var overlay: Overlay
var desktop: Desktop

var step := S.NOTICE
var busy := false
var pausable_cutscene := false
var wrong_tries := 0
var day_time := 0.0
var _tear_t := 0.0
var _idle_t := 0.0
var _d7_wait := -1.0
var _hold := ""          # active hold / mash task
var _hold_v := 0.0
var _hold_need := 1.0
var _aiming := false
var _aim_az := 0.0
var _aim_locked_t := -1.0
var _wire := {}
var _seq_skip := false
var _desk_lock_t := 0.0
var _doc_clue := ""
var _sonar := false
var _sonar_id := ""
var _sonar_cool := 0.0
var _sonar_done_t := -1.0
var _radio_t := 0.0
var _radio_sched: Array = []      # [start, dur, digit index]
var _radio_len := 0.0
var _radio_lamp := false
var _radio_listen := 0.0


func _ready() -> void:
	world = main.world
	overlay = main.overlay
	desktop = main.desktop
	_build_radio()


# ============================================================ helpers
## Seconds a line needs on screen: words for English, characters for Chinese.
static func read_time(s: String) -> float:
	var cjk := 0
	for i in s.length():
		if s.unicode_at(i) > 0x2e80:
			cjk += 1
	if cjk > 0:
		return cjk * 0.16
	return s.split(" ").size() * 0.36


func wait(s: float) -> void:
	await get_tree().create_timer(s, false).timeout


func fade_to(a: float, dur: float) -> void:
	var tw := create_tween()
	tw.tween_property(overlay, "fade", a, dur)
	await tw.finished


func say(id: String, prio: int = 1) -> void:
	overlay.say(id, prio)


func say_once(id: String, prio: int = 1) -> void:
	if G.today_once("say_" + id):
		overlay.say(id, prio)


func control(on: bool) -> void:
	world.can_move = on
	overlay.show_prompt = on
	busy = not on


func hint_for_step() -> String:
	match step:
		S.NOTICE: return "step_computer"
		S.FUEL: return "step_fuel"
		S.SURVEY: return "step_survey"
		S.ANTENNA: return "step_antenna"
		S.OUTAGE: return "step_fuel"
		S.CHART: return "step_starchart"
		S.REPORT: return "step_report"
		S.EXTRA:
			if G.day == 4:
				return "step_pill"
			return "step_inspect"
		S.SLEEP: return "step_sleep"
	return ""


func wrong() -> void:
	wrong_tries += 1
	if wrong_tries >= 2:
		say(hint_for_step())
		wrong_tries = 0
	else:
		say("generic_unfinished")


## A clue is saved to the investigation notes (first time only).
func found(id: String, in_world: bool = true) -> void:
	if G.add_clue(id):
		Sfx.play("note_saved", -8.0)
		overlay.show_tip(Txt.ui("tip.clue"), 4.0, in_world)


## Esc belongs to an open panel before it belongs to the pause menu.
func wants_esc() -> bool:
	return main.mode == "world" and (overlay.panel != "" or _aiming or _bed_ask or vista_showing())


## Lets the world panels (documents, wires, sounder, radio) hold the player still.
func _panel_open(p: String) -> void:
	overlay.panel = p
	world.can_move = false
	overlay.show_prompt = false


func _panel_close() -> void:
	overlay.panel = ""
	world.can_move = true
	overlay.show_prompt = true


# ============================================================ new game
func new_game() -> void:
	G.new_game()
	G.erase_save()
	await play_prologue()


func continue_game() -> void:
	if not G.load_game():
		await new_game()
		return
	G.persist["retry_day"] = 0
	G.save_meta()
	await start_day(G.day)


func restart_day() -> void:
	Sfx.stop_all_loops(0.3)
	main.tear = 0.0
	overlay.clear_mono()
	overlay.red_bottom = ""
	overlay.red_center = ""
	_end_tasks()
	if main.mode == "desktop":
		desktop.force_close()
	if not G.load_game():
		G.day = maxi(1, G.day)
	await start_day(G.day)


## Developer shortcut (main.gd F1..F7): drop whatever is running, reset the run
## and start day n. Reviewing day 5 should not mean playing days 1..4 first.
func debug_jump(n: int) -> void:
	n = clampi(n, 1, 7)
	Sfx.stop_all_loops(0.2)
	Sfx.stop_sfx()
	main.tear = 0.0
	main.shake = 0.0
	overlay.clear_mono()
	overlay.subtitle = ""
	overlay.red_bottom = ""
	overlay.red_center = ""
	overlay.card_day = 0
	overlay.show_hud = false
	if main.menu.is_open():
		main.menu.close()
	if main.mode == "desktop":
		desktop.force_close()
	if main.mode == "dream":
		main.mg.stop()
	get_tree().paused = false
	_end_tasks()
	G.new_game()
	G.erase_save()
	await start_day(n)


func to_title() -> void:
	Sfx.stop_all_loops(0.5)
	main.tear = 0.0
	overlay.clear_mono()
	overlay.subtitle = ""
	overlay.red_bottom = ""
	overlay.red_center = ""
	overlay.card_day = 0
	overlay.title_text = ""
	overlay.show_hud = false
	overlay.credits = []
	overlay.caption = ""
	overlay.black = 0.0
	overlay.cg = null
	overlay.cg_a = 0.0
	overlay.subtitle_tag = ""
	_end_tasks()
	if main.mode == "desktop":
		desktop.force_close()
	main.set_mode("menu")
	main.menu.open_title(false)


## The view from the hilltop fence: an illustration fading in as the camera
## swings out. 1: Days 1-4, 2: Days 5-6, 3: Day 7.
## Closed by a click (or E / Esc), it stays closed until he steps away from the fence.
var _vista_off := false


func _update_vista(dt: float) -> void:
	if main.mode == "world" and world.loc == "peak":
		var n := 1 if G.day <= 4 else (2 if G.day <= 6 else 3)
		var path := "res://assets/art/cg/vista_%d.png" % n
		if overlay.vista == null or overlay.vista.resource_path != path:
			overlay.vista = load(path)
		if _vista_off and world.cam_off < 20.0:
			_vista_off = false
		if _vista_off:
			overlay.vista_a = maxf(0.0, overlay.vista_a - dt * 3.0)
		else:
			overlay.vista_a = smoothstep(60.0, 125.0, world.cam_off)
	elif overlay.vista_a > 0.0:
		overlay.vista_a = maxf(0.0, overlay.vista_a - dt * 3.0)


func vista_showing() -> bool:
	return main.mode == "world" and overlay.vista_a > 0.5 and not _vista_off


func _end_tasks() -> void:
	overlay.vista_a = 0.0
	_vista_off = false
	_bed_ask = false
	_hold = ""
	overlay.gauge = -1.0
	overlay.panel = ""
	_aiming = false
	_sonar = false
	_sonar_done_t = -1.0
	_radio_lamp = false
	_radio_listen = 0.0
	_doc_clue = ""
	_d7_wait = -1.0
	world.auto_target = INF
	world.player.clear_pose()
	world.player.carrying_axe = false


# ============================================================ prologue
func play_prologue() -> void:
	busy = true
	main.set_mode("cutscene")
	pausable_cutscene = true
	main.set_grade(1)
	overlay.fade = 1.0
	overlay.show_hud = false
	G.day = 1
	G.f = {}
	world.goto("road", 0)
	world._apply_phase(0.42)
	Sfx.loop("engine", "car_engine", -8.0, 2.0)
	Sfx.loop("road", "amb_wind", -18.0, 2.0)
	Sfx.music("music_prologue", -6.0, 3.0)
	await fade_to(0.0, 2.5)
	await wait(3.5)
	Sfx.play("phone_beep", -6.0)
	await wait(1.2)
	overlay.subtitle_tag = Txt.ui("voicemail")
	Sfx.loop("tape", "tape_hiss", -20.0, 0.4)
	for line in Txt.phone():
		overlay.subtitle = line
		_seq_skip = false
		var hold := maxf(4.0, read_time(String(line)) * 1.2 + 1.4)
		var tt := 0.0
		while tt < hold and not _seq_skip:
			await get_tree().process_frame
			tt += get_process_delta_time()
		overlay.subtitle = ""
		await wait(0.7)
	overlay.subtitle_tag = ""
	Sfx.stop_loop("tape", 0.4)
	Sfx.play("phone_end", -8.0)
	await wait(3.0)
	world.drive.stop_soon()
	Sfx.set_loop_volume("engine", -14.0, 3.0)
	await world.drive.stopped
	Sfx.stop_loop("engine", 0.8)
	await wait(0.8)
	Sfx.play("car_door", -4.0)
	await wait(0.6)
	Sfx.music("", 0.0, 3.0)
	await fade_to(1.0, 2.0)
	Sfx.stop_all_loops(1.0)
	pausable_cutscene = false
	await wait(0.8)
	await start_day(1)


func cutscene_input(_e: InputEvent) -> void:
	_seq_skip = true


# ============================================================ day start
func start_day(n: int) -> void:
	busy = true
	control(false)
	main.set_mode("cutscene")
	Sfx.stop_all_loops(0.6)
	main.tear = 0.0
	G.begin_day(n)
	G.save_game()
	_build_radio()
	day_time = 0.0
	_tear_t = 0.0
	_idle_t = 0.0
	_d7_wait = -1.0
	wrong_tries = 0
	_end_tasks()
	overlay.clear_mono()
	overlay.red_bottom = ""
	overlay.red_center = ""
	overlay.fade = 1.0
	main.set_grade(n)
	world.power = true
	world.gen_running = false
	world.interior_dim = 0.0
	world.set_antenna_az(float(G.f["antenna_start"]))
	step = S.NOTICE if n == 1 else (S.ANTENNA if n == 7 else S.FUEL)
	if n == 7:
		G.tod = "night"
		world.gen_running = true
	world._apply_phase(2.0 if n == 7 else 0.0)
	# the card
	overlay.card_day = n
	overlay.card_a = 0.0
	var tw := create_tween()
	tw.tween_property(overlay, "card_a", 1.0, 0.6)
	await tw.finished
	Sfx.play("day_card", -4.0 if n < 4 else 0.0, 1.0 - (n - 1) * 0.04)
	if n >= 5:
		Sfx.play("heartbeat", -8.0)
	await wait(2.4)
	tw = create_tween()
	tw.tween_property(overlay, "card_a", 0.0, 0.6)
	await tw.finished
	overlay.card_day = 0
	if n == 1:
		world.goto("outdoor", 104, 1)
	else:
		world.goto("cab", 300, -1)
	_refresh_interacts()
	main.set_mode("world")
	overlay.show_hud = true
	update_ambience(true)
	await fade_to(0.0, 1.4)
	control(true)
	if n == 1:
		overlay.show_tip(Txt.ui("tip.walk"), 10.0)
	match n:
		1: say("d1_arrive")
		2: say("d2_wake")
		3: say("d3_wake")
		4: say("d4_wake")
		5: say("d5_wake")
		6: say("d6_wake")
		7:
			say("d7_wake")
			say("d7_work")


# ============================================================ per-frame
func _process(dt: float) -> void:
	if main.mode == "menu":
		return
	day_time += dt
	if main.mode in ["world", "desktop"]:
		_day_timers(dt)
		G.tick_clock(dt)
	if main.mode == "world":
		_task_update(dt)
		update_ambience(false)
	_update_vista(dt)
	if _desk_lock_t > 0.0:
		_desk_lock_t -= dt
	_radio_update(dt)
	if step == S.ESCAPE and main.mode == "world" and world.loc == "outdoor" and world.player.position.x >= world.bounds.y - 1.0:
		say_once("escape_shore")


func _day_timers(dt: float) -> void:
	# Day 1: two minutes without opening the computer
	if G.day == 1 and step == S.NOTICE and not G.f.get("pc_opened", false) and day_time > 120.0 and G.today_once("nudge"):
		say("d1_check_computer", 2)
	# Day 4: every minute, two seconds of distortion
	if G.day == 4 and not busy_cutscene():
		_tear_t += dt
		if _tear_t >= 60.0:
			_tear_t = 0.0
			_tear_episode()
	# Day 6: stand still and the line comes
	if G.day == 6 and main.mode == "world":
		if absf(Input.get_axis("left", "right")) < 0.1:
			_idle_t += dt
			if _idle_t > 4.0:
				say_once("d6_silence", 0)
		else:
			_idle_t = 0.0
	# Day 7: thirty seconds in the room after the desktop died
	if _d7_wait >= 0.0 and main.mode == "world":
		_d7_wait += dt
		world.interior_dim = clampf(_d7_wait / 30.0, 0.0, 1.0)
		world.apply_light()
		if _d7_wait >= 30.0:
			_d7_wait = -1.0
			_day7_march()


func busy_cutscene() -> bool:
	return main.mode in ["cutscene", "dream", "ending", "menu"]


func _tear_episode() -> void:
	Sfx.play("tear_drone", -4.0)
	var tw := create_tween()
	tw.tween_property(main, "tear", 1.0, 0.25)
	tw.tween_interval(1.5)
	tw.tween_property(main, "tear", 0.0, 0.25)
	say_once("d4_blur", 0)


# ============================================================ ambience
func update_ambience(force: bool) -> void:
	var loc := world.loc
	var px := world.player.position.x
	var storm: bool = G.env("storm")
	match loc:
		"climb", "peak":
			# up on the hill: only the wind and blowing snow; the lake is far below
			Sfx.loop("amb", "amb_wind_night" if world.phase > 1.6 else "amb_wind", -6.0 if not storm else -3.0, 1.5)
			Sfx.stop_loop("lake", 1.0)
			Sfx.stop_loop("gen", 1.0)
			Sfx.stop_loop("rain", 1.0)
			if G.day >= 6:
				Sfx.loop("flesh", "amb_flesh", -16.0, 2.0)
		"outdoor":
			Sfx.loop("amb", "amb_wind_night" if world.phase > 1.6 else "amb_wind", -10.0 if not storm else -6.0, 1.5)
			var lake_k := clampf(1.0 - absf(px - 1000.0) / 260.0, 0.0, 1.0)
			Sfx.loop("lake", "amb_lake", linear_to_db(maxf(lake_k, 0.001)) - 6.0, 0.5)
			if world.gen_running:
				var gk := clampf(1.0 - absf(px - 540.0) / 300.0, 0.05, 1.0)
				Sfx.loop("gen", "amb_generator", linear_to_db(gk) - 12.0, 0.4)
			else:
				Sfx.stop_loop("gen", 0.5)
			Sfx.stop_loop("rain", 1.0)
			if G.day >= 6:
				Sfx.loop("flesh", "amb_flesh", -16.0, 2.0)
		"cab":
			Sfx.loop("amb", "amb_room", -12.0, 1.0)
			Sfx.stop_loop("lake", 0.6)
			if world.gen_running:
				Sfx.loop("gen", "amb_generator", -32.0, 0.6)
			else:
				Sfx.stop_loop("gen", 0.5)
			Sfx.stop_loop("rain", 1.0)
			if G.day >= 6:
				Sfx.loop("flesh", "amb_flesh", -14.0, 2.0)
		"shed":
			Sfx.loop("amb", "amb_shed", -12.0, 1.0)
			Sfx.stop_loop("lake", 0.6)
			if world.gen_running:
				Sfx.loop("gen", "amb_generator", -3.0, 0.4)
			else:
				Sfx.stop_loop("gen", 0.3)
			Sfx.stop_loop("rain", 1.0)
			if G.day >= 6:
				Sfx.loop("flesh", "amb_flesh", -14.0, 2.0)
	Sfx.muffle(main.mode == "desktop")


# ============================================================ input
func world_input(e: InputEvent) -> void:
	if busy:
		if e.is_action_pressed("interact"):
			overlay.accelerate()
		return
	if _bed_ask:
		if e.is_action_pressed("interact"):
			_bed_answer(true)
		elif e.is_action_pressed("pause"):
			_bed_answer(false)
		return
	if vista_showing():
		if (e is InputEventMouseButton and e.pressed) or e.is_action_pressed("interact") or e.is_action_pressed("pause"):
			_vista_off = true
			Sfx.play("ui_tick", -12.0)
		return
	if _aiming:
		_aim_input(e)
		return
	match overlay.panel:
		"wire":
			_wire_input(e)
			return
		"doc":
			_doc_input(e)
			return
		"sonar":
			_sonar_input(e)
			return
		"radio":
			_radio_input(e)
			return
	if _hold != "":
		if e.is_action_pressed("interact") and _hold in ["pull", "crank", "chop"]:
			_mash()
		return
	if e.is_action_pressed("interact"):
		if overlay.cur.size() > 0 and overlay.accelerate() and world.focus.is_empty():
			return
		if not world.focus.is_empty():
			interact(String(world.focus["id"]))


func interact(id: String) -> void:
	match id:
		"tower_door":
			await _travel("cab", 178, 1)
			if G.day == 1:
				say_once("d1_inside")
		"cab_door":
			await _travel("outdoor", 340, -1)
			if G.day == 3 and G.f.get("marked", false) and world.phase > 1.6:
				say_once("d3_sky")
		"shed_door":
			await _travel("shed", 172, 1)
			if G.day == 1 and step == S.FUEL:
				say_once("d1_shed")
		"shed_exit":
			await _travel("outdoor", 537, 1)
		"trail_up":
			await _go_up()
		"trail_down":
			await _climb(false)
		"computer":
			_use_computer()
		"bed":
			_use_bed()
		"can":
			_use_can()
		"generator":
			_use_generator()
		"axe":
			_use_axe()
		"stake_boat", "hole":
			_use_stake(id)
		"shore_path":
			await _travel("boathouse", 60, 1, false)
		"shore_back":
			await _travel("outdoor", 905, -1, false)
		"boat":
			_use_boat()
		"receiver":
			_use_receiver()
		"antenna":
			_use_antenna()
		"junction":
			_use_junction()
		"pills":
			_use_pills()
		"plant":
			match G.day:
				3: say_once("d3_plant", 0)
				4, 5: say_once("d4_plant", 0)
		"stain":
			say_once("d4_wall", 0)
		"window":
			say_once("d3_sky", 0)
		"sign":
			read_doc("rumor", "rumor")
		"binder":
			read_doc("not_weather", "not_weather")
		"locker":
			read_doc("prev_notes", "prev_notes")
		"coats":
			read_doc("last_record", "last_record")
		"footprints":
			say("footprints_d4" if G.day >= 4 else "footprints", 1)
			found("footprints")
		"radio":
			_use_radio()
		"truck":
			_use_truck()


func _go_up() -> void:
	if step < S.ANTENNA:
		wrong()
		return
	if step in [S.END, S.ESCAPE]:
		say_once("escape_shore")
		return
	await _climb(true)


## The trail between the site and the hilltop. Going up the first time each
## day is walked at a normal pace, and night falls on the way (it is fully
## dark on arrival); later trips, and going down, are quicker.
func _climb(up: bool) -> void:
	control(false)
	main.set_mode("cutscene")
	Sfx.play_var("step_snow", 4, -6.0)
	await fade_to(1.0, 0.4)
	var first: bool = up and not G.f.get("climbed", false)
	if up:
		G.f["climbed"] = true
	world.goto("climb", 20.0 if up else World.CLIMB_LEN - 20.0, 1 if up else -1)
	update_ambience(true)
	world.auto_speed = 46.0 if first else 92.0
	var dur := (World.CLIMB_LEN - 40.0) / world.auto_speed
	if up and world.phase < 1.99:
		world.set_phase(2.0, dur)
		G.clock_at_least(1830)
	await fade_to(0.0, 0.4)
	world.auto_target = World.CLIMB_LEN - 20.0 if up else 20.0
	while world.auto_target != INF:
		await get_tree().process_frame
	await fade_to(1.0, 0.4)
	if world.phase >= 1.99:
		G.tod = "night"
	if up:
		world.goto("peak", 60.0, 1)
	else:
		world.goto("outdoor", 764.0, -1)
	update_ambience(true)
	_refresh_interacts()
	main.set_mode("world")
	await fade_to(0.0, 0.4)
	control(true)


func _travel(loc: String, x: float, facing: int, door: bool = true) -> void:
	control(false)
	if door:
		Sfx.play("door_open" if world.loc != "shed" and loc != "shed" else "door_metal", -6.0)
	else:
		Sfx.play_var("step_snow", 4, -6.0)
	await fade_to(1.0, 0.25)
	world.goto(loc, x, facing)
	update_ambience(true)
	_refresh_interacts()
	await wait(0.1)
	await fade_to(0.0, 0.3)
	control(true)


func _refresh_interacts() -> void:
	if world.loc == "shed":
		world.set_interact("axe", G.day == 2 and G.f.get("need_axe", false) and not G.f.get("has_axe", false))
		world.nodes["axe"].visible = not G.f.get("has_axe", false)
		world.set_interact("can", step == S.FUEL and not G.f.get("fueled", false) and not G.f.get("has_can", false))
		var has_rcv: bool = G.persist.get("has_receiver", false)
		world.set_interact("receiver", not has_rcv)
		world.nodes["receiver"].visible = not has_rcv
	if world.loc == "boathouse":
		world.set_interact("locker", G.day >= 4)
		world.set_interact("boat", not G.f.get("has_plug", false))
	if world.loc == "cab":
		world.set_interact("pills", G.day == 4 and step == S.EXTRA)
		world.set_interact("window", G.day == 3 and G.f.get("marked", false) and world.phase > 1.6)
		world.set_interact("coats", G.day >= 6)
	if world.loc == "peak":
		var day3_fix: bool = G.day == 3 and G.f.get("cable_loose", false) and not G.f.get("cable_fixed", false)
		world.set_interact("junction", day3_fix)
	if world.loc == "outdoor":
		(world.nodes["marks"] as GroundMarks).logged = G.f.get("survey", {})
		world.bounds.y = 840.0 if step == S.ESCAPE else 990.0
	world.player.carrying_axe = G.f.get("has_axe", false) and not G.f.get("ice_broken", false)


# ============================================================ flow 1
func _use_can() -> void:
	if step != S.FUEL or G.f.get("fueled", false):
		return
	Sfx.play("can_pick", -4.0)
	G.f["has_can"] = true
	world.nodes["can1"].visible = false
	world.set_interact("can", false)


func _use_generator() -> void:
	if step == S.OUTAGE:
		_start_crank()
		return
	if step < S.FUEL:
		wrong()
		return
	if step > S.FUEL or G.f.get("started", false):
		if G.day == 3:
			say_once("d3_generator", 0)
		return
	if not G.f.get("has_can", false) and not G.f.get("fueled", false):
		say("generic_no_fuel")
		return
	if not G.f.get("fueled", false):
		if G.day == 2:
			say_once("d2_routine", 0)
		_begin_hold("pour", 2.6, Txt.ui("hold_e"), Txt.ui("task.diesel"))
		return
	_begin_hold("pull", 1.0, Txt.ui("mash_e"), Txt.ui("task.cord"))


func _begin_hold(kind: String, need: float, hint: String, label: String) -> void:
	_hold = kind
	_hold_v = 0.0
	_hold_need = need
	overlay.gauge = 0.0
	overlay.gauge_hint = hint
	overlay.gauge_label = label
	world.can_move = false
	overlay.show_prompt = false
	match kind:
		"pour":
			world.player.set_pose("pour", 2.0)
			Sfx.loop("task", "pour_loop", -8.0, 0.2, "SFX")
		"pull":
			world.player.set_pose("pull", 0.0)
		"crank":
			world.player.set_pose("crank", 0.0)
		"chop":
			world.player.set_pose("chop", 0.0)


func _mash() -> void:
	match _hold:
		"pull":
			_hold_v += 0.2
			world.player.set_pose("pull", 0.0)
			world.player.pose_t = 0.26
			Sfx.play_var("cord_pull", 2, -4.0)
			if _hold_v < 1.0:
				Sfx.play("engine_cough", -10.0 + _hold_v * 6.0, 0.9 + _hold_v * 0.3)
			await wait(0.12)
			if _hold == "pull":
				world.player.pose_t = 0.0
		"crank":
			_hold_v += 0.075
			world.player.pose_t += 0.25
			Sfx.play_var("crank", 2, -6.0)
		"chop":
			_hold_v += 0.26
			world.player.pose_t = 0.26
			Sfx.play_var("ice_chop", 3, -2.0)
			main.shake = 0.25
			await wait(0.16)
			if _hold == "chop":
				world.player.pose_t = 0.0


func _task_update(dt: float) -> void:
	if _aiming:
		_aim_update(dt)
	if _sonar:
		_sonar_update(dt)
	if _hold == "":
		return
	match _hold:
		"pour":
			if Input.is_action_pressed("interact"):
				_hold_v += dt
				world.player.pose_fps = 2.0
			else:
				world.player.pose_t = 0.0
				world.player.pose_fps = 0.0
			Sfx.set_loop_volume("task", -8.0 if Input.is_action_pressed("interact") else -40.0, 0.1)
		"pull":
			_hold_v = maxf(0.0, _hold_v - dt * 0.32)
		"crank":
			_hold_v = maxf(0.0, _hold_v - dt * 0.09)
			world.player.pose_fps = 0.0
	overlay.gauge = _hold_v / _hold_need
	if _hold_v >= _hold_need:
		var k := _hold
		_hold = ""
		overlay.gauge = -1.0
		Sfx.stop_loop("task", 0.2)
		world.player.clear_pose()
		_task_done(k)


func _task_done(kind: String) -> void:
	match kind:
		"pour":
			G.f["fueled"] = true
			G.f["has_can"] = false
			world.nodes["can1"].visible = true
			Sfx.play("tank_full", -6.0)
			world.can_move = true
			overlay.show_prompt = true
		"pull":
			_generator_started()
		"crank":
			_crank_done()
		"chop":
			G.f["ice_broken"] = true
			world.player.carrying_axe = false
			Sfx.play("ice_break", -2.0)
			world.apply_env()
			say("d2_ice_done")
			world.can_move = true
			overlay.show_prompt = true


func _generator_started() -> void:
	G.f["started"] = true
	Sfx.play("engine_start", -2.0)
	world.set_generator(true)
	update_ambience(true)
	world.can_move = true
	overlay.show_prompt = true
	await wait(0.9)
	step = S.SURVEY
	G.clock_at_least(1620)
	G.tod = "dusk"
	world.set_phase(1.0, 3.0)
	if G.day == 1:
		say("generic_fuel_done")
		say("d1_dusk")
	elif G.day == 3:
		say_once("d3_generator", 0)


# ============================================================ flow 2
func _use_axe() -> void:
	G.f["has_axe"] = true
	Sfx.play("axe_take", -4.0)
	world.nodes["axe"].visible = false
	world.set_interact("axe", false)
	world.player.carrying_axe = true
	say("d2_axe")


func _use_receiver() -> void:
	if step < S.FUEL:
		wrong()
		return
	G.persist["has_receiver"] = true
	Sfx.play("can_pick", -4.0)
	world.nodes["receiver"].visible = false
	world.set_interact("receiver", false)


func _use_stake(id: String) -> void:
	if step < S.SURVEY:
		wrong()
		return
	if step > S.SURVEY:
		return
	if not G.persist.get("has_receiver", false):
		say("survey_need")
		return
	if (G.f.get("survey", {}) as Dictionary).has(id):
		return
	if id == "hole" and G.day == 2 and not G.f.get("ice_broken", false):
		if not G.f.get("has_axe", false):
			G.f["need_axe"] = true
			Sfx.play("ice_knock", -4.0)
			say("d2_ice")
			return
		_begin_hold("chop", 1.0, Txt.ui("mash_e"), Txt.ui("task.ice"))
		return
	_open_sonar(id)


func survey_bearing(id: String) -> float:
	var p: Vector2 = SURVEY_POINTS[id][1]
	return rad_to_deg(atan2(SOURCE.y - p.y, SOURCE.x - p.x))


func survey_range(id: String) -> float:
	return (SURVEY_POINTS[id][1] as Vector2).distance_to(SOURCE)


func _open_sonar(id: String) -> void:
	_sonar = true
	_sonar_id = id
	_sonar_cool = 0.0
	_sonar_done_t = -1.0
	var target := survey_bearing(id)
	var off := randf_range(35.0, 70.0) * (1.0 if randf() < 0.5 else -1.0)
	var start := target + off
	if start < 5.0 or start > 175.0:
		start = target - off
	overlay.sonar = {"point": SURVEY_POINTS[id][0], "az": clampf(start, 5.0, 175.0), "pings": [], "trace": {}, "logged": false}
	_panel_open("sonar")
	world.player.set_pose("kneel", 1.5)
	Sfx.play("box_open", -8.0)


func _sonar_update(dt: float) -> void:
	_sonar_cool = maxf(0.0, _sonar_cool - dt)
	var tr: Dictionary = overlay.sonar.get("trace", {})
	if not tr.is_empty():
		tr["t"] = float(tr["t"]) + dt
	if _sonar_done_t >= 0.0:
		_sonar_done_t += dt
		if _sonar_done_t > 1.4:
			_sonar_logged()
		return
	var dir := Input.get_axis("left", "right")
	if absf(dir) > 0.1:
		# A turns toward the left of the lake (larger bearing), D toward the right
		overlay.sonar["az"] = clampf(float(overlay.sonar["az"]) - dir * 24.0 * dt, 0.0, 180.0)


func _sonar_input(e: InputEvent) -> void:
	if _sonar_done_t >= 0.0:
		return
	if e is InputEventKey and e.pressed and not e.echo:
		if e.is_action("left"):
			overlay.sonar["az"] = clampf(float(overlay.sonar["az"]) + 1.0, 0.0, 180.0)
		elif e.is_action("right"):
			overlay.sonar["az"] = clampf(float(overlay.sonar["az"]) - 1.0, 0.0, 180.0)
	if e.is_action_pressed("pause"):
		_sonar = false
		world.player.clear_pose()
		_panel_close()
		get_viewport().set_input_as_handled()
		return
	if e.is_action_pressed("interact"):
		sonar_ping()


## One pulse at the current bearing. Strength is only known after the return.
func sonar_ping() -> void:
	if _sonar_cool > 0.0 or _sonar_done_t >= 0.0:
		return
	_sonar_cool = 0.9
	var az := float(overlay.sonar["az"])
	var err := az - survey_bearing(_sonar_id)
	var s := exp(-pow(err / 10.0, 2.0))
	(overlay.sonar["pings"] as Array).append([az, s])
	overlay.sonar["trace"] = {"t": 0.0, "s": s, "range": survey_range(_sonar_id), "seed": randi() % 9999, "struct": G.day >= 3}
	Sfx.play("sonar_ping", -6.0)
	if absf(err) <= 6.0:
		overlay.sonar["logged"] = true
		overlay.sonar["range"] = survey_range(_sonar_id)
		overlay.sonar["depth"] = G.source_depth()
		_sonar_done_t = 0.0
	await wait(0.35)
	Sfx.play("sonar_echo", lerpf(-30.0, -4.0, s))
	if G.day >= 5 and s > 0.5:
		main.shake = 0.15


func _sonar_logged() -> void:
	_sonar = false
	_sonar_done_t = -1.0
	world.player.clear_pose()
	_panel_close()
	Sfx.play("lock_beep", -6.0)
	if not G.f.has("survey"):
		G.f["survey"] = {}
	G.f["survey"][_sonar_id] = {"az": survey_bearing(_sonar_id), "range": survey_range(_sonar_id)}
	_refresh_interacts()
	if (G.f["survey"] as Dictionary).size() >= SURVEY_POINTS.size():
		_survey_done()


func _survey_done() -> void:
	G.f["survey_done"] = true
	G.persist["surveys"].append({"day": G.day, "depth": G.source_depth()})
	step = S.ANTENNA
	G.clock_at_least(1750)
	if G.day == 1:
		overlay.show_tip(Txt.ui("tip.survey"), 6.0)
	# still dusk: night falls on the way up the hill (_climb)
	world.set_phase(1.3, 4.0)
	update_ambience(true)
	_refresh_interacts()


# ============================================================ documents
func read_doc(id: String, clue: String = "") -> void:
	overlay.doc = {"title": Txt.doc_title(id), "lines": Txt.doc(id), "scroll": 0}
	_doc_clue = clue
	_panel_open("doc")
	Sfx.play("paper", -6.0)


func _doc_input(e: InputEvent) -> void:
	if e.is_action_pressed("up"):
		overlay.doc["scroll"] = int(overlay.doc.get("scroll", 0)) - 1
	elif e.is_action_pressed("down"):
		overlay.doc["scroll"] = int(overlay.doc.get("scroll", 0)) + 1
	elif e.is_action_pressed("interact") or e.is_action_pressed("pause"):
		close_doc()
		get_viewport().set_input_as_handled()


func close_doc() -> void:
	if overlay.panel != "doc":
		return
	_panel_close()
	Sfx.play("paper", -12.0)
	if _doc_clue != "":
		found(_doc_clue)
	_doc_clue = ""


# ============================================================ the radio (Day 5 only)
func _build_radio() -> void:
	_radio_sched.clear()
	var u := MORSE_UNIT
	var tt := 0.0
	var i := 0
	var digits := G.morse_code()
	for g in MORSE_GROUPS:
		for k in int(g):
			var code: String = Overlay.MORSE[digits[i]]
			for c in code.length():
				var dur := u if code[c] == "." else u * 3.0
				_radio_sched.append([tt, dur, i])
				tt += dur + u
			tt += u * 6.0           # between digits
			i += 1
		tt += u * 10.0              # between groups
	_radio_len = tt + 4.0           # then a pause, and again


func radio_active() -> bool:
	return G.day == 5 and G.f.get("radio_on", false)


func _radio_update(dt: float) -> void:
	if not radio_active() or main.mode == "menu":
		_radio_lamp = false
		return
	var t0 := _radio_t
	_radio_t = fposmod(_radio_t + dt, _radio_len)
	var lamp := false
	for ev in _radio_sched:
		var s := float(ev[0])
		if _radio_t >= s and _radio_t < s + float(ev[1]):
			lamp = true
		var crossed := (t0 < s and _radio_t >= s) or (_radio_t < t0 and (s >= t0 or s <= _radio_t))
		if crossed:
			var vol := -60.0
			if overlay.panel == "radio":
				vol = -4.0
			elif main.mode == "world" and world.loc == "cab":
				vol = -30.0 + 14.0 * clampf(1.0 - absf(world.player.position.x - 452.0) / 260.0, 0.0, 1.0)
			if vol > -59.0:
				Sfx.play("morse_dah" if float(ev[1]) > MORSE_UNIT * 1.5 else "morse_dit", vol)
	_radio_lamp = lamp
	if overlay.panel == "radio":
		overlay.radio["lamp"] = lamp
		overlay.radio["shown"] = radio_shown(_radio_t, int(G.settings.get("assist", 0)))
		_radio_listen += dt
		# heard it all once: remembered silently (no text points anywhere)
		if _radio_listen >= _radio_len:
			G.persist["morse_heard"] = true


## What the assist shows after `t` seconds of the message: dots/dashes or digits.
func radio_shown(t: float, assist: int) -> String:
	if assist <= 0:
		return ""
	var done := {}
	for ev in _radio_sched:
		done[int(ev[2])] = t >= float(ev[0]) + float(ev[1])
	var out := ""
	var i := 0
	var digits := G.morse_code()
	for g in MORSE_GROUPS:
		var grp := ""
		for k in int(g):
			if done.get(i, false):
				var d := digits[i]
				grp += (d if assist >= 2 else Overlay.MORSE[d] + " ")
			i += 1
		if grp != "":
			out += grp.strip_edges() + ("  /  " if assist == 1 else " ")
	return out.strip_edges().trim_suffix("/").strip_edges()


func _use_radio() -> void:
	if not radio_active():
		Sfx.play("static_burst", -10.0)
		say_once("radio_static", 0)
		return
	overlay.radio = {"lamp": false, "shown": ""}
	_radio_listen = 0.0
	_panel_open("radio")
	Sfx.play("static_burst", -12.0)


func _radio_input(e: InputEvent) -> void:
	if e.is_action_pressed("interact") or e.is_action_pressed("pause"):
		_panel_close()
		get_viewport().set_input_as_handled()


# ============================================================ antenna
func _use_antenna() -> void:
	if step == S.EXTRA and G.day == 3 and G.f.get("inspect", false):
		await _inspect_antenna()
		return
	if step == S.EXTRA and G.day == 5:
		await _antenna_flesh_flash()
		return
	if step < S.ANTENNA:
		wrong()
		return
	if step > S.ANTENNA:
		if G.day == 6:
			say_once("d6_antenna", 0)
		return
	if world.phase < 1.95:
		say("generic_not_yet")
		return
	if G.day == 1:
		say_once("d1_night_antenna", 0)
	if G.day == 6:
		say_once("d6_antenna", 0)
	if G.day == 3 and not G.f.get("cable_fixed", false):
		G.f["cable_loose"] = true
		Sfx.play("static_burst", -6.0)
		overlay.panel = "aim"
		overlay.aim = {"az": world.antenna_az, "err": 180.0, "locked": false}
		control(false)
		await wait(1.4)
		overlay.panel = ""
		control(true)
		say("d3_cable")
		_refresh_interacts()
		return
	_aiming = true
	_aim_az = world.antenna_az
	_aim_locked_t = -1.0
	overlay.panel = "aim"
	world.can_move = false
	overlay.show_prompt = false
	Sfx.loop("static", "static_loop", -16.0, 0.3, "SFX")


func _aim_err() -> float:
	var target: float = G.f["antenna_target"]
	return wrapf(_aim_az - target, -180.0, 180.0)


func _aim_update(dt: float) -> void:
	if _aim_locked_t >= 0.0:
		_aim_locked_t += dt
		if _aim_locked_t > 1.3:
			_aim_finish()
		return
	var dir := Input.get_axis("left", "right")
	if absf(dir) > 0.1:
		_aim_az = fposmod(_aim_az + dir * 32.0 * dt, 360.0)
		if not Sfx.has_loop("servo"):
			Sfx.loop("servo", "servo_loop", -10.0, 0.05, "SFX")
	else:
		Sfx.stop_loop("servo", 0.08)
	world.set_antenna_az(_aim_az)
	var err := _aim_err()
	overlay.aim = {"az": _aim_az, "err": err, "locked": false}
	Sfx.set_loop_volume("static", lerpf(-14.0, -40.0, clampf(1.0 - absf(err) / 90.0, 0.0, 1.0)), 0.1)


func _aim_input(e: InputEvent) -> void:
	if _aim_locked_t >= 0.0:
		return
	if e is InputEventKey and e.pressed and not e.echo:
		if e.is_action("left"):
			_aim_az = fposmod(_aim_az - 1.0, 360.0)
		elif e.is_action("right"):
			_aim_az = fposmod(_aim_az + 1.0, 360.0)
	if e.is_action_pressed("pause"):
		_aiming = false
		overlay.panel = ""
		Sfx.stop_loop("servo", 0.1)
		Sfx.stop_loop("static", 0.2)
		world.can_move = true
		overlay.show_prompt = true
		get_viewport().set_input_as_handled()
		return
	if e.is_action_pressed("interact"):
		if absf(_aim_err()) <= 3.0:
			_aim_locked_t = 0.0
			overlay.aim = {"az": _aim_az, "err": _aim_err(), "locked": true}
			Sfx.stop_loop("servo", 0.05)
			Sfx.stop_loop("static", 0.3)
			Sfx.play("lock_beep", -4.0)
		else:
			Sfx.play("error_buzz", -8.0)


func _aim_finish() -> void:
	_aiming = false
	overlay.panel = ""
	world.can_move = true
	overlay.show_prompt = true
	G.f["aimed"] = true
	if G.day == 5:
		step = S.OUTAGE
		_day5_outage()
	else:
		step = S.CHART


# ============================================================ Day 3: wires
func _use_junction() -> void:
	if not G.f.get("cable_loose", false) or G.f.get("cable_fixed", false):
		return
	var cols := [Color8(200, 50, 50), Color8(230, 200, 70), Color8(70, 120, 220)]
	var order := [2, 0, 1]
	_wire = {"colors": cols, "sockets": [cols[order[0]], cols[order[1]], cols[order[2]]], "order": order,
		"links": [-1, -1, -1], "sel": 0, "target": 0, "flesh": G.day >= 6}
	overlay.wire = _wire
	overlay.panel = "wire"
	world.can_move = false
	overlay.show_prompt = false
	Sfx.play("box_open", -6.0)


func _wire_input(e: InputEvent) -> void:
	var links: Array = _wire["links"]
	if e.is_action_pressed("up"):
		_wire["sel"] = posmod(int(_wire["sel"]) - 1, 3)
		Sfx.play("ui_tick", -12.0)
	elif e.is_action_pressed("down"):
		_wire["sel"] = posmod(int(_wire["sel"]) + 1, 3)
		Sfx.play("ui_tick", -12.0)
	elif e.is_action_pressed("left"):
		_wire["target"] = posmod(int(_wire["target"]) - 1, 3)
		Sfx.play("ui_tick", -12.0)
	elif e.is_action_pressed("right"):
		_wire["target"] = posmod(int(_wire["target"]) + 1, 3)
		Sfx.play("ui_tick", -12.0)
	elif e.is_action_pressed("pause"):
		overlay.panel = ""
		world.can_move = true
		overlay.show_prompt = true
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("interact"):
		var sel: int = _wire["sel"]
		var tgt: int = _wire["target"]
		var order: Array = _wire["order"]
		if links[sel] >= 0:
			links[sel] = -1
			Sfx.play("plug_out", -6.0)
		elif order[tgt] == sel and not links.has(tgt):
			links[sel] = tgt
			Sfx.play("plug_in", -4.0)
			world.player.set_pose("reach", 3.0)
			await wait(0.3)
			world.player.clear_pose()
			for i in 3:
				if links[i] < 0:
					_wire["sel"] = i
					break
		else:
			Sfx.play("spark", -6.0)
			main.shake = 0.2
		if not links.has(-1):
			Sfx.play("lock_beep", -6.0)
			await wait(0.6)
			overlay.panel = ""
			world.can_move = true
			overlay.show_prompt = true
			if _wire.get("purpose", "") == "truck":
				await _truck_wired()
			else:
				G.f["cable_fixed"] = true
				world.set_interact("junction", false)
				say("d3_cable_done")
	overlay.wire = _wire


# ============================================================ Day 7: the way out
## The truck has had no spark plug since the previous cycle (the sealed record
## says where the spare is: under the boat at the boathouse). The boat comes
## free only on Day 7, when the shore ice round it has turned to tissue.
func _use_boat() -> void:
	if G.day < 7:
		Sfx.play("ice_knock", -6.0)
		say_once("boat_frozen", 0)
		return
	if G.f.get("has_plug", false):
		return
	control(false)
	world.player.set_pose("reach", 2.0)
	Sfx.play("flesh_hit", -6.0)
	await wait(1.0)
	world.player.clear_pose()
	G.f["has_plug"] = true
	Sfx.play("can_pick", -4.0)
	world.set_interact("boat", false)
	say("plug_found", 1)
	control(true)


func _use_truck() -> void:
	if not G.f.get("has_plug", false) or step >= S.END:
		Sfx.play("engine_cough", -10.0)
		say_once("truck_dead", 0)
		return
	# the spare plug in, then the ignition leads: colour to colour
	var cols := [Color8(200, 50, 50), Color8(230, 200, 70), Color8(70, 120, 220)]
	var order := [1, 2, 0]
	_wire = {"colors": cols, "sockets": [cols[order[0]], cols[order[1]], cols[order[2]]], "order": order,
		"links": [-1, -1, -1], "sel": 0, "target": 0, "flesh": true, "purpose": "truck",
		"title": Txt.ui("ignition.title")}
	overlay.wire = _wire
	_panel_open("wire")
	Sfx.play("box_open", -6.0)


func _truck_wired() -> void:
	step = S.ESCAPE
	await _escape()


## Leaving by road. With the number from the radio opened in the archive and
## enough of the truth (G.can_escape), the road goes away from the lake. Without
## it, the road comes back round to the site, and to the lake.
func _escape() -> void:
	control(false)
	main.set_mode("cutscene")
	Sfx.play("car_door", -4.0)
	await fade_to(1.0, 1.2)
	overlay.red_bottom = ""
	overlay.show_hud = false
	Sfx.stop_all_loops(0.8)
	Sfx.play("engine_start", -2.0)
	await wait(1.0)
	var out := G.can_escape()
	world.goto("road", 0)
	world._apply_phase(2.0)
	world.sky.object_size = 40.0
	world.sky.aurora = 1.0
	Sfx.loop("engine", "car_engine", -8.0, 1.0)
	Sfx.loop("road", "amb_wind", -18.0, 2.0)
	await fade_to(0.0, 2.0)
	if out:
		# driving away: the night thins out behind, the thing in the sky goes with it
		world.set_phase(0.55, 14.0)
		var tw2 := create_tween().set_parallel()
		tw2.tween_property(world.sky, "aurora", 0.0, 12.0)
		tw2.tween_property(world.sky, "object_size", 0.0, 10.0)
		await wait(15.0)
		await fade_to(1.0, 2.5)
		Sfx.stop_all_loops(1.5)
		await _finish_run("escape")
		return
	# the red does not thin out; the road bends back
	var tw3 := create_tween().set_parallel()
	tw3.tween_property(world.sky, "object_size", 60.0, 9.0)
	await wait(9.0)
	world.drive.stop_soon()
	await world.drive.stopped
	await fade_to(1.0, 1.5)
	Sfx.stop_all_loops(0.5)
	world.goto("outdoor", 104, 1)
	world._apply_phase(2.0)
	update_ambience(true)
	main.set_mode("world")
	overlay.show_hud = true
	await fade_to(0.0, 1.5)
	await _march_to_lake()


## Walked to the shore, no control (Day 7 after the report, or after the road).
func _march_to_lake() -> void:
	control(false)
	overlay.red_bottom = Txt.red("d7_move")
	var tw := create_tween()
	tw.tween_property(overlay, "red_bottom_a", 1.0, 1.0)
	Sfx.play("red_sting", -4.0)
	await wait(1.6)
	world.auto_speed = 30.0
	if world.loc in ["cab", "shed", "boathouse"]:
		var door_x: float = {"cab": 170.0, "shed": 165.0, "boathouse": 52.0}[world.loc]
		var back_x: float = {"cab": 340.0, "shed": 537.0, "boathouse": 905.0}[world.loc]
		world.auto_target = door_x
		while world.auto_target != INF:
			await get_tree().process_frame
		await _travel_forced("outdoor", back_x)
	world.auto_target = 984.0
	while world.auto_target != INF:
		await get_tree().process_frame
	await wait(2.4)
	tw = create_tween()
	tw.tween_property(overlay, "red_bottom_a", 0.0, 1.0)
	await _ending()


# ============================================================ Day 5: outage
func _day5_outage() -> void:
	await wait(1.2)
	control(false)
	Sfx.play("ice_groan", -4.0)
	main.shake = 0.35
	await wait(0.35)
	Sfx.play("power_down", -2.0)
	world.set_power(false)
	world.set_generator(false)
	update_ambience(true)
	await wait(1.4)
	control(true)
	say("d5_outage")


func _start_crank() -> void:
	say_once("d5_crank")
	_begin_hold("crank", 1.0, Txt.ui("mash_e"), Txt.ui("task.crank"))
	if G.day == 5 and world.loc == "shed" and not G.f.get("intruder", false):
		_intruder()


## While the observer cranks in the dark, the shed door opens behind him.
## Power back before it reaches him: it is gone with the light. Too slow: the end.
const INTRUDER_TIME := 9.0


func _intruder() -> void:
	G.f["intruder"] = true
	await wait(1.4)
	if _hold != "crank":
		return
	Sfx.play("door_metal", 0.0)
	Sfx.loop("intruder", "heartbeat_loop", -14.0, 1.0, "SFX")
	var fig := Intruder.new()
	fig.z_index = 4
	fig.position = Vector2(170, World.GROUND)
	world.root.add_child(fig)
	world.nodes["intruder"] = fig
	var from := fig.position.x
	var to := world.player.position.x - 10.0
	var tt := 0.0
	while _hold == "crank" and is_instance_valid(fig):
		await get_tree().process_frame
		var dt := get_process_delta_time()
		tt += dt
		fig.walk += dt
		fig.position.x = lerpf(from, to, clampf(tt / INTRUDER_TIME, 0.0, 1.0))
		Sfx.set_loop_volume("intruder", lerpf(-14.0, 0.0, clampf(tt / INTRUDER_TIME, 0.0, 1.0)), 0.1)
		if tt >= INTRUDER_TIME:
			Sfx.stop_loop("intruder", 0.1)
			await _caught()
			return
	Sfx.stop_loop("intruder", 0.05)
	if is_instance_valid(fig):
		fig.queue_free()
	world.nodes.erase("intruder")
	if G.f.get("cranked", false):
		await wait(0.6)
		say("d5_what", 2)


## It reached him. He is not offered at the shore: he is taken in. The only way
## to the assimilation ending; the title then offers Day 5 again.
func _caught() -> void:
	_hold = ""
	overlay.gauge = -1.0
	world.player.clear_pose()
	control(false)
	main.set_mode("cutscene")
	main.shake = 1.2
	Sfx.play("flesh_sting", 2.0)
	Sfx.play("red_sting", 0.0)
	overlay.fade = 1.0
	Sfx.stop_all_loops(0.2)
	G.persist["retry_day"] = 5
	await wait(1.5)
	world.goto("outdoor", 984, 1)
	world._apply_phase(2.0)
	main.shake = 0.0
	var tw := create_tween()
	tw.tween_property(overlay, "fade", 0.0, 2.0)
	await _ending("assimilate", true)


func _crank_done() -> void:
	G.f["cranked"] = true
	Sfx.play("engine_start", -2.0)
	world.set_generator(true)
	world.set_power(true)
	update_ambience(true)
	world.can_move = true
	overlay.show_prompt = true
	say("d5_crank_done")
	step = S.CHART
	if G.day == 5:
		# the only night the receiver says anything (MYSTERY_BIBLE §4)
		G.f["radio_on"] = true
		_radio_t = 0.0


# ============================================================ the computer
func _use_computer() -> void:
	if step == S.OUTAGE or not world.power:
		say("d5_outage")
		return
	if step == S.END:
		say_once("d7_desktop", 0)
		return
	if step == S.ESCAPE:
		say("no_signal")
		return
	G.f["pc_opened"] = true
	control(false)
	Sfx.play("chair", -10.0)
	await fade_to(1.0, 0.35)
	main.set_mode("desktop")
	desktop.open_for_today()
	update_ambience(true)
	Sfx.loop("pc", "amb_pc", -14.0, 0.5, "SFX")
	await fade_to(0.0, 0.35)
	if G.day <= 2 and G.today_once("desk_tip"):
		overlay.show_tip(Txt.ui("tip.desk"), 9.0, false)


func desktop_closed() -> void:
	## Called by the desktop after the player leaves it.
	Sfx.stop_loop("pc", 0.3)
	await fade_to(1.0, 0.25)
	main.set_mode("world")
	update_ambience(true)
	_refresh_interacts()
	await fade_to(0.0, 0.3)
	control(true)
	if G.f.get("notice_closed_line", false):
		G.f["notice_closed_line"] = false
		say("d1_notice_read")
	if G.f.get("pending_after_desk", "") != "":
		var p: String = G.f["pending_after_desk"]
		G.f["pending_after_desk"] = ""
		if p == "d4_wipe":
			pass


func desk_can_close() -> bool:
	if _desk_lock_t > 0.0:
		if G.today_once("close_blocked"):
			say("d2_close_blocked")
		return false
	if G.f.get("d7_locked", false):
		return false
	return true


func on_notice_opened() -> void:
	if G.day >= 3:
		say_once("d3_notice", 0)


func on_notice_closed() -> void:
	if step == S.NOTICE:
		step = S.FUEL
		G.f["notice_closed_line"] = true


func on_chart_opened() -> void:
	match G.day:
		3: say_once("d3_chart", 0)
		4: say_once("d4_chart", 0)
		5: say_once("d5_chart", 0)
		6: say_once("d6_chart", 0)


func chart_state() -> String:
	## What the star chart should show right now.
	if step < S.CHART:
		return "no_signal"
	if step > S.CHART:
		return "recorded"
	return "ready"


func on_chart_recorded(hit: bool, marks: Array) -> void:
	if step != S.CHART:
		return
	step = S.REPORT
	G.f["marked"] = hit
	G.persist["records"].append({"day": G.day, "marks": marks})
	if hit and G.day >= 3:
		G.persist["marks_hit"].append(G.day)
		world.interior_dim = 0.35
		world.apply_light()
		found("red_body", false)
	match G.day:
		1: say("d1_starchart", 0)
		2: say("d2_chart", 0)


func report_state() -> String:
	if step < S.REPORT:
		return "need_chart"
	if step > S.REPORT:
		return "done"
	return "ready"


func on_report_opened() -> void:
	if G.day == 1:
		say_once("d1_report", 0)


## Returns the reply lines the report page shows after submitting.
func on_report_submitted(answer: String) -> Array:
	G.persist["answers"].append(answer)
	# The question is "is there an anomaly?". What the station wants is No:
	# No is thanked, Yes is asked to look again, and then quietly corrected.
	var replies := [Txt.ui("report.received")]
	var ys := G.streak("yes")
	var ns := G.streak("no")
	if G.day >= 6:
		replies.append(Txt.ui("report.forced"))
	elif answer == "no":
		if ns >= 4:
			replies.append(Txt.ui("report.yes4"))
		elif ns == 3:
			replies.append(Txt.ui("report.yes3"))
		elif ns == 2:
			replies.append(Txt.ui("report.yes2"))
	else:
		if ys >= 3:
			replies.append(Txt.ui("report.no3"))
			G.persist["corrected"] = true
		elif ys == 2:
			replies.append(Txt.ui("report.no2"))
	step = S.SLEEP
	match G.day:
		1:
			pass
		2:
			_desk_lock_t = 5.0
			_day2_after_report()
			if answer == "no":
				say("d2_report", 0)
		3:
			if answer == "no":
				step = S.EXTRA
				G.f["inspect"] = true
				say("d3_report")
				say("d3_antenna_off")
		4:
			if answer == "no":
				step = S.EXTRA
				say("d4_report")
				_day4_wipe()
			else:
				say("d4_report_yes")
		5:
			step = S.EXTRA
			if answer == "yes":
				say("d5_report", 2)
			say("d5_uranus", 2)
		6:
			say_once("d6_type_yes", 0)
		7:
			step = S.END
			_day7_blackout()
	if step == S.SLEEP and G.day <= 2:
		say("generic_report_done", 0)
	return replies


func on_type_yes_shown() -> void:
	pass


func on_sealed_opened() -> void:
	Sfx.play("note_saved", -8.0)
	Sfx.play("low_boom", -14.0)
	overlay.show_tip(Txt.ui("tip.clue"), 4.0, false)


# ------------------------------------------------------------ Day 2
func _day2_after_report() -> void:
	await wait(5.0)
	if main.mode == "desktop":
		say("d2_game_hint", 2)


func on_game_over(score: int, games: int) -> void:
	if G.day == 2:
		say_once("d2_game_over", 0)
		if score >= 2000:
			say_once("d2_game_best", 0)
		if games >= 3 and step >= S.SLEEP and G.today_once("forced_rest"):
			_day2_forced_rest()


func _day2_forced_rest() -> void:
	say("d2_forced_rest", 2)
	await overlay.wait_line("d2_forced_rest")
	if main.mode == "desktop":
		desktop.force_close()


# ------------------------------------------------------------ Day 3
func _inspect_antenna() -> void:
	control(false)
	world.player.set_pose("reach", 2.0)
	Sfx.play("antenna_check", -6.0)
	await wait(2.2)
	world.player.clear_pose()
	G.f["inspect"] = false
	step = S.SLEEP
	say("d3_antenna", 2)
	control(true)


# ------------------------------------------------------------ Day 4
func _day4_wipe() -> void:
	G.f["d4_wipe"] = true
	await wait(1.2)
	await desktop.play_wipe()
	say("d4_wipe", 2)
	await overlay.wait_line("d4_wipe")
	say("d4_pill", 2)
	await overlay.wait_line("d4_pill")
	desktop.force_close()


func _use_pills() -> void:
	if not (G.day == 4 and step == S.EXTRA):
		return
	control(false)
	Sfx.play("pills", -4.0)
	await wait(0.9)
	Sfx.play("gulp", -6.0)
	world.nodes["pills"].visible = false
	world.set_interact("pills", false)
	step = S.SLEEP
	say("d4_pill_take")
	control(true)


# ------------------------------------------------------------ Day 5
func _antenna_flesh_flash() -> void:
	control(false)
	world.player.facing = 1
	Sfx.stop_loop("rain", 0.5)
	Sfx.stop_loop("amb", 0.5)
	await wait(2.0)                       # two seconds of silence first
	Sfx.play("static_burst", -2.0)
	var dm: ShaderMaterial = world.nodes["dish_mat"]
	dm.set_shader_parameter("protect", 0.0)
	dm.set_shader_parameter("amount", 1.0)
	Sfx.play("flesh_sting", 0.0)
	Sfx.loop("flesh_beat", "heartbeat_loop", -2.0, 0.1, "SFX")
	await wait(3.0)
	Sfx.play("static_burst", -4.0)
	await wait(0.1)
	dm.set_shader_parameter("amount", 0.0)
	dm.set_shader_parameter("protect", 1.0)
	Sfx.stop_loop("flesh_beat", 0.3)
	update_ambience(true)
	await wait(3.0)
	say("d5_antenna", 2)
	await overlay.wait_line("d5_antenna")
	say("d5_quit", 2)
	step = S.SLEEP
	control(true)


# ------------------------------------------------------------ Day 7
func _day7_blackout() -> void:
	G.f["d7_locked"] = true
	await wait(1.5)
	desktop.begin_blackout()
	Sfx.play("low_boom", 0.0)
	Sfx.loop("drone", "amb_drone", -6.0, 4.0, "SFX")
	await wait(7.0)
	overlay.red_center = Txt.red("d7_desktop")
	var tw := create_tween()
	tw.tween_property(overlay, "red_center_a", 1.0, 1.5)
	Sfx.play("red_sting", -2.0)
	await wait(2.0)
	say("d7_desktop", 2)
	await wait(6.0)
	tw = create_tween()
	tw.tween_property(overlay, "red_center_a", 0.0, 1.0)
	await tw.finished
	overlay.red_center = ""
	G.f["d7_locked"] = false
	desktop.force_close()
	await wait(1.0)
	_d7_wait = 0.0


func _day7_march() -> void:
	await _march_to_lake()


func _travel_forced(loc: String, x: float) -> void:
	Sfx.play("door_open", -6.0)
	await fade_to(1.0, 0.4)
	world.goto(loc, x, 1)
	update_ambience(true)
	await fade_to(0.0, 0.6)


## The lake. "sacrifice" for everyone who reaches the shore; "assimilate" only
## for the one the shed took on Day 5 (MYSTERY_BIBLE §6).
func _ending(kind: String = "sacrifice", keep_save: bool = false) -> void:
	main.set_mode("ending")
	overlay.show_hud = false
	overlay.show_prompt = false
	overlay.red_bottom = ""
	main.ending.play(world, kind)
	await main.ending.finished
	main.set_mode("cutscene")
	Sfx.stop_all_loops(0.5)
	overlay.fade = 1.0
	if kind == "assimilate":
		await wait(1.5)
		overlay.red_center = Txt.red("end_cycle")
		var tw := create_tween()
		tw.tween_property(overlay, "red_center_a", 1.0, 1.5)
		Sfx.play("deep_bell", -4.0)
		await wait(6.0)
		tw = create_tween()
		tw.tween_property(overlay, "red_center_a", 0.0, 1.5)
		await tw.finished
		overlay.red_center = ""
	await _finish_run(kind, keep_save)


## Every ending: the title, the credits, then what that ending leaves behind.
func _finish_run(kind: String, keep_save: bool = false) -> void:
	main.set_mode("cutscene")
	overlay.fade = 1.0
	G.persist["finished"] = true
	G.persist["last_ending"] = kind
	G.save_meta()
	if not keep_save:
		G.erase_save()
	await wait(2.0)
	overlay.title_text = Txt.red("title")
	Sfx.play("title_hit", 0.0)
	var tw := create_tween()
	tw.tween_property(overlay, "title_a", 1.0, 0.15)
	await wait(7.0)
	tw = create_tween()
	tw.tween_property(overlay, "title_a", 0.0, 2.0)
	await tw.finished
	overlay.title_text = ""
	await _credits()
	if kind == "escape":
		await _epilogue()
	await _show_cg(kind)
	await wait(1.0)
	overlay.fade = 0.0
	to_title()


## The last image of every ending: an illustration (assets/art/cg/).
## Assimilation plays its voicemail over it -- the next observer's first message.
func _show_cg(kind: String) -> void:
	if kind == "ufo":
		await _show_ufo_cgs()
		return
	overlay.cg = load("res://assets/art/cg/cg_%s.png" % kind)
	overlay.fade = 0.0
	overlay.black = 1.0
	Sfx.play("low_boom", -16.0)
	var tw := create_tween()
	tw.tween_property(overlay, "cg_a", 1.0, 3.0)
	await tw.finished
	if kind == "assimilate":
		await wait(2.0)
		Sfx.play("phone_beep", -6.0)
		await wait(1.2)
		overlay.subtitle_tag = Txt.ui("voicemail")
		Sfx.loop("tape", "tape_hiss", -20.0, 0.4)
		overlay.subtitle = Txt.phone()[0]
		await wait(maxf(4.0, read_time(overlay.subtitle) * 1.2 + 1.4))
		overlay.subtitle = ""
		overlay.subtitle_tag = ""
		Sfx.stop_loop("tape", 0.4)
		Sfx.play("phone_end", -8.0)
		await wait(2.5)
	else:
		_seq_skip = false
		var tt := 0.0
		while tt < 9.0 and not (_seq_skip and tt > 2.5):
			await get_tree().process_frame
			tt += get_process_delta_time()
	tw = create_tween()
	tw.tween_property(overlay, "cg_a", 0.0, 2.5)
	await tw.finished
	overlay.cg = null
	overlay.fade = 1.0
	overlay.black = 0.0


## The easter egg (slept through four days or more by the sixth night): the
## cabin roof gone, the bed in the beam -- 5 s; the saucer past the red body -- 3 s.
func _show_ufo_cgs() -> void:
	overlay.fade = 0.0
	overlay.black = 1.0
	overlay.cg_a = 1.0
	overlay.cg = load("res://assets/art/cg/cg_ufo_1.png")
	Sfx.play("low_boom", -16.0)
	await wait(5.0)
	overlay.cg = load("res://assets/art/cg/cg_ufo_2.png")
	await wait(3.0)
	overlay.cg = null
	overlay.cg_a = 0.0
	overlay.fade = 1.0
	overlay.black = 0.0


func _credits() -> void:
	for page in Txt.credits():
		overlay.credits = page
		var tw := create_tween()
		tw.tween_property(overlay, "credits_a", 1.0, 0.8)
		_seq_skip = false
		var tt := 0.0
		while tt < 4.5 and not _seq_skip:
			await get_tree().process_frame
			tt += get_process_delta_time()
		tw = create_tween()
		tw.tween_property(overlay, "credits_a", 0.0, 0.8)
		await tw.finished
	overlay.credits = []


## Escape: thirteen years later, someone else finds the site.
func _epilogue() -> void:
	main.set_grade(1)
	main.set_mode("ending")
	main.ending.play(world, "epilogue")
	overlay.caption = Txt.red("later")
	var tw := create_tween()
	tw.tween_property(overlay, "fade", 0.0, 2.0)
	tw.tween_property(overlay, "caption_a", 1.0, 1.0)
	tw.tween_interval(3.0)
	tw.tween_property(overlay, "caption_a", 0.0, 1.5)
	await main.ending.finished
	overlay.caption = ""
	overlay.fade = 1.0
	main.set_mode("cutscene")
	Sfx.stop_all_loops(1.0)


# ============================================================ sleep
## Days 1-6 the bed can be used at any time. With the day's work not done it
## asks first (E: sleep, Esc: back). Days slept through like that are counted;
## UFO_SKIPS or more by the sixth night, and the sixth night is the last.
const UFO_SKIPS := 4
var _bed_ask := false


func _use_bed() -> void:
	if step == S.END:
		say("d7_bed", 2)
		return
	if step != S.SLEEP:
		if G.day >= 7:
			if step == S.EXTRA:
				say(hint_for_step())
			else:
				wrong()
			return
		_bed_ask = true
		world.can_move = false
		overlay.show_prompt = false
		overlay.ask("bed_unfinished", Txt.ui("bed.ask"))
		return
	await _go_to_sleep(false)


func _bed_answer(sleep: bool) -> void:
	_bed_ask = false
	overlay.clear_mono()
	if not sleep:
		world.can_move = true
		overlay.show_prompt = true
		return
	await _go_to_sleep(true)


func _go_to_sleep(unfinished: bool) -> void:
	control(false)
	if unfinished:
		G.persist["skipped_days"] = int(G.persist.get("skipped_days", 0)) + 1
	else:
		match G.day:
			1: say("d1_sleep")
			2: say("d2_bed")
			3: say("d3_sleep")
			4: say("d4_sleep")
			5: say("d5_bed")
			6: say("d6_bed")
		await overlay.wait_quiet()
	Sfx.play("bed", -4.0)
	await fade_to(1.0, 1.6)
	Sfx.stop_all_loops(1.5)
	await wait(1.2)
	if G.day == 6 and int(G.persist.get("skipped_days", 0)) >= UFO_SKIPS:
		await _finish_run("ufo")
		return
	if G.day == 5:
		await _dream()
		return
	await start_day(G.day + 1)


func _dream() -> void:
	main.set_mode("dream")
	main.show_minigame_layer(true, false)
	main.mg.start_dream()
	overlay.fade = 0.0
	overlay.show_hud = false
	await main.mg.dream_done
	overlay.fade = 1.0
	main.show_minigame_layer(false, false)
	Sfx.stop_all_loops(0.2)
	await wait(2.0)
	await start_day(6)
