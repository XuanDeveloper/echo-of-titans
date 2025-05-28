extends Control
@onready var highlightExit = $VBoxContainer/HBoxContainer/VBoxContainer/btn_exit/HighlightExit
@onready var highlightPlay = $VBoxContainer/HBoxContainer/VBoxContainer/btn_play/HighlightPlay

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	highlightPlay.visible = false
	highlightExit.visible = false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_btn_exit_pressed() -> void:
	get_tree().quit()


func _on_btn_exit_mouse_entered() -> void:
	highlightExit.visible = true


func _on_btn_exit_mouse_exited() -> void:
	highlightExit.visible = false


func _on_btn_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/fase_1.tscn")


func _on_btn_play_mouse_entered() -> void:
	highlightPlay.visible = true


func _on_btn_play_mouse_exited() -> void:
	highlightPlay.visible = false
