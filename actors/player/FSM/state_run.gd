extends State
class_name PlayerRun

@export var PLAYER : Player

func enter():
	%DustStep.emitting = true

func update(delta: float):
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	#Update Player Direction Tracking (For animations and shooting)
	if input_dir != Vector2.ZERO:
		PLAYER.cur_dir = input_dir
		PLAYER.last_dir = input_dir
		
		#Updating specific axes if needed for your 4-way/8-way blend space
		if input_dir.x != 0:
			PLAYER.last_dir_x = input_dir.x
		if input_dir.y != 0:
			PLAYER.last_dir_y = input_dir.y
	
	#Movement Component handles the math
	PLAYER.movement_component.accelerate_in_direction(input_dir, delta)
	PLAYER.movement_component.move()
	
	#Check Transitions
	if Input.is_action_just_pressed("dash") and GameManager.has_dash and PLAYER.canDash: 
		transition.emit(self, "Dash")
	elif Input.is_action_just_pressed("attack"):
		transition.emit(self, "Atk1")
	elif Input.is_action_just_pressed("attack_range"):
		transition.emit(self, "Shoot")
		
	#Check the component's internal velocity to see if we've come to a stop
	elif PLAYER.movement_component.current_velocity == Vector2.ZERO:
		transition.emit(self, "Idle")

func exit():
	%DustStep.emitting = false
