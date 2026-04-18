extends State
class_name PlayerCharge

@export var PLAYER : Player

var original_speed : float
var current_charge_time : float = 0.0
@export var required_charge_time : float = 1.0

var sfx_played : bool = false

func enter():
	sfx_played = false
	original_speed = PLAYER.movement_component.MAX_SPEED
	PLAYER.movement_component.MAX_SPEED = original_speed * 0.25
	current_charge_time = 0.0
func update(delta: float):
	current_charge_time += delta
	if current_charge_time >= required_charge_time:
		if !sfx_played:
			_play_strike_ready_sfx()
			sfx_played = true
	
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
	PLAYER.movement_component.MAX_SPEED = original_speed

func _play_strike_ready_sfx():
	%charged.pitch_scale = randf_range(0.8, 1.2)
	%charged.play()
