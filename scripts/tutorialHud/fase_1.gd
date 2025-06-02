extends Node2D

@onready var wall_move = $wallMove
@onready var wall_trigger = $wallTrigger
@onready var boss = $Boss

func _ready():
	wall_move.enabled = false
	wall_trigger.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	print("Colidiu com algo: ", body.name)
	if body.is_in_group("player"):
		boss.activate()
		print("Player colidiu com o gatilho!")
		wall_move.enabled = true
