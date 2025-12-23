extends CharacterBody2D

@export var FSM : StateMachine #Looks for current movement state
@export var STATS : Stats_Component
const bullet_path : PackedScene = preload("res://resuables/projectile/bullet.tscn")

var damage_received : int

##Positioning
var last_dir : Vector2 = Vector2(0,1)
var last_dir_x : float
var last_dir_y : float
var cur_dir : Vector2
var mouse_pos : Vector2

##Dash
var dash_chain : int = 0

##Player vars
var enem_knockback : float

#DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG
func _ready() -> void:
	%HP_BAR.max_value = STATS.MAX_HP
	%HP_BAR.value = STATS.CUR_HP

func _process(_delta: float) -> void:
	update_debug()
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
	%Marker2D.look_at(get_global_mouse_position())

#func got_hit(damage:int, knockback:float): #Forces a STATE CHANGE
	#print("Player got hit for ", damage, " damage and ", knockback, " knockback strength")
	#enem_knockback = knockback
	##Saves player from a One Shot death
	#if STATS.CUR_HP == STATS.MAX_HP and damage >= STATS.CUR_HP: 
		#STATS.CUR_HP = 1
		##print("saved from ONE SHOT")
	#else:
		#STATS.CUR_HP = clamp(STATS.CUR_HP - damage, 0, STATS.MAX_HP)
	#%HP_BAR.value = STATS.CUR_HP
	#%HurtBox.set_deferred("monitorable", false)
	#%IFrame.start()
	#FSM.force_change_state("Hurt")

func damage_taken():
	pass


func _on_i_frame_timeout() -> void:
	%HurtBox.set_deferred("monitorable", true)

func shoot():
	var bullet = bullet_path.instantiate() #Place an instance of a bullet in the variable
	
	#Initialize properties of the variable
	bullet.DMG = STATS.RANGE_DMG
	bullet.dir = %Marker2D.rotation
	bullet.global_position = %Marker2D.global_position
	bullet.global_rotation = %Marker2D.global_rotation
	
	get_tree().root.add_child(bullet) #Instantiate the bullet

func get_damage():
	return STATS.MELEE_DMG

func take_damage(damage: int):
	print("player took ", damage, " damage")
