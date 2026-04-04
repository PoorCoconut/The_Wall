extends State
class_name PlayerDeath

@export var PLAYER : Player

func enter():
	PLAYER.movement_component.current_velocity = Vector2.ZERO
	PLAYER.get_node("Hurtbox").set_deferred("monitorable", false)
	PLAYER.get_node("Hurtbox").set_deferred("monitoring", false)
	
	#Tell the UI / GameManager to show the Game Over screen
	# Events.player_died.emit() 
	
	#Play the death animation
	# PLAYER.get_node("AnimationPlayer").play("death")
