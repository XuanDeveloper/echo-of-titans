extends Node2D

enum State { IDLE, EXPANDING, ATTACKING_1, EXTENDING_1, ATTACKING_2, RETURNING }

@export var base_attack_speed: float = 300.0
var attack_speed: float = base_attack_speed

@export var base_expand_scale: float = 2.0
var expand_scale: float = base_expand_scale

@export var normal_scale: float = 1.0
@export var extend_distance: float = 100.0

var state: State = State.IDLE

var idle_position: Vector2 = Vector2.ZERO
var first_target: Vector2 = Vector2.ZERO
var second_target: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.ZERO

var boss_ref: Node = null

func _ready():
	idle_position = global_position
	scale = Vector2.ONE * normal_scale
	attack_speed = base_attack_speed
	expand_scale = base_expand_scale

func capture_idle_position():
	idle_position = global_position

func set_boss_ref(boss_node: Node):
	boss_ref = boss_node

func set_attack_speed(speed: float):
	attack_speed = speed

func set_expand_scale(scale: float):
	expand_scale = scale

func attack(player_pos: Vector2):
	if state != State.IDLE:
		return
	first_target = player_pos
	direction = (first_target - global_position).normalized()
	state = State.EXPANDING
	animate_expand(true)

func animate_expand(expand: bool):
	var tween = create_tween()
	if expand:
		tween.tween_property(self, "scale", Vector2.ONE * expand_scale, 0.3)
		tween.connect("finished", Callable(self, "_on_expand_finished"))
	else:
		tween.tween_property(self, "scale", Vector2.ONE * normal_scale, 0.3)
		tween.connect("finished", Callable(self, "_on_contract_finished"))

func _on_expand_finished():
	if state == State.EXPANDING:
		state = State.ATTACKING_1

func _on_contract_finished():
	if state == State.RETURNING:
		state = State.IDLE
		global_position = idle_position

func _process(delta):
	match state:
		State.IDLE:
			global_position = idle_position
		State.EXPANDING:
			pass
		State.ATTACKING_1:
			var dist = global_position.distance_to(first_target)
			if dist > 5:
				global_position += direction * attack_speed * delta
			else:
				state = State.EXTENDING_1
				first_target += direction * extend_distance
		State.EXTENDING_1:
			var dist = global_position.distance_to(first_target)
			if dist > 5:
				global_position += direction * attack_speed * delta
			else:
				if boss_ref != null:
					second_target = boss_ref.get_player_position()
				else:
					second_target = global_position
				direction = (second_target - global_position).normalized()
				state = State.ATTACKING_2
		State.ATTACKING_2:
			var dist = global_position.distance_to(second_target)
			if dist > 5:
				global_position += direction * attack_speed * delta
			else:
				state = State.RETURNING
				animate_expand(false)
		State.RETURNING:
			var dist = global_position.distance_to(idle_position)
			if dist > 5:
				direction = (idle_position - global_position).normalized()
				global_position += direction * attack_speed * delta
			else:
				global_position = idle_position
				state = State.IDLE
