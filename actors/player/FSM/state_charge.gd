extends State
class_name PlayerCharge

@export var PLAYER : Player

var original_speed : float
var current_charge_time : float = 0.0
@export var required_charge_time : float = 1.0

func enter():
	original_speed = PLAYER.movement_component.MAX_SPEED
	PLAYER.movement_component.MAX_SPEED = original_speed * 0.25
	current_charge_time = 0.0 # Reset the stopwatch every time!

func update(delta: float):
	current_charge_time += delta
	# (Optional Juice: If current_charge_time hits required_charge_time, 
	# play a *DING* sound or flash the sprite white so the player knows it's ready!)
	if current_charge_time >= required_charge_time:
		print("Charged!")
	
	#Handle Movement
	var input_dir = Input.get_vector("left", "right", "up", "down")
	if input_dir != Vector2.ZERO:
		var target_velocity = input_dir * PLAYER.movement_component.MAX_SPEED
		PLAYER.movement_component.current_velocity = PLAYER.movement_component.current_velocity.move_toward(target_velocity, PLAYER.movement_component.ACCELERATION * delta)
	else:
		PLAYER.movement_component.apply_friction(delta)
		
	PLAYER.movement_component.move()
	
	#Handle Transition
	if Input.is_action_just_released("attack"):
		if current_charge_time >= required_charge_time:
			#Held long enough. Do a strike
			transition.emit(self, "Strike")
		else:
			#Cancel attack if not held long enough
			if input_dir == Vector2.ZERO:
				transition.emit(self, "Idle")
			else:
				transition.emit(self, "Run")

func exit():
	# Always restore the speed!
	PLAYER.movement_component.MAX_SPEED = original_speed
