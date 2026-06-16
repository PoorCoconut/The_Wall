extends EnemyState

## SHOOT STATE  (Ranged / Mixed enemies)
## Activates the BulletSprayer_Component while the enemy is in this state.
## The enemy stands still, faces the target, and fires until it is out of range.
##
## Transitions:
##   → Chase : target leaves attack range (or target lost)
##   → Idle  : target lost

@export var min_engage_distance : float = 32.0   # stay at least this far away

func enter() -> void:
	enemy.set_sprayer_active(true)
	if enemy.sprite is AnimatedSprite2D:
		enemy.sprite.play("shoot")

func update(delta: float) -> void:
	if not has_target():
		go_to("Idle")
		return

	enemy.look_at_target(enemy.target.global_position)

	var d = dist()

	# If the player walks into melee range, back off a little
	if d < min_engage_distance:
		var away_dir = (enemy.global_position - enemy.target.global_position).normalized()
		enemy.movement_component.set_velocity(away_dir)
		enemy.movement_component.apply_friction(delta)
		enemy.movement_component.move()
	else:
		enemy.stop_moving(delta)

	# Leave if the target escapes attack range
	if not enemy.target_in_attack_range:
		go_to("Chase")

func exit() -> void:
	enemy.set_sprayer_active(false)
