extends State
class_name PlayerStrike

@export var PLAYER : Player
@onready var StrikeTimer : Timer = $StrikeTimer #Use animation finished instead of timers

func enter():
	StrikeTimer.start()
	GameManager.do_camera_shake(8.0, 0.4) # Big impact needs big screen shake
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
