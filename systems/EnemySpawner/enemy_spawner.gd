extends Node2D
class_name EnemySpawner

## EnemySpawner
## Drop this scene anywhere in the world and call spawn() with any PackedScene
## that contains an EnemyBase (or subclass). The spawner handles everything:
##   1. Instantiates the enemy and immediately freezes it
##   2. Plays the light pillar build-up
##   3. Flashes at the peak
##   4. Releases the enemy and fades away
##   5. Frees itself
##
## The spawner never reads any property of the enemy directly —
## it only calls begin_spawn_freeze() and end_spawn_freeze() on EnemyBase.

# ─────────────────────────────────────────────────────────────────
# EXPORTS
# ─────────────────────────────────────────────────────────────────
@export_group("Timing")
## Total duration of the full spawn sequence (build-up + hold + flash + release).
## Set low (~0.2) for a quick flash; set high (~2.5) for a dramatic boss entrance.
@export var spawn_duration : float = 1.2

## How much of spawn_duration is spent building up the pillar before the flash.
## The rest is the flash + fade-out that happens after the enemy is released.
@export_range(0.0, 1.0) var buildup_ratio : float = 0.75

@export_group("Visuals")
## Tint of the light pillar (default: warm white).
@export var pillar_color   : Color = Color(1.0, 0.95, 0.8, 1.0)
## How wide the pillar is in pixels (scales with the sprite automatically).
@export var pillar_width   : float = 20.0
## How tall the pillar stretches above the spawn point.
@export var pillar_height  : float = 180.0
## Radius of the ground glow circle at the base.
@export var glow_radius    : float = 28.0

# ─────────────────────────────────────────────────────────────────
# CHILD NODE REFERENCES  (set up in _ready via code — no .tscn needed)
# ─────────────────────────────────────────────────────────────────
var _pillar    : ColorRect   # The vertical shaft of light
var _glow      : ColorRect   # The elliptical bloom at the base
var _particles : CPUParticles2D

# ─────────────────────────────────────────────────────────────────
# INTERNAL
# ─────────────────────────────────────────────────────────────────
var _enemy_instance : EnemyBase = null
var _spawn_scene    : PackedScene = null

# ─────────────────────────────────────────────────────────────────
# PUBLIC API
# ─────────────────────────────────────────────────────────────────

## Call this to kick off the spawn sequence.
##   entity_scene   — any PackedScene whose root extends EnemyBase
##   spawn_position — world position for both the spawner and the enemy
##   parent_node    — where to add the enemy (usually get_tree().current_scene)
func spawn(entity_scene: PackedScene, spawn_position: Vector2, parent_node: Node) -> void:
	_spawn_scene = entity_scene
	global_position = spawn_position

	# ── 1. Instantiate the enemy NOW so it exists during the effect ──
	_enemy_instance = entity_scene.instantiate() as EnemyBase
	if not _enemy_instance:
		push_error("EnemySpawner: PackedScene root is not an EnemyBase. Aborting.")
		queue_free()
		return

	_enemy_instance.global_position = spawn_position
	parent_node.add_child(_enemy_instance)

	# ── 2. Freeze it immediately ──────────────────────────────────
	_enemy_instance.begin_spawn_freeze()

	# ── 3. Run the visual sequence ────────────────────────────────
	_run_sequence()

# ─────────────────────────────────────────────────────────────────
# GODOT CALLBACKS
# ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_visuals()
	# Start fully invisible — visuals are driven by the tween in _run_sequence
	_set_alpha(0.0)

# ─────────────────────────────────────────────────────────────────
# SEQUENCE
# ─────────────────────────────────────────────────────────────────
func _run_sequence() -> void:
	var buildup_time  : float = spawn_duration * buildup_ratio
	var flash_time    : float = 0.08
	var fadeout_time  : float = spawn_duration * (1.0 - buildup_ratio)

	var tween = create_tween()
	tween.set_parallel(false)   # steps run one after another

	# ── PHASE 1: Build up ─────────────────────────────────────────
	# Pillar fades in and stretches upward
	tween.tween_method(_set_alpha,      0.0, 1.0, buildup_time * 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_pillar_scale, 0.0, 1.0, buildup_time * 0.4).set_ease(Tween.EASE_OUT)

	# ── PHASE 2: Hold briefly at peak ────────────────────────────
	tween.tween_interval(buildup_time * 0.15)

	# ── PHASE 3: Screen flash + release enemy ─────────────────────
	tween.tween_callback(_release_enemy)
	tween.tween_method(_set_alpha, 1.0, 0.0, flash_time)   # quick white pop

	# ── PHASE 4: Fade out the remaining glow ─────────────────────
	tween.tween_method(_set_alpha, 0.6, 0.0, fadeout_time).set_ease(Tween.EASE_IN)

	# ── DONE ─────────────────────────────────────────────────────
	tween.tween_callback(queue_free)

func _release_enemy() -> void:
	if _enemy_instance and is_instance_valid(_enemy_instance):
		_enemy_instance.end_spawn_freeze()

# ─────────────────────────────────────────────────────────────────
# VISUAL BUILDERS  (procedural — no .tscn nodes required)
# ─────────────────────────────────────────────────────────────────
func _build_visuals() -> void:
	# ── Glow circle at the base ──────────────────────────────────
	_glow = ColorRect.new()
	_glow.color = pillar_color
	_glow.size  = Vector2(glow_radius * 2.0, glow_radius)
	_glow.position = Vector2(-glow_radius, -glow_radius * 0.5)
	add_child(_glow)

	# ── Light pillar ──────────────────────────────────────────────
	_pillar = ColorRect.new()
	_pillar.color  = pillar_color
	_pillar.size   = Vector2(pillar_width, pillar_height)
	_pillar.position = Vector2(-pillar_width * 0.5, -pillar_height)
	add_child(_pillar)

	# ── Rising particles ─────────────────────────────────────────
	_particles = CPUParticles2D.new()
	_particles.amount          = 18
	_particles.lifetime        = 0.9
	_particles.explosiveness   = 0.0
	_particles.direction       = Vector2(0, -1)
	_particles.spread          = 18.0
	_particles.gravity         = Vector2.ZERO
	_particles.initial_velocity_min = 30.0
	_particles.initial_velocity_max = 70.0
	_particles.scale_amount_min     = 1.5
	_particles.scale_amount_max     = 3.5
	_particles.color                = pillar_color
	_particles.emission_shape       = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents = Vector2(pillar_width * 0.4, 4.0)
	add_child(_particles)

# ─────────────────────────────────────────────────────────────────
# TWEEN TARGETS
# ─────────────────────────────────────────────────────────────────
func _set_alpha(value: float) -> void:
	var c = pillar_color
	c.a = clampf(value, 0.0, 1.0)
	if _pillar:
		_pillar.color = c
	if _glow:
		var gc = c
		gc.a = c.a * 0.5   # glow is subtler than the pillar
		_glow.color = gc
	if _particles:
		_particles.color = c

func _set_pillar_scale(value: float) -> void:
	# The pillar "grows" from the bottom upward by scaling on Y
	if _pillar:
		_pillar.scale.y = value
		# Keep the base anchored to the ground while it grows
		_pillar.position.y = lerp(0.0, -pillar_height, value)
