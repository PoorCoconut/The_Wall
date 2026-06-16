extends EnemyState

## CHASE STATE
## The enemy moves toward its target.
## Transitions:
##   → Idle   : target lost
##   → Attack : target enters attack range

func enter() -> void:
	if enemy.sprite is AnimatedSprite2D:
		enemy.sprite.play("walk")

func update(delta: float) -> void:
	if not has_target():
		go_to("Idle")
		return

	# Face and move toward the target
	enemy.look_at_target(enemy.target.global_position)
	enemy.move_toward_point(enemy.target.global_position, delta)

	if enemy.target_in_attack_range:
		go_to("Attack")

func exit() -> void:
	pass
