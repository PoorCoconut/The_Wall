extends StaticBody2D
class_name EnemyTest

@export var STATS : Node

signal deal_damage(damage:int, knockback:float)

func _on_area_2d_area_entered(area: Area2D) -> void:
	#print("Something is in me!")
	if area.is_in_group("Player"):
		#print("It's the Player!")
		deal_damage.emit(STATS.CONTACT_DMG, STATS.KNOCKBACK)
		GameManager.enemyhitpos = self.global_position
