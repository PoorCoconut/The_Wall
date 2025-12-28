extends State
class_name Player_Atk1

#1st timer to wait out the attack animation [might be able to switch the timer to the anim end signal]
#2nd Timer is to listen for the attack input for combo
@export var PLAYER : Player
@export var STATS : Stats_Component
var combo : bool = false
var can_combo : bool = true

@onready var ComboTimer : Timer = $ComboTimer

func enter():
	combo = false
	can_combo = true
	ComboTimer.start()
	
	%attack.pitch_scale = randf_range(1.0,1.3)
	%attack.play()

func update(delta:float): #"Generally holds the transitions"
	#THIS IS THE SLIDE
	PLAYER.velocity = PLAYER.velocity.move_toward(Vector2.ZERO, STATS.FRICTION * delta)
	PLAYER.move_and_slide()
	
	
	if Input.is_action_just_pressed("attack") and can_combo:
		combo = true
		transition.emit(self, "Atk2")

func _on_combo_timer_timeout() -> void:
	can_combo = false
	if !combo:
		transition.emit(self, "Run")
