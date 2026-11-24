extends Node
## Run: godot --headless --path . res://tests/check.tscn
## Loads every script with the autoloads present; prints failures.

func _ready() -> void:
	var bad := 0
	var files := []
	_walk("res://scripts", files)
	_walk("res://tests", files)
	for f in files:
		var s: Script = load(f)
		if s == null or not s.can_instantiate():
			print("FAIL ", f)
			bad += 1
	print("CHECK: %d files, %d failed" % [files.size(), bad])
	get_tree().quit(1 if bad > 0 else 0)


func _walk(dir: String, out: Array) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for sub in d.get_directories():
		_walk(dir + "/" + sub, out)
