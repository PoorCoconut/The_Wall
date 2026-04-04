extends State
class_name PlayerHit

@export var PLAYER : Player
@export var stun_duration : float = 0.3 # How long the Drifter loses control

var current_stun_time : float = 0.0

func enter():
	# Reset the stun timer every time we get hit
	current_stun_time = stun_duration
	
	# (Play your damage sound effect and flashing red animation here!)

func update(delta: float):
	# 1. THE KNOCKBACK SLIDE
	# The Hurtbox already shoved the MovementComponent's velocity.
	# We just apply friction here so the player organically slides to a halt!
	PLAYER.movement_component.apply_friction(delta)
	PLAYER.movement_component.move()
	
	# 2. THE HIT STUN TIMER
	current_stun_time -= delta
	
	if current_stun_time <= 0.0:
		# Regain control and return to normal states
		if Input.get_vector("left", "right", "up", "down") == Vector2.ZERO:
			transition.emit(self, "Idle")
		else:
			transition.emit(self, "Run")
