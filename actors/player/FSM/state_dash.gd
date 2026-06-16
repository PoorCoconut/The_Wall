extends State
class_name PlayerDash

@export var PLAYER : Player
@export var slide_duration : float = 0.75

@onready var DashCooldown : Timer = $DashCooldown
@onready var DashDuration : Timer = $DashDuration

var dash_direction : Vector2 = Vector2.ZERO

# The Two Phases of the Dash
var is_dashing : bool = false
var in_combo_window : bool = false

# The Rhythm Timer
var combo_timer : float = 0.0
const COMBO_ALLOWANCE : float = 0.1
var has_mashed : bool = false
var is_stumbling : bool = false

# ── DASH TRAIL ──────────────────────────────────────────────────────────────
## Preload the DashGhost scene (adjust path if yours differs).
const DashGhost : PackedScene = preload("res://actors/player/Dash Trail/dash_trail.tscn")

## Seconds between each ghost spawn. Lower = denser trail.
@export var ghost_interval: float = 0.04

## Tint colour for the ghosts (feel free to expose/change per chain level).
@export var ghost_tint: Color = Color(0.35, 0.78, 1.0, 0.65)

## How long each ghost takes to fade out completely.
@export var ghost_fade_duration: float = 0.18

var _ghost_timer: float = 0.0   # accumulator
# ────────────────────────────────────────────────────────────────────────────


func enter():
	PLAYER.dashchain_damage_boost()

	var base_pitch  = randf_range(0.8, 1.2)
	var chain_bonus = PLAYER.dash_chain * 0.1

	%dash.pitch_scale = min(base_pitch + chain_bonus, 4.0)
	%dash.play()
	PLAYER.canDash    = false
	is_dashing        = true
	in_combo_window   = false
	has_mashed        = false
	_ghost_timer      = 0.0   # spawn a ghost immediately on the next frame

	# 1. LOCK THE DIRECTION
	dash_direction = Input.get_vector("left", "right", "up", "down")
	if dash_direction == Vector2.ZERO:
		dash_direction = PLAYER.last_dir
	else:
		PLAYER.cur_dir  = dash_direction
		PLAYER.last_dir = dash_direction

	DashCooldown.stop()
	DashDuration.start()


func update(delta: float):
	# PHASE 3: THE PUNISHMENT STUMBLE
	if is_stumbling:
		PLAYER.movement_component.apply_friction(delta)
		PLAYER.movement_component.move()

		if PLAYER.movement_component.current_velocity.length() < 10.0:
			is_stumbling = false
			if Input.get_vector("left", "right", "up", "down") == Vector2.ZERO:
				transition.emit(self, "Idle")
			else:
				transition.emit(self, "Run")
		return

	# PHASE 1: ZOOMING FORWARD
	if is_dashing:
		PLAYER.movement_component.current_velocity = dash_direction * PLAYER.dash_speed
		PLAYER.movement_component.move()

		# ── Spawn trail ghosts ───────────────────────────────────────────────
		_ghost_timer -= delta
		if _ghost_timer <= 0.0:
			_ghost_timer = ghost_interval
			_spawn_ghost()
		# ────────────────────────────────────────────────────────────────────

		if Input.is_action_just_pressed("dash"):
			has_mashed = true

	# PHASE 2: THE SWEET SPOT (POST-DASH)
	elif in_combo_window:
		if has_mashed:
			exit_dash()
			return

		PLAYER.movement_component.apply_friction(delta)
		PLAYER.movement_component.move()

		combo_timer -= delta

		if Input.is_action_just_pressed("dash") and GameManager.has_dash:
			PLAYER.dash_chain += 1
			enter()
			return

		if combo_timer <= 0.0:
			exit_dash()


# ── TRAIL HELPER ─────────────────────────────────────────────────────────────
func _spawn_ghost() -> void:
	# Find the player's AnimatedSprite2D. Adjust the node path to match yours.
	var anim_sprite: Sprite2D = PLAYER.get_node_or_null("sprite")
	if anim_sprite == null: # adjust path if "sprite" is nested differently
		return  # safety check — won't crash if the node path is wrong

	var ghost: Node2D = DashGhost.instantiate()

	# Ghost tint can shift colour with chain depth for extra flair.
	ghost.tint_color    = _get_chain_tint()
	ghost.fade_duration = ghost_fade_duration

	# Add to the scene root so the ghost isn't a child of the player
	# (children would move with the player and ruin the trail effect).
	PLAYER.get_tree().current_scene.add_child(ghost)

	# setup() copies the sprite frame and sets the world position.
	ghost.setup(anim_sprite)


func _get_chain_tint() -> Color:
	# Optionally shift the hue as the dash chain grows — pure HLD vibes.
	# Remove/simplify this if you just want a flat colour.
	match PLAYER.dash_chain % 3:
		0: return Color(0.35, 0.78, 1.0,  0.65)   # cyan
		1: return Color(1.0,  0.35, 0.85, 0.65)   # magenta
		_: return Color(0.55, 1.0,  0.45, 0.65)   # green
# ─────────────────────────────────────────────────────────────────────────────


func _on_dash_duration_timeout() -> void:
	is_dashing      = false
	in_combo_window = true
	combo_timer     = COMBO_ALLOWANCE


func exit_dash() -> void:
	in_combo_window = false

	if PLAYER.dash_chain >= PLAYER.chains_to_damage:
		PLAYER.apply_stumble_debuff(0.5)
		PLAYER.dashchain_damage_boost()
		PLAYER.dash_chain = 0
		DashCooldown.start()
		is_stumbling = true
		return

	PLAYER.dash_chain = 0
	DashCooldown.start()

	if Input.get_vector("left", "right", "up", "down") == Vector2.ZERO:
		transition.emit(self, "Idle")
	else:
		transition.emit(self, "Run")


func _on_dash_cooldown_timeout() -> void:
	PLAYER.canDash = true
