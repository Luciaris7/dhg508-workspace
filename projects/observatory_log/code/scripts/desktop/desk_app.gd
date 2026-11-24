class_name DeskApp
extends RefCounted
## Base for programs hosted in a desktop window.

var desk: Node2D          # the Desktop
var title := ""
var icon: Texture2D
var size := Vector2(300, 200)
var id := ""


func draw(_ci: CanvasItem, _r: Rect2) -> void:
	pass


## Mouse event in client coordinates (local) -- return true if consumed.
func mouse(_e: InputEvent, _local: Vector2, _r: Rect2) -> bool:
	return false


func key(_e: InputEventKey) -> bool:
	return false


func can_close() -> bool:
	return true


func on_open() -> void:
	pass


func on_close() -> void:
	pass


func tick(_dt: float) -> void:
	pass
