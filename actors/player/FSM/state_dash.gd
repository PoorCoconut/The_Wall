extends State
class_name PlayerDash

@export var PLAYER : Player
@export var slide_duration : float = 0.75

@onready var DashCooldown : Timer = $DashCooldown
@onready var DashDuration : Timer = $DashDuration

var dash_direction : Vector2 = Vector2.ZERO

# The Two Phases of the Dash0
var is_dashing : bool = false
var in_combo_window : bool = false

# The Rhythm Timer
var combo_timer : float = 0.0
const COMBO_ALLOWANCE : float = 0.1 # You have exactly X seconds AFTER the dash to chain it.
var has_mashed : bool = false
var is_stumbling : bool = false



func enter():
	PLAYER.dashchain_damage_boost()
	
	var base_pitch = randf_range(0.8, 1.2)
	var chain_bonus = PLAYER.dash_chain * 0.1
	
	%dash.pitch_scale = min(base_pitch + chain_bonus, 4.0)
	%dash.play()
	PLAYER.canDash = false
	is_dashing = true
	in_combo_window = false
	has_mashed = false # Reset the mash flag every dash!
	
	# 1. LOCK THE DIRECTION
	dash_direction = Input.get_vector("left", "right", "up", "down")
	if dash_direction == Vector2.ZERO:
		dash_direction = PLAYER.last_dir
	else:
		PLAYER.cur_dir = dash_direction
		PLAYER.last_dir = dash_direction
		
	# Make sure the cooldown isn't running while we chain
	DashCooldown.stop() 
	DashDuration.start()

func update(delta: float):
	# PHASE 3: THE PUNISHMENT STUMBLE
	if is_stumbling:
		# Force them to slide, ignoring all player input
		PLAYER.movement_component.apply_friction(delta)
		PLAYER.movement_component.move()
		
		# Have they finally stopped sliding? (We use < 10.0 instead of 0 just to be safe)
		if PLAYER.movement_component.current_velocity.length() < 10.0:
			is_stumbling = false
			
			# NOW we safely release them back to normal gameplay
			if Input.get_vector("left", "right", "up", "down") == Vector2.ZERO:
				transition.emit(self, "Idle")
			else:
				transition.emit(self, "Run")
				
		return # VERY IMPORTANT: This stops the rest of the update function from running!
		
	# PHASE 1: ZOOMING FORWARD
	if is_dashing:
		PLAYER.movement_component.current_velocity = dash_direction * PLAYER.dash_speed
		PLAYER.movement_component.move()
		
		# THE MASH PUNISHMENT
		# If you press dash while you are STILL dashing, you fail the rhythm.
		if Input.is_action_just_pressed("dash"):
			has_mashed = true 
		
	# PHASE 2: THE SWEET SPOT (POST-DASH)
	elif in_combo_window:
		# If they spammed during Phase 1, instantly kick them out!
		if has_mashed:
			exit_dash()
			return
			
		# Apply friction so the Drifter "skids" momentarily
		PLAYER.movement_component.apply_friction(delta) 
		PLAYER.movement_component.move()
		
		combo_timer -= delta
		
		# If they hit the rhythm perfectly (and didn't mash earlier!):
		if Input.is_action_just_pressed("dash") and GameManager.has_dash:
			PLAYER.dash_chain += 1
			enter() 
			return
			
		# If they just let the window expire without pressing anything:
		if combo_timer <= 0.0:
			exit_dash()

func _on_dash_duration_timeout() -> void:
	# The physical dash is over. Open the rhythm window!
	is_dashing = false
	in_combo_window = true
	combo_timer = COMBO_ALLOWANCE 

func exit_dash() -> void:
	in_combo_window = false
	
	# THE PUNISHMENT LOGIC
	if PLAYER.dash_chain >= PLAYER.chains_to_damage:
		PLAYER.apply_stumble_debuff(0.5) 
		PLAYER.dashchain_damage_boost()
		PLAYER.dash_chain = 0
		DashCooldown.start()
		
		# THE FIX: Trap them in this state!
		is_stumbling = true 
		return # Stop reading code here. Do NOT transition!
		
	# NORMAL EXIT (If they didn't fail a high chain)
	PLAYER.dash_chain = 0
	DashCooldown.start()
	
	if Input.get_vector("left", "right", "up", "down") == Vector2.ZERO:
		transition.emit(self, "Idle")
	else:
		transition.emit(self, "Run")

func _on_dash_cooldown_timeout() -> void:
	PLAYER.canDash = true
