extends EnemyState

## STUNNED STATE
## Entered automatically by EnemyBase._on_hp_changed() via force_change_state("stunned").
## The enemy can't act. EnemyBase._on_stun_finished() calls force_change_state("idle")
## once the stun duration expires, so this state has no explicit transition logic.
##
## You CAN add knockback visuals, blink effects, or hitstop here.

func enter() -> void:
	if enemy.sprite is AnimatedSprite2D:
		enemy.sprite.play("hurt")

func update(_delta: float) -> void:
	# Movement during stun is handled by EnemyBase._physics_process (friction bleed-off).
	# Nothing to do here; we wait for EnemyBase to pop us out.
	pass

func exit() -> void:
	pass
