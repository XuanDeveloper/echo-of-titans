extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _unhandled_input(event):
	if event.is_action("ui_cancel"):
		visible = true
		get_tree().paused = true
	
func _on_btn_resume_pressed() -> void:
	visible = false
	get_tree().paused = false


func _on_btn_exit_pressed() -> void:
	get_tree().quit()
