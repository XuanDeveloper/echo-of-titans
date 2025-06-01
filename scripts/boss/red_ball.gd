extends Area2D

enum State { IDLE, ATTACK, RETURN }

@export var speed: float = 250.0
@export var home_offset: Vector2 = Vector2(50, 0)
@export var overshoot_distance: float = 80.0
@onready var animation := $AnimatedSprite2D 
var boss_ref: Node2D = null
var player_ref: Node2D = null

var state: State = State.IDLE
var home_position: Vector2
var attacks_to_do: int = 1
var attacks_done: int = 0
var target_position: Vector2

var speed_by_difficulty = [250.0, 275.0, 300.0, 350.0, 390.0, 420.0, 480.0] # para dificuldade 1 a 7
var scale_by_difficulty = [1.75, 1.90, 2.05, 2.10, 2.15, 2.25, 2.45]

func _ready():
	assert(boss_ref != null)
	player_ref = boss_ref.player_ref
	animation.play("idle")
	update_home()
	global_position = home_position
	go_idle()

func update_home():
	home_position = boss_ref.global_position + home_offset

func go_idle():
	update_home()
	state = State.IDLE
	global_position = home_position
	attacks_done = 0
	attacks_to_do = 1
	# animação de idle se quiser

func trigger_attack(n_steps: int):
	if state != State.IDLE:
		return
	attacks_to_do = n_steps
	attacks_done = 0
	state = State.ATTACK
	set_next_attack_target()
	# animação de ataque se quiser

func set_next_attack_target():
	var to_player = player_ref.global_position - global_position
	if to_player.length() > 0:
		var overshoot = to_player.normalized() * overshoot_distance
		target_position = player_ref.global_position + overshoot
	else:
		target_position = player_ref.global_position

func go_return():
	state = State.RETURN
	# animação de retorno se quiser

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
					set_next_attack_target() # registra novo alvo do player
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
	print("Alterando dificuldade da bola. Dificuldade:", diff, "Speed:", speed, "Scale:", scale)
