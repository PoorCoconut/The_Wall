extends Node2D

var user_name : String = "Player"

func _ready() -> void:
	#Checks for username. Failsafes to Player.
	if OS.has_environment("USERNAME"):
		user_name = OS.get_environment("USERNAME")
	else:
		if OS.has_environment("USER"):
			user_name = OS.get_environment("USER")
		
	if user_name == "user":
			user_name = "Player"
		
	%Window_YesNo.dialog_text = "Hello, " + user_name
	%Window_YesNo.show()

func reset_label_ratio() -> void:
	%DialogueText.visible_ratio = 0.0
