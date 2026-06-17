extends EnemyState

## CHASE STATE — NavigationAgent2D variant
## Moves toward the player using a NavigationAgent2D for wall-aware pathing.
## Falls back to a direct direction vector if no nav agent is present.
##
## IMPORTANT: avoidance_enabled is for agent-vs-agent avoidance only (other
## NavigationAgent2D nodes), NOT for walls. Wall avoidance comes purely from
## following the baked NavigationMesh path correctly — that's what this
## script does. Avoidance is OFF by default; see the export below.
##
## Transitions:
##   → Idle : target lost (player left attack range)

const PATH_DESIRED_DISTANCE : float = 4.0

## Turn on only if you actually want crawlers to steer around EACH OTHER
## (e.g. a swarm that shouldn't stack on top of one another). It costs extra
## per-agent overhead, so leave off unless you need it.
@export var use_agent_avoidance : bool = false

var _nav : NavigationAgent2D = null

func enter() -> void:
	_nav = _find_nav_agent()

	if _nav:
		_nav.path_desired_distance   = PATH_DESIRED_DISTANCE
		_nav.target_desired_distance = PATH_DESIRED_DISTANCE
		_nav.avoidance_enabled       = use_agent_avoidance

		if use_agent_avoidance:
			# Avoidance is signal-driven: Godot computes a safe velocity and
			# reports it back here. We MUST move using that reported velocity,
			# not get_next_path_position(), or the avoidance step is ignored
			# and the agent can walk straight through what it was steering around.
			if not _nav.velocity_computed.is_connected(_on_safe_velocity_computed):
				_nav.velocity_computed.connect(_on_safe_velocity_computed)

	if enemy.sprite is AnimatedSprite2D:
		enemy.sprite.play("walk")

func update(delta: float) -> void:
	if not has_target():
		go_to("Idle")
		return

	if _nav:
		_navigate_with_agent(delta)
	else:
		_navigate_direct(delta)

func exit() -> void:
	if _nav and _nav.velocity_computed.is_connected(_on_safe_velocity_computed):
		_nav.velocity_computed.disconnect(_on_safe_velocity_computed)

# ─────────────────────────────────────────────────────────────────
# NAVIGATION HELPERS
# ─────────────────────────────────────────────────────────────────

func _navigate_with_agent(delta: float) -> void:
	# Only update the target when it actually moved meaningfully — recomputing
	# every single frame is one of the biggest hidden costs with many agents.
	if enemy.target.global_position.distance_to(_nav.target_position) > 8.0:
		_nav.target_position = enemy.target.global_position

	if _nav.is_navigation_finished():
		return

	var next_point : Vector2 = _nav.get_next_path_position()
	enemy.look_at_target(next_point)

	if use_agent_avoidance:
		# Tell the agent what velocity we WANT (toward next_point); avoidance
		# will adjust it and report back via velocity_computed.
		var desired_dir = (next_point - enemy.global_position).normalized()
		var desired_vel = desired_dir * enemy.movement_component.MAX_SPEED
		_nav.set_velocity(desired_vel)
	else:
		# No avoidance — move straight along the path point. This alone is
		# enough to go around static walls correctly.
		enemy.move_toward_point(next_point, delta)

func _navigate_direct(delta: float) -> void:
	enemy.look_at_target(enemy.target.global_position)
	enemy.move_toward_point(enemy.target.global_position, delta)

func _on_safe_velocity_computed(safe_velocity: Vector2) -> void:
	# Called by the NavigationServer once avoidance has adjusted our desired
	# velocity. This is the ONLY correct place to apply movement when
	# avoidance is enabled.
	if enemy.movement_component:
		enemy.movement_component.current_velocity = safe_velocity
		enemy.movement_component.move()

func _find_nav_agent() -> NavigationAgent2D:
	for child in enemy.get_children():
		if child is NavigationAgent2D:
			return child
	push_warning("ChaseNavAgent: No NavigationAgent2D found on %s — using direct movement." % enemy.name)
	return null
