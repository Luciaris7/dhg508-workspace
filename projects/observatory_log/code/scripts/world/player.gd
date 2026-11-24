class_name Player
extends Node2D
## The observer. Always centred on screen by the camera; A/D move him, and
## he keeps facing the direction of the last movement command.

const SPEED := 52.0
const WALK_FPS := 9.0

var sprite: Sprite2D
var anims := {}
var cell := Vector2i(24, 34)
var anim := "idle"
var anim_t := 0.0
var facing := 1
var pose := ""          # non-empty: holding an action pose
var pose_t := 0.0
var pose_fps := 4.0
var carrying_axe := false
var surface := "snow"   # footsteps: snow / wood / metal
var moving := false
var _last_step := -1


func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/art/char/player.png")
	sprite.centered = false
	sprite.region_enabled = true
	sprite.offset = Vector2(-12, -34)
	add_child(sprite)
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/char/player.json"))
	anims = d["anims"]
	_set_frame(0)


func _set_frame(i: int) -> void:
	sprite.region_rect = Rect2(i * cell.x, 0, cell.x, cell.y)


func set_pose(p: String, fps: float = 4.0) -> void:
	pose = p
	pose_t = 0.0
	pose_fps = fps


func clear_pose() -> void:
	pose = ""


func step(dt: float, dir: float) -> void:
	moving = absf(dir) > 0.01 and pose == ""
	if moving:
		facing = 1 if dir > 0 else -1
	sprite.flip_h = facing < 0
	if pose != "":
		pose_t += dt
		var fr: Array = anims.get(pose, anims["idle"])
		_set_frame(int(fr[int(pose_t * pose_fps) % fr.size()]))
		return
	if moving:
		anim = "walk_axe" if carrying_axe else "walk"
		anim_t += dt
		var fr: Array = anims[anim]
		var idx := int(anim_t * WALK_FPS) % fr.size()
		_set_frame(int(fr[idx]))
		if (idx == 0 or idx == 3) and idx != _last_step:
			_footstep()
		_last_step = idx
	else:
		anim_t += dt
		_last_step = -1
		var fr: Array = anims["idle"]
		_set_frame(int(fr[int(anim_t * 1.2) % fr.size()]))


func _footstep() -> void:
	match surface:
		"wood":
			Sfx.play_var("step_wood", 4, -10.0)
		"metal":
			Sfx.play_var("step_metal", 3, -11.0)
		"stair":
			Sfx.play_var("step_wood", 4, -8.0, 0.12)
		_:
			Sfx.play_var("step_snow", 4, -9.0)
