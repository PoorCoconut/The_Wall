extends Node

var player_name : String = "Player"

var enemyhitpos : Vector2
var enemy_aggro_count : int
var shakeWindow : bool = false

#Threat Mechanic
signal threat_level_changed(new_level)
var threat_level: float = 1.0:
	set(value):
		# Only update if the value is actually different
		if threat_level != value:
			threat_level = value
			# 3. Emit the signal whenever this variable is changed
			threat_level_changed.emit(threat_level)

enum LOCATION{
	UNKNOWN, #The DEFAULT and failsafe value
	HUB,
	RUINS,
	FOREST,
	SNOW,
	PEAK,
	CAVERN
}
var current_location = LOCATION.UNKNOWN

func _ready() -> void:
	Dialogic.signal_event.connect(_on_dialogic_signal)

func setShakeWindow(option : bool):
	$Timer.start()
	shakeWindow = option

func setPlayerName(_player_name : String) -> void:
	Dialogic.VAR.set('playerName', _player_name)
	player_name = _player_name

func getPlayerName() -> String:
	return player_name

func _process(_delta: float) -> void:
	if shakeWindow:
		window_shake()

func window_shake():
	DisplayServer.window_set_position(DisplayServer.window_get_position()+Vector2i(randi_range(-10, 10),randi_range(-10, 10)))

func _on_timer_timeout() -> void:
	shakeWindow = false

func _on_dialogic_signal(argument:String):
	#print("hello???")
	if argument == "name_changed":
		setPlayerName(Dialogic.VAR.playerName)
		
