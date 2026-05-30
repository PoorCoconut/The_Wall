extends CharacterBody2D
class_name EnemyBase

@export_category("Components")
@export var health_component: HealthComponent
@export var movement_component: MovementComponent
@export var fsm : StateMachine
@export var sprite: Node2D # Generic Node2D so it works with Sprite2D or AnimatedSprite2D

@export_category("Base Stats")
@export var threat_level: float = 0.4

@export_category("Base Effects")
@export var particle_path_hit : PackedScene
@export var particle_path_death : PackedScene

# Universal Enemy State
var target : Node2D = null
var is_stunned : bool = false
var is_detected : bool = false

func _ready() -> void:
	# 1. Connect universal signals
	if health_component:
		health_component.hp_changed.connect(_on_hp_changed)
		health_component.died.connect(_on_death)
		
		# Setup UI if it exists in the tree
		if has_node("%HealthBar"):
			%HealthBar.max_value = health_component.MAX_HP
			%HealthBar.value = health_component.CUR_HP

	# 2. Call a virtual function so child scripts can do their own _ready setup
	_enemy_ready()

func _physics_process(delta: float) -> void:
	if is_stunned:
		# Universally handle knockback sliding
		movement_component.apply_friction(delta)
		movement_component.move()
	else:
		# Delegate movement and AI to the specific enemy script
		_enemy_physics_process(delta)

# ─────────────────────────────────────────────────────────────────
# VIRTUAL FUNCTIONS (To be overridden by child scripts)
# ─────────────────────────────────────────────────────────────────

## Override this in child scripts instead of _ready()
func _enemy_ready() -> void:
	pass

## Override this in child scripts to handle AI (Chase, Shoot, Patrol)
func _enemy_physics_process(_delta: float) -> void:
	pass

## Override this if a specific enemy needs custom death logic
func _custom_death() -> void:
	pass

# ─────────────────────────────────────────────────────────────────
# UNIVERSAL COMBAT LOGIC
# ─────────────────────────────────────────────────────────────────

func _on_hp_changed(new_hp: int, _max_hp: int) -> void:
	if has_node("%HealthBar"):
		%HealthBar.value = new_hp
	
	_play_hit_flash()
	if fsm:
		#fsm.force_change_state("Stunned") #DO SOMETHING HERE
		pass
	_spawn_particle(particle_path_hit)
	
	# Universal Hit Stun (Assuming you have %StunTimer in the base tree)
	is_stunned = true
	if has_node("%StunTimer"):
		%StunTimer.start()

func _on_death() -> void:
	GameManager.do_camera_shake(10, 0.5)
	_spawn_particle(particle_path_death)
	_custom_death() # Let the child script do anything extra before freeing
	queue_free()

func _on_stun_timer_timeout() -> void:
	is_stunned = false

# --- Helper Functions ---

func _play_hit_flash() -> void:
	if sprite and sprite.material:
		var tween = get_tree().create_tween()
		tween.tween_method(_set_shader_blink, 1.0, 0.0, 0.5)

func _set_shader_blink(value: float) -> void:
	sprite.material.set_shader_parameter("blink_intensity", value)

func _spawn_particle(particle_scene: PackedScene) -> void:
	if particle_scene:
		var particle = particle_scene.instantiate()
		particle.global_position = global_position
		get_tree().root.add_child(particle)

func set_threat(): 
	if is_detected:
		is_detected = false
		GameManager.threat_level -= threat_level
	else:
		is_detected = true
		GameManager.threat_level += threat_level
