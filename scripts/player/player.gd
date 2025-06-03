extends CharacterBody2D 

enum PlayerState { IDLE, RUN, DASH, ATTACK, HIT }

@export var projectile_scene: PackedScene
var state: int = PlayerState.IDLE
@onready var animation := $AnimatedSprite2D 
var can_shoot: bool = true
var life: bool = true

var speed: float = 250.0
var dash_speed: float = 600.0
var dash_duration: float = 0.2
var dash_timer: float = 0.0
var dash_cooldown: float = 1.0
var cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

# --- Campos de knockback ---
var hit_duration: float = 0.15
var hit_timer: float = 0.0
var hit_knockback_speed: float = 300.0

# --- Campos para invencibilidade ---
var invincible_duration: float = 1.0
var invincible_timer: float = 0.0
var invincible: bool = false

# Guarda a última direção válida em que o player se moveu
var last_facing: Vector2 = Vector2.RIGHT

func _ready():
	add_to_group("player")
	play_idle_animation()

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
			if velocity.length() > 0.0:
				state = PlayerState.RUN
				play_run_animation()
			else:
				state = PlayerState.IDLE
				play_idle_animation()
		else:
			move_and_slide()
		return

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

	velocity = input_vector * speed

	if input_vector != Vector2.ZERO:
		state = PlayerState.RUN
		play_run_animation()

		if input_vector.x != 0.0:
			animation.flip_h = input_vector.x < 0.0

		last_facing = input_vector.normalized()
	else:
		state = PlayerState.IDLE
		play_idle_animation()

	if Input.is_action_just_pressed("dash") and cooldown_timer <= 0.0 and can_shoot:
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
	if dash_timer <= 0.0:
		state = PlayerState.IDLE
		velocity = Vector2.ZERO

func shoot():
	if projectile_scene and can_shoot:
		var projectile = projectile_scene.instantiate()

		var head_offset = Vector2(0, -20)
		projectile.global_position = global_position + head_offset

		projectile.direction = (get_global_mouse_position() - projectile.global_position).normalized()
		projectile.player = self

		get_tree().current_scene.add_child(projectile)

		can_shoot = false
		state = PlayerState.ATTACK
		animation.play("Attack")

		await animation.animation_finished

		if velocity.length() > 0.0:
			state = PlayerState.RUN
			play_run_animation()
		else:
			state = PlayerState.IDLE
			play_idle_animation()

func recover_projectile():
	can_shoot = true
func drop_head_on_hit() -> void:
	call_deferred("_drop_head_deferred")

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("ball_blue"):
		life = false
		print("Contato com ball_blue detectado!")

func _drop_head_deferred() -> void:
	if projectile_scene == null:
		push_warning("projectile_scene não foi atribuído no Inspetor.")
		return

	var head = projectile_scene.instantiate()
	get_tree().current_scene.add_child(head)
	head.global_position = global_position

	head.is_moving = false
	head.player = self

func apply_knockback(from_position: Vector2) -> void:
	if state == PlayerState.DASH:
		return

	if invincible:
		return

	if can_shoot:
		drop_head_on_hit()
		can_shoot = false

	var dir := (global_position - from_position).normalized()
	velocity = dir * hit_knockback_speed

	state = PlayerState.HIT
	hit_timer = hit_duration

	invincible = true
	invincible_timer = invincible_duration

	if animation.sprite_frames.has_animation("Hurt"):
		animation.play("Hurt")
	else:
		push_warning("Animação 'Hurt' não encontrada em AnimatedSprite2D.")
func play_run_animation():
	if can_shoot:
		animation.play("Run")
	else:
		animation.play("Run_nohead")

func play_idle_animation():
	if can_shoot:
		animation.play("Idle")
	else:
		animation.play("Idle2")
