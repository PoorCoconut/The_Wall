extends Node

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug"):
		$Window/NativeAcceptDialog.show()
	$Window.position = Vector2i($Window/player.global_position.x + 1000, $Window/player.global_position.y)

func _on_window_close_requested() -> void:
	
	get_tree().queue_delete($Window)
