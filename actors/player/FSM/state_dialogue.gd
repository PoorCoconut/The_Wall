extends "res://systems/FSM/state.gd"
class_name PlayerDialogue

@export var PLAYER : Player

func physics_update(delta: float) -> void:
	PLAYER.movement_component.apply_friction(delta)
	
	if GameManager.current_world_state != "Dialogue":
		transition.emit(self, "Idle")
