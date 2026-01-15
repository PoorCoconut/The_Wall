extends State
class_name Player_Atk2

@export var PLAYER : Player
@export var STATS : Stats_Component
var combo : bool = false
var can_combo : bool = true
@onready var ComboTimer : Timer = $ComboTimer

func enter():
	combo = false
	can_combo = true
	ComboTimer.start()
	
	%attack_sword.pitch_scale = randf_range(1.0,1.3)
	%attack_sword.play()

func update(delta:float): #"Generally holds the transitions"
	PLAYER.velocity = PLAYER.velocity.move_toward(Vector2.ZERO, STATS.FRICTION * delta)
	PLAYER.move_and_slide()
	if Input.is_action_just_pressed("attack_range") and can_combo:
		combo = true
		transition.emit(self, "Shoot")

func _on_combo_timer_timeout() -> void:
	can_combo = false
	if !combo:
		transition.emit(self, "Run")
