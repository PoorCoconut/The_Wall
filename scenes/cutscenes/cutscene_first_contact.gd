extends Node2D

@export var next_scene : PackedScene
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
	
	GameManager.setPlayerName(user_name)
	
	Dialogic.signal_event.connect(_on_dialogic_signal)
	var music_tween = get_tree().create_tween()
	music_tween.tween_property(%TW_AMBIENCE, "volume_db", -10, 5)
	var tween = get_tree().create_tween()
	tween.tween_property(%Background, "modulate", Color(1,1,1,0), 5)
	await tween.finished
	Dialogic.start("TW_first_greet_1")
	change_kaleidoscope_speed(10)

func change_kaleidoscope_speed(newValue: float):
	var tween = get_tree().create_tween()
	tween.tween_property(%Kaleidoscope.material, "shader_parameter/sourceAngle", newValue, 120)

func _on_dialogic_signal(argument:String):
	if argument == "window_confirm":
		%Window_YesNo.title = "The Wall asks..."
		%Window_YesNo.dialog_text = "We will call you " + GameManager.getPlayerName()
		%Window_YesNo.show()
	
	elif argument == "dialogue_done":
		%Background.color = Color(1.0, 1.0, 1.0, 0.0)
		var tween = get_tree().create_tween()
		tween.tween_property(%Background, "modulate", Color(1,1,1,1), 5)
		await tween.finished
		get_tree().change_scene_to_packed(next_scene)


func _on_window_yes_no_confirmed() -> void:
	Dialogic.VAR.set('nameChange', false)
	Dialogic.start("TW_first_greet_2")

func _on_window_yes_no_canceled() -> void:
	Dialogic.VAR.set('nameChange', true)
	Dialogic.start("TW_first_greet_2")
