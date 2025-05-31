extends Area2D

signal shield_hit
signal shield_broken

@export var max_lives: int = 6
var lives: int
@export var animated_sprite_path: NodePath = "AnimatedSprite2D"
var sprite_ref: AnimatedSprite2D = null

func _ready():
	lives = max_lives
	sprite_ref = get_node(animated_sprite_path)
	update_frame()

func hit():
	if lives <= 0:
		return
	lives -= 1
	update_frame()
	emit_signal("shield_hit")
	if lives == 0:
		emit_signal("shield_broken")
		queue_free()

func update_frame():
	if sprite_ref:
		sprite_ref.frame = max_lives - lives
