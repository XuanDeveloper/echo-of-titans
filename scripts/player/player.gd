extends CharacterBody2D

@export var move_speed : float = 180.0

func _physics_process(delta: float) -> void:
	# Captura o vetor de movimento diretamente dos inputs do teclado
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	# Normaliza o vetor para movimento consistente em todas as direções
	input_vector = input_vector.normalized()
	
	# Define a velocidade baseada no vetor de entrada
	velocity = input_vector * move_speed
	
	# Move o personagem
	move_and_slide()
