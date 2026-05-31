extends StaticBody2D
class_name BurstTurret

@export_category("Components")
@export var health_component: HealthComponent
@export var hurtbox_component: HurtboxComponent

@export_category("Stats")
@export var damage: int = 1
@export var bullet_speed: int = 120
@export var turn_speed: float = 1.5
@export var laser_length: float = 200.0
@export var threat_level: float = 0.1

@export_category("Burst Settings")
@export var burst_count: int = 3           # Number of shots per burst
@export var burst_interval: float = 0.12  # Time between each shot in the burst
@export var recharge_duration: float = 2.5 # Time to recharge after full burst

var bullet_path: PackedScene = preload("res://objects/projectile/Bullet/Enemy Bullet/Turrets/SniperBolt/sniper_bolt_bullet.tscn")

var is_detected: bool = false
var is_aiming: bool = true
var player: Player
var _shots_fired: int = 0

@onready var aim_timer: Timer = %AimTimer
@onready var cooldown_timer: Timer = %CooldownTimer

func _ready() -> void:
	%HealthBar.max_value = health_component.MAX_HP
	%HealthBar.value = health_component.CUR_HP

	health_component.hp_changed.connect(_on_hp_changed)
	health_component.died.connect(_death)
	%Laser.set_point_position(0, Vector2.ZERO)
	%Laser.set_point_position(1, Vector2.RIGHT * laser_length)

	# Repurpose AimTimer as burst interval timer
	aim_timer.wait_time = burst_interval
	aim_timer.one_shot = false
	cooldown_timer.wait_time = recharge_duration

func _process(delta: float) -> void:
	if player:
		if is_aiming:
			var tween = get_tree().create_tween()
			tween.tween_property(%TurretRotation, "volume_db", 0, 0.5)

			var target_angle = %TurretHead.global_position.angle_to_point(player.global_position)
			var angle_diff = angle_difference(%TurretHead.global_rotation, target_angle)
			%TurretHead.global_rotation += clamp(angle_diff, -turn_speed * delta, turn_speed * delta)

			if abs(angle_diff) < 0.05:
				if aim_timer.is_stopped() and cooldown_timer.is_stopped():
					_start_burst()

func _start_burst() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(%TurretRotation, "volume_db", -80, 0.2)
	SoundBank.play_sfx("turret_charge", global_position)
	is_aiming = false
	_shots_fired = 0
	aim_timer.start()

func _fire_bullet() -> void:
	var bullet: Bullet = bullet_path.instantiate()
	SoundBank.play_sfx("sniperbolt_attack", global_position)
	bullet.SPEED = bullet_speed
	bullet.dir = %TurretHead.rotation
	bullet.global_rotation = %TurretHead.global_rotation
	bullet.global_position = %Marker.global_position
	get_tree().root.add_child(bullet)
	bullet.hitbox_component.damage = damage

func _on_aim_timer_timeout() -> void:
	_fire_bullet()
	_shots_fired += 1

	if _shots_fired >= burst_count:
		aim_timer.stop()
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
		_shots_fired = 0
		is_aiming = true

func _on_hp_changed(new_hp: int, _max_hp: int) -> void:
	%HealthBar.value = new_hp
	var tween = get_tree().create_tween()
	tween.tween_method(SetShader_BlinkIntensity, 1.0, 0.0, 0.5)
	play_hit_sound()

func _death() -> void:
	hurtbox_component.queue_free()
	var tween = get_tree().create_tween()
	tween.tween_property(%TurretRotation, "volume_db", 0, 0.5)
	is_aiming = false
	player = null
	aim_timer.stop()
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
