extends Node
## The three endings' conditions (docs/MYSTERY_BIBLE.md §3, §6), without
## playing a whole week: clue thresholds, the Morse key, save round trip.
##   godot --headless --path . res://tests/ending_test.tscn

var fails := 0


func ok(c: bool, what: String) -> void:
	print(("ok    " if c else "FAIL  ") + what)
	if not c:
		fails += 1


func _ready() -> void:
	G.new_game()
	G.day = 1
	ok(not G.can_escape(), "nothing found: no way out")
	for i in 7:
		G.add_clue(G.CLUES[i])
	ok(not G.add_clue(G.CLUES[0]), "a clue only counts once")
	ok(not G.add_clue("not_a_clue"), "unknown ids are ignored")
	G.persist["morse_solved"] = true
	ok(G.clue_count() == 7 and not G.can_escape(), "7 clues (70 %) + the number: the road brings him back")
	G.add_clue(G.CLUES[7])
	ok(G.clue_count() == 8 and G.can_escape(), "8 clues (80 %) + the number: the road out holds")
	G.persist["morse_solved"] = false
	G.add_clue(G.CLUES[8])
	G.add_clue(G.CLUES[9])
	ok(G.clue_count() == 10 and not G.can_escape(), "all ten without the number: no way out")
	G.persist["morse_solved"] = true
	ok(G.can_escape(), "all ten + the number")
	# the number and its format
	# the sealed record: thirteen years before Day 7, 23:40 (2023-11-14 start -> Day 7 2023-11-20)
	G.persist["start_unix"] = 1700000000
	ok(G.morse_code() == "201011202340" and G.sealed_id() == "2010-11-20-2340", "sealed: 13 years before Day 7, 23:40 (%s)" % G.sealed_id())
	ok(AppArchive.digits("2010-11-20-2340") == G.morse_code(), "the dashed number is the key")
	ok(AppArchive.digits("2010 11 20 23:40") == G.morse_code(), "separators do not matter")
	ok(Txt.story("{sid}") == "2010-11-20-2340", "the sealed number in the text")
	var digits := ""
	for d in G.morse_code():
		ok(Overlay.MORSE.has(d) and Overlay.MORSE[d].length() == 5, "digit %s has a 5-element code" % d)
		digits += d
	# years in the story text
	G.persist["start_unix"] = 1700000000   # 2023-11-14
	ok(G.cycle_year(0) == 2023 and G.cycle_year(1) == 2010 and G.cycle_year(-1) == 2036, "cycle years step by 13")
	ok(Txt.story("{y3} {y2} {y1} {yn}") == "1984 1997 2010 2036", "story tokens filled")
	ok(is_equal_approx(G.source_depth(1), 12.0) and is_equal_approx(G.source_depth(7), 0.0), "on the lakebed on Day 1, at the surface on Day 7")
	var prev_rise := 0.0
	var accel := true
	for d in range(2, 8):
		var rise := G.source_depth(d - 1) - G.source_depth(d)
		accel = accel and rise > prev_rise
		prev_rise = rise
	ok(accel, "and it rises faster every day")
	# the station clock: jumps forward only, and drives the chart's date
	G.begin_day(2)
	var c0 := G.clock_min
	G.clock_at_least(1620)
	G.clock_at_least(900)
	ok(is_equal_approx(G.clock_min, 16.0 * 60.0 + 20.0) and c0 < G.clock_min, "the clock only moves forward")
	ok(G.world_unix() % 86400 == (16 * 60 + 20) * 60 and G.clock_str() == "4:20 PM", "taskbar and chart share the time")
	# a save keeps the investigation
	G.day = 3
	G.save_game()
	G.new_game()
	ok(G.clue_count() == 0, "new game forgets")
	ok(G.load_game() and G.clue_count() == 10 and bool(G.persist["morse_solved"]), "load restores the clues and the number")
	G.erase_save()
	# every clue has a note in both languages
	for lang in ["en", "zh"]:
		G.settings["lang"] = lang
		for id in G.CLUES:
			ok(Txt.clue_note(id) != "", "%s note: %s" % [lang, id])
		for id in ["rumor", "not_weather", "prev_notes", "last_record", "sealed"]:
			ok(Txt.doc(id).size() >= 3, "%s document: %s" % [lang, id])
		ok(Txt.credits()[0] == ["", "A GAME BY LUCIA"], "%s credits open with: A GAME BY LUCIA" % lang)
		ok(Txt.credits()[1].has("GLM 5.3 Flash") and Txt.credits()[1].has("ChatGPT 6.1 Sol"), "%s credits list the AI members" % lang)
	G.settings["lang"] = "en"
	print("ENDINGS %s" % ("PASS" if fails == 0 else "FAIL"))
	get_tree().quit(0 if fails == 0 else 1)
