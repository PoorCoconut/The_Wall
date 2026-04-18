extends State
class_name PlayerLock
@export var PLAYER : Player

func update(delta : float):
	PLAYER.movement_component.apply_friction(delta)
	if GameManager.current_world_state != "freeze":
		transition.emit(self, "Idle")
