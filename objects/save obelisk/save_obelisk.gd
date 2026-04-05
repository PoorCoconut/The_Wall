extends Node2D
class_name SaveObelisk

@onready var sprite: Sprite2D = $Sprite

func _on_interaction_area_interacted() -> void:
	print("DO SOMETHING!")
	var player = get_tree().get_first_node_in_group("Player")
	
	if player:
		GameManager.save_game(player.global_position)
		play_save_feedback()

func play_save_feedback() -> void:
	# Play a specific animation, spawn particles, or play a chime
	#sprite.play("saving")
	
	# Optional: You can trigger a small UI popup here that says "Game Saved"
	print("Game Successfully Saved.")
