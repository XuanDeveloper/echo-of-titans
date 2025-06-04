extends CharacterBody2D

enum PlayerState { IDLE, RUN, DASH, ATTACK, HIT, DEAD }

# ===== EXPORTS =====
@export var projectile_scene: PackedScene

# ===== CORE PROPERTIES =====
var state: PlayerState = PlayerState.IDLE
var life: int = 2 # Agora é int, começa com 2
var can_shoot: bool = true
var last_facing: Vector2 = Vector2.RIGHT

# ===== NODES =====
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

# ===== MOVEMENT CONSTANTS =====
const SPEED: float = 250.0
const DASH_SPEED: float = 600.0
const DASH_DURATION: float = 0.2
const DASH_COOLDOWN: float = 1.0

# ===== COMBAT CONSTANTS =====
const HIT_DURATION: float = 0.15
const HIT_KNOCKBACK_SPEED: float = 300.0
const INVINCIBLE_DURATION: float = 1.0
const RED_EFFECT_DURATION: float = 0.1

# ===== TIMERS =====
var dash_timer: float = 0.0
var cooldown_timer: float = 0.0
var hit_timer: float = 0.0
var invincible_timer: float = 0.0
var red_effect_timer: float = 0.0

# ===== STATE FLAGS =====
var dash_direction: Vector2 = Vector2.ZERO
var invincible: bool = false
var is_red: bool = false

# ===== INITIALIZATION =====
func _ready() -> void:
	add_to_group("player")
	_play_idle_animation()

# ===== MAIN LOOP =====
func _physics_process(delta: float) -> void:
	if state == PlayerState.DEAD:
		return

	_update_timers(delta)
	_handle_state_logic(delta)
	move_and_slide()
	_handle_shooting()

# ===== TIMER MANAGEMENT =====
func _update_timers(delta: float) -> void:
	# Dash cooldown
	if cooldown_timer > 0.0:
		cooldown_timer = max(0.0, cooldown_timer - delta)

	# Invincibility
	if invincible:
		invincible_timer -= delta
		if invincible_timer <= 0.0:
			invincible = false
			invincible_timer = 0.0

	# Red damage effect
	if is_red:
		red_effect_timer -= delta
		if red_effect_timer <= 0.0:
			is_red = false
			animation.modulate = Color.WHITE

# ===== STATE MANAGEMENT =====
func _handle_state_logic(delta: float) -> void:
	match state:
		PlayerState.HIT:
			_process_hit_state(delta)
		PlayerState.ATTACK:
			return  # Attack state is handled by animation signals
		PlayerState.IDLE, PlayerState.RUN:
			_process_movement(delta)
		PlayerState.DASH:
			_process_dash(delta)

func _process_hit_state(delta: float) -> void:
	hit_timer -= delta
	if hit_timer <= 0.0:
		_transition_from_hit()

func _transition_from_hit() -> void:
	if velocity.length() > 0.0:
		state = PlayerState.RUN
		_play_run_animation()
	else:
		state = PlayerState.IDLE
		_play_idle_animation()

# ===== MOVEMENT SYSTEM =====
func _process_movement(delta: float) -> void:
	var input_vector := _get_input_vector()
	velocity = input_vector * SPEED

	_update_movement_state(input_vector)
	_handle_dash_input(input_vector)

func _get_input_vector() -> Vector2:
	return Vector2(
		Input.get_action_strength("Right") - Input.get_action_strength("Left"),
		Input.get_action_strength("Down") - Input.get_action_strength("Up")
	).normalized()

func _update_movement_state(input_vector: Vector2) -> void:
	if input_vector != Vector2.ZERO:
		state = PlayerState.RUN
		_play_run_animation()
		_update_sprite_direction(input_vector)
		last_facing = input_vector.normalized()
	else:
		state = PlayerState.IDLE
		_play_idle_animation()

func _update_sprite_direction(input_vector: Vector2) -> void:
	if input_vector.x != 0.0:
		animation.flip_h = input_vector.x < 0.0

func _handle_dash_input(input_vector: Vector2) -> void:
	if not Input.is_action_just_pressed("dash"):
		return
	if cooldown_timer > 0.0:
		return
	if not can_shoot:  # Can't dash without head
		return

	_execute_dash(input_vector)

func _execute_dash(input_vector: Vector2) -> void:
	_play_dash_animation()
	state = PlayerState.DASH
	dash_timer = DASH_DURATION

	dash_direction = input_vector if input_vector != Vector2.ZERO else last_facing
	velocity = dash_direction * DASH_SPEED
	cooldown_timer = DASH_COOLDOWN

func _process_dash(delta: float) -> void:
	dash_timer -= delta
	if dash_timer <= 0.0:
		state = PlayerState.IDLE
		velocity = Vector2.ZERO

# ===== COMBAT SYSTEM =====
func _handle_shooting() -> void:
	if Input.is_action_just_pressed("Shoot") and _can_shoot():
		shoot()

func _can_shoot() -> bool:
	return state != PlayerState.ATTACK and can_shoot

func shoot() -> void:
	if not projectile_scene or not can_shoot:
		return

	_create_projectile()
	_start_attack_state()

func _create_projectile() -> void:
	if not is_inside_tree():
		return

	var projectile = projectile_scene.instantiate()
	var head_offset = Vector2(0, -20)

	projectile.global_position = global_position + head_offset
	projectile.direction = (get_global_mouse_position() - projectile.global_position).normalized()
	projectile.player = self

	get_tree().current_scene.add_child(projectile)

func _start_attack_state() -> void:
	can_shoot = false
	state = PlayerState.ATTACK
	animation.play("Attack")

	await animation.animation_finished
	_end_attack_state()

func _end_attack_state() -> void:
	if velocity.length() > 0.0:
		state = PlayerState.RUN
		_play_run_animation()
	else:
		state = PlayerState.IDLE
		_play_idle_animation()

func recover_projectile() -> void:
	can_shoot = true
	life = 2

# ===== DAMAGE SYSTEM =====
func apply_knockback(from_position: Vector2) -> void:
	if not _can_take_damage():
		return

	if can_shoot and life == 2:
		# Primeira vez tomando dano: perde a cabeça e fica com 1 de vida
		_handle_head_loss()
		life = 1
		_apply_knockback_physics(from_position)
		_start_hit_state()
		_start_invincibility()
		_apply_damage_effect()
	elif not can_shoot:
		# Sem cabeça: qualquer dano mata
		life = 0
		_apply_knockback_physics(from_position)
		_start_hit_state()
		_start_invincibility()
		_apply_damage_effect()
		die_with_animation()
	else:
		# Proteção extra, caso tente tomar dano em outro estado
		pass

func _can_take_damage() -> bool:
	return state != PlayerState.DASH and state != PlayerState.DEAD and not invincible

func _handle_head_loss() -> void:
	if can_shoot:
		drop_head_on_hit()
		can_shoot = false

func _apply_knockback_physics(from_position: Vector2) -> void:
	var direction := (global_position - from_position).normalized()
	velocity = direction * HIT_KNOCKBACK_SPEED

func _start_hit_state() -> void:
	state = PlayerState.HIT
	hit_timer = HIT_DURATION

func _start_invincibility() -> void:
	invincible = true
	invincible_timer = INVINCIBLE_DURATION

func _apply_damage_effect() -> void:
	# Sempre aplica o efeito visual de dano
	is_red = true
	red_effect_timer = RED_EFFECT_DURATION
	animation.modulate = Color.RED
	print("Player took damage!")

	if animation.sprite_frames.has_animation("Hurt"):
		animation.play("Hurt")
	else:
		push_warning("Animation 'Hurt' not found in AnimatedSprite2D.")

func drop_head_on_hit() -> void:
	call_deferred("_drop_head_deferred")

func _drop_head_deferred() -> void:
	if not projectile_scene:
		push_warning("projectile_scene not assigned in Inspector.")
		return

	var head = projectile_scene.instantiate()
	get_tree().current_scene.add_child(head)
	head.global_position = global_position
	head.is_moving = false
	head.player = self

# ===== COLLISION HANDLING =====
func _on_area_entered(area: Area2D) -> void:
	if _is_deadly_collision(area):
		print("Player died by touching ball while headless!")
		die_with_animation()
		return

	print("Collision with: ", area.name, " | Groups: ", area.get_groups())

func _is_deadly_collision(area: Area2D) -> bool:
	return (area.is_in_group("ball_blue") or area.is_in_group("ball_red")) and not can_shoot

# ===== DEATH SYSTEM =====
func die_with_animation() -> void:
	if state == PlayerState.DEAD or can_shoot:
		return  # Não morre se ainda tiver cabeça

	_set_death_state()
	await _wait_for_death_animation()
	game_over()

func die() -> void:
	if state == PlayerState.DEAD or can_shoot:
		return  # Não morre se ainda tiver cabeça

	_set_death_state()
	_play_death_animation_simple()
	_apply_death_effect()

	await get_tree().create_timer(1.5).timeout
	restart_level()

func _set_death_state() -> void:
	life = false
	state = PlayerState.DEAD
	velocity = Vector2.ZERO
	_disable_collisions()
	game_over()
	print("Player died!")

func _disable_collisions() -> void:
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

func _play_death_animation_simple() -> void:
	if animation.sprite_frames.has_animation("Death"):
		animation.play("Death")
	else:
		animation.play("Idle2")  # Idle without head

func _apply_death_effect() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.5)

func _wait_for_death_animation() -> void:
	if animation.sprite_frames.has_animation("Death"):
		await animation.animation_finished
	else:
		await get_tree().create_timer(1.0).timeout

# ===== ANIMATION SYSTEM =====
func _play_run_animation() -> void:
	if state == PlayerState.DEAD:
		return

	if can_shoot:
		animation.play("Run")
	else:
		animation.play("Run_nohead")

func _play_idle_animation() -> void:
	if state == PlayerState.DEAD:
		return

	if can_shoot:
		animation.play("Idle")
	else:
		animation.play("Idle2")

func _play_dash_animation() -> void:
	if can_shoot:
		animation.play("Dash")
	else:
		animation.play("Dash_nohead")

# ===== SCENE MANAGEMENT =====
func _die_without_head() -> void:
	if not is_inside_tree():
		return

	print("Player died without head!")
	_set_death_state()

	# Use call_deferred to ensure the scene change happens after current frame
	call_deferred("_change_to_death_menu")

func _change_to_death_menu() -> void:
	if is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/menus/death_menu.tscn")

func restart_level() -> void:
	if is_inside_tree():
		get_tree().reload_current_scene()

func game_over() -> void:
	if is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/menus/death_menu.tscn")
