extends Node2D
class_name EnemySpawner

@onready var pillar: Line2D = $Pillar
@onready var land_particles: GPUParticles2D = $LandParticles

@export_group("Timing")
@export var spawn_duration : float = 1.2
@export_range(0.0, 1.0) var buildup_ratio : float = 0.75

@export_group("Enemy")
@export var default_enemy_scene : PackedScene

var _enemy_instance : EnemyBase = null
var _spawn_scene    : PackedScene = null

# ─────────────────────────────────────────────────────────────────
# PUBLIC API
# ─────────────────────────────────────────────────────────────────
func spawn(entity_scene: PackedScene, spawn_position: Vector2, parent_node: Node) -> void:
	var scene_to_use : PackedScene = entity_scene if entity_scene else default_enemy_scene
	if not scene_to_use:
		push_error("EnemySpawner: no entity_scene passed and no default_enemy_scene set.")
		queue_free()
		return

	_spawn_scene = scene_to_use
	global_position = spawn_position

	_enemy_instance = scene_to_use.instantiate() as EnemyBase
	if not _enemy_instance:
		push_error("EnemySpawner: PackedScene root is not an EnemyBase.")
		queue_free()
		return

	_enemy_instance.global_position = spawn_position
	parent_node.add_child(_enemy_instance)
	_enemy_instance.begin_spawn_freeze()

	_run_sequence()

# ─────────────────────────────────────────────────────────────────
# GODOT CALLBACKS
# ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	pillar.modulate.a = 0.0
	land_particles.emitting = false

# ─────────────────────────────────────────────────────────────────
# SEQUENCE
# ─────────────────────────────────────────────────────────────────
func _run_sequence() -> void:
	var buildup_time : float = spawn_duration * buildup_ratio
	var fadeout_time : float = spawn_duration * (1.0 - buildup_ratio)

	var tween = create_tween()
	tween.set_parallel(false)

	# Fade pillar in + start particles
	tween.tween_callback(func(): land_particles.emitting = true)
	tween.tween_property(pillar, "modulate:a", 1.0, buildup_time).set_ease(Tween.EASE_OUT)

	# Hold, then release the enemy
	tween.tween_interval(buildup_time * 0.15)
	tween.tween_callback(_release_enemy)

	# Fade pillar + particles out
	tween.tween_property(pillar, "modulate:a", 0.0, fadeout_time).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): land_particles.emitting = false)

	# Wait for any lingering particles, then free
	tween.tween_interval(1.0)
	tween.tween_callback(queue_free)

func _release_enemy() -> void:
	if _enemy_instance and is_instance_valid(_enemy_instance):
		_enemy_instance.end_spawn_freeze()
