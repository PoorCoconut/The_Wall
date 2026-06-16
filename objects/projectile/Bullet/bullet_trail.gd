extends Line2D

@export var length : int = 10 # How long the tail is

func _ready() -> void:
	# 1. Detach from the bullet so the trail doesn't spin if the bullet rotates!
	set_as_top_level(true) 
	clear_points()

func _physics_process(_delta: float) -> void:
	# 2. Safety check in case the bullet is destroyed
	var parent = get_parent()
	if not is_instance_valid(parent):
		return
		
	# 3. Add the bullet's current position to the line
	add_point(parent.global_position)
	
	# 4. Erase the oldest point to keep the trail short
	if get_point_count() > length:
		remove_point(0)
