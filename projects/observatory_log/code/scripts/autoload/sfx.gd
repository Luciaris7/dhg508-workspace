extends Node
## Audio: one-shot pool, named loop channels with crossfades, four buses
## (Music / SFX / Amb / Mono), and a muffle filter for when the player is
## looking at the monitor. All assets are synthesized by tools/gen_audio.py.

const DIRS := ["res://assets/audio/sfx/", "res://assets/audio/amb/", "res://assets/audio/music/"]

var _pool: Array[AudioStreamPlayer] = []
var _loops := {}
var _cache := {}
var _lowpass: AudioEffectLowPassFilter
var _muffled := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for b in ["Music", "SFX", "Amb"]:
		if AudioServer.get_bus_index(b) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, b)
			AudioServer.set_bus_send(i, "Master")
	_lowpass = AudioEffectLowPassFilter.new()
	_lowpass.cutoff_hz = 900.0
	var amb := AudioServer.get_bus_index("Amb")
	AudioServer.add_bus_effect(amb, _lowpass)
	AudioServer.set_bus_effect_enabled(amb, 0, false)
	for i in 24:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	G.settings_changed.connect(apply_volumes)
	apply_volumes()


func apply_volumes() -> void:
	_set_bus("Master", float(G.settings["master"]))
	_set_bus("Music", float(G.settings["music"]))
	_set_bus("SFX", float(G.settings["sfx"]))
	_set_bus("Amb", float(G.settings["amb"]))


func _set_bus(n: String, lin: float) -> void:
	var i := AudioServer.get_bus_index(n)
	if i >= 0:
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(lin, 0.0001)))
		AudioServer.set_bus_mute(i, lin <= 0.001)


func stream(n: String) -> AudioStream:
	if _cache.has(n):
		return _cache[n]
	var s: AudioStream = null
	for d in DIRS:
		var p: String = d + n + ".wav"
		if ResourceLoader.exists(p):
			s = load(p)
			break
	_cache[n] = s
	return s


func play(n: String, vol_db: float = 0.0, pitch: float = 1.0, bus: String = "SFX") -> AudioStreamPlayer:
	var s := stream(n)
	if s == null:
		return null
	var p: AudioStreamPlayer = null
	for q in _pool:
		if not q.playing:
			p = q
			break
	if p == null:
		p = _pool[0]
		_pool.push_back(_pool.pop_front())
	p.stream = s
	p.volume_db = vol_db
	p.pitch_scale = pitch
	p.bus = bus
	p.play()
	return p


## Random variant: name_1 .. name_n, with a little pitch spread.
func play_var(base: String, n: int, vol_db: float = 0.0, spread: float = 0.06) -> void:
	play("%s_%d" % [base, randi_range(1, n)], vol_db, randf_range(1.0 - spread, 1.0 + spread))


func loop(channel: String, n: String, vol_db: float = 0.0, fade: float = 1.0, bus: String = "Amb") -> void:
	var cur: Dictionary = _loops.get(channel, {})
	if not cur.is_empty() and cur["name"] == n:
		set_loop_volume(channel, vol_db, fade)
		return
	if not cur.is_empty():
		_fade_out(cur["player"], fade)
		_loops.erase(channel)
	if n == "":
		return
	var s := stream(n)
	if s == null:
		return
	if s is AudioStreamWAV:
		var w := (s as AudioStreamWAV).duplicate() as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = int(w.get_length() * w.mix_rate)
		s = w
	var p := AudioStreamPlayer.new()
	p.stream = s
	p.bus = bus
	p.volume_db = -60.0
	add_child(p)
	p.play()
	var tw := create_tween()
	tw.tween_property(p, "volume_db", vol_db, maxf(fade, 0.01))
	_loops[channel] = {"name": n, "player": p}


func set_loop_volume(channel: String, vol_db: float, fade: float = 0.5) -> void:
	if not _loops.has(channel):
		return
	var p: AudioStreamPlayer = _loops[channel]["player"]
	var tw := create_tween()
	tw.tween_property(p, "volume_db", vol_db, maxf(fade, 0.01))


func set_loop_pitch(channel: String, pitch: float) -> void:
	if _loops.has(channel):
		(_loops[channel]["player"] as AudioStreamPlayer).pitch_scale = maxf(pitch, 0.05)


func stop_loop(channel: String, fade: float = 0.6) -> void:
	loop(channel, "", 0.0, fade)


func stop_all_loops(fade: float = 0.6) -> void:
	for ch in _loops.keys():
		_fade_out(_loops[ch]["player"], fade)
	_loops.clear()


func has_loop(channel: String) -> bool:
	return _loops.has(channel)


func _fade_out(p: AudioStreamPlayer, fade: float) -> void:
	var tw := create_tween()
	tw.tween_property(p, "volume_db", -60.0, maxf(fade, 0.01))
	tw.tween_callback(p.queue_free)


func music(n: String, vol_db: float = 0.0, fade: float = 2.0) -> void:
	loop("music", n, vol_db, fade, "Music")


func muffle(on: bool) -> void:
	if on == _muffled:
		return
	_muffled = on
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("Amb"), 0, on)


func stop_sfx() -> void:
	for p in _pool:
		p.stop()
