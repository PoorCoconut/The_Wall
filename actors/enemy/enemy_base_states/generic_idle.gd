extends EnemyState

## IDLE STATE
## The enemy stands still and waits.
## Transitions:
##   → Chase  : when enemy.target becomes non-null (detected by Looker/sight logic)

func enter() -> void:
	# Play idle animation if the sprite supports it
	if enemy.sprite is AnimatedSprite2D:
		enemy.sprite.play("idle")

func update(_delta: float) -> void:
	if has_target():
		go_to("Chase")

func exit() -> void:
	pass
