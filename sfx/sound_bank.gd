extends Node2D

func play(sfx_name : String) -> void:
	var foundFlag : bool = false
	for node in get_children():
		if sfx_name.to_lower() == node.name.to_lower():
			node.pitch_scale = randf_range(0.9, 1.2)
			node.play()
			foundFlag = true
			break

	if !foundFlag:
		print("Name: " + sfx_name + " not found in children of SoundBank.")

func _on_hit_metal_1_finished() -> void:
	queue_free()

func _on_hit_metal_2_finished() -> void:
	queue_free()

func _on_hit_organic_finished() -> void:
	queue_free()
