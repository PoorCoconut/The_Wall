extends EnemyState

## CHASE STATE WITH NAV
## Moves toward the player using NavigationAgent2D for obstacle avoidance.
## Falls back to a direct direction vector if no nav agent is present,
## so the crawler still works in scenes without a NavigationRegion2D.
##
## Transitions:
##   → Idle : target lost (player left attack range)

# How close to the next path point before we ask for the next one.
# Keeps the crawler from oscillating around corners.
const PATH_DESIRED_DISTANCE : float = 4.0

var _nav : NavigationAgent2D = null

func enter() -> void:
	_nav = _find_nav_agent()

	if _nav:
		# Tune the agent for a compact, fast-reacting enemy
		_nav.path_desired_distance     = PATH_DESIRED_DISTANCE
		_nav.target_desired_distance   = PATH_DESIRED_DISTANCE
		_nav.avoidance_enabled         = true   # steers around other agents too

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
	pass

# ─────────────────────────────────────────────────────────────────
# NAVIGATION HELPERS
# ─────────────────────────────────────────────────────────────────

func _navigate_with_agent(delta: float) -> void:
	# Update destination every frame (player moves)
	_nav.target_position = enemy.target.global_position

	if _nav.is_navigation_finished():
		return

	var next_point : Vector2 = _nav.get_next_path_position()
	enemy.look_at_target(next_point)
	enemy.move_toward_point(next_point, delta)

func _navigate_direct(delta: float) -> void:
	# Simple fallback: straight line, no wall avoidance
	enemy.look_at_target(enemy.target.global_position)
	enemy.move_toward_point(enemy.target.global_position, delta)

func _find_nav_agent() -> NavigationAgent2D:
	for child in enemy.get_children():
		if child is NavigationAgent2D:
			return child
	push_warning("EnemyChase: No NavigationAgent2D found on %s — using direct movement." % enemy.name)
	return null
