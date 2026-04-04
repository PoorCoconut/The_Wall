extends CharacterBody2D
class_name Enemy

signal deal_damage(damage:int, knockback:float)

func got_hit(damage:int, knockback:float): #Forces a STATE CHANGE
	pass
