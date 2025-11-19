extends Node2D
class_name DashTrail

@onready var FR : CPUParticles2D = %FrontRight
@onready var FL : CPUParticles2D = %FrontLeft
@onready var BR : CPUParticles2D = %BackRight
@onready var BL : CPUParticles2D = %BackLeft
@onready var Trail_Timer : Timer = %TrailTimer
@export var TrailDuration : float 
@export var TrailAmount : int

func _ready() -> void:
	FR.amount = TrailAmount
	FR.lifetime = TrailDuration
	
	FL.amount = TrailAmount
	FL.lifetime = TrailDuration
	
	BR.amount = TrailAmount
	BR.lifetime = TrailDuration
	
	BL.amount = TrailAmount
	BL.lifetime = TrailDuration

func emit_particle(dir : String):
	if dir == "FR" :
		FR.emitting = true
		self.z_index = 0
		#print("Front Right Trail")
	elif dir == "FL":
		
		FL.emitting = true
		self.z_index = 0
		#print("Front Left Trail")
	elif dir == "BR":
		
		BR.emitting = true
		self.z_index = 1
		#print("Back Right Trail")
	elif dir == "BL":
		
		BL.emitting = true
		self.z_index = 1
		#print("Back Left Trail")
	else:
		print("DASHTRAIL ERROR: INVALID FUNCTION PARAMETER")
