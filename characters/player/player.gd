extends CharacterBody2D
class_name Player

@export var FSM : StateMachine #Looks for current movement state
@export var STATS : Stats_Component
const bullet_path : PackedScene = preload("res://resuables/projectile/bullet.tscn")

##Positioning
var last_dir : Vector2 = Vector2(0,1)
var last_dir_x : float
var last_dir_y : float
var cur_dir : Vector2
var mouse_pos : Vector2

##Dash
var dash_chain : int = 0
var canDash : bool = true

##Player vars
var enem_knockback : float

##Gun vars
@onready var GunMarker := %GunMarker
@onready var GunSprite : Sprite2D = $GunMarker/GunSprite

##THIS READY FUNCTION ONLY EXISTS TO SERVE FOR DEBUGGING PROCESSES
func _ready() -> void:
	PlayerHud.update_visual(STATS.MAX_HP, STATS.CUR_HP)
	%HP_BAR.max_value = STATS.MAX_HP
	%HP_BAR.value = STATS.CUR_HP

func _process(_delta: float) -> void:
	update_debug()
	#print("Can Dash: ", canDash)
	#update_playerUI()

func update_debug():
	UiDebug.plast_dir = last_dir
	UiDebug.plast_dir_x = last_dir_x
	UiDebug.plast_dir_y = last_dir_y
	UiDebug.pcur_dir = cur_dir
	UiDebug.pvelocity = velocity
	UiDebug.pcur_state = FSM.current_state.name
	UiDebug.pchain = dash_chain

func update_playerUI():
	PlayerHud.STATS = STATS

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("attack_range") or Input.is_action_just_pressed("attack"):
		mouse_pos = get_local_mouse_position()
		last_dir = -(last_dir - mouse_pos).normalized()
	GunMarker.look_at(get_global_mouse_position())

func _on_i_frame_timeout() -> void:
	%HurtBox.set_deferred("monitorable", true)

##COMBAT SYSTEM
#SHOOTING
func shoot():
	var bullet = bullet_path.instantiate() #Place an instance of a bullet in the variable
	#Initialize properties of the variable
	bullet.set_damage(STATS.RANGE_DMG)
	bullet.dir = GunMarker.rotation
	bullet.global_rotation = GunMarker.global_rotation
	bullet.global_position = GunSprite.global_position
	get_tree().root.add_child(bullet) #Instantiate the bullet

#DAMAGE
func get_damage(): #The hitbox node uses this to send an attack damage number to the "victim" of the attack
	return STATS.MELEE_DMG

func take_damage(damage: int):
	STATS.CUR_HP -= damage
	print("player took ", damage, " damage")
	PlayerHud.update_visual(STATS.MAX_HP, STATS.CUR_HP)
