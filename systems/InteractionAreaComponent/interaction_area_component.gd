extends Area2D
class_name InteractionAreaComponent

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		trigger_interaction()

func trigger_interaction() -> void:
	var overlapping_areas = get_overlapping_areas()
	if overlapping_areas.is_empty():
		return
	var closest_interactable = null
	var closest_distance = INF
	for area in overlapping_areas:
		if area: 
			var distance = global_position.distance_to(area.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_interactable = area
				
	if closest_interactable is InteractableArea:
		
		closest_interactable.interacted.emit()
