extends State
class_name PlayerDash

@export var PLAYER : Player
@export var STATS :Stats_Component
@export var Dash_Trail : DashTrail

@onready var DashCooldown : Timer = $DashCooldown
@onready var DashDuration : Timer = $DashDuration

func enter():
	#trail_handler()
	
	PLAYER.canDash = false
	DashCooldown.wait_time = STATS.DASH_CD
	DashCooldown.start()
	DashDuration.start()

func update(delta:float):
	dash(delta);
	pass

func get_input():
	var input = Vector2.ZERO
	if Input.is_action_pressed("right"):
		input.x += 1
	if Input.is_action_pressed("left"):
		input.x -= 1
	if Input.is_action_pressed("down"):
		input.y += 1
	if Input.is_action_pressed("up"):
		input.y -= 1
	return input.normalized()

func dash(_delta : float):
	var direction = get_input()
	PLAYER.velocity = PLAYER.velocity.move_toward(direction * STATS.DASH_DIST, STATS.DASH_ACCEL)
	PLAYER.move_and_slide()

#func trail_handler():
	#if PLAYER.last_dir_x == 0 and PLAYER.last_dir_y == 0:
		#Dash_Trail.emit_particle("FL")
		#
		#
	#elif PLAYER.last_dir_x == -1 and PLAYER.last_dir_y == 0:
		#Dash_Trail.emit_particle("FL")
	#elif PLAYER.last_dir_x == 1 and PLAYER.last_dir_y == 0:
		#Dash_Trail.emit_particle("FR")
	#elif PLAYER.last_dir_x == 0 and PLAYER.last_dir_y == 1:
		#Dash_Trail.emit_particle("BR")
	#elif PLAYER.last_dir_x == 0 and PLAYER.last_dir_y == -1:
		#Dash_Trail.emit_particle("FL")
		#
		#
	#elif PLAYER.last_dir_x == 1 and PLAYER.last_dir_y == -1:
		#Dash_Trail.emit_particle("FR")
	#elif PLAYER.last_dir_x == -1 and PLAYER.last_dir_y == -1:
		#Dash_Trail.emit_particle("FL")
	#elif PLAYER.last_dir_x == -1 and PLAYER.last_dir_y == 1:
		#Dash_Trail.emit_particle("BL")
	#elif PLAYER.last_dir_x == 1 and PLAYER.last_dir_y == 1:
		#Dash_Trail.emit_particle("BR")
	#
	#else:
		#print("DASH STATE ERROR: TRAIL ERROR; LAST DIRECTIONS OUT OF BOUNDS")
		#print("Last_DIR X = ", PLAYER.last_dir_x)
		#print("Last_DIR Y = ", PLAYER.last_dir_y)

#The Dash's cooldown
func _on_dash_cooldown_timeout() -> void:
	PLAYER.canDash = true
	#print("PLAYER CAN NOW DASH AGAIN")

#The Dash's duration. When timer is finished, it switches to the Run State
func _on_dash_duration_timeout() -> void:
	transition.emit(self, "Run")
	#print("DASH DURATION ENDED")
