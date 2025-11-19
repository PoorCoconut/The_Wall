extends CharacterBody2D
class_name Bullet
#COLORS FOR PARTICLES PLAYER: e400fc, 

@export_category("BULLET STATS")
@export var SPEED : float
var DMG : int
var dir : float

func _ready() -> void:
	#global_position = pos
	#global_rotation = rota
	pass

func _physics_process(delta: float) -> void:
	#print(global_position)
	velocity = Vector2(SPEED,0).rotated(dir)
	move_and_slide()

func _on_on_screen_detector_screen_exited() -> void:
	queue_free()
