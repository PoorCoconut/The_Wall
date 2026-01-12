extends CharacterBody2D
var BULLET_PATH = preload("res://resuables/projectile/bullet.tscn")

func _process(delta: float) -> void:
	look_at(get_global_mouse_position())
	if Input.is_action_just_pressed("attack_range"):
		fire()
	pass

func fire():
	var bullet = BULLET_PATH.instantiate()
	#Initialize properties of the variable
	bullet.dir = rotation
	bullet.global_rotation = global_rotation
	bullet.global_position = global_position
	get_tree().root.add_child(bullet) #Instantiate the bullet
