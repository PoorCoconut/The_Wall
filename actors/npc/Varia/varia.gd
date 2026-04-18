extends "res://actors/npc/npc_base.gd"
class_name NPCVaria

@export var dialogue : String = "v_greet" #  <--Fail safe

func _on_interact_area_interacted() -> void:
	Dialogic.start(dialogue)

func _on_interact_area_toggle_display_hint() -> void:
	if %InteractHint.visible == false:
		%InteractHint.show()
	else:
		%InteractHint.hide()
