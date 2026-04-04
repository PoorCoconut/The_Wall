extends CharacterBody2D
class_name Player

@export_category("Components")
@export var FSM : StateMachine
@export var health_component: HealthComponent
# Make sure to assign your new MovementComponent in the inspector!
@export var movement_component: MovementComponent 
@export var hurtbox_component : HurtboxComponent
@export var hitbox_component : HitboxComponent

@export_category("Player Base Stats")
@export var melee_damage: int = 1

##bonus damage is temporary modifier that disappears on hit or on other special circumstances
var melee_bonus_damage : int = 0

@export var range_damage: int = 1
@export var max_bullets: int = 5
var cur_bullets: int = max_bullets

@export_category("Abilities & Powers (Debug)")
## Check these to test powers without the GameManager
@export var debug_has_dash: bool = false
@export var debug_has_glow: bool = false
@export var debug_has_strike: bool = false

@export_category("Dash Mechanics")
@export var dash_speed: float = 500.0 
@export var dash_friction: float = 50.0
@export var dash_cooldown: float = 1.0
@export var chains_to_damage : int = 5

@export_category("Glow Mechanics")
@export var light_aura_radius: float = 150.0

const bullet_path : PackedScene = preload("res://objects/projectile/Bullet/Player Bullet/player_bullet.tscn")

##Positioning
var last_dir : Vector2 = Vector2(0,1)
var last_dir_x : float
var last_dir_y : float
var cur_dir : Vector2
var mouse_pos : Vector2

##Dash
var dash_chain : int = 0
var canDash : bool = true

##Gun vars
@onready var GunMarker := %GunMarker
@onready var GunSprite : Sprite2D = $GunMarker/GunSprite
var consecutive_hits : int
@export var HITS_TO_RECHARGE : int = 3

##World / Scene Access vars
@onready var camera = get_tree().get_first_node_in_group("Camera")

func _ready() -> void:
	if OS.has_feature("editor"):
		if debug_has_dash:
			GameManager.has_dash = true
		if debug_has_glow:
			GameManager.has_glow = true
		if debug_has_strike:
			GameManager.has_strike = true
	
	health_component.hp_changed.connect(_on_hp_changed)
	hitbox_component.hit_landed.connect(_on_sword_hit_landed)
	
	Events.player_hp_updated.emit(health_component.CUR_HP, health_component.MAX_HP)
	Events.player_ammo_updated.emit(cur_bullets, max_bullets)

func _process(_delta: float) -> void:
	update_debug()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("interact"):
		$InteractionArea/CollisionShape2D.disabled = false
		await get_tree().create_timer(0.1).timeout
		$InteractionArea/CollisionShape2D.disabled = true

func update_debug():
	UiDebug.plast_dir = last_dir
	UiDebug.plast_dir_x = last_dir_x
	UiDebug.plast_dir_y = last_dir_y
	UiDebug.pcur_dir = cur_dir
	UiDebug.pvelocity = velocity
	UiDebug.pcur_state = FSM.current_state.name
	UiDebug.pchain = dash_chain
	UiDebug.pcur_dmg = hitbox_component.damage

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("attack_range") or Input.is_action_just_pressed("attack"):
		mouse_pos = get_local_mouse_position()
		last_dir = -(last_dir - mouse_pos).normalized()
	GunMarker.look_at(get_global_mouse_position())

func _on_i_frame_timeout() -> void:
	%HurtBox.set_deferred("monitorable", true)

func apply_stumble_debuff(duration: float) -> void:
	movement_component.apply_slide_debuff(duration, 10)
	#This block here is for special effects in the future

##COMBAT SYSTEM
func shoot():
	GameManager.do_camera_shake(5.0, 0.5)
	var bullet = bullet_path.instantiate()
	bullet.get_node("Hitbox").damage = range_damage 
	bullet.dir = GunMarker.rotation
	bullet.global_rotation = GunMarker.global_rotation
	bullet.global_position = GunSprite.global_position
	
	get_tree().root.add_child(bullet)

func _on_hp_changed(new_hp: int, max_hp: int) -> void:
	Events.player_hp_updated.emit(new_hp, max_hp)
	FSM.force_change_state("Hit")
	remove_bonus_damage() #When Player is hit, remove bonus damage

func _on_sword_hit_landed(_recoil_direction: Vector2) -> void:
	if hitbox_component.damage > 3:
		GameManager.do_camera_shake(10.0 + hitbox_component.damage, 0.5)
	
	# Only count hits if the gun isn't already full!
	if cur_bullets < max_bullets:
		consecutive_hits += 1
		if consecutive_hits >= HITS_TO_RECHARGE:
			cur_bullets += 1
			consecutive_hits = 0 # Reset the counter for the next bullet
			
			Events.player_ammo_updated.emit(cur_bullets, max_bullets)
			
			# HIGHLY RECOMMENDED JUICE: 
			# Play a sharp, satisfying mechanical 'click' sound effect right here!
	
	#For bonus damage
	await get_tree().create_timer(0.5).timeout
	remove_bonus_damage() #When Player hits something, remove bonus damage

func dashchain_damage_boost() -> void:
	if dash_chain == 0:
		remove_bonus_damage()
	elif dash_chain >= chains_to_damage and dash_chain % chains_to_damage == 0:
		melee_bonus_damage += 1
		update_sword_damage()
		%DashChainDamageTimer.start()

func remove_bonus_damage() -> void:
	melee_bonus_damage = 0
	update_sword_damage()

func update_sword_damage() -> void:
	hitbox_component.damage = melee_damage + melee_bonus_damage 

func _on_dash_chain_damage_timer_timeout() -> void:
	remove_bonus_damage()

#THREAT / ENEMY DETECTION
func _on_threat_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy") and body.has_method("set_threat"):
		body.set_threat()

func _on_threat_detector_body_exited(body: Node2D) -> void:
	if body.is_in_group("Enemy") and body.has_method("set_threat"):
		body.set_threat()
