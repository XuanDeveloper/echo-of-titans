extends CanvasLayer

var step = 0 
var tutorial_steps  = [
	{"action": "Left", "message": "para andar para a esquerda"},
	{"action": "Right", "message": "para andar para a direita"},
	{"action": "Down", "message": "para andar para descer"},
	{"action": "Up", "message": "para andar para subir"},
	{"action": "dash", "message": " dash"}
]


func _ready() -> void:
	update_message()

func _process(delta: float) -> void:
	if step < tutorial_steps.size():  
		var action = tutorial_steps[step]["action"]
		if Input.is_action_just_pressed(action):
			advance_tutorial()

func advance_tutorial():
	step += 1
	if step < tutorial_steps.size():
		update_message()
	else:
		queue_free()  


func update_message():
	var label_size = $TextWithKey/Label.size
	$BackgroundBox.size = label_size + Vector2(40, 20)  # Adiciona margem
	
	# Centraliza o fundo em relação ao texto
	
	$TextWithKey/Label.text = tutorial_steps[step]["message"]

	$TextWithKey/a_sprite.visible = false
	$TextWithKey/d_sprite.visible = false
	$TextWithKey/s_sprite.visible = false
	$TextWithKey/w_sprite.visible = false
	$TextWithKey/space_sprite.visible = false

	match tutorial_steps[step]["action"]:
		"Left":
			$TextWithKey/a_sprite.visible = true
		"Right":
			$TextWithKey/d_sprite.visible = true
		"Down":
			$TextWithKey/s_sprite.visible = true
		"Up":
			$TextWithKey/w_sprite.visible = true
		"dash":
			$TextWithKey/space_sprite.visible = true
