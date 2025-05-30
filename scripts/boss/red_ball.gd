extends Node2D

@export var speed: float = 100.0
var target_player_position: Vector2

func set_player_position(pos: Vector2):
	target_player_position = pos

func _process(delta):
	if target_player_position == null:
		return
	var direction = (target_player_position - global_position).normalized()
	global_position += direction * speed * delta
