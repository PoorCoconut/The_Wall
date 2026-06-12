extends StaticBody2D
class_name SaveObelisk

@onready var sprite: Sprite2D = $Sprite
@onready var ground_particles: GPUParticles2D = $GroundParticles
@onready var shockwave: GPUParticles2D = $Shockwave
@export var location : String = "Somewhere in Apocrypha..." ##Please change this according the location

func _on_interaction_area_interacted() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	
	if player:
		GameManager.save_game(player.global_position, location, get_tree().current_scene.scene_file_path)
		play_save_feedback()

func play_save_feedback() -> void:
	# Play a specific animation, spawn particles, or play a chime
	shockwave.emitting = true
	
	# Optional: You can trigger a small UI popup here that says "Game Saved"
	print("Game Successfully Saved.")


func _on_body_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		ground_particles.emitting = true

func _on_body_detector_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		ground_particles.emitting = false
