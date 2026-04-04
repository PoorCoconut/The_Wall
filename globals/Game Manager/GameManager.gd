extends Node

##Player State
var player_name : String = "Player"
var current_player_state : String = "idle"
var has_dash : bool = false
var has_glow : bool = false
var has_strike : bool = false

##World State
var current_world_state : String = "Nothing"
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

##Save File
const SAVE_PATH : String = "user://savegame.json"

#Threat Mechanic
var threat_level: float = 0.0:
	set(value):
		if threat_level != value:
			threat_level = value
			MusicManager.set_intensity(threat_level, 2)

func _ready() -> void:
	Dialogic.signal_event.connect(_on_dialogic_signal)
	load_game()

func setPlayerName(_player_name : String) -> void:
	Dialogic.VAR.set('playerName', _player_name)
	player_name = _player_name

func getPlayerName() -> String:
	return player_name

func window_shake():
	DisplayServer.window_set_position(DisplayServer.window_get_position()+Vector2i(randi_range(-10, 10),randi_range(-10, 10)))

func _on_dialogic_signal(argument:String):
	if argument == "name_changed":
		setPlayerName(Dialogic.VAR.playerName)

##SAVE FILE LOGIC
func save_game(player_pos: Vector2) -> void:
	var save_data = {
		"player_name" : player_name,
		"player_x": player_pos.x,
		"player_y": player_pos.y,
		"current_location": current_location,
		"dash": has_dash,
		"glow": has_glow,
		"strike": has_strike,
		"world_state": current_world_state,
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data, "\t"))
	print("Game Saved!")

func load_game():
	#Check if the player has ever saved the game before
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found. Starting from the bottom!")
		return null # Returning null lets the Player node know to use its default spawn
		
	#Open the file and read the text
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_text = file.get_as_text()
	
	#Parse the JSON back into a dictionary
	var save_data = JSON.parse_string(json_text)
	
	#Extract the coordinates and return them as a usable Vector2
	if save_data:
		if save_data.has("player_name"):
			player_name = save_data["player_name"]
			
		if save_data.has("player_x") and save_data.has("player_y"):
			var loaded_pos = Vector2(save_data["player_x"], save_data["player_y"])
			print("Save loaded! Teleporting player to: ", loaded_pos)
			return loaded_pos
			
		if save_data.has("current_location"):
			current_location = save_data["current_location"]
			
		if save_data.has("dash") and save_data.has("glow") and save_data.has("strike"):
			has_dash = save_data["dash"]
			has_glow = save_data["glow"]
			has_strike = save_data["strike"]
			
		if save_data.has("world_state"):
			current_world_state = save_data["world_state"]
			
	return null

##Next Level Helper Functions
func load_next_level(next_level_path : String) -> void:
	await ScreenTransition.trans_in().finished
	LoadingScreen.load_level(next_level_path)

##Camera Helper Functions
func do_camera_shake(intensity:float, time:float):
	if get_tree().get_first_node_in_group("camera"):
		var camera : WorldCamera = get_tree().get_first_node_in_group("camera")
		var camera_tween = get_tree().create_tween()
		camera_tween.tween_method(camera.startCameraShake, intensity, 1.0, time)
		camera.startCameraShake(intensity)
		await get_tree().create_timer(time).timeout
		camera.resetCameraOffset()

#func move_camera_to_player(player_pos : Vector2):
	#if get_tree().get_first_node_in_group("camera"):
		#var camera = get_tree().get_first_node_in_group("camera")
		#camera.moveCameraToEntity(player_pos)
