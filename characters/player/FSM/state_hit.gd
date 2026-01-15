extends State
class_name PlayerHit


@export var PLAYER : Player
@export var STATS : Stats_Component
var knockback : Vector2 = Vector2.ZERO
var knockback_timer : float = 0.0

func enter():
	pass

func update(delta:float):
	
	if knockback_timer > 0.0:
		PLAYER.velocity = knockback
		knockback_timer -= delta
		if knockback_timer <= 0.0:
			knockback = Vector2.ZERO
	else:
		transition.emit(self, "Run")
