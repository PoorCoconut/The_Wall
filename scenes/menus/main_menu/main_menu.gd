extends Node2D

@export var next_scene : PackedScene

#func _ready() -> void:
	#%CanvasFader.color = Color()

func _on_button_new_game_pressed() -> void:
	print("Possible new game+ content")

func _on_button_continue_pressed() -> void:
	%Anim_ZoomFX.play("zoom")
	var tween = get_tree().create_tween()
	tween.tween_property(%MenuMusic, "volume_db", -60, 5)

func _on_button_options_pressed() -> void:
	%Camera2D.global_position = Vector2(416.0, 96.0)

func _on_button_quit_pressed() -> void:
	get_tree().quit()


func _on_button_back_to_menu_pressed() -> void:
	%Camera2D.global_position = Vector2(160.0, 96.0)

func _on_anim_zoom_fx_animation_finished(_anim_name: StringName) -> void:
	get_tree().change_scene_to_packed(next_scene)
