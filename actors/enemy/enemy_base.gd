extends CharacterBody2D
class_name EnemyBase

# ─────────────────────────────────────────────────────────────────
# COMPONENTS
# ─────────────────────────────────────────────────────────────────
@export_category("Components")
@export var health_component   : HealthComponent
@export var movement_component : MovementComponent
@export var sprite             : Node2D
@export var fsm                : StateMachine

@export var bullet_sprayer     : BulletSprayer_Component
@export var attack_range       : Area2D
@export var looker             : Node2D

# ─────────────────────────────────────────────────────────────────
# BASE STATS
# ─────────────────────────────────────────────────────────────────
@export_category("Base Stats")
@export var threat_level  : float = 0.4
@export var stun_duration : float = 0.15

# ─────────────────────────────────────────────────────────────────
# VISUAL EFFECTS
# ─────────────────────────────────────────────────────────────────
@export_category("Base Effects")
@export var particle_path_hit   : PackedScene
@export var particle_path_death : PackedScene

# ─────────────────────────────────────────────────────────────────
# RUNTIME STATE
# ─────────────────────────────────────────────────────────────────
var target      : Node2D = null
var is_stunned  : bool   = false
var is_detected : bool   = false

## Set to true by EnemySpawner at birth; cleared when the spawn effect ends.
## While true: no movement, no knockback, FSM is paused, sprite is white.
var is_spawning : bool = false

var target_in_attack_range : bool = false
var target_in_sight        : bool = false

var _stun_timer : SceneTreeTimer = null

# ─────────────────────────────────────────────────────────────────
# GODOT CALLBACKS
# ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_connect_signals()
	_setup_health_bar()
	_setup_attack_range()
	_enemy_ready()

func _physics_process(delta: float) -> void:
	# Spawning overrides everything — enemy is frozen in place.
	# Hurtbox is still active (enemy CAN be hit), but no movement or AI.
	if is_spawning:
		velocity = Vector2.ZERO
		return

	if is_stunned:
		if movement_component:
			movement_component.apply_friction(delta)
			movement_component.move()
		return

	if fsm:
		fsm._process(delta)
	else:
		_enemy_physics_process(delta)

# ─────────────────────────────────────────────────────────────────
# SPAWN FREEZE API  — called by EnemySpawner only
# ─────────────────────────────────────────────────────────────────

## Called by EnemySpawner right after instantiation.
## Freezes AI and movement; blanches the sprite to full white.
func begin_spawn_freeze() -> void:
	is_spawning = true

	# Pause the FSM so no state transitions fire during spawn
	if fsm:
		fsm.set_process(false)
		fsm.set_physics_process(false)

	# Hold sprite at full white using the same shader param the hit-flash uses
	_set_shader_blink(1.0)

## Called by EnemySpawner when the light pillar animation finishes.
## Restores colour and re-enables AI.
func end_spawn_freeze() -> void:
	is_spawning = false

	# Fade from white back to full colour
	var tween = create_tween()
	tween.tween_method(_set_shader_blink, 1.0, 0.0, 0.25)

	# Re-enable the FSM and kick off its initial state
	if fsm:
		fsm.set_process(true)
		fsm.set_physics_process(true)
		if fsm.current_state:
			fsm.current_state.enter()

# ─────────────────────────────────────────────────────────────────
# VIRTUAL HOOKS
# ─────────────────────────────────────────────────────────────────
func _enemy_ready() -> void:
	pass

func _enemy_physics_process(_delta: float) -> void:
	pass

func _on_enemy_death() -> void:
	pass

func _on_enemy_damaged(_new_hp: int, _max_hp: int) -> void:
	pass

# ─────────────────────────────────────────────────────────────────
# PUBLIC HELPERS
# ─────────────────────────────────────────────────────────────────
func move_toward_point(point: Vector2, delta: float) -> void:
	if not movement_component:
		return
	var dir = (point - global_position).normalized()
	movement_component.accelerate_in_direction(dir, delta)
	movement_component.move()

func stop_moving(delta: float) -> void:
	if movement_component:
		# Passing ZERO makes accelerate_in_direction apply friction internally
		movement_component.accelerate_in_direction(Vector2.ZERO, delta)
		movement_component.move()

## Apply an instant knockback impulse (e.g. from a melee hit or explosion).
## force is a velocity-space vector — direction * strength.
func apply_knockback(force: Vector2) -> void:
	if movement_component:
		movement_component.apply_knockback(force)

func look_at_target(world_pos: Vector2) -> void:
	if looker:
		looker.look_at(world_pos)

func set_sprayer_active(active: bool) -> void:
	if bullet_sprayer:
		bullet_sprayer.enabled = active
		if active and bullet_sprayer.has_node("%Shoot_Cooldown"):
			bullet_sprayer.get_node("%Shoot_Cooldown").start()
		elif not active and bullet_sprayer.has_node("%Shoot_Cooldown"):
			bullet_sprayer.get_node("%Shoot_Cooldown").stop()

func set_state(state_name: String) -> void:
	if fsm:
		fsm.force_change_state(state_name)

func distance_to_target() -> float:
	if not target:
		return INF
	return global_position.distance_to(target.global_position)

func direction_to_target() -> Vector2:
	if not target:
		return Vector2.ZERO
	return (target.global_position - global_position).normalized()

# ─────────────────────────────────────────────────────────────────
# INTERNAL – SIGNAL WIRING
# ─────────────────────────────────────────────────────────────────
func _connect_signals() -> void:
	if health_component:
		health_component.hp_changed.connect(_on_hp_changed)
		health_component.died.connect(_on_death)

	if has_node("Hurtbox"):
		var hurtbox : Area2D = get_node("Hurtbox")
		if not hurtbox.area_entered.is_connected(_on_hurtbox_hit):
			hurtbox.area_entered.connect(_on_hurtbox_hit)

	if attack_range:
		attack_range.body_entered.connect(_on_attack_range_entered)
		attack_range.body_exited.connect(_on_attack_range_exited)

func _setup_health_bar() -> void:
	if health_component and has_node("%HealthBar"):
		%HealthBar.max_value = health_component.MAX_HP
		%HealthBar.value     = health_component.CUR_HP

func _setup_attack_range() -> void:
	target_in_attack_range = false

# ─────────────────────────────────────────────────────────────────
# INTERNAL – COMBAT RESPONSES
# ─────────────────────────────────────────────────────────────────
func _on_hp_changed(new_hp: int, max_hp: int) -> void:
	if has_node("%HealthBar"):
		%HealthBar.value = new_hp

	_play_hit_flash()
	_spawn_particle(particle_path_hit)

	# Hits during spawn register damage but cause NO knockback or stun.
	if not is_spawning:
		_apply_stun()
		if fsm and fsm.STATES.has("stunned"):
			fsm.force_change_state("stunned")

	_on_enemy_damaged(new_hp, max_hp)

func _on_death() -> void:
	GameManager.do_camera_shake(10, 0.5)
	_spawn_particle(particle_path_death)
	set_threat()
	_on_enemy_death()
	queue_free()

func _on_hurtbox_hit(area: Area2D) -> void:
	if health_component and area.has_method("get_damage"):
		health_component.take_damage(area.get_damage())

func _apply_stun() -> void:
	is_stunned = true
	if _stun_timer:
		_stun_timer = null
	_stun_timer = get_tree().create_timer(stun_duration)
	_stun_timer.timeout.connect(_on_stun_finished)

func _on_stun_finished() -> void:
	is_stunned = false
	if fsm and fsm.current_state and fsm.current_state.name.to_lower() == "stunned":
		fsm.force_change_state("idle")

# ─────────────────────────────────────────────────────────────────
# INTERNAL – ATTACK RANGE CALLBACKS
# ─────────────────────────────────────────────────────────────────
func _on_attack_range_entered(body: Node2D) -> void:
	if body == target:
		target_in_attack_range = true

func _on_attack_range_exited(body: Node2D) -> void:
	if body == target:
		target_in_attack_range = false

# ─────────────────────────────────────────────────────────────────
# INTERNAL – VISUAL HELPERS
# ─────────────────────────────────────────────────────────────────
func _play_hit_flash() -> void:
	# Skip while spawning — enemy is already fully white, flash would be invisible
	if is_spawning:
		return
	if sprite and sprite.material:
		var tween = get_tree().create_tween()
		tween.tween_method(_set_shader_blink, 1.0, 0.0, 0.3)

func _set_shader_blink(value: float) -> void:
	if sprite and sprite.material:
		sprite.material.set_shader_parameter("blink_intensity", value)

func _spawn_particle(particle_scene: PackedScene) -> void:
	if not particle_scene:
		return
	var p = particle_scene.instantiate()
	p.global_position = global_position
	get_tree().root.add_child(p)

# ─────────────────────────────────────────────────────────────────
# THREAT SYSTEM
# ─────────────────────────────────────────────────────────────────
func set_threat() -> void:
	if is_detected:
		is_detected = false
		GameManager.threat_level -= threat_level
	else:
		is_detected = true
		GameManager.threat_level += threat_level
