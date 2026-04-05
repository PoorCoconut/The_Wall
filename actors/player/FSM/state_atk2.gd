extends State
class_name Player_Atk2

@export var PLAYER : Player
var wants_to_combo : bool = false

@onready var ComboTimer : Timer = $ComboTimer
@export var lunge_strength : float = 150.0

func enter():
	wants_to_combo = false
	ComboTimer.start()
	
	%attack_sword2.pitch_scale = randf_range(0.8, 1.3)
	%attack_sword2.play()
	
	var mouse_pos = PLAYER.get_global_mouse_position()
	var dir_to_mouse = PLAYER.global_position.direction_to(mouse_pos)
	PLAYER.movement_component.current_velocity = dir_to_mouse * lunge_strength

func update(delta: float):
	PLAYER.movement_component.apply_friction(delta)
	PLAYER.movement_component.move()
	
	# Buffer the gun combo
	if Input.is_action_just_pressed("attack_range"):
		wants_to_combo = true

func _on_combo_timer_timeout() -> void:
	if wants_to_combo:
		transition.emit(self, "Shoot")
		
	#Check for the hold and the power if unlocked
	elif Input.is_action_pressed("attack") and GameManager.has_strike: 
		transition.emit(self, "Charge")
		
	else:
		# If they are holding the button but DON'T have the power, return to normal movement
		if Input.get_vector("left", "right", "up", "down") == Vector2.ZERO:
			transition.emit(self, "Idle")
		else:
			transition.emit(self, "Run")
