extends CharacterBody2D 

enum PlayerState { IDLE, RUN, DASH, ATTACK }

@export var projectile_scene: PackedScene
var state: int = PlayerState.IDLE
@export var boss_path: NodePath
@onready var animation := $AnimatedSprite2D 
var can_shoot: bool = true

var speed: float = 400.0
var dash_speed: float = 700.0
var dash_duration: float = 0.2
var dash_timer: float = 0.0
var dash_cooldown: float = 1.0
var cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

func _ready():
	add_to_group("player")
	animation.play("Idle")

func _physics_process(delta: float) -> void:
	if cooldown_timer > 0:
		cooldown_timer -= delta
		
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
		animation.play("Run")
		if input_vector.x != 0:
			animation.flip_h = input_vector.x < 0
	else:
		state = PlayerState.IDLE
		animation.play("Idle")
	
	if Input.is_action_just_pressed("dash") and cooldown_timer <= 0:
		animation.play("Dash")
		state = PlayerState.DASH
		dash_timer = dash_duration
		dash_direction = input_vector if input_vector != Vector2.ZERO else Vector2.RIGHT
		velocity = dash_direction * dash_speed
		cooldown_timer = dash_cooldown

func process_dash(delta: float) -> void:
	dash_timer -= delta
	if dash_timer <= 0:
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
		
		can_shoot = false
		state = PlayerState.ATTACK
		animation.play("Attack")

		await animation.animation_finished
		
		if velocity.length() > 0:
			state = PlayerState.RUN
			animation.play("Run")
		else:
			state = PlayerState.IDLE
			animation.play("Idle")

func recover_projectile():
	can_shoot = true
