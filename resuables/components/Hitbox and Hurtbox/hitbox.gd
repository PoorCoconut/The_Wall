extends Area2D
class_name ComponentHitbox
var parent
var damage : int = 0

func _ready() -> void:
	parent = self.get_parent()

func _on_area_entered(area: Area2D) -> void:
	if parent.has_method("get_damage"):
		damage = parent.get_damage()
	else:
		print(parent.name + " has no get damage function. Setting attack to 0.")
	var area_parent = area.get_parent()
	if area_parent.has_method("take_damage"):
		area_parent.take_damage(damage)
	else:
		print(parent.name + " has no take damage function")
