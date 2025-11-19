extends State
class_name PlayerShoot

@export var Player : CharacterBody2D
@export var STATS : Stats_Component

func enter():
	Player.shoot()
	%Gun_CD.start()

func update(delta:float):
	Player.velocity = Player.velocity.move_toward(Vector2.ZERO, STATS.FRICTION * delta)
	Player.move_and_slide()
	pass


func _on_gun_cd_timeout() -> void:
	transition.emit(self,"Run")
