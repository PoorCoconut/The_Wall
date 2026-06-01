extends Line2D

@export var laser_tip: Node2D # Drag your laser tip marker into this in the inspector
@export var drop_distance: float = 8.0 # How far the tip moves before dropping a new point
@export var max_length: int = 50 # How many points before the oldest ones fade
var delete : bool = false
func _ready() -> void:
	# Ensure we start with a clean slate
	clear_points()

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(laser_tip):
		return
		
	var current_pos = laser_tip.global_position
	#print("Tip Position: ", current_pos)
	
	# If the line is empty, just drop the first point
	if get_point_count() == 0:
		add_point(current_pos)
		return
		
	# Check the distance from the LAST point we dropped
	var last_point = get_point_position(get_point_count() - 1)
	
	if last_point.distance_to(current_pos) > drop_distance:
		add_point(current_pos)
		
		# Erase the oldest point if the trail gets too long
		if get_point_count() > max_length:
			remove_point(0)
	
	if delete:
		remove_point(0)
