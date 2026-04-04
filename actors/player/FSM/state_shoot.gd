extends State
class_name PlayerShoot

@export var PLAYER : Player

@onready var sfx_attack_gun := %attack_gun
@onready var sfx_gun_empty := %attack_gun_empty

func enter():
	%Gun_CD.start()
	
	# ONE SINGLE IF STATEMENT! 
	if PLAYER.cur_bullets > 0:
		# Successful Shot
		sfx_attack_gun.pitch_scale = randf_range(0.8, 1.2)
		sfx_attack_gun.play()
		PLAYER.shoot()
		PLAYER.cur_bullets -= 1 # Decrement right here!
	else:
		# Empty Mag
		sfx_gun_empty.pitch_scale = randf_range(0.8, 1.2)
		sfx_gun_empty.play()
	
	# Update the UI
	print(PLAYER.cur_bullets, "/", PLAYER.max_bullets)
	Events.player_ammo_updated.emit(PLAYER.cur_bullets, PLAYER.max_bullets)

func update(delta: float):
	# Component Physics handles the slide perfectly
	PLAYER.movement_component.apply_friction(delta)
	PLAYER.movement_component.move()

func _on_gun_cd_timeout() -> void:
	# Safe transition! Don't force them to Run if they let go of the keys.
	if Input.get_vector("left", "right", "up", "down") == Vector2.ZERO:
		transition.emit(self, "Idle")
	else:
		transition.emit(self, "Run")
