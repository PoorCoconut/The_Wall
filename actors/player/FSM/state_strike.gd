extends State
class_name PlayerStrike

@export var PLAYER : Player
@export var strike_lunge_strength : float = 300.0
@onready var StrikeTimer : Timer = $StrikeTimer #Use animation finished instead of timers


func enter():
	StrikeTimer.start()
	GameManager.do_camera_shake(8.0, 0.4) # Big impact needs big screen shake
	var mouse_pos = PLAYER.get_global_mouse_position()
	var dir_to_mouse = PLAYER.global_position.direction_to(mouse_pos)
	
	PLAYER.movement_component.current_velocity = dir_to_mouse * strike_lunge_strength
	# Turn on the massive strike hitbox here
	# Play the heavy swing animation and sound

func update(delta: float):
	PLAYER.movement_component.apply_friction(delta)
	PLAYER.movement_component.move()

func _on_strike_timer_timeout() -> void:
	if Input.get_vector("left", "right", "up", "down") == Vector2.ZERO:
		transition.emit(self, "Idle")
	else:
		transition.emit(self, "Run")
