extends SceneTree
## godot --headless --path . --script res://tests/check_scripts.gd
## Loads every script so parse errors are reported one file at a time.

func _init() -> void:
	var bad := 0
	var files := []
	_walk("res://scripts", files)
	for f in files:
		var s: Script = load(f)
		if s == null or not s.can_instantiate():
			print("FAIL ", f)
			bad += 1
	print("check_scripts: %d files, %d failed" % [files.size(), bad])
	quit(1 if bad > 0 else 0)


func _walk(dir: String, out: Array) -> void:
	var d := DirAccess.open(dir)
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for sub in d.get_directories():
		_walk(dir + "/" + sub, out)
