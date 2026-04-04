extends State
class_name enemyChase

@export var ENEMY : CharacterBody2D
@export var STATS : Stats_Component

func enter():
	print("Enemy Crawler Transitioned to Chase")

func update(delta:float):
	if ENEMY.target != null:
		var direction = ENEMY.global_position.direction_to(ENEMY.target.global_position)
		ENEMY.velocity = ENEMY.velocity.lerp(direction * STATS.MAX_SPEED, STATS.ACCELERATION * delta)
	else:
		ENEMY.velocity = ENEMY.velocity.move_toward(Vector2.ZERO, STATS.FRICTION * delta)
		if ENEMY.velocity <= Vector2(1, 1):
			#print("Enemy Crawler Transitioning to Idle")
			transition.emit(self,"Idle")
	ENEMY.move_and_slide()
	pass
