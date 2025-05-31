extends CharacterBody2D 

enum PlayerState { IDLE, RUN, DASH, ATTACK }

@export var projectile_scene: PackedScene
var state: int = PlayerState.IDLE
@onready var animation := $AnimatedSprite2D 
var can_shoot: bool = true

var speed: float = 400.0
var dash_speed: float = 700.0
var dash_duration: float = 0.2
var dash_timer: float = 0.0
var dash_cooldown: float = 1.0
var cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

# Guarda a última direção válida em que o player se moveu
var last_facing: Vector2 = Vector2.RIGHT

func _ready():
	add_to_group("player")
	animation.play("Idle")

func _physics_process(delta: float) -> void:
	# Atualiza cooldown do dash
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
		if cooldown_timer < 0.0:
			cooldown_timer = 0.0

	# Se estiver atacando, sai imediatamente
	if state == PlayerState.ATTACK:
		return
	
	match state:
		PlayerState.IDLE, PlayerState.RUN:
			process_movement(delta)
		PlayerState.DASH:
			process_dash(delta)
		
	# Aplica movimento físico do CharacterBody2D
	move_and_slide()
	
	# Input de disparo de projétil
	if Input.is_action_just_pressed("Shoot") and state != PlayerState.ATTACK and can_shoot:
		shoot()

func process_movement(delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("Right") - Input.get_action_strength("Left"),
		Input.get_action_strength("Down") - Input.get_action_strength("Up")
	).normalized()
	
	# Atualiza velocidade de corrida
	velocity = input_vector * speed
	
	if input_vector != Vector2.ZERO:
		# Está correndo
		state = PlayerState.RUN
		animation.play("Run")

		# Atualiza flip horizontal caso precise
		if input_vector.x != 0.0:
			animation.flip_h = input_vector.x < 0.0

		# Guarda esta direção como a última válida
		last_facing = input_vector.normalized()
	else:
		# Parado
		state = PlayerState.IDLE
		animation.play("Idle")
	
	# Se apertou dash e não estiver em cooldown
	if Input.is_action_just_pressed("dash") and cooldown_timer <= 0.0:
		animation.play("Dash")
		state = PlayerState.DASH
		dash_timer = dash_duration

		# Se houver input de movimento, dash nessa direção; senão, usa last_facing
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
		
		# Posiciona o projétil um pouco acima do player (saindo da “cabeça”)
		var head_offset = Vector2(0, -20)
		var spawn_pos = global_position + head_offset
		projectile.global_position = spawn_pos
		
		# Chama o método shoot(stage_pos, direção) no script do projétil
		# (o script do projétil deve definir velocity a partir de “direction” internamente)
		var aim_dir = (get_global_mouse_position() - spawn_pos).normalized()
		projectile.shoot(spawn_pos, aim_dir)
		projectile.player = self  # passa referência para o player
		
		get_tree().current_scene.add_child(projectile)
		
		# Ajusta flags de ataque/animação
		can_shoot = false
		state = PlayerState.ATTACK
		animation.play("Attack")

		await animation.animation_finished
		
		# Após o ataque, volta para Run ou Idle
		if velocity.length() > 0.0:
			state = PlayerState.RUN
			animation.play("Run")
		else:
			state = PlayerState.IDLE
			animation.play("Idle")

func recover_projectile():
	can_shoot = true
