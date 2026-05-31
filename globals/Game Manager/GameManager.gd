extends Node

##Player State
var player_name : String = "Player"
var current_player_state : String = "idle"
var has_dash : bool = false
var has_glow : bool = false
var has_strike : bool = false

var player : Player

## ── Persistent Player Stats ───────────────────────────────────────
## These are the single source of truth for health and ammo.
## Player reads these on _ready() and writes back whenever they change.
## -1 means "not yet initialised" — player will use its own export defaults.
var player_max_hp: int = -1
var player_cur_hp: int = -1
var player_max_bullets: int = -1
var player_cur_bullets: int = -1


##World State
var intro_done : bool = false
var launched_game : bool = false
var last_saved_room

var current_world_state : String = "default"
#List of world states [default , freeze]

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
var target_door_id : String = ""

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
	Dialogic.timeline_started.connect(_on_timeline_started)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
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

## ── Persistent stat helpers ───────────────────────────────────────

func has_player_stats() -> bool:
	## Returns true if GameManager already holds initialised player stats.
	## False means this is a fresh start and the player should use its own defaults.
	return player_cur_hp != -1

func save_player_stats(p: Player) -> void:
	## Call this right before a scene transition so stats survive the load.
	player_max_hp      = p.health_component.MAX_HP
	player_cur_hp      = p.health_component.CUR_HP
	player_max_bullets = p.max_bullets
	player_cur_bullets = p.cur_bullets

func restore_player_stats(p: Player) -> void:
	## Called from Player._ready(). Pushes GameManager values into the player
	## and its components, then fires UI update events.
	if not has_player_stats():
		## First run — use the player's inspector defaults and seed GameManager.
		player_max_hp      = p.health_component.MAX_HP
		player_cur_hp      = p.health_component.CUR_HP
		player_max_bullets = p.max_bullets
		player_cur_bullets = p.cur_bullets
	else:
		## Room transition — restore saved values into the components.
		p.health_component.MAX_HP = player_max_hp
		p.health_component.CUR_HP = player_cur_hp
		p.max_bullets             = player_max_bullets
		p.cur_bullets             = player_cur_bullets

	## Always fire UI events so HUD reflects current state immediately.
	Events.player_hp_updated.emit(p.health_component.CUR_HP, p.health_component.MAX_HP)
	Events.player_ammo_updated.emit(p.cur_bullets, p.max_bullets)

##SAVE FILE LOGIC
func save_game(player_pos: Vector2) -> void:
	var save_data = {
		"player_name"       : player_name,
		"player_x"          : player_pos.x,
		"player_y"          : player_pos.y,
		"current_location"  : current_location,
		"dash"              : has_dash,
		"glow"              : has_glow,
		"strike"            : has_strike,
		"world_state"       : current_world_state,
		## Persistent stats
		"player_max_hp"     : player_max_hp,
		"player_cur_hp"     : player_cur_hp,
		"player_max_bullets": player_max_bullets,
		"player_cur_bullets": player_cur_bullets,
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data, "\t"))

	# Sync Dialogic narrative data to a default slot
	Dialogic.Save.save("slot_1")

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found.")
		return null

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var save_data = JSON.parse_string(file.get_as_text())

	var loaded_pos = null

	if save_data:
		if save_data.has("player_name"):
			player_name = save_data["player_name"]

		if save_data.has("player_x") and save_data.has("player_y"):
			loaded_pos = Vector2(save_data["player_x"], save_data["player_y"])

		if save_data.has("current_location"):
			current_location = int(save_data["current_location"])

		if save_data.has("dash") and save_data.has("glow") and save_data.has("strike"):
			has_dash   = save_data["dash"]
			has_glow   = save_data["glow"]
			has_strike = save_data["strike"]

		if save_data.has("world_state"):
			current_world_state = save_data["world_state"]

		## Load persistent stats (guarded — old save files won't have these)
		if save_data.has("player_max_hp"):
			player_max_hp      = int(save_data["player_max_hp"])
		if save_data.has("player_cur_hp"):
			player_cur_hp      = int(save_data["player_cur_hp"])
		if save_data.has("player_max_bullets"):
			player_max_bullets = int(save_data["player_max_bullets"])
		if save_data.has("player_cur_bullets"):
			player_cur_bullets = int(save_data["player_cur_bullets"])

	# Sync Dialogic narrative data
	if Dialogic.Save.has_slot("slot_1"):
		Dialogic.Save.load("slot_1")

	print("Save loaded! Teleporting player to: ", loaded_pos)
	if get_tree().get_first_node_in_group("Player") and get_tree().get_first_node_in_group("Obelisk"):
		teleport_player(loaded_pos)

##Player Helper Functions
func teleport_player(new_pos : Vector2) -> void:
	player = get_tree().get_first_node_in_group("Player")
	if player:
		player.global_position = new_pos

##Next Level Helper Functions
func load_next_level(next_level_path : String) -> void:
	## Save player stats right before the scene unloads.
	player = get_tree().get_first_node_in_group("Player")
	if player:
		save_player_stats(player)
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

func _on_timeline_started() -> void:
	current_world_state = "freeze"
	player = get_tree().get_first_node_in_group("Player")
	if player:
		player.FSM.force_change_state("Lock")

func _on_timeline_ended() -> void:
	current_world_state = "default"
