extends State
class_name PlayerIdle

@export var STATS : Stats_Component

func enter():
	pass

func update(_delta:float): #"Generally holds the transitions"
	if(Input.get_vector("left", "right", "up", "down")):
		#Transition to Run State
		transition.emit(self, "Run")
	elif(Input.is_action_just_pressed("dash") and STATS.dash):
		transition.emit(self, "Dash")
	elif(Input.is_action_just_pressed("attack")):
		transition.emit(self, "Atk1")
	elif(Input.is_action_just_pressed("attack_range")):
		transition.emit(self, "Shoot")
