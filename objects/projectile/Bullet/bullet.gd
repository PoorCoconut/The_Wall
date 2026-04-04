extends CharacterBody2D
class_name Bullet

@export_category("BULLET STATS")
@export var SPEED : float = 500.0

@export_category("Components")
@export var hitbox_component : HitboxComponent
var dir : float = 0.0

func _ready() -> void:
	hitbox_component.hit_landed.connect(delete_bullet)
 
func _physics_process(_delta: float) -> void:
	# Keep it simple: just fly forward
	velocity = Vector2(SPEED, 0).rotated(dir)
	move_and_slide()

func _on_on_screen_detector_screen_exited() -> void:
	queue_free()

func delete_bullet(_recoil_direction : Vector2)->void:
	queue_free()
