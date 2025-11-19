extends State
class_name enemyHit

@onready var STATS : Stats_Component = %Stats_Component

func enter():
	pass

#func update(_delta:float):
	#knockback()

#func knockback():
	#var damage_source_position : Vector2
	#var knockback_direction = self.global_position.direction_to(damage_source_position)
	#var knockback_vector = -knockback_direction * enem_knockback / (1.0 + STATS.WEIGHT)
	#velocity = knockback_vector
