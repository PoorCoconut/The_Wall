extends State
class_name PlayerShoot

@export var PLAYER : Player
@export var recoil_strength : float = 100.0

@onready var sfx_attack_gun := %attack_gun
@onready var sfx_gun_empty := %attack_gun_empty

func enter():
	%Gun_CD.start()
	if PLAYER.cur_bullets > 0:
		#Successful Shot
		sfx_attack_gun.pitch_scale = randf_range(0.8, 1.2)
		sfx_attack_gun.play()
		PLAYER.shoot()
		PLAYER.cur_bullets -= 1
		var mouse_pos = PLAYER.get_global_mouse_position()
		var dir_to_mouse = PLAYER.global_position.direction_to(mouse_pos)
		
		#Push Drifter back a bit [recoil]
		PLAYER.movement_component.current_velocity = -dir_to_mouse * recoil_strength
	else:
		#Empty Mag
		sfx_gun_empty.pitch_scale = randf_range(0.8, 1.2)
		sfx_gun_empty.play()
	
	#Update the UI
	print(PLAYER.cur_bullets, "/", PLAYER.max_bullets)
	Events.player_ammo_updated.emit(PLAYER.cur_bullets, PLAYER.max_bullets)

func update(delta: float):
	PLAYER.movement_component.apply_friction(delta)
	PLAYER.movement_component.move()

func _on_gun_cd_timeout() -> void:
	if Input.get_vector("left", "right", "up", "down") == Vector2.ZERO:
		transition.emit(self, "Idle")
	else:
		transition.emit(self, "Run")
