extends CanvasLayer

@onready var highlightResume = $VBoxContainer/btn_resume/HighlightResume
@onready var highlightExit = $VBoxContainer/btn_exit/HighlightExit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_btn_resume_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/fase_1.tscn")

func _on_btn_exit_pressed() -> void:
	get_tree().quit()
