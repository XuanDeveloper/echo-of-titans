extends Area2D

enum State { IDLE, ATTACK, RETURN }

@export var speed: float = 250
@export var home_offset: Vector2 = Vector2(50, 0)
@export var overshoot_distance: float = 80.0
@export var max_repel_strength: float = 1800.0
@onready var animation := $AnimatedSprite2D
@onready var gravity_field := $GravityField
@onready var gravity_shape := $GravityField/CollisionShape2D

var boss_ref: Node2D = null
var player_ref: Node2D = null

var state: State = State.IDLE
var home_position: Vector2
var attacks_to_do: int = 1
var attacks_done: int = 0
var target_position: Vector2

var speed_by_difficulty = [250, 275.0, 295.0, 315.0, 335.0, 345.0, 380.0] # Para dificuldade 1 a 7
var scale_by_difficulty = [1.75, 1.85, 1.90, 2.0, 2.10, 2.15, 2.25]
var radius_by_difficulty = [160.0, 175.0, 200.0, 215.0, 245.0, 265.0, 295.0] # Exemplo: ajuste como quiser

func _ready():
	add_to_group("red_gravity")
	# Conecta o sinal de colisão com corpos para detectar o Player:
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))

	assert(boss_ref != null)
	player_ref = boss_ref.player_ref
	animation.play("idle")
	update_home()
	global_position = home_position
	go_idle()
	gravity_field.add_to_group("red_gravity_field")

func set_gravity_radius(new_radius: float):
	var shape = gravity_shape.shape
	if shape is CircleShape2D:
		shape.radius = new_radius

func update_home():
	home_position = boss_ref.global_position + home_offset

func go_idle():
	update_home()
	state = State.IDLE
	global_position = home_position
	attacks_done = 0
	attacks_to_do = 1

func trigger_attack(n_steps: int):
	if state != State.IDLE:
		return
	attacks_to_do = n_steps
	attacks_done = 0
	state = State.ATTACK
	set_next_attack_target()

func set_next_attack_target():
	var to_player = player_ref.global_position - global_position
	if to_player.length() > 0:
		var overshoot = to_player.normalized() * overshoot_distance
		target_position = player_ref.global_position + overshoot
	else:
		target_position = player_ref.global_position

func go_return():
	state = State.RETURN

func _physics_process(delta):
	match state:
		State.IDLE:
			pass
		State.ATTACK:
			var direction = (target_position - global_position)
			if direction.length() < speed * delta:
				global_position = target_position
				attacks_done += 1
				if attacks_done < attacks_to_do:
					set_next_attack_target()
				else:
					go_return()
			else:
				global_position += direction.normalized() * speed * delta
		State.RETURN:
			update_home()
			var direction = (home_position - global_position)
			if direction.length() < speed * delta:
				global_position = home_position
				go_idle()
			else:
				global_position += direction.normalized() * speed * delta

func set_difficulty(diff: int):
	var idx = clamp(diff - 1, 0, speed_by_difficulty.size() - 1)
	speed = speed_by_difficulty[idx]
	scale = Vector2.ONE * scale_by_difficulty[idx]
	set_gravity_radius(radius_by_difficulty[idx])
func _on_body_entered(body):
	# Se colidir com o Player (que está em grupo "player") e não estiver em Dash, aplica knockback
	if body.is_in_group("player"):
		# Chama o método do player para aplicar knockback, passando a posição desta RedBall
		body.apply_knockback(global_position)
		# (Se quiser dar “dano” ou efeitos adicionais, faça aqui)
		# Exemplo: body.take_damage(1) 
