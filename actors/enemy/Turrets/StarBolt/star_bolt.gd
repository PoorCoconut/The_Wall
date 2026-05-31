extends StaticBody2D
class_name RingTurret

@export_category("Components")
@export var health_component: HealthComponent
@export var hurtbox_component: HurtboxComponent

@export_category("Stats")
@export var damage: int = 1
@export var bullet_speed: int = 100
@export var laser_length: float = 200.0
@export var threat_level: float = 0.2

@export_category("Ring Settings")
@export var bullet_count: int = 5              # Number of bullets fired in the ring
@export var rotation_offset_degrees: float = 0.0  # Rotational offset for the ring pattern

# Ring turret doesn't need to aim, so no turn_speed needed.
# It just fires periodically whenever player is in range.

var bullet_path: PackedScene = preload("res://objects/projectile/Bullet/Enemy Bullet/Turrets/SniperBolt/sniper_bolt_bullet.tscn")

var is_detected: bool = false
var player: Player

@onready var aim_timer: Timer = %AimTimer
@onready var cooldown_timer: Timer = %CooldownTimer

func _ready() -> void:
	%HealthBar.max_value = health_component.MAX_HP
	%HealthBar.value = health_component.CUR_HP

	health_component.hp_changed.connect(_on_hp_changed)
	health_component.died.connect(_death)

	# No laser sight needed for ring turret; hide it
	%Laser.visible = false

	# AimTimer acts as the wind-up before firing
	aim_timer.one_shot = true

func _on_attack_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player = body
		if aim_timer.is_stopped() and cooldown_timer.is_stopped():
			_start_firing_sequence()

func _on_attack_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player = null

func _start_firing_sequence() -> void:
	SoundBank.play_sfx("turret_charge", global_position)
	aim_timer.start()

func _on_aim_timer_timeout() -> void:
	if player:
		_fire_ring()
		cooldown_timer.start()

func _fire_ring() -> void:
	SoundBank.play_sfx("sniperbolt_attack", global_position)
	var angle_step = TAU / bullet_count
	var offset_rad = deg_to_rad(rotation_offset_degrees)

	for i in bullet_count:
		var bullet_angle = offset_rad + angle_step * i

		var bullet: Bullet = bullet_path.instantiate()
		bullet.SPEED = bullet_speed
		bullet.dir = bullet_angle
		bullet.global_rotation = bullet_angle
		bullet.global_position = %Marker.global_position
		get_tree().root.add_child(bullet)
		bullet.hitbox_component.damage = damage

func _on_cooldown_timer_timeout() -> void:
	if player:
		_start_firing_sequence()

func _on_hp_changed(new_hp: int, _max_hp: int) -> void:
	%HealthBar.value = new_hp
	var tween = get_tree().create_tween()
	tween.tween_method(SetShader_BlinkIntensity, 1.0, 0.0, 0.5)
	play_hit_sound()

func _death() -> void:
	hurtbox_component.queue_free()
	player = null
	aim_timer.stop()
	cooldown_timer.stop()
	%TurretWarnToExplode.play()

func play_hit_sound() -> void:
	if randi_range(1, 2) == 1:
		SoundBank.play_sfx("robot_hit1", global_position)
	else:
		SoundBank.play_sfx("robot_hit2", global_position)

func set_threat() -> void:
	if is_detected:
		is_detected = false
		GameManager.threat_level -= threat_level
	else:
		is_detected = true
		GameManager.threat_level += threat_level

func SetShader_BlinkIntensity(newValue: float) -> void:
	%Sprite.material.set_shader_parameter("blink_intensity", newValue)

func _on_turret_warn_to_explode_finished() -> void:
	SoundBank.play_sfx("robot_explosion", global_position)
	GameManager.do_camera_shake(8.0, 0.5)
	queue_free()
