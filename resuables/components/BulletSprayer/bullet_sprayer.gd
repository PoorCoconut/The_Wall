extends Node2D
class_name BulletSprayer_Component

const bullet_path = preload("res://resuables/projectile/enemy_bullet.tscn")
@onready var ShootTimer : Timer = %Shoot_Cooldown

##Reload scene to see changes for spawn_amount
@export var spawn_amount : int
@export var rot_speed : float
@export var shoot_cooldown : float
@export var radius : int

@export var bullet_dmg : int
@export var bullet_speed : float
@export var enabled : bool = false

func _ready() -> void:
	if enabled:
		ShootTimer.start()
	ShootTimer.wait_time = shoot_cooldown
	
	var step = 2 * PI / spawn_amount
	
	for i in range(spawn_amount):
		var spawn_point = Node2D.new()
		var pos = Vector2(radius, 0).rotated(step*i)
		spawn_point.position = pos
		spawn_point.rotation = pos.angle()
		%rotator.add_child(spawn_point)

func _process(delta: float) -> void:
	spawn_amount = spawn_amount
	rot_speed = rot_speed
	ShootTimer.wait_time = shoot_cooldown
	radius = radius
	var new_rotation = %rotator.rotation_degrees + rot_speed * delta
	%rotator.rotation_degrees = fmod(new_rotation, 360)

func _on_shoot_cooldown_timeout() -> void:
	#print("shoot")
	for s in %rotator.get_children():
		var bullet = bullet_path.instantiate()
		bullet.position = s.global_position
		bullet.SPEED = bullet_speed
		bullet.dir = s.global_rotation
		bullet.DMG = bullet_dmg
		get_tree().root.add_child(bullet)
		
