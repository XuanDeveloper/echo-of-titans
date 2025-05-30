# BlueBall.gd  OU  RedBall.gd
extends Area2D

var boss_ref: Node2D = null
var target_player_position: Vector2
@export var speed: float = 100.0

func set_player_position(pos: Vector2):
	target_player_position = pos

func _process(delta):
	if target_player_position == null:
		return
	var direction = (target_player_position - global_position).normalized()
	global_position += direction * speed * delta

func _ready():
	print("BlueBall spawnada em: ", global_position)
