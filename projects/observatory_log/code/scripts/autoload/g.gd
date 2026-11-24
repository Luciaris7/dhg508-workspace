extends Node
## Global state: the current day, per-day flags, persistent history, settings,
## save/load, fonts and shared materials.

signal settings_changed

const SAVE_PATH := "user://save.json"
const SETTINGS_PATH := "user://settings.json"
const SAVE_VERSION := 2

## The ten key clues (docs/MYSTERY_BIBLE.md §3). Order = notes order.
const CLUES := ["rumor", "not_weather", "footprints", "echo_hollow", "red_body",
	"future_log", "prev_notes", "echo_aurora", "autocorrect", "last_record"]
const CLUES_FOR_GOOD := 8      # 80 % of the ten
## The one hidden number: cycle 03, site 07, day 07, 23:40.
## The sealed record: left on the previous observer's seventh night, thirteen
## years before this cycle's Day 7, at 23:40. Its number is what the radio
## sends on the fifth night: YYYY MM DD HHMM.
const SEALED_TIME := "2340"


func sealed_date() -> Dictionary:
	var d := Time.get_datetime_dict_from_unix_time(day_unix(7))
	var y := int(d["year"]) - 13
	var m := int(d["month"])
	var dd := int(d["day"])
	if m == 2 and dd == 29:
		dd = 28
	return {"year": y, "month": m, "day": dd}


func morse_code() -> String:
	var d := sealed_date()
	return "%04d%02d%02d%s" % [d["year"], d["month"], d["day"], SEALED_TIME]


func sealed_id() -> String:
	var c := morse_code()
	return "%s-%s-%s-%s" % [c.substr(0, 4), c.substr(4, 2), c.substr(6, 2), c.substr(8, 4)]

const WORLD_W := 320
const WORLD_H := 180
const SCREEN_W := 640
const SCREEN_H := 360
const GROUND_Y := 153

var font: PixelFont
var font_en: PixelFont
var day_fonts: Array = []
var day_fonts_en: Array = []

var day := 1
## Outdoor time of day: "day", "dusk", "night".
var tod := "day"
## Per-day flags; cleared at the start of every day.
var f := {}
## Survives across days and is saved.
var persist := {}
var settings := {
	"master": 0.8, "music": 0.8, "sfx": 0.9, "amb": 0.9,
	"flash": true, "tear": true, "fullscreen": false, "text_speed": 1.0, "lang": "en",
	"assist": 0,   # radio puzzle: 0 off, 1 show dots/dashes, 2 show digits
}

var rng := RandomNumberGenerator.new()
var flesh_mat: ShaderMaterial
var debug := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	debug = OS.is_debug_build()
	_setup_input()
	if not FileAccess.file_exists(SETTINGS_PATH):
		settings["lang"] = "zh" if OS.get_locale_language() == "zh" else "en"
	flesh_mat = ShaderMaterial.new()
	flesh_mat.shader = load("res://shaders/world.gdshader")
	flesh_mat.set_shader_parameter("amount", 0.0)
	load_settings()
	_load_fonts()
	reset_persist()


var _loaded_lang := ""
## Big text scale: English 5x8 glyphs are drawn at 2x, Chinese 12px glyphs at 1x.
var bs := 2


func _load_fonts() -> void:
	var lang := String(settings.get("lang", "en"))
	if lang == _loaded_lang:
		return
	_loaded_lang = lang
	var sfx := "_zh" if lang == "zh" else ""
	if font_en == null:
		font_en = PixelFont.load_font("ui")
		day_fonts_en = [null]
		for i in range(1, 8):
			day_fonts_en.append(PixelFont.load_font("day%d" % i))
	font = PixelFont.load_font("ui" + sfx)
	day_fonts = [null]
	for i in range(1, 8):
		day_fonts.append(PixelFont.load_font("day%d%s" % [i, sfx]))
	bs = 1 if lang == "zh" else 2


func set_lang(lang: String) -> void:
	settings["lang"] = lang
	_load_fonts()
	save_settings()


func _setup_input() -> void:
	var map := {
		"left": [KEY_A, KEY_LEFT],
		"right": [KEY_D, KEY_RIGHT],
		"up": [KEY_W, KEY_UP],
		"down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E, KEY_ENTER, KEY_SPACE],
		"pause": [KEY_ESCAPE],
	}
	for action in map.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)


func day_font(n: int = -1) -> PixelFont:
	if n < 1:
		n = day
	return day_fonts[clampi(n, 1, 7)]


# ------------------------------------------------------------------ state
func reset_persist() -> void:
	persist = {
		"answers": [],        # one "yes"/"no" per finished day
		"marks_hit": [],      # days on which the player marked the unknown object
		"records": [],        # [{day, marks:[[x,y]...]}]
		"best": int(persist.get("best", 0)) if persist.has("best") else 0,
		"start_unix": int(Time.get_unix_time_from_system()),
		"games_played": 0,
		"seen": {},
		"finished": bool(persist.get("finished", false)) if persist.has("finished") else false,
		"clues": {},          # id -> day found
		"surveys": [],        # [{day, depth}] one per finished lake survey
		"has_receiver": false,
		"morse_heard": false,
		"morse_solved": false,
	}


func new_game() -> void:
	var keep_best := int(persist.get("best", 0))
	var keep_fin := bool(persist.get("finished", false))
	reset_persist()
	persist["best"] = keep_best
	persist["finished"] = keep_fin
	day = 1


func begin_day(n: int) -> void:
	day = n
	f = {}
	tod = "night" if n == 7 else "day"
	clock_min = 21.0 * 60.0 + 30.0 if n == 7 else 7.0 * 60.0 + 40.0
	# the antenna's correct azimuth: fresh every day, never reused
	rng.seed = int(persist.get("start_unix", 0)) * 7 + n * 7919
	var target := rng.randf_range(20.0, 340.0)
	f["antenna_target"] = target
	var off := rng.randf_range(70.0, 150.0) * (1.0 if rng.randf() < 0.5 else -1.0)
	f["antenna_start"] = fposmod(target + off, 360.0)


func seen(key: String) -> bool:
	return bool(persist["seen"].get(key, false))


func mark_seen(key: String) -> void:
	persist["seen"][key] = true


func once(key: String) -> bool:
	## True the first time it is called for this key (persisted).
	if seen(key):
		return false
	mark_seen(key)
	return true


func today_once(key: String) -> bool:
	if f.get("once_" + key, false):
		return false
	f["once_" + key] = true
	return true


func answers() -> Array:
	return persist["answers"]


func streak(ans: String) -> int:
	var n := 0
	var a: Array = persist["answers"]
	for i in range(a.size() - 1, -1, -1):
		if a[i] == ans:
			n += 1
		else:
			break
	return n


## ------------------------------------------------------------- the mystery
func add_clue(id: String) -> bool:
	## Saves a clue to the investigation notes. True only the first time.
	if not CLUES.has(id) or has_clue(id):
		return false
	persist["clues"][id] = day
	return true


func has_clue(id: String) -> bool:
	return (persist["clues"] as Dictionary).has(id)


func clue_count() -> int:
	return (persist["clues"] as Dictionary).size()


## The road out holds only for someone who opened the sealed record (the radio's
## number) and found at least 80 % of the clues. Anyone else is brought back.
func can_escape() -> bool:
	return bool(persist.get("morse_solved", false)) and clue_count() >= CLUES_FOR_GOOD


## The cycle year (the year of the in-game calendar); k cycles back (k>0) or ahead (k<0).
func cycle_year(k: int = 0) -> int:
	var y := int(Time.get_datetime_dict_from_unix_time(day_unix(1))["year"])
	return y - 13 * k


## Depth of the top of the structure under the lake, metres. Day 1 it lies on
## the bottom (12 m); it rises faster every day and breaks the surface on Day 7.
const LAKE_DEPTH := 12.0


func source_depth(d: int = -1) -> float:
	if d < 1:
		d = day
	var k := clampf((d - 1) / 6.0, 0.0, 1.0)
	return snappedf(LAKE_DEPTH * (1.0 - k * k), 0.1)


# ------------------------------------------------------------ world clock
## Minutes since midnight of today's in-game date. Shown by the taskbar clock
## and the star chart. Moves on by itself and jumps forward at the day's beats.
var clock_min := 460.0
const CLOCK_RATE := 0.5      # in-game minutes per real second


func clock_at_least(hhmm: int) -> void:
	clock_min = maxf(clock_min, float(int(hhmm / 100.0) * 60 + hhmm % 100))


func tick_clock(dt: float) -> void:
	clock_min = minf(clock_min + dt * CLOCK_RATE, 23.0 * 60.0 + 58.0)


func world_unix() -> int:
	var u := day_unix()
	return u - posmod(u, 86400) + int(clock_min * 60.0)


func clock_str() -> String:
	var h := int(clock_min / 60.0)
	return "%d:%02d %s" % [((h + 11) % 12) + 1, int(clock_min) % 60, "PM" if h >= 12 else "AM"]


## The calendar date the star chart shows for game day n (real date of the
## first session, plus one day per game day).
func day_unix(n: int = -1) -> int:
	if n < 1:
		n = day
	return int(persist.get("start_unix", Time.get_unix_time_from_system())) + (n - 1) * 86400


## Environment by day -- the world itself changes, nobody is introduced.
func env(key: String) -> Variant:
	var d := day
	match key:
		"snow":        return d != 5
		"storm":       return d == 5
		"breath":      return d >= 2
		"ice":         return d == 2
		"frost":       return clampf((d - 2) / 4.0, 0.0, 1.0)
		"plant":       return 0 if d <= 2 else (1 if d == 3 else (2 if d <= 5 else 3))
		"stain":       return clampf((d - 3) / 3.0, 0.0, 1.0)
		"water_red":   return [0.0, 0.0, 0.0, 0.0, 0.25, 0.6, 1.0, 1.0][d]
		"slush":       return d >= 6
		"bare_trees":  return d >= 6
		"flesh":       return [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.58, 0.8][d]
		"sky_object":  return [0.0, 0.0, 0.0, 0.0, 0.0, 3.0, 9.0, 60.0][d]
		"aurora":      return [0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.6, 0.9][d]
		# bare footprints from the lake: how far toward the door they reach (0 = none)
		"footprints":  return [0.0, 0.0, 640.0, 450.0, 372.0, 0.0, 0.0, 0.0][d]
	return null


# ------------------------------------------------------------------- save
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var data := {"version": SAVE_VERSION, "day": day, "persist": persist}
	var tmp := SAVE_PATH + ".tmp"
	var fa := FileAccess.open(tmp, FileAccess.WRITE)
	if fa == null:
		return
	fa.store_string(JSON.stringify(data))
	fa.close()
	var dir := DirAccess.open("user://")
	if dir:
		if dir.file_exists("save.json"):
			if dir.file_exists("save.bak"):
				dir.remove("save.bak")
			dir.rename("save.json", "save.bak")
		dir.rename("save.json.tmp", "save.json")


func load_game() -> bool:
	for path in [SAVE_PATH, "user://save.bak"]:
		if not FileAccess.file_exists(path):
			continue
		var txt := FileAccess.get_file_as_string(path)
		var data: Variant = JSON.parse_string(txt)
		if typeof(data) != TYPE_DICTIONARY or not data.has("day") or not data.has("persist"):
			continue
		day = clampi(int(data["day"]), 1, 7)
		var p: Dictionary = data["persist"]
		reset_persist()
		for k in p.keys():
			persist[k] = p[k]
		return true
	return false


func save_meta() -> void:
	## Persist cross-run things (best score, finished) without a run in progress.
	var fa := FileAccess.open("user://meta.json", FileAccess.WRITE)
	if fa:
		fa.store_string(JSON.stringify({"best": persist.get("best", 0), "finished": persist.get("finished", false),
			"last_ending": persist.get("last_ending", ""), "retry_day": persist.get("retry_day", 0)}))


func load_meta() -> void:
	if FileAccess.file_exists("user://meta.json"):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("user://meta.json"))
		if typeof(d) == TYPE_DICTIONARY:
			persist["best"] = int(d.get("best", 0))
			persist["finished"] = bool(d.get("finished", false))
			persist["last_ending"] = String(d.get("last_ending", ""))
			persist["retry_day"] = int(d.get("retry_day", 0))


func erase_save() -> void:
	var dir := DirAccess.open("user://")
	if dir:
		for n in ["save.json", "save.bak"]:
			if dir.file_exists(n):
				dir.remove(n)


# --------------------------------------------------------------- settings
func load_settings() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
		if typeof(d) == TYPE_DICTIONARY:
			for k in d.keys():
				if settings.has(k):
					settings[k] = d[k]
	load_meta()
	apply_settings()


func save_settings() -> void:
	var fa := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if fa:
		fa.store_string(JSON.stringify(settings))
	apply_settings()


func apply_settings() -> void:
	if not Engine.is_editor_hint():
		var want_fs: bool = settings["fullscreen"]
		var mode := DisplayServer.window_get_mode()
		var is_fs := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		if want_fs and not is_fs:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		elif not want_fs and is_fs:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	settings_changed.emit()
