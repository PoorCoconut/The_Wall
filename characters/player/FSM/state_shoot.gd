extends State
class_name PlayerShoot

@export var PLAYER : Player
@export var STATS : Stats_Component

func enter():
	PLAYER.shoot()
	%Gun_CD.start()

func update(delta:float):
	PLAYER.velocity = PLAYER.velocity.move_toward(Vector2.ZERO, STATS.FRICTION * delta)
	PLAYER.move_and_slide()
	pass


func _on_gun_cd_timeout() -> void:
	transition.emit(self,"Run")
