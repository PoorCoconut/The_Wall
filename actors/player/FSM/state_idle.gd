extends State
class_name PlayerIdle

@export var PLAYER : Player

func enter():
	pass

func update(delta: float): 
	PLAYER.movement_component.apply_friction(delta)
	PLAYER.movement_component.move()
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	if input_dir != Vector2.ZERO:
		transition.emit(self, "Run")
	elif Input.is_action_just_pressed("dash") and GameManager.has_dash and PLAYER.canDash:
		transition.emit(self, "Dash")
	elif Input.is_action_just_pressed("attack"):
		transition.emit(self, "Atk1")
	elif Input.is_action_just_pressed("attack_range"):
		transition.emit(self, "Shoot")
