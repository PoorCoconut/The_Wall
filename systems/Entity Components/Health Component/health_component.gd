extends Node
class_name HealthComponent

@export var MAX_HP : int
##Saving Grace is a way to stop one-shots. When damage is fatal, it sets health to 1 instead. This is a 1-time thing however.
@export var hasSavingGrace : bool = false
var CUR_HP : int

signal hp_changed(new_hp, max_hp)
signal died

func _ready() -> void:
	CUR_HP = MAX_HP

##FLAT DAMAGE
func take_damage(damage : int) -> void:
	if hasSavingGrace and CUR_HP - damage <= 0:
		CUR_HP = 1
		hasSavingGrace = false
	else:
		CUR_HP = clampi(CUR_HP - damage, 0, MAX_HP)
	
	hp_changed.emit(CUR_HP, MAX_HP)
	check_death()

func check_death() -> void:
	if CUR_HP <= 0:
		died.emit()
