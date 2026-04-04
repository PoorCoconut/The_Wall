extends CharacterBody2D

@export_category("Components")
@export var health_component: HealthComponent
@export var movement_component: MovementComponent

@export_category("Enemy Stats")
@export var threat_level: float = 0.4

@export_category("Effects")
@export var particle_path_gore : PackedScene
@export var particle_path_explosion : PackedScene
@export var particle_path_hit : PackedScene

@onready var looker : Marker2D = %LookerNode
@onready var sprite: AnimatedSprite2D = $Sprite2D

var target : CharacterBody2D 
var following : bool = false
var stunned : bool = false # Acts as our "Hit Stun" flag
var is_detected = false
@onready var camera = get_tree().get_first_node_in_group("Camera")

func _ready() -> void:
	# 1. Connect to the Health Component signals
	health_component.hp_changed.connect(_on_hp_changed)
	health_component.died.connect(death)
	
	# 2. Setup UI
	%HealthBar.max_value = health_component.MAX_HP
	%HealthBar.value = health_component.CUR_HP

func _physics_process(delta: float) -> void:
	# 1. CHECK STATES & CALCULATE MOVEMENT
	if stunned:
		# If stunned (hit), just slide to a halt based on the Hurtbox knockback
		movement_component.apply_friction(delta)
		
	elif following and target:
		# Chase the player!
		looker.look_at(target.global_position)
		var direction = global_position.direction_to(target.global_position)
		movement_component.accelerate_in_direction(direction, delta)
		
	else:
		# Idle / Not chasing
		movement_component.apply_friction(delta)
		
	# 2. EXECUTE MOVEMENT (This safely handles collisions and knockback!)
	movement_component.move()

# --- COMBAT & HEALTH SIGNALS ---

# This runs automatically whenever the HealthComponent takes damage!
func _on_hp_changed(new_hp: int, max_hp: int) -> void:
	%HealthBar.value = new_hp
	
	# Visuals
	var tween = get_tree().create_tween()
	tween.tween_method(SetShader_BlinkIntensity, 1.0, 0.0, 0.5)
	play_hit_sound()
	
	var particle_hit = particle_path_hit.instantiate()
	particle_hit.global_position = global_position
	get_tree().root.add_child(particle_hit)
	
	# Trigger Hit Stun
	stunned = true
	following = false
	%StunTimer.start()

func SetShader_BlinkIntensity(newValue: float):
	sprite.material.set_shader_parameter("blink_intensity", newValue)

func play_hit_sound() -> void:
	if randi_range(1, 2) == 1:
		SoundBank.play_sfx("hit_metal1", global_position)
	else:
		SoundBank.play_sfx("hit_metal2", global_position)

func play_death_sound() -> void:
	SoundBank.play_sfx("kill_enemy1", global_position)

# This runs automatically when the HealthComponent hits 0!
func death():
	GameManager.do_camera_shake(10, 0.5)
	
	var particle_gore = particle_path_gore.instantiate()
	var particle_explosion = particle_path_explosion.instantiate()
	
	particle_gore.global_position = global_position
	particle_explosion.global_position = global_position
	get_tree().root.add_child(particle_gore)
	get_tree().root.add_child(particle_explosion)
	
	queue_free()

# --- AI & UTILITY ---

func _on_attack_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target = body
		following = true

func _on_attack_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target = null
		following = false

func _on_stun_timer_timeout() -> void:
	# Wake up and resume chasing!
	stunned = false
	if target:
		following = true

func set_threat(): 
	if is_detected:
		is_detected = false
		GameManager.threat_level -= threat_level
	else:
		is_detected = true
		GameManager.threat_level += threat_level
