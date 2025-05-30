extends Node2D

@export var blue_ball_scene: PackedScene
@export var red_ball_scene: PackedScene
@export var player_path: NodePath = "Player"

var balls := []
var player_ref: Node2D = null

func _ready():
	player_ref = get_node(player_path)
	spawn_balls()

func spawn_balls():
	print("Chamando spawn_balls") # 👈 Adicione este print!
	
	if blue_ball_scene:
		var blue_ball = blue_ball_scene.instantiate()
		print("Instanciando blue_ball:", blue_ball) # 👈
		blue_ball.global_position = global_position + Vector2(50, 0)
		blue_ball.boss_ref = self
		get_tree().current_scene.add_child(blue_ball)
		balls.append(blue_ball)
	else:
		print("blue_ball_scene está nulo!") # 👈

	if red_ball_scene:
		var red_ball = red_ball_scene.instantiate()
		print("Instanciando red_ball:", red_ball) # 👈
		red_ball.global_position = global_position + Vector2(-50, 0)
		red_ball.boss_ref = self
		get_tree().current_scene.add_child(red_ball)
		balls.append(red_ball)
	else:
		print("red_ball_scene está nulo!") # 👈

func _process(delta):
	if not player_ref:
		return
	for bola in balls:
		if bola:
			bola.set_player_position(player_ref.global_position)
