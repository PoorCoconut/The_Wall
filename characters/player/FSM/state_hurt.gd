extends State
class_name PlayerHurt

@export var Player : CharacterBody2D
@export var STATS : Stats_Component
var damage_source_position : Vector2

func enter():
	#Do Animation -> Get Knockbacked -> Return to Idle
	damage_source_position = GameManager.enemyhitpos
	print(damage_source_position)
	knockback()
	pass

func update(delta:float):
	if !Player.velocity.is_zero_approx():
		#Codeblock
		var knockback_direction = Player.global_position.direction_to(damage_source_position)
		Player.velocity = Player.velocity.move_toward(Vector2.ZERO, STATS.FRICTION * delta)
	else:
		#Return to other state
		transition.emit(self, "Run")
	Player.move_and_slide()
	pass

func exit():
	pass

func knockback():
	var knockback_direction = Player.global_position.direction_to(damage_source_position)
	var knockback_vector = -knockback_direction * Player.enem_knockback / (1.0 + STATS.WEIGHT)
	Player.velocity = knockback_vector
