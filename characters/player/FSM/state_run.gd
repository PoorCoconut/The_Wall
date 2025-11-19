extends State
class_name PlayerRun

@export var player : CharacterBody2D
@export var STATS : Stats_Component

func enter():
	%DustStep.emitting = true
	pass

func update(delta:float):
	movement(delta)
	
	
	var last_input = Vector2( #Handles the last input
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
		)
	if last_input.length() > 0:
		player.last_dir = last_input
	
	
	
	if Input.is_action_pressed("right") or Input.is_action_pressed("left"):
		player.last_dir_x = Input.get_action_strength("right") - Input.get_action_strength("left")
	if Input.is_action_pressed("down") or Input.is_action_pressed("up"):
		player.last_dir_y = Input.get_action_strength("up") - Input.get_action_strength("down")
	
	if Input.is_action_just_pressed("dash") and STATS.dash == true: #Looks if about to dash
		transition.emit(self, "Dash")
	elif(Input.is_action_just_pressed("attack")):
		transition.emit(self, "Atk1")
	elif(Input.is_action_just_pressed("attack_range")):
		transition.emit(self, "Shoot")

func exit():
	%DustStep.emitting = false

func get_input():
	var input = Vector2.ZERO
	if Input.is_action_pressed("right"):
		input.x += 1
	if Input.is_action_pressed("left"):
		input.x -= 1
	if Input.is_action_pressed("down"):
		input.y += 1
	if Input.is_action_pressed("up"):
		input.y -= 1
	return input.normalized()

func movement(delta : float):
	var direction = get_input()
	player.cur_dir = direction
	if direction.length() > 0:
		player.velocity = player.velocity.lerp(direction * STATS.MAX_SPEED, STATS.ACCELERATION * delta)
	else:
		player.velocity = player.velocity.move_toward(Vector2.ZERO, STATS.FRICTION * delta)
	
	#Transition to Idle
	if player.velocity == Vector2.ZERO:
		transition.emit(self, "Idle")
	player.move_and_slide()
