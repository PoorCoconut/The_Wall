extends State
class_name PlayerShoot

@export var PLAYER : Player
@export var STATS : Stats_Component
@onready var sfx_attack_gun := %attack_gun
@onready var sfx_gun_empty := %attack_gun_empty

func enter():
	if STATS.CUR_BULLETS >= 0: #I'm sorry I'm sorry
		STATS.CUR_BULLETS -= 1
	
	print(STATS.CUR_BULLETS, "/", STATS.MAX_BULLETS)
	PlayerHud.update_bullets_visual(STATS.MAX_BULLETS, STATS.CUR_BULLETS)
	
	%Gun_CD.start()
	if STATS.CUR_BULLETS >= 0:
		sfx_attack_gun.pitch_scale = randf_range(0.8, 1.2)
		sfx_attack_gun.play()
		PLAYER.shoot()
	else:
		sfx_attack_gun.pitch_scale = randf_range(0.8, 1.2)
		sfx_gun_empty.play()

func update(delta:float):
	PLAYER.velocity = PLAYER.velocity.move_toward(Vector2.ZERO, STATS.FRICTION * delta)
	PLAYER.move_and_slide()
	pass


func _on_gun_cd_timeout() -> void:
	transition.emit(self,"Run")
