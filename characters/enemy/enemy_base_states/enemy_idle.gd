extends State
class_name enemyIdle

@export var ENEMY : CharacterBody2D

func enter():
	pass

func update(_delta:float):
	if ENEMY.target != null:
		transition.emit(self, "Chase")
