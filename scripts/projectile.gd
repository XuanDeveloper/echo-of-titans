extends Node2D
#att 19/03
var speed: float = 600.0
var direction: Vector2 = Vector2.ZERO
var max_bounces: int = 5  # ricochetes
var bounces: int = 0

@onready var animation := $Area2D/AnimatedSprite2D

func _ready():
	connect("area_entered", _on_area_entered)
	animation.play("basic")

func _physics_process(delta: float) -> void:
	# Move o projétil
	position += direction * speed * delta

func _on_area_entered(area: Area2D) -> void:
	# Se atingir uma parede, ricochetear
	if area.is_in_group("walls"):  
		if bounces < max_bounces:
			bounces += 1
			direction = direction.rotated(randf_range(-PI / 4, PI / 4))  # Rotação aleatória 
		else:
			queue_free()  # Remove o projétil após atingir o limite de ricochetes (alterar para ser coletado)

	# Se atingir um inimigo, destrói o projétil e o inimigo (alterar para o projetil ficar no chão)
	elif area.is_in_group("enemies"):
		area.queue_free()  # Remove o inimigo
		queue_free()  # Remove o projétil
