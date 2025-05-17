extends Area2D
@export var player: Node
@export var speed: float = 600.0
@export var friction: float = 1000.0
@export var bounce_factor: float = 0.7  # Fator de rebote (0-1)
@export var max_bounces: int = 3  # Número máximo de rebotes
var direction: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var is_moving: bool = true
var bounce_count: int = 0
@onready var wall_ray := $WallRay

func _ready():
	# Garantir que os sinais estão conectados
	if not is_connected("body_entered", _on_body_entered):
		connect("body_entered", _on_body_entered)
	
	# Configuração inicial
	velocity = direction.normalized() * speed
	update_raycast()
	wall_ray.enabled = true
	
	# Camadas de colisão
	collision_mask = 0xFFFF
	wall_ray.collision_mask = 0xFFFF
	
	print("Projétil inicializado, direção:", direction)

func update_raycast():
	# Atualiza a direção do raycast para apontar na direção da velocidade
	if velocity.length() > 0:
		wall_ray.target_position = velocity.normalized() * 15

func _physics_process(delta):
	if is_moving:
		update_raycast()
		wall_ray.force_raycast_update()
		
		# Verifica colisão com o raycast
		if wall_ray.is_colliding():
			handle_wall_collision(wall_ray.get_collision_normal())
		
		# Aplica fricção e move o projétil
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		position += velocity * delta
		
		# Verifica se está muito lento
		if velocity.length() < 10:
			print("Projétil parou devido à velocidade baixa")
			is_moving = false
			velocity = Vector2.ZERO

func handle_wall_collision(normal: Vector2):
	bounce_count += 1
	print("Rebote #", bounce_count, " Normal:", normal)
	
	# Aplica o rebote usando a fórmula de reflexão
	velocity = velocity.bounce(normal) * bounce_factor
	
	# Move o projétil ligeiramente para fora da colisão para evitar ficar preso
	position += normal * 5
	
	print("Velocidade após rebote: ", velocity)
	
	# Verifica se atingiu o número máximo de rebotes
	if bounce_count >= max_bounces:
		print("Número máximo de rebotes atingido, parando projétil")
		is_moving = false
		velocity = Vector2.ZERO
		return
	
	# Se a velocidade for muito baixa após o rebote, pare o projétil
	if velocity.length() < 50:
		print("Velocidade após rebote muito baixa, parando projétil")
		is_moving = false
		velocity = Vector2.ZERO

func _on_body_entered(body):
	print("Body entered: ", body.name)
	
	# Se for uma parede, calcule o rebote
	if body.name == "wall" or "Wall" in body.name or body is TileMap or "TileMap" in body.name:
		print("Colidiu com parede: ", body.name)
		
		# Primeiro tenta usar o raycast para obter a normal correta
		if wall_ray.is_colliding():
			handle_wall_collision(wall_ray.get_collision_normal())
		else:
			# Fallback: usa uma aproximação da normal baseada nas posições
			var approximated_normal = (global_position - body.global_position).normalized()
			handle_wall_collision(approximated_normal)
		
		return
	
	# Verifica se é o jogador
	if body.is_in_group("player"):
		if not is_moving:
			print("Projétil coletado pelo player!")
			if player and player.has_method("recover_projectile"):
				player.recover_projectile()
				queue_free()
		else:
			print("Projétil ainda está em movimento, jogador não pode coletar")
