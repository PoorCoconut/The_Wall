extends Node
class_name HP_Component

@export var MAX_HP : int
var CUR_HP : int = MAX_HP

func _ready() -> void:
	CUR_HP = MAX_HP
