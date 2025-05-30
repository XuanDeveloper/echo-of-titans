extends Node2D

@export var player_path: NodePath = "Player"
var player_ref: Node2D = null

func _ready():
	player_ref = get_node(player_path)

func _process(delta):
	if player_ref:
		var player_pos = player_ref.global_position
		for bola in get_tree().get_nodes_in_group("boss_balls"):
			bola.set_player_position(player_pos)
