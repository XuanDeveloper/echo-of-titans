extends CharacterBody2D 

enum PlayerState { IDLE, RUN, DASH, ATTACK, HIT }

@export var projectile_scene: PackedScene
var state: int = PlayerState.IDLE
@onready var animation := $AnimatedSprite2D 
var can_shoot: bool = true

var speed: float = 250.0
var dash_speed: float = 700.0
var dash_duration: float = 0.2
var dash_timer: float = 0.0
var dash_cooldown: float = 1.0
var cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

# 02/06 - Campos para o knockback
var hit_duration: float = 0.15         # duração (em segundos) do hitstun
var hit_timer: float = 0.0
var hit_knockback_speed: float = 300.0

# 02/06 - Campos para invencibilidade após sofrer dano
var invincible_duration: float = 1.0    # 1 segundo de invencibilidade (ajuste conforme desejar)
var invincible_timer: float = 0.0
var invincible: bool = false            # flag que indica se o player está invencível

# Guarda a última direção válida em que o player se moveu
var last_facing: Vector2 = Vector2.RIGHT

func _ready():
	add_to_group("player")
	animation.play("Idle")

func _physics_process(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
		if cooldown_timer < 0.0:
			cooldown_timer = 0.0
	if invincible:
		invincible_timer -= delta
		if invincible_timer <= 0.0:
			invincible = false
			invincible_timer = 0.0
	if state == PlayerState.HIT:
		hit_timer -= delta
		if hit_timer <= 0.0:
			# Quando o hitstun termina, volta para IDLE (ou RUN se estiver se movendo)
			if velocity.length() > 0.0:
				state = PlayerState.RUN
				animation.play("Run")
			else:
				state = PlayerState.IDLE
				animation.play("Idle")
		else:
			# Enquanto hit_timer > 0, mantém a velocidade de knockback
			move_and_slide()
		return  # não processa nenhuma outra entrada enquanto estiver em HIT
	if state == PlayerState.ATTACK:
		return
	
	match state:
		PlayerState.IDLE, PlayerState.RUN:
			process_movement(delta)
		PlayerState.DASH:
			process_dash(delta)
		
	move_and_slide()
	
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
	# Durante o dash, o move_and_slide já ocorre em _physics_process

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
# 02/06 - Novo método para aplicar knockback + invencibilidade
func apply_knockback(from_position: Vector2) -> void:
	# 1) Se estiver em DASH, ignora (intangível por causa do dash)
	if state == PlayerState.DASH:
		return

	# 2) Se já estiver invencível, ignora (não toma dano/knockback de novo)
	if invincible:
		return

	# 3) Aplica o knockback (calcula direção e velocidade)
	var dir := (global_position - from_position).normalized()
	velocity = dir * hit_knockback_speed

	# 4) Entra em estado HIT e seta o timer de hitstun
	state = PlayerState.HIT
	hit_timer = hit_duration

	# 5) Inicia invencibilidade
	invincible = true
	invincible_timer = invincible_duration

	# 6) Toca a animação “Hurt” (certifique-se de que existe no SpriteFrames)
	if animation.sprite_frames.has_animation("Hurt"):
		animation.play("Hurt")
	else:
		push_warning("Animação 'Hurt' não encontrada em AnimatedSprite2D; verifique o nome no SpriteFrames.")

	# (Opcional) Dar feedback visual de invencibilidade, ex.:
	# animation.modulate = Color(1, 1, 1, 0.5)  # semitransparente enquanto invencível
