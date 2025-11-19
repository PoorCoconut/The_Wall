extends State
class_name PlayerDash

@export var player : CharacterBody2D
@export var STATS :Stats_Component
@export var Dash_Trail : DashTrail

@export_category("Chain Dash Variables")
@export var Early_Time : float = 0.3
@export var Window_Time : float = 0.5
@export var Reset_Time : float = 0.5

@export var CHAIN_FORCE : float = 0.05
var CHAIN_VELOCITY : float = 1.0

@onready var dashTimer : Timer = $dashTimer
@onready var chainTimer : Timer = $chainTimer

enum CHAIN_STATE{EARLY, READY, RESET}
var can_chain : bool = false
var chained : bool = false
var chain_phase := CHAIN_STATE.EARLY


func enter():
	trail_handler()
	dashTimer.start()
	chain_start()

func update(delta:float):
	dash(delta)

func _input(_event: InputEvent) -> void:
	if can_chain and Input.is_action_just_pressed("dash"):
		#print("chained")
		chained = true
		CHAIN_VELOCITY += CHAIN_FORCE
		player.dash_chain += 1
		
	elif Input.is_action_just_pressed("dash"):
		CHAIN_VELOCITY = 1.0
		player.dash_chain = 0
		#print("pressed dash but not possible to chain")

func dash(delta):
	player.velocity = player.velocity.lerp(player.last_dir * STATS.DASH_DIST, STATS.DASH_ACCEL * delta).normalized() * (STATS.DASH_DIST * CHAIN_VELOCITY)
	player.move_and_slide()

func chain_start():
	chain_phase = CHAIN_STATE.EARLY
	can_chain = false
	chained = false
	chainTimer.wait_time = Early_Time  # "too early" cooldown
	chainTimer.start()
	#print("Too early phase started.")

func _on_dash_timer_timeout() -> void:
	player.velocity = player.velocity.move_toward(Vector2.ZERO, STATS.DASH_FRICTION) #Actually this works well; just need move and slide
	transition.emit(self, "Run")

func _on_chain_timer_timeout() -> void:
	match chain_phase:
		CHAIN_STATE.EARLY:
			chain_phase = CHAIN_STATE.READY
			can_chain = true
			chainTimer.wait_time = Window_Time
			chainTimer.start()
			#print("Dash window OPEN!")
		CHAIN_STATE.READY:
			chain_phase = CHAIN_STATE.RESET
			can_chain = false
			chainTimer.wait_time = Reset_Time
			chainTimer.start()
			#print("Entering reset...")
		CHAIN_STATE.RESET:
			chain_phase = CHAIN_STATE.EARLY
			chained = false
			#print("Reset complete.")
			
			CHAIN_VELOCITY = 1.0
			player.dash_chain = 0

func trail_handler():
	if player.last_dir_x == 0 and player.last_dir_y == 0:
		Dash_Trail.emit_particle("FL")
		
		
	elif player.last_dir_x == -1 and player.last_dir_y == 0:
		Dash_Trail.emit_particle("FL")
	elif player.last_dir_x == 1 and player.last_dir_y == 0:
		Dash_Trail.emit_particle("FR")
	elif player.last_dir_x == 0 and player.last_dir_y == 1:
		Dash_Trail.emit_particle("BR")
	elif player.last_dir_x == 0 and player.last_dir_y == -1:
		Dash_Trail.emit_particle("FL")
		
		
	elif player.last_dir_x == 1 and player.last_dir_y == -1:
		Dash_Trail.emit_particle("FR")
	elif player.last_dir_x == -1 and player.last_dir_y == -1:
		Dash_Trail.emit_particle("FL")
	elif player.last_dir_x == -1 and player.last_dir_y == 1:
		Dash_Trail.emit_particle("BL")
	elif player.last_dir_x == 1 and player.last_dir_y == 1:
		Dash_Trail.emit_particle("BR")
	
	else:
		print("DASH STATE ERROR: TRAIL ERROR; LAST DIRECTIONS OUT OF BOUNDS")
		print("Last_DIR X = ", player.last_dir_x)
		print("Last_DIR Y = ", player.last_dir_y)
