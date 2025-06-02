extends Node2D

@export var blue_ball_scene: PackedScene
@export var red_ball_scene: PackedScene
@export var player_path: NodePath = "Player"
@export var shield_path: NodePath = "Shield"

var escudo: Area2D = null
var dificuldade := 1
var balls := []
var player_ref: Node2D = null
var activated: bool = false
var ball_timer: Timer = null

func _ready():
	# NÃO FAZ NADA! (só ativa depois)
	pass

func activate():
	if activated:
		return
	activated = true
	player_ref = get_node(player_path)
	spawn_balls()
	escudo = get_node(shield_path)
	if escudo:
		escudo.connect("shield_hit", _on_shield_hit)
		escudo.connect("shield_broken", _on_shield_broken)
	
	ball_timer = Timer.new()
	ball_timer.wait_time = 2.0
	ball_timer.one_shot = false
	ball_timer.autostart = true
	add_child(ball_timer)
	ball_timer.timeout.connect(_on_attack_timer)
	print("Boss ativado!")

func spawn_balls():
	var blue_ball = blue_ball_scene.instantiate()
	blue_ball.global_position = global_position + Vector2(50, 0)
	blue_ball.boss_ref = self
	blue_ball.home_offset = Vector2(50, 0)
	get_parent().call_deferred("add_child", blue_ball)
	balls.append(blue_ball)

	var red_ball = red_ball_scene.instantiate()
	red_ball.global_position = global_position + Vector2(-50, 0)
	red_ball.boss_ref = self
	red_ball.home_offset = Vector2(-50, 0)
	get_parent().call_deferred("add_child", red_ball)
	balls.append(red_ball)
	for bola in balls:
		bola.call_deferred("set_difficulty", dificuldade)

func _on_shield_hit():
	dificuldade += 1
	update_balls_difficulty()
	print("Escudo tomou hit, dificuldade = ", dificuldade)

func _on_shield_broken():
	dificuldade += 1
	update_balls_difficulty()
	print("Escudo quebrou! Dificuldade = ", dificuldade)

func _on_attack_timer():
	print("Disparando ataque! Dificuldade atual: ", dificuldade)
	if balls.size() >= 1:
		balls[0].trigger_attack(dificuldade)
		await get_tree().create_timer(0.5).timeout
	if balls.size() >= 2:
		balls[1].trigger_attack(dificuldade)

func update_balls_difficulty():
	for bola in balls:
		bola.set_difficulty(dificuldade)
