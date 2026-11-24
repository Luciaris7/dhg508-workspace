extends Node
## TV-10 acceptance: geocentric ecliptic longitudes vs Astronomy Engine
## reference points (36 dates, 1985-2119). Must be < 0.1 deg for every body.
##   godot --headless --path . res://tests/ephem_test.tscn

func _ready() -> void:
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/ephem_check.json"))
	var worst := {}
	var t0 := Time.get_ticks_usec()
	for row in rows:
		var pos := Ephemeris.positions(float(row["ut"]))
		for n in (row["lon"] as Dictionary).keys():
			var err := absf(wrapf(float(pos[n].x) - float(row["lon"][n]), -180.0, 180.0))
			worst[n] = maxf(float(worst.get(n, 0.0)), err)
	var us := (Time.get_ticks_usec() - t0) / float(rows.size())
	var fail := false
	for n in worst.keys():
		print("EPHEM %-8s max error %.4f deg" % [n, worst[n]])
		if worst[n] >= 0.1:
			fail = true
	print("EPHEM %s | %d dates, %.2f ms per full chart" % ["PASS" if not fail else "FAIL", rows.size(), us / 1000.0])
	get_tree().quit(1 if fail else 0)
