extends Node
## Visual review harness. Run windowed:
##   godot --path . --resolution 1280x720 res://tests/shots.tscn [-- set=name]
## Writes PNGs to user://shots (and prints their paths).

var main: Node
var out := "res://tests/_shots/"
var only := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("set="):
			only = a.substr(4)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _f(10)
	if only == "" or only == "base":
		await _base()
	if only == "" or only == "desk":
		await _desk()
	if only == "" or only == "mini":
		await _mini()
	if only == "" or only == "end":
		await _end()
	if only == "" or only == "lake":
		await _lake()
	if only == "" or only == "zh":
		await _zh()
	if only == "" or only == "story":
		G.set_lang("en")
		await _story()
	if only == "v2":
		await _v2()
	if only == "v4":
		G.set_lang("zh")
		await _v4()
		G.set_lang("en")
	if only == "story_zh":
		G.set_lang("zh")
		await _story()
		G.set_lang("en")
	print("SHOTS DONE")
	get_tree().quit()


func _f(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func shot(name: String) -> void:
	await _f(3)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var p := ProjectSettings.globalize_path(out + name + ".png")
	img.save_png(p)
	print("SHOT ", p)


func setup(day: int, loc: String, x: float, phase: float, facing: int = 1) -> void:
	main.menu.page = ""
	get_tree().paused = false
	G.begin_day(day)
	main.set_grade(day)
	main.overlay.fade = 0.0
	main.overlay.card_day = 0
	main.overlay.show_hud = true
	main.world.goto(loc, x, facing)
	main.world._apply_phase(phase)
	main.set_mode("world")
	main.world.can_move = false
	await _f(4)


func _base() -> void:
	main.menu.page = "title"
	main.menu._build()
	await _f(20)
	await shot("menu")
	await setup(1, "outdoor", 104, 0.0)
	await shot("d1_truck")
	await setup(1, "outdoor", 300, 0.0)
	await shot("d1_tower")
	await setup(1, "outdoor", 540, 1.0)
	await shot("d1_shed_dusk")
	await setup(1, "outdoor", 760, 2.0)
	await shot("d1_antenna_night")
	await setup(2, "outdoor", 985, 0.0)
	await shot("d2_lake_ice")
	await setup(1, "cab", 300, 0.0, -1)
	await shot("cab_day")
	await setup(1, "cab", 340, 2.0, 1)
	await shot("cab_night")
	await setup(4, "cab", 280, 2.0, 1)
	await shot("cab_d4")
	await setup(1, "shed", 210, 1.0)
	await shot("shed")
	await setup(5, "outdoor", 700, 2.0)
	await shot("d5_blizzard")
	await setup(6, "outdoor", 320, 1.0)
	await _f(30)
	await shot("d6_flesh")
	await setup(6, "cab", 300, 2.0)
	await _f(30)
	await shot("d6_cab")
	await setup(7, "outdoor", 900, 2.0)
	await shot("d7_lake")
	# the road
	await setup(1, "road", 0, 0.42)
	await _f(60)
	main.overlay.subtitle = Txt.phone()[1]
	main.overlay.subtitle_tag = "VOICEMAIL  -  1 NEW MESSAGE"
	await shot("prologue")
	main.overlay.subtitle = ""
	main.overlay.subtitle_tag = ""
	# monologue + prompt
	await setup(1, "outdoor", 340, 0.0)
	main.overlay.say("d2_game_hint", 2)
	await _f(90)
	await shot("mono_prompt")
	main.overlay.clear_mono()
	# day cards
	for d in [1, 4, 6, 7]:
		main.overlay.card_day = d
		main.overlay.card_a = 1.0
		G.day = d
		await shot("card_%d" % d)
	main.overlay.card_day = 0
	# antenna panel
	await setup(1, "outdoor", 760, 2.0)
	main.overlay.panel = "aim"
	main.overlay.aim = {"az": 120.0, "err": 20.0, "locked": false}
	await shot("aim")
	main.overlay.panel = "wire"
	main.overlay.wire = {"colors": [Color8(200, 50, 50), Color8(230, 200, 70), Color8(70, 120, 220)], "sockets": [Color8(70, 120, 220), Color8(200, 50, 50), Color8(230, 200, 70)], "links": [1, -1, -1], "sel": 1, "target": 2, "flesh": false}
	await shot("wire")
	main.overlay.panel = ""


func _desk() -> void:
	await setup(3, "cab", 372, 2.0)
	main.flow.step = Flow.S.CHART
	main.set_mode("desktop")
	main.desktop.open_for_today()
	main.desktop.boot_t = -1.0
	await shot("desk_day3")
	main.desktop.launch("notice")
	await shot("desk_notice")
	main.desktop.launch("chart")
	await _f(10)
	await shot("desk_chart")
	main.desktop.launch("report")
	await shot("desk_report")
	main.desktop.boot_t = 0.4
	await shot("desk_boot")
	main.desktop.boot_t = 2.0
	await shot("desk_boot2")
	main.desktop.boot_t = -1.0
	await setup(7, "cab", 372, 2.0)
	main.flow.step = Flow.S.CHART
	main.set_mode("desktop")
	main.desktop.open_for_today()
	main.desktop.boot_t = -1.0
	main.desktop.launch("chart")
	await _f(10)
	await shot("desk_chart_d7")
	main.desktop.start_open = true
	await shot("desk_start")
	main.desktop.start_open = false
	main.desktop.force_close()
	await _f(10)


func _mini() -> void:
	await setup(2, "cab", 372, 2.0)
	main.set_mode("desktop")
	main.desktop.open_for_today()
	main.desktop.boot_t = -1.0
	main.desktop._start_game()
	await _f(10)
	await shot("mini_title_d2")
	main.mg._begin_run()
	await _f(240)
	await shot("mini_run_d2")
	main.mg.stop()
	main.desktop.game_on = false
	for d in [4, 6]:
		G.day = d
		main.mg.start_desktop()
		await _f(10)
		await shot("mini_title_d%d" % d)
	main.mg.stop()
	main.mg.start_dream()
	main.set_mode("dream")
	main.show_minigame_layer(true, false)
	main.mg._begin_run()
	main.mg.run_t = 39.0
	await _f(200)
	await shot("mini_dream_church")
	main.mg.mode = "temple"
	main.mg.church_x = 150
	main.mg.fig_k = 0.6
	await shot("mini_temple")
	main.mg.stop()


func _lake() -> void:
	await setup(1, "outdoor", 990, 0.0)
	await shot("lake_d1")
	await setup(1, "outdoor", 900, 1.0)
	await shot("lake_d1_dusk")
	await setup(2, "outdoor", 984, 2.0)
	await shot("lake_d2_frozen")
	await setup(5, "outdoor", 984, 2.0)
	await shot("lake_d5")
	await setup(6, "outdoor", 960, 2.0)
	await _f(20)
	await shot("lake_d6")


func _zh() -> void:
	G.set_lang("zh")
	main.menu.page = "settings"
	main.menu._back_page = "title"
	main.menu._build()
	await _f(10)
	await shot("zh_settings")
	main.menu.page = "title"
	main.menu._build()
	await shot("zh_title")
	await setup(1, "outdoor", 340, 0.0)
	main.overlay.say("d1_check_computer", 2)
	main.overlay.show_tip(Txt.ui("tip.walk"), 5.0)
	await _f(150)
	await shot("zh_mono")
	main.overlay.clear_mono()
	main.overlay.panel = "aim"
	main.overlay.aim = {"az": 120.0, "err": 20.0, "locked": false}
	await shot("zh_aim")
	main.overlay.panel = ""
	await setup(3, "cab", 372, 2.0)
	main.flow.step = Flow.S.REPORT
	main.set_mode("desktop")
	main.desktop.open_for_today()
	main.desktop.boot_t = -1.0
	main.desktop.launch("notice")
	await shot("zh_desk_notice")
	main.desktop.launch("chart")
	await _f(5)
	await shot("zh_desk_chart")
	main.desktop.launch("report")
	await shot("zh_desk_report")
	main.desktop.start_open = true
	await shot("zh_desk_start")
	main.desktop.start_open = false
	main.desktop.force_close()
	await _f(5)
	main.overlay.card_day = 7
	main.overlay.card_a = 1.0
	G.day = 7
	await shot("zh_card7")
	main.overlay.card_day = 0
	main.set_mode("cutscene")
	main.overlay.fade = 1.0
	main.overlay.red_center = Txt.red("d7_desktop")
	main.overlay.red_center_a = 1.0
	await shot("zh_red")
	main.overlay.red_center = ""
	main.overlay.title_text = Txt.red("title")
	main.overlay.title_a = 1.0
	await shot("zh_title_end")
	main.overlay.title_text = ""
	main.overlay.fade = 0.0
	G.set_lang("en")


## Playtest report 2026-11-16: the hill, footprints, section, dream key, chart.
## The last round (修改建议和方案.docx): archive, sealed record, locker, bed, hilltop hint.
func _v4() -> void:
	G.new_game()
	await setup(6, "cab", 372, 2.0)
	main.set_mode("desktop")
	main.desktop.open_for_today()
	main.desktop.boot_t = -1.0
	main.desktop.launch("archive")
	await shot("v4_archive")
	main.desktop.open_app(AppText.new(Txt.ui("archive.rec_title") % G.sealed_id(), Txt.doc("sealed"), Vector2(400, 290)), "sealed")
	await shot("v4_sealed")
	main.desktop.force_close()
	await setup(4, "boathouse", 208, 1.0)
	main.flow.read_doc("prev_notes", "prev_notes")
	await shot("v4_locker")
	main.overlay.panel = ""
	await setup(3, "cab", 275, 1.0)
	main.flow.interact("bed")
	await get_tree().create_timer(2.5).timeout
	await shot("v4_bed")
	main.flow._bed_answer(false)
	await setup(1, "peak", World.FENCE_X - 8.0, 2.0)
	await get_tree().create_timer(3.0).timeout
	print("VISTA a=%.2f cam_off=%.1f off=%s loc=%s mode=%s x=%.0f" % [main.overlay.vista_a, main.world.cam_off, main.flow._vista_off, main.world.loc, main.mode, main.world.player.position.x])
	await shot("v4_vista")


func _v2() -> void:
	G.new_game()
	await setup(1, "boathouse", 200, 1.0)
	await shot("v3_boathouse_d1")
	await setup(7, "boathouse", 150, 2.0)
	await _f(20)
	await shot("v3_boathouse_d7")
	await setup(7, "outdoor", 70, 2.0)
	main.flow._wire = {"colors": [Color8(200, 50, 50), Color8(230, 200, 70), Color8(70, 120, 220)], "sockets": [Color8(230, 200, 70), Color8(70, 120, 220), Color8(200, 50, 50)], "order": [1, 2, 0], "links": [-1, 0, -1], "sel": 2, "target": 1, "flesh": true, "purpose": "truck", "title": Txt.ui("ignition.title")}
	main.overlay.wire = main.flow._wire
	main.overlay.panel = "wire"
	await shot("v3_ignition")
	main.overlay.panel = ""
	main.set_mode("cutscene")
	main.overlay.fade = 1.0
	main.overlay.title_text = Txt.red("title")
	main.overlay.title_a = 1.0
	await shot("v3_title")
	main.overlay.title_text = ""
	main.overlay.fade = 0.0
	main.mg.start_desktop()
	main.set_mode("desktop")
	main.show_minigame_layer(true, true)
	await _f(10)
	await shot("v3_homeward")
	main.mg.stop()
	main.show_minigame_layer(false, true)
	await setup(2, "climb", 300, 1.6)
	await _f(20)
	await shot("v2_climb")
	await setup(2, "outdoor", 690, 0.0)
	await shot("v2_prints_d2")
	await setup(4, "outdoor", 400, 0.0)
	await shot("v2_prints_d4")
	await setup(1, "peak", 320, 2.0)
	await shot("v2_summit")
	G.persist["surveys"] = [{"day": 1, "depth": 12.0}, {"day": 3, "depth": G.source_depth(3)}, {"day": 5, "depth": G.source_depth(5)}]
	await setup(5, "cab", 372, 2.0)
	main.set_mode("desktop")
	main.desktop.open_for_today()
	main.desktop.boot_t = -1.0
	main.desktop.open_app(AppSurvey.new(5, G.source_depth(5)), "survey_5")
	await shot("v2_survey_d5")
	main.desktop.force_close()
	await get_tree().create_timer(1.5).timeout
	await setup(7, "cab", 372, 2.0)
	main.flow.step = Flow.S.CHART
	main.set_mode("desktop")
	main.desktop.open_for_today()
	main.desktop.boot_t = -1.0
	main.desktop.launch("chart")
	await _f(10)
	await shot("v2_chart_d7")
	main.desktop.force_close()
	await get_tree().create_timer(1.5).timeout
	main.mg.start_dream()
	main.set_mode("dream")
	main.show_minigame_layer(true, false)
	main.mg._begin_run()
	main.mg.score = 5000
	main.mg.rocks.clear()
	while main.mg.mode != "temple":
		await get_tree().process_frame
	main.mg.fig_k = 1.0
	while main.mg.door_t < 2.9:
		await get_tree().process_frame
	await shot("v2_dream_key")
	main.mg.stop()


## The investigation layer and the three endings (MYSTERY_BIBLE).
func _story() -> void:
	var p := "story_" if G.settings["lang"] == "en" else "story_zh_"
	var fl: Flow = main.flow
	var ov: Overlay = main.overlay
	G.new_game()
	await setup(1, "outdoor", 150, 0.0)
	await shot(p + "sign_world")
	fl.read_doc("rumor")
	await shot(p + "doc_rumor")
	fl.close_doc()
	await setup(3, "outdoor", 470, 0.0, -1)
	await shot(p + "footprints")
	await setup(1, "outdoor", 925, 1.0)
	await shot(p + "stakes")
	fl.step = Flow.S.SURVEY
	fl._open_sonar("stake_boat")
	ov.sonar["az"] = fl.survey_bearing("stake_boat") + 14.0
	ov.sonar["pings"] = [[40.0, 0.0], [60.0, 0.3], [fl.survey_bearing("stake_boat") + 14.0, 0.14]]
	ov.sonar["trace"] = {"t": 2.0, "s": 0.6, "range": fl.survey_range("stake_boat"), "seed": 4, "struct": true}
	await shot(p + "sonar")
	fl._sonar = false
	fl._panel_close()
	await setup(6, "outdoor", 700, 2.0)
	await _f(30)
	await shot(p + "aurora_d6")
	await setup(5, "cab", 452, 2.0)
	await shot(p + "cab_radio")
	G.f["radio_on"] = true
	fl._use_radio()
	G.settings["assist"] = 1
	fl._radio_t = 20.0
	await _f(20)
	await shot(p + "radio")
	fl._panel_close()
	G.f["radio_on"] = false
	G.settings["assist"] = 0
	await setup(4, "shed", 330, 1.0)
	await shot(p + "shed_bench")
	fl.read_doc("prev_notes")
	await shot(p + "doc_prev")
	fl.close_doc()
	await setup(7, "outdoor", 734, 2.0)
	fl._wire = {"colors": [Color8(200, 50, 50), Color8(230, 200, 70), Color8(70, 120, 220)], "sockets": [Color8(70, 120, 220), Color8(200, 50, 50), Color8(230, 200, 70)], "order": [2, 0, 1], "links": [1, 2, -1], "sel": 1, "target": 0, "flesh": true, "cut": true, "pulled": [2]}
	ov.wire = fl._wire
	fl._panel_open("wire")
	await shot(p + "cut")
	fl._panel_close()
	# desktop: notes, archive, survey map, future log
	for id in G.CLUES.slice(0, 6):
		G.add_clue(id)
	G.persist["surveys"] = [{"day": 1, "depth": 38}, {"day": 2, "depth": 38}, {"day": 3, "depth": 31}, {"day": 5, "depth": 9}]
	G.persist["answers"] = ["no", "no", "yes", "yes", "yes"]
	await setup(6, "cab", 372, 2.0)
	main.set_mode("desktop")
	main.desktop.open_for_today()
	main.desktop.boot_t = -1.0
	await shot(p + "desk_icons")
	main.desktop.launch("notes")
	await shot(p + "desk_notes")
	main.desktop.force_close()
	main.set_mode("desktop")
	main.desktop.open_for_today()
	main.desktop.boot_t = -1.0
	main.desktop.launch("archive")
	var ar: AppArchive = main.desktop.wins[-1]["app"]
	ar.text = G.sealed_id().substr(0, 10)
	await shot(p + "desk_archive")
	main.desktop.open_app(AppSurvey.new(5, 9), "survey_5")
	await shot(p + "desk_survey")
	main.desktop.launch("mydocs")
	await shot(p + "desk_mydocs")
	main.desktop.open_app(AppText.new(Txt.ui("obslog.title") % Desktop.future_date(1), main.desktop.future_log_lines(), Vector2(400, 220)), "obslog")
	await shot(p + "desk_obslog")
	main.desktop.launch("log")
	await shot(p + "desk_log_d6")
	main.desktop.open_app(AppText.new("sealed", Txt.doc("sealed"), Vector2(400, 290)), "sealed")
	await shot(p + "desk_sealed")
	main.desktop.force_close()
	# every pending desktop close finishes in under a second of real time
	await get_tree().create_timer(1.5).timeout
	# assimilation
	await setup(7, "outdoor", 984, 2.0)
	main.set_mode("ending")
	main.ending.play(main.world, "assimilate")
	for tt in [8.0, 16.0, 26.0, 34.0, 41.0]:
		while main.ending.t < tt:
			await get_tree().process_frame
		await shot(p + "assim_%02d" % int(tt))
	main.ending.t = 48.0
	await _f(30)
	main.set_mode("cutscene")
	ov.fade = 1.0
	G.day = 7
	ov.red_center = Txt.red("end_cycle")
	ov.red_center_a = 1.0
	await shot(p + "assim_red")
	ov.red_center = ""
	ov.credits = Txt.credits()[1]
	ov.credits_a = 1.0
	await shot(p + "credits")
	ov.credits = []
	# escape road and the epilogue
	await setup(7, "road", 0, 2.0)
	main.world.sky.aurora = 0.7
	main.world.sky.object_size = 30.0
	main.world._apply_phase(1.4)
	main.set_mode("cutscene")
	await _f(30)
	await shot(p + "escape_road")
	main.set_grade(1)
	main.set_mode("ending")
	main.ending.play(main.world, "epilogue")
	ov.caption = Txt.red("later")
	ov.caption_a = 1.0
	while main.ending.t < 3.0:
		await get_tree().process_frame
	await shot(p + "epilogue_03")
	ov.caption = ""
	while main.ending.t < 16.0:
		await get_tree().process_frame
	await shot(p + "epilogue_16")
	main.ending.t = 22.5
	await _f(10)
	main.set_mode("cutscene")
	ov.fade = 0.0


func _end() -> void:
	await setup(7, "outdoor", 984, 2.0)
	main.set_mode("ending")
	main.ending.play(main.world)
	for tt in [2.0, 12.0, 24.0, 38.0]:
		while main.ending.t < tt:
			await get_tree().process_frame
		await shot("end_%02d" % int(tt))
	main.ending.t = 49.0
	await _f(30)
	main.set_mode("cutscene")
	main.overlay.fade = 1.0
	main.overlay.title_text = Txt.red("title")
	main.overlay.title_a = 1.0
	await shot("end_title")
	main.overlay.title_text = ""
	main.overlay.fade = 0.0
