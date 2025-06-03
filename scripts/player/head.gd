extends Area2D

@export var player: Node
@export var speed: float = 600.0
@export var friction: float = 1000.0
@export var bounce_factor: float = 0.7  # Fator de rebote (0-1)
@export var max_bounces: int = 3        # Número máximo de rebotes

# Tempo antes de permitir coleta, para que a “cabeça” não seja coletada imediatamente ao nascer em cima do player
var collect_delay: float = 0.1   # 0.1 segundos de delay antes de coletar
var _collect_timer: float = 0.0
var can_be_collected: bool = false

var direction: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var is_moving: bool = true
var bounce_count: int = 0

@onready var wall_ray := $WallRay

func _ready():
	# Conecta sinais apenas para lidar com colisões dinâmicas
	connect("area_entered", Callable(self, "_on_area_entered"))
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
	
	# Configuração inicial: se o head foi instanciado via 'drop', direction provavelmente é Vector2.ZERO
	velocity = direction.normalized() * speed
	update_raycast()
	wall_ray.enabled = true
	
	# Camadas de colisão (ajuste conforme suas regras de camada/máscara)
	collision_mask = 0xFFFF
	wall_ray.collision_mask = 0xFFFF
	
	# Inicia o temporizador de coleta
	_collect_timer = collect_delay
	can_be_collected = false

	print("Projétil inicializado, direção:", direction)

func update_raycast():
	# Atualiza a direção do raycast para apontar na direção da velocidade
	if velocity.length() > 0:
		wall_ray.target_position = velocity.normalized() * 15

func _physics_process(delta):
	# 1) Se ainda não pode coletar, decrementar timer
	if not can_be_collected:
		_collect_timer -= delta
		if _collect_timer <= 0.0:
			can_be_collected = true

	# 2) Se ainda estiver se movendo, continue com a lógica normal de física
	if is_moving:
		# Atração/repulsão por Red/Blue Balls
		for area in get_overlapping_areas():
			if area.is_in_group("red_gravity_field"):
				var redball = area.get_parent()
				var to_head = global_position - area.global_position
				var dist = to_head.length()
				var gravity_radius = area.get_node("CollisionShape2D").shape.radius
				var max_strength = redball.max_repel_strength
				if dist < gravity_radius:
					var force = (gravity_radius - dist) / gravity_radius
					var repel_strength = lerp(0.0, max_strength, force)
					var boss_pos = redball.boss_ref.global_position
					var to_boss = (boss_pos - global_position).normalized()
					var alignment = to_head.normalized().dot(to_boss)
					if alignment > 0.7:
						var lateral = Vector2(-to_boss.y, to_boss.x).normalized()
						var mix = 0.6
						var safe_dir = (to_head.normalized() * mix + lateral * (1.0 - mix)).normalized()
						velocity += safe_dir * repel_strength * delta
					else:
						velocity += to_head.normalized() * repel_strength * delta

			if area.is_in_group("blue_gravity_field"):
				var blueball = area.get_parent()
				var dist = (area.global_position - global_position).length()
				var gravity_radius = area.get_node("CollisionShape2D").shape.radius
				var max_strength = blueball.max_attract_strength
				var boss_pos = blueball.boss_ref.global_position
				if dist < gravity_radius:
					var force = (gravity_radius - dist) / gravity_radius
					var attract_strength = lerp(0.0, max_strength, force)
					# Sempre joga para o lado oposto ao boss
					var away_from_boss = (global_position - boss_pos).normalized()
					velocity += away_from_boss * attract_strength * delta

		update_raycast()
		wall_ray.force_raycast_update()
		
		# Verifica colisão com o raycast
		if wall_ray.is_colliding():
			handle_wall_collision(wall_ray.get_collision_normal())
		
		# Aplica fricção ao projétil
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

		# Calcula o próximo passo/movimento
		var motion = velocity * delta

		# Define comprimento do raycast, considerando o buffer do CollisionShape2D
		var buffer: float = 20.0
		if $CollisionShape2D.shape is CircleShape2D:
			buffer = max(20.0, $CollisionShape2D.shape.radius)
		var ray_length: float = motion.length() + buffer
		if motion.length() > 0:
			wall_ray.target_position = motion.normalized() * ray_length
			wall_ray.force_raycast_update()
			
			if wall_ray.is_colliding():
				var collision_point = wall_ray.get_collision_point()
				var dist_to_collision = collision_point.distance_to(global_position)
				if dist_to_collision <= ray_length:
					# Move até o ponto de contato com a parede
					var move_vec = collision_point - global_position
					position += move_vec.normalized() * max(0, dist_to_collision - 1)
					handle_wall_collision(wall_ray.get_collision_normal())
					return  # Para processamento deste frame
		# Se não colidiu, move normalmente
		position += motion

		# Se a velocidade ficar abaixo de 10, considere que parou
		if velocity.length() < 10:
			print("Projétil parou devido à velocidade baixa")
			is_moving = false
			velocity = Vector2.ZERO

	else:
		# 3) Quando não está mais se movendo, permite coleta apenas após o delay 
		# e se estiver sobrepondo o player
		if can_be_collected:
			for body in get_overlapping_bodies():
				if body.is_in_group("player"):
					if player and player.has_method("recover_projectile"):
						player.recover_projectile()
					queue_free()
					return

func _on_area_entered(area):
	print("Área entrou em contato: ", area.name)
	if area.is_in_group("boss_shield"):
		print("Acertou o escudo do boss!")
		if area.has_method("hit"):
			area.hit()
		
		# Rebote (como se fosse uma parede), usando vetor normal
		var normal = (global_position - area.global_position).normalized()
		handle_wall_collision(normal)
		return

func handle_wall_collision(normal: Vector2):
	bounce_count += 1
	print("Rebote #", bounce_count, " Normal:", normal)
	
	# Aplica o rebote usando reflexão com bounce_factor
	velocity = velocity.bounce(normal) * bounce_factor
	
	# Move um pouco para fora da colisão para não “grudar”
	position += normal * 5
	
	print("Velocidade após rebote: ", velocity)
	
	# Se atingir o número máximo de rebotes, pare o head
	if bounce_count >= max_bounces:
		print("Número máximo de rebotes atingido, parando projétil")
		is_moving = false
		velocity = Vector2.ZERO
		return
	
	# Se após o rebote a velocidade for muito baixa, pare também
	if velocity.length() < 50:
		print("Velocidade após rebote muito baixa, parando projétil")
		is_moving = false
		velocity = Vector2.ZERO

func _on_body_entered(body):
	print("Body entered: ", body.name)
	# Se colidir com parede estática (TileMap ou nó “Wall”), trata como rebote
	if body.name == "wall" or "Wall" in body.name or body is TileMap or "TileMap" in body.name:
		print("Colidiu com parede: ", body.name)
		if wall_ray.is_colliding():
			handle_wall_collision(wall_ray.get_collision_normal())
		else:
			var approximated_normal = (global_position - body.global_position).normalized()
			handle_wall_collision(approximated_normal)
		return

	# Se encontrar o player enquanto ainda está se movendo, ignoramos (coleta só é válida quando parado)
	if body.is_in_group("player") and is_moving:
		return
