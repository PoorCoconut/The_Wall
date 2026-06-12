extends StaticBody2D
class_name LaserTurret

# ── Scene nodes ──────────────────────────────────────────────────────────────
# Required nodes in the scene tree (same structure as SniperBolt):
#   %TurretHead          – Node2D that rotates (sprite visual only)
#   %Laser               – Line2D with at least 2 points.
#                          point[0] = beam origin (stays at Vector2.ZERO in TurretHead local space)
#                          point[1] = beam tip    (updated every frame to follow _laser_tip_pos)
#                          The Line2D should be a child of %TurretHead so local-space math works.
#   %AttackRange         – Area2D that detects the player
#   %HurtboxComponent    – HurtboxComponent node
#   %HealthBar           – ProgressBar / TextureProgressBar
#   %TurretRotation      – AudioStreamPlayer2D (rotation sound)
#   %TurretWarnToExplode – AnimationPlayer / AudioStreamPlayer2D (death sound)
#   %Sprite              – Sprite2D with blink shader
#   %LaserHitbox         – HitboxComponent child of %TurretHead.
#                          Moved every frame to the tip position in local space.
#                          Damage is dealt automatically by HurtboxComponent._on_area_entered
#                          whenever the tip overlaps the player — no signals needed.

@export_category("Components")
@export var health_component: HealthComponent
@export var hurtbox_component: HurtboxComponent

@export_category("Stats")
@export var threat_level: float = 0.2

@export_category("Laser – Visuals")
## Width of the Line2D stroke.
@export var laser_width: float = 4.0

@export_category("Laser – Tip Movement")
## How fast the laser tip travels toward the player in pixels/second.
@export var tip_speed: float = 80.0
## Max distance the tip can reach from the turret (beam won't extend beyond this).
@export var max_laser_length: float = 400.0

@export_category("Laser – Turret Head")
## How fast the turret SPRITE rotates to face the player (purely visual, rad/s).
@export var turn_speed: float = 2.0

@export_category("Laser – Damage")
## Damage dealt on each overlap (set on the HitboxComponent directly).
@export var damage: int = 1

# ── Runtime state ─────────────────────────────────────────────────────────────
var is_detected: bool = false
var player: Player

# The tip's current world-space position.
# Starts at the turret origin when the player enters range.
var _laser_tip_pos: Vector2 = Vector2.ZERO

@onready var laser_hitbox: HitboxComponent = %LaserHitbox
@onready var visible_bar: Node2D = %VisibleBar

signal boss_dead

# ── Ready ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	%HealthBar.max_value = health_component.MAX_HP
	%HealthBar.value = health_component.CUR_HP

	health_component.hp_changed.connect(_on_hp_changed)
	health_component.died.connect(_death)

	%Laser.width = laser_width
	%Laser.set_point_position(0, Vector2.ZERO)
	%Laser.set_point_position(1, Vector2.ZERO)
	%Laser.visible = false

	laser_hitbox.damage = damage
	# Start outside the scene so it can't accidentally overlap anything.
	laser_hitbox.monitoring = false

# ── Process ───────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not player:
		return

	_rotate_turret_head(delta)
	_move_laser_tip(delta)
	_update_laser_visuals()

func _rotate_turret_head(delta: float) -> void:
	var target_angle = %TurretHead.global_position.angle_to_point(player.global_position)
	var angle_diff = angle_difference(%TurretHead.global_rotation, target_angle)
	%TurretHead.global_rotation += clamp(angle_diff, -turn_speed * delta, turn_speed * delta)

func _move_laser_tip(delta: float) -> void:
	var to_player = player.global_position - _laser_tip_pos
	var step = tip_speed * delta

	if to_player.length() <= step:
		_laser_tip_pos = player.global_position
	else:
		_laser_tip_pos += to_player.normalized() * step

	# Never extend further than max_laser_length from the turret.
	var from_turret = _laser_tip_pos - global_position
	if from_turret.length() > max_laser_length:
		_laser_tip_pos = global_position + from_turret.normalized() * max_laser_length

func _update_laser_visuals() -> void:
	var local_tip = %TurretHead.to_local(_laser_tip_pos)
	%Laser.set_point_position(0, Vector2.ZERO)
	%Laser.set_point_position(1, local_tip)
	# Hitbox rides on the tip — HurtboxComponent handles damage automatically on overlap.
	laser_hitbox.position = local_tip

# ── Attack range ──────────────────────────────────────────────────────────────
func _on_attack_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		var boss_bar_tween = get_tree().create_tween()
		boss_bar_tween.tween_property(visible_bar, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1)
		
		player = body
		_laser_tip_pos = global_position
		%Laser.visible = true
		laser_hitbox.monitoring = true
		SoundBank.play_sfx("turret_charge", global_position)
		var tween = get_tree().create_tween()
		tween.tween_property(%TurretRotation, "volume_db", 0, 0.5)

func _on_attack_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		var boss_bar_tween = get_tree().create_tween()
		boss_bar_tween.tween_property(visible_bar, "modulate", Color(1.0, 1.0, 1.0, 0.0), 1)
		
		player = null
		laser_hitbox.monitoring = false
		if is_instance_valid(%Laser):
			%Laser.visible = false
		if is_instance_valid(%TurretRotation):
			var tween = get_tree().create_tween()
			tween.tween_property(%TurretRotation, "volume_db", -80, 0.5)

# ── Health / death ────────────────────────────────────────────────────────────
func _on_hp_changed(new_hp: int, _max_hp: int) -> void:
	%HealthBar.value = new_hp
	var tween = get_tree().create_tween()
	tween.tween_method(SetShader_BlinkIntensity, 1.0, 0.0, 0.5)
	play_hit_sound()

func _death() -> void:
	boss_dead.emit()
	%LaserScorchTrail.delete = true
	# Stop _process immediately so nothing accesses nodes after this point.
	set_process(false)
	hurtbox_component.queue_free()
	player = null
	laser_hitbox.monitoring = false
	%Laser.visible = false
	var tween = get_tree().create_tween()
	tween.tween_property(%TurretRotation, "volume_db", -80, 0.3)
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
	GameManager.do_camera_shake(10.0, 1)
	queue_free()
