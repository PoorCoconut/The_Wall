extends StaticBody2D
class_name SniperBolt

@export_category("Components")
@export var health_component: HealthComponent

@export_category("Stats")
@export var damage : int = 1
@export var bullet_speed : int = 100
@export var turn_speed : float = 1.0 # Maximum turn speed (radians per second)
@export var laser_length : float = 200.0 # How far the physical laser sight projects
@export var threat_level : float = 0.1

var bullet_path : PackedScene = preload("res://objects/projectile/Bullet/bullet.tscn")

var is_detected : bool = false
var is_aiming : bool = true 
var player : Player

@onready var aim_timer: Timer = %AimTimer
@onready var cooldown_timer: Timer = %CooldownTimer

func _ready() -> void:
	health_component.died.connect(_death)
	%Laser.set_point_position(0, Vector2.ZERO)
	%Laser.set_point_position(1, Vector2.RIGHT * laser_length)

func _process(delta: float) -> void:
	if player:
		if is_aiming:
			var target_angle = %TurretHead.global_position.angle_to_point(player.global_position)
			var angle_diff = angle_difference(%TurretHead.global_rotation, target_angle)
			%TurretHead.global_rotation += clamp(angle_diff, -turn_speed * delta, turn_speed * delta)
			
			if abs(angle_diff) < 0.1:
				if aim_timer.is_stopped() and cooldown_timer.is_stopped():
					_start_firing_sequence()

func _start_firing_sequence() -> void:
	is_aiming = false
	aim_timer.start()

func _on_aim_timer_timeout() -> void:
	var bullet : Bullet = bullet_path.instantiate()
	get_tree().root.add_child(bullet)
	
	bullet.SPEED = bullet_speed
	bullet.dir = %TurretHead.rotation
	bullet.global_rotation = %TurretHead.global_rotation
	bullet.global_position = %Marker.global_position
	
	bullet.hitbox_component.damage = damage
	cooldown_timer.start()

func _on_cooldown_timer_timeout() -> void:
	is_aiming = true 

func _on_attack_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player = body

func _on_attack_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player = null
		aim_timer.stop()
		is_aiming = true

func _death():
	queue_free()

func set_threat(): 
	if is_detected:
		is_detected = false
		GameManager.threat_level -= threat_level
	else:
		is_detected = true
		GameManager.threat_level += threat_level
