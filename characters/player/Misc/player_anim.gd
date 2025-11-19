extends Node
class_name PlayerAnimation

@export var animation_tree : AnimationTree
var last_dir : Vector2
var mouse_pos : Vector2

func _ready() -> void:
	animation_tree.active = true

func _physics_process(_delta: float) -> void:
	last_dir = get_parent().last_dir
	mouse_pos = get_parent().mouse_pos
	
	animation_tree.set("parameters/Idle/blend_position", last_dir)
	animation_tree.set("parameters/Run/blend_position", last_dir)
	animation_tree.set("parameters/Dash/blend_position", last_dir)
	
	#Find a way to "lock" the facing direction, if player moves mouse during animation, it also rotates
	#Use a bool to see if Player attacked, if yes, it enables that bool and it will stop updating the mouse pos check
	#When the anim/state is finished, only then will mous pos get updated once again!
	animation_tree.set("parameters/Atk1/blend_position", mouse_pos)
	animation_tree.set("parameters/Atk2/blend_position", mouse_pos)
	animation_tree.set("parameters/Shoot/blend_position", mouse_pos)
