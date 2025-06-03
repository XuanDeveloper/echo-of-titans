extends CharacterBody2D 

enum PlayerState { IDLE, RUN, DASH, ATTACK }

@export var projectile_scene: PackedScene
var state: int = PlayerState.IDLE
@onready var animation := $AnimatedSprite2D 
var can_shoot: bool = true

var speed: float = 230.0
var dash_speed: float = 700.0
var dash_duration: float = 0.2
var dash_timer: float = 0.0
var dash_cooldown: float = 1.0
var cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

# Guarda a última direção válida em que o player se moveu
var last_facing: Vector2 = Vector2.RIGHT

var vida: int = 1
var sem_cabeca: bool = false
var morto: bool = false

func _ready():
	add_to_group("player")
	animation.play("Idle")

func _physics_process(delta: float) -> void:
	if morto:
		velocity = Vector2.ZERO
		return
	
	# Atualiza cooldown do dash
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
		if cooldown_timer < 0.0:
			cooldown_timer = 0.0

	# Permite movimento mesmo sem cabeça
	match state:
		PlayerState.IDLE, PlayerState.RUN, PlayerState.ATTACK:
			process_movement(delta)
		PlayerState.DASH:
			process_dash(delta)
		
	# Aplica movimento físico do CharacterBody2D
	move_and_slide()
	
	# Input de disparo de projétil
	if Input.is_action_just_pressed("Shoot") and not sem_cabeca and can_shoot:
		shoot()

func process_movement(delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("Right") - Input.get_action_strength("Left"),
		Input.get_action_strength("Down") - Input.get_action_strength("Up")
	).normalized()
	
	velocity = input_vector * speed
	
	if input_vector != Vector2.ZERO:
		state = PlayerState.RUN
		if sem_cabeca:
			animation.play("run_nohead")
		else:
			animation.play("Run")
		if input_vector.x != 0.0:
			animation.flip_h = input_vector.x < 0.0
		last_facing = input_vector.normalized()
	else:
		state = PlayerState.IDLE
		if sem_cabeca:
			animation.play("idle_nohead")
		else:
			animation.play("Idle")
	
	if Input.is_action_just_pressed("dash") and cooldown_timer <= 0.0:
		animation.play("Dash")
		state = PlayerState.DASH
		dash_timer = dash_duration
		if input_vector != Vector2.ZERO:
			dash_direction = input_vector.normalized()
		else:
			dash_direction = last_facing
		velocity = dash_direction * dash_speed
		cooldown_timer = dash_cooldown

func process_dash(delta: float) -> void:
	dash_timer -= delta
	# Quando o dash termina, volta para Idle (ou Run se houver velocidade residual)
	if dash_timer <= 0.0:
		state = PlayerState.IDLE
		velocity = Vector2.ZERO

func shoot():
	if projectile_scene and can_shoot:
		var projectile = projectile_scene.instantiate()
		
		var head_offset = Vector2(0, -20)  # ajuste para sair da cabeça
		projectile.global_position = global_position + head_offset
		
		projectile.direction = (get_global_mouse_position() - projectile.global_position).normalized()
		projectile.player = self  # passa referência do player para o projétil
		
		get_tree().current_scene.add_child(projectile)
		
		# Ajusta flags de ataque/animação
		can_shoot = false
		state = PlayerState.ATTACK
		sem_cabeca = true # Agora está sem cabeça
		# Troca para animação sem cabeça
		if velocity.length() > 0.0:
			animation.play("run_nohead")
		else:
			animation.play("idle_nohead")

		await animation.animation_finished

func recover_projectile():
	can_shoot = true
	sem_cabeca = false # Recuperou a cabeça
	# Volta para animação normal com cabeça
	if velocity.length() > 0.0:
		animation.play("Run")
	else:
		animation.play("Idle")

func levar_ataque():
	if sem_cabeca and not morto:
		vida = 0
		morto = true
		animation.play("morte") # Troque para o nome da animação de morte se houver
		velocity = Vector2.ZERO
		set_physics_process(false) # Para tudo
