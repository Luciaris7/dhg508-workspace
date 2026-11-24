class_name DrawLayer
extends Node2D
## A Node2D whose _draw is delegated to a callable(ci), so one script can
## draw several layers with other nodes sandwiched between them.

var cb: Callable


func _draw() -> void:
	if cb.is_valid():
		cb.call(self)
