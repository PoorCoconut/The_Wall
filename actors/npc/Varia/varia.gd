extends "res://actors/npc/npc_base.gd"
class_name NPCVaria


func _on_interact_area_interacted() -> void:
	Dialogic.start("v_greet")
	
