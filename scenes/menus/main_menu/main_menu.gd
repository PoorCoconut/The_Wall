extends Node2D
#
#func _ready() -> void:
	#%CanvasFader.color = Color()

func _on_button_new_game_pressed() -> void:
	print("Possible new game+ content")

func _on_button_continue_pressed() -> void:
	%Anim_ZoomFX.play("zoom")

func _on_button_options_pressed() -> void:
	%Camera2D.global_position = Vector2(416.0, 96.0)

func _on_button_quit_pressed() -> void:
	get_tree().quit()


func _on_button_back_to_menu_pressed() -> void:
	%Camera2D.global_position = Vector2(160.0, 96.0)

func _on_anim_zoom_fx_animation_finished(_anim_name: StringName) -> void:
	print("Switch Scenes now")
