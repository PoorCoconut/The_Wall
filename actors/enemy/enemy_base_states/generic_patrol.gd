extends EnemyState

## PATROL STATE
## The enemy wanders to randomly chosen points within a radius around its
## spawn position. If the scene has a NavigationAgent2D child on the enemy,
## it will path-find around obstacles; otherwise it walks in a straight line.
##
## Transitions:
##   → Chase : enemy.target becomes non-null (player detected)
##
## Required on the enemy scene:
##   - MovementComponent
##
## Optional (but recommended) on the enemy scene:
##   - NavigationAgent2D  (child node, any name — we find it by type)
##
## Inspector exports let you tune patrol behaviour per-enemy without
## touching this script.

@export_group("Patrol")
@export var wander_radius      : float = 80.0   # max distance from spawn origin
@export var wait_time_min      : float = 1.0    # seconds to idle between walks
@export var wait_time_max      : float = 3.0    # seconds to idle between walks
@export var arrival_threshold  : float = 6.0    # distance considered "arrived"

# Internal
var _spawn_origin   : Vector2
var _current_goal   : Vector2
var _nav_agent      : NavigationAgent2D
var _waiting        : bool = false
var _wait_elapsed   : float = 0.0
var _wait_duration  : float = 0.0

func enter() -> void:
	# Record where the enemy spawned — patrol stays near here
	_spawn_origin = enemy.global_position

	# Look for a NavigationAgent2D anywhere on the enemy (direct child is fine)
	_nav_agent = _find_nav_agent()

	_pick_new_goal()

	if enemy.sprite is AnimatedSprite2D:
		enemy.sprite.play("walk")

func update(delta: float) -> void:
	# Always bail out to Chase the moment a target appears
	if has_target():
		go_to("Chase")
		return

	if _waiting:
		_wait_elapsed += delta
		if _wait_elapsed >= _wait_duration:
			_waiting = false
			_pick_new_goal()
			if enemy.sprite is AnimatedSprite2D:
				enemy.sprite.play("walk")
		else:
			enemy.stop_moving(delta)
			return

	# ── Move toward the current goal ──────────────────────────────
	if _nav_agent:
		# NavigationAgent2D handles obstacle avoidance
		_nav_agent.target_position = _current_goal
		if _nav_agent.is_navigation_finished():
			_start_wait()
			return
		var next_pos = _nav_agent.get_next_path_position()
		enemy.move_toward_point(next_pos, delta)
		enemy.look_at_target(next_pos)
	else:
		# Straight-line fallback
		var dist_to_goal = enemy.global_position.distance_to(_current_goal)
		if dist_to_goal <= arrival_threshold:
			_start_wait()
			return
		enemy.move_toward_point(_current_goal, delta)
		enemy.look_at_target(_current_goal)

func exit() -> void:
	_waiting = false

# ─────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────

func _pick_new_goal() -> void:
	# Try a few times to find a point the NavigationServer considers reachable
	var attempts := 8
	for _i in range(attempts):
		var candidate = _random_point_in_radius()
		if _nav_agent:
			# NavigationServer2D.map_get_closest_point returns the nearest
			# point ON the navmesh — if it's close to our candidate, it's valid
			var map      = _nav_agent.get_navigation_map()
			var on_mesh  = NavigationServer2D.map_get_closest_point(map, candidate)
			if on_mesh.distance_to(candidate) < wander_radius * 0.5:
				_current_goal = on_mesh
				return
		else:
			# No navmesh — accept any point (straight-line movement)
			_current_goal = candidate
			return

	# Fallback: just return to spawn origin
	_current_goal = _spawn_origin

func _random_point_in_radius() -> Vector2:
	# Uniform distribution inside a circle (not just on its edge)
	var angle  = randf() * TAU
	var radius = sqrt(randf()) * wander_radius   # sqrt keeps it uniform inside the circle
	return _spawn_origin + Vector2(cos(angle), sin(angle)) * radius

func _start_wait() -> void:
	_waiting      = true
	_wait_elapsed = 0.0
	_wait_duration = randf_range(wait_time_min, wait_time_max)
	if enemy.sprite is AnimatedSprite2D:
		enemy.sprite.play("idle")

func _find_nav_agent() -> NavigationAgent2D:
	for child in enemy.get_children():
		if child is NavigationAgent2D:
			return child
	return null
