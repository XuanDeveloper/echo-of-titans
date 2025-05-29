extends Node2D

@export var max_shield_hits: int = 6

var current_shield_hits: int = 0
var shield_broken: bool = false

var blue_ball: Node = null
var red_ball: Node = null
var shield: AnimatedSprite2D = null
var shield_container: Node = null

var attack_timer := 0.0
var base_attack_interval := 3.0
var accelerated_attack_interval := 1.0
var test_interval := base_attack_interval

var attacks_left_blue := 0
var attacks_left_red := 0
var attack_toggle := true  # para alternar ataque entre bolas nos primeiros estágios
var attack_cooldown := false  # controla o delay entre ataques para evitar ataques simultâneos

const BASE_SPEED := 300.0

const STAGE_SPEEDS = [
	BASE_SPEED,        # 0 hits
	BASE_SPEED * 1.0,  # 1 hit
	BASE_SPEED * 1.3,  # 2 hits
	BASE_SPEED * 1.5,  # 3 hits (tamanho cresce)
	BASE_SPEED * 1.7,  # 4 hits
	BASE_SPEED * 2.0,  # 5 hits (tamanho cresce)
	BASE_SPEED * 2.5   # 6 hits (escudo quebrado)
]

const STAGE_SCALES = [
	1.5,  # 0 hits
	1.8,  # 1 hit
	2.0,  # 2 hits
	2.0,  # 3 hits
	2.0,  # 4 hits
	2.2,  # 5 hits
	2.4   # 6 hits (escudo quebrado)
]

const ATTACKS_PER_STAGE = [
	1,  # 0 hits (apenas bola vermelha ataca uma vez)
	2,  # 1 hit (2 ataques alternados)
	2,  # 2 hits
	3,  # 3 hits
	4,  # 4 hits
	5,  # 5 hits
	6   # 6 hits (escudo quebrado)
]

func _ready():
	blue_ball = $BlueBall
	red_ball = $RedBall
	shield = $Shield/AnimatedSprite2D
	shield_container = $Shield

	assert(blue_ball != null, "BlueBall node não encontrado! Verifique o caminho.")
	assert(red_ball != null, "RedBall node não encontrado! Verifique o caminho.")

	blue_ball.set_boss_ref(self)
	red_ball.set_boss_ref(self)

	blue_ball.capture_idle_position()
	red_ball.capture_idle_position()

	shield.frame = 0
	shield_container.show()

	blue_ball.get_node("AnimatedSprite2D").play("idle")
	red_ball.get_node("AnimatedSprite2D").play("idle")

	dificuldade_por_hit(0)

	attacks_left_blue = 0
	attacks_left_red = 0

	test_interval = base_attack_interval

func _process(delta):
	if attack_cooldown:
		return

	attack_timer += delta
	if attack_timer < test_interval:
		return

	attack_timer = 0
	attack_cooldown = true

	if shield_broken:
		test_interval = accelerated_attack_interval

		if attacks_left_blue <= 0:
			attacks_left_blue = ATTACKS_PER_STAGE[max_shield_hits]
		if attacks_left_red <= 0:
			attacks_left_red = ATTACKS_PER_STAGE[max_shield_hits]

		# Controla ataque alternado, evitando ataques simultâneos
		if attack_toggle:
			if blue_ball.state == blue_ball.State.IDLE and attacks_left_blue > 0:
				await attack_single(blue_ball, "blue")
				attacks_left_blue -= 1
				attack_toggle = false
		else:
			if red_ball.state == red_ball.State.IDLE and attacks_left_red > 0:
				await attack_single(red_ball, "red")
				attacks_left_red -= 1
				attack_toggle = true
	else:
		test_interval = base_attack_interval
		var stage = clamp(current_shield_hits, 0, max_shield_hits)
		var attacks_per_cycle = ATTACKS_PER_STAGE[stage]

		if stage == 0:
			if red_ball.state == red_ball.State.IDLE and attacks_left_red <= 0:
				attacks_left_red = attacks_per_cycle
			if red_ball.state == red_ball.State.IDLE and attacks_left_red > 0:
				await attack_single(red_ball, "red")
				attacks_left_red -= 1
		elif stage == 1 or stage == 2:
			if attacks_left_blue <= 0:
				attacks_left_blue = attacks_per_cycle
			if attacks_left_red <= 0:
				attacks_left_red = attacks_per_cycle

			if attack_toggle:
				if blue_ball.state == blue_ball.State.IDLE and attacks_left_blue > 0:
					await attack_single(blue_ball, "blue")
					attacks_left_blue -= 1
					attack_toggle = false
			else:
				if red_ball.state == red_ball.State.IDLE and attacks_left_red > 0:
					await attack_single(red_ball, "red")
					attacks_left_red -= 1
					attack_toggle = true
		else:
			if attacks_left_blue <= 0:
				attacks_left_blue = attacks_per_cycle
			if attacks_left_red <= 0:
				attacks_left_red = attacks_per_cycle

			# Aqui ambas atacam quase simultâneo, mas com await sequencial para delay sutil
			if blue_ball.state == blue_ball.State.IDLE and attacks_left_blue > 0:
				await attack_single(blue_ball,"blue")
				attacks_left_blue -= 1
			if red_ball.state == red_ball.State.IDLE and attacks_left_red > 0:
				await attack_single(red_ball,"red")
				attacks_left_red -= 1

	# Libera cooldown quando ambas as bolas voltam a IDLE
	if blue_ball.state == blue_ball.State.IDLE and red_ball.state == red_ball.State.IDLE:
		attack_cooldown = false

func attack_single(ball: Node, ball_name: String):
	var player_pos = get_player_position()
	ball.attack(player_pos)
	while ball.state != ball.State.IDLE:
		await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout

func dificuldade_por_hit(hit_count: int):
	print("Aumentando dificuldade no hit ", hit_count)
	
	var idx = clamp(hit_count, 0, max_shield_hits)
	var speed = STAGE_SPEEDS[idx]
	var scale = STAGE_SCALES[idx]
	
	blue_ball.set_attack_speed(speed)
	blue_ball.set_expand_scale(scale)
	
	red_ball.set_attack_speed(speed)
	red_ball.set_expand_scale(scale)

func take_shield_hit():
	if shield_broken:
		return
		
	current_shield_hits += 1
	print("Escudo levou hit ", current_shield_hits)
	shield.frame = current_shield_hits
	
	if current_shield_hits >= max_shield_hits:
		shield_broken = true
		on_shield_break()
	else:
		dificuldade_por_hit(current_shield_hits)

func on_shield_break():
	shield_container.hide()
	print("Escudo quebrado! Chefão vulnerável!")
	dificuldade_por_hit(max_shield_hits)

func _input(event):
	if event.is_action_pressed("ui_accept"):
		take_shield_hit()

func get_player_position() -> Vector2:
	var player = get_tree().get_root().get_node("fase1/Player")
	if player:
		return player.global_position
	else:
		print("Player não encontrado no caminho!")
		return Vector2.ZERO
