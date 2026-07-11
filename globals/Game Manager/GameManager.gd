## GameManager.gd
## Autoload — tracks global game state and coordinates scene transitions.
##
## Save / load logic has been extracted to SaveManager.
## The public API (save_game, load_game, teleport_player, …) is unchanged so
## existing call-sites need no edits.

extends Node

# ── Player State ───────────────────────────────────────────────────────────────
var player_name  : String = "Player"
var current_player_state : String = "idle"
var has_dash     : bool = false
var has_glow     : bool = false
var has_strike   : bool = false

var player : Player

# ── Persistent Player Stats ────────────────────────────────────────────────────
# -1 means "not yet initialised" — player will use its own export defaults.
var player_max_hp      : int = -1
var player_cur_hp      : int = -1
var player_max_bullets : int = -1
var player_cur_bullets : int = -1

# ── World State ────────────────────────────────────────────────────────────────
var intro_done   : bool   = false
var launched_game: bool   = false
var last_saved_room

var current_world_state : String = "default"
# World states: [default, freeze]

# -- Game State --
var defeated_lazik1 : bool = false
var defeated_lazik2 : bool = false


enum LOCATION {
	UNKNOWN, # Default / failsafe
	HUB,
	RUINS,
	FOREST,
	SNOW,
	PEAK,
	CAVERN
}
var current_location = LOCATION.UNKNOWN
var target_door_id   : String = ""

## Human-readable name of the area where the player last saved.
## Shown on the save-select screen.
var last_saved_area : String = "Unknown Area"

## Scene file path (.tscn) the player was in when they last saved.
## Used by load_saved_scene() to transition back to the right room.
var last_saved_scene : String = ""

# ── Active Save Slot ───────────────────────────────────────────────────────────
## Which slot (1-3) is currently in use.  Set before calling save_game /
## load_game if you want a specific slot; defaults to 1 for backwards
## compatibility.
var active_slot : int = 1

# ── Threat Mechanic ────────────────────────────────────────────────────────────
var threat_level: float = 0.0:
	set(value):
		if threat_level != value:
			threat_level = value
			MusicManager.set_intensity(threat_level, 2)


# ── Playtime Tracking ─────────────────────────────────────────────────────────
## Total accumulated playtime in seconds for the active save slot.
## Loaded from disk on continue, then counted up in _process().
var playtime_seconds : float = 0.0

## Only paused during level loads (LoadingScreen sets this via
## pause_playtime / resume_playtime) so loading time isn't counted.
var playtime_running : bool = false


# ── Lifecycle ──────────────────────────────────────────────────────────────────
func _ready() -> void:
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.timeline_started.connect(_on_timeline_started)
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	load_game()


func _process(delta: float) -> void:
	if playtime_running:
		playtime_seconds += delta


# ── Player Name ────────────────────────────────────────────────────────────────
func setPlayerName(_player_name : String) -> void:
	Dialogic.VAR.set('playerName', _player_name)
	player_name = _player_name

func getPlayerName() -> String:
	return player_name


# ── Misc Helpers ───────────────────────────────────────────────────────────────
func window_shake() -> void:
	DisplayServer.window_set_position(
		DisplayServer.window_get_position()
		+ Vector2i(randi_range(-10, 10), randi_range(-10, 10))
	)

func _on_dialogic_signal(argument: String) -> void:
	if argument == "name_changed":
		setPlayerName(Dialogic.VAR.playerName)



## Called by LoadingScreen at the start and end of every level load.
func pause_playtime() -> void:
	playtime_running = false

func resume_playtime() -> void:
	playtime_running = true


## Converts raw seconds to a "HH:MM:SS" display string.
func format_playtime(total_seconds: float) -> String:
	var s := int(total_seconds)
	var hours   := s / 3600
	var minutes := (s % 3600) / 60
	var seconds := s % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]


# ── Persistent Stat Helpers ────────────────────────────────────────────────────
func has_player_stats() -> bool:
	return player_cur_hp != -1

func save_player_stats(p: Player) -> void:
	player_max_hp      = p.health_component.MAX_HP
	player_cur_hp      = p.health_component.CUR_HP
	player_max_bullets = p.max_bullets
	player_cur_bullets = p.cur_bullets

func restore_player_stats(p: Player) -> void:
	if not has_player_stats():
		player_max_hp      = p.health_component.MAX_HP
		player_cur_hp      = p.health_component.CUR_HP
		player_max_bullets = p.max_bullets
		player_cur_bullets = p.cur_bullets
	else:
		p.health_component.MAX_HP = player_max_hp
		p.health_component.CUR_HP = player_cur_hp
		p.max_bullets             = player_max_bullets
		p.cur_bullets             = player_cur_bullets

	Events.player_hp_updated.emit(p.health_component.CUR_HP, p.health_component.MAX_HP)
	Events.player_ammo_updated.emit(p.cur_bullets, p.max_bullets)


# ── Save / Load (public API — unchanged, delegates to SaveManager) ─────────────

## Saves the game to `active_slot`.
##
## player_pos  — world position to store. If omitted (or called from a menu
##               where no player exists), the last known position is preserved
##               so the player resumes from where they actually saved in-world.
## area_name   — human-readable label shown on the save-select screen.
## scene_path  — the .tscn path to return to on continue. If omitted, the
##               last known scene is preserved (safe to call from menus).
func save_game(player_pos: Vector2 = Vector2(INF, INF), area_name: String = last_saved_area, scene_path: String = last_saved_scene) -> void:
	last_saved_area  = area_name
	if scene_path != "":
		last_saved_scene = scene_path

	# If no position was passed, try to read it live from the player node.
	# If the player node doesn't exist either (e.g. main menu), fall back to
	# whatever was loaded from disk so we never overwrite with garbage.
	var pos_to_save : Vector2 = loaded_player_pos
	if player_pos != Vector2(INF, INF):
		pos_to_save = player_pos
	else:
		var p = get_tree().get_first_node_in_group("Player")
		if p:
			pos_to_save = p.global_position

	var save_data := {
		"player_name"        : player_name,
		"player_x"           : pos_to_save.x,
		"player_y"           : pos_to_save.y,
		"current_location"   : current_location,
		"area_name"          : last_saved_area,
		"save_time"          : Time.get_datetime_string_from_system(),
		"scene_path"         : last_saved_scene,
		"playtime_seconds"   : playtime_seconds,
		"dash"               : has_dash,
		"glow"               : has_glow,
		"strike"             : has_strike,
		"world_state"        : current_world_state,
		"player_max_hp"      : player_max_hp,
		"player_cur_hp"      : player_cur_hp,
		"player_max_bullets" : player_max_bullets,
		"player_cur_bullets" : player_cur_bullets,
	}

	SaveManager.write_save(active_slot, save_data)


## Loads game state from `active_slot` into GameManager variables.
##
## load_position — when TRUE the player node is immediately teleported to the
##                 saved coordinates (normal gameplay).
##                 When FALSE (default) the coordinates are stored in
##                 `loaded_player_pos` and nothing moves — useful while
##                 testing individual rooms in the editor.
var loaded_player_pos : Vector2 = Vector2.ZERO
## Set to true by load_saved_scene() so Player._ready() knows to
## override the RTC spawn with the saved world position.
var pending_save_position : bool = false

## When true, Player._ready() should override its spawn position with
## loaded_player_pos after RoomTransitionComponent runs.
## Cleared automatically once consumed so it never bleeds into the next load.

func load_game(load_position: bool = false) -> void:
	var save_data = SaveManager.read_save(active_slot)

	if save_data == null:
		print("GameManager: no save found in slot %d." % active_slot)
		return

	_apply_save_data(save_data)

	print("GameManager: slot %d loaded. Saved position: %s" % [active_slot, loaded_player_pos])

	# Begin counting playtime now that a save is loaded.
	playtime_running = true

	if load_position:
		if get_tree().get_first_node_in_group("Player") and get_tree().get_first_node_in_group("Obelisk"):
			teleport_player(loaded_player_pos)


## Convenience wrapper: load a specific slot without changing active_slot permanently.
func load_game_slot(slot: int, load_position: bool = false) -> void:
	var prev := active_slot
	active_slot = slot
	load_game(load_position)
	active_slot = prev


## Applies a raw save Dictionary to all GameManager fields.
## Split out so it can be called from both load_game variants.
func _apply_save_data(data: Dictionary) -> void:
	if data.has("player_name"):
		player_name = data["player_name"]

	if data.has("player_x") and data.has("player_y"):
		loaded_player_pos = Vector2(data["player_x"], data["player_y"])

	if data.has("current_location"):
		current_location = int(data["current_location"])

	if data.has("area_name"):
		last_saved_area = data["area_name"]

	if data.has("scene_path"):
		last_saved_scene = data["scene_path"]

	if data.has("dash"):   has_dash   = data["dash"]
	if data.has("glow"):   has_glow   = data["glow"]
	if data.has("strike"): has_strike = data["strike"]

	if data.has("world_state"):
		current_world_state = data["world_state"]

	if data.has("playtime_seconds"):
		playtime_seconds = float(data["playtime_seconds"])

	if data.has("player_max_hp"):      player_max_hp      = int(data["player_max_hp"])
	if data.has("player_cur_hp"):      player_cur_hp      = int(data["player_cur_hp"])
	if data.has("player_max_bullets"): player_max_bullets = int(data["player_max_bullets"])
	if data.has("player_cur_bullets"): player_cur_bullets = int(data["player_cur_bullets"])


## Loads a specific slot's data into GameManager, then transitions to the scene
## that was active when the player saved.
## Call this from the save-select / continue screen.
##
## If the slot has no scene recorded (old save file), falls back to
## `fallback_path` — which you can wire up to your default starting scene.
func load_saved_scene(slot: int, fallback_path: String = "") -> void:
	active_slot = slot
	load_game()  # populate all GameManager vars; position NOT applied yet

	var scene := last_saved_scene if last_saved_scene != "" else fallback_path
	if scene == "":
		push_error("GameManager.load_saved_scene: no scene path found for slot %d and no fallback provided." % slot)
		return

	## Clear any pending door-spawn so the RTC system doesn't override us.
	SpawnData.clear()
	## Flag the player's _ready() to apply the saved position
	## instead of the scene-default spawn point.
	pending_save_position = true
	load_next_level(scene)  # handles ScreenTransition + LoadingScreen


# ── Player Helper Functions ────────────────────────────────────────────────────
func teleport_player(new_pos: Vector2) -> void:
	player = get_tree().get_first_node_in_group("Player")
	if player:
		player.global_position = new_pos

## Teleports the player to the position that was loaded from the save file.
## Call this manually from a room's _ready() once everything has spawned.
func teleport_player_to_saved_pos() -> void:
	teleport_player(loaded_player_pos)


# ── Next Level Helper Functions ────────────────────────────────────────────────
func load_next_level(next_level_path: String) -> void:
	player = get_tree().get_first_node_in_group("Player")
	if player:
		save_player_stats(player)
	await ScreenTransition.trans_in().finished
	LoadingScreen.load_level(next_level_path)


# ── Camera Helper Functions ────────────────────────────────────────────────────
func do_camera_shake(intensity: float, time: float) -> void:
	if get_tree().get_first_node_in_group("camera"):
		var camera : WorldCamera = get_tree().get_first_node_in_group("camera")
		var camera_tween := get_tree().create_tween()
		camera_tween.tween_method(camera.startCameraShake, intensity, 1.0, time)
		camera.startCameraShake(intensity)
		await get_tree().create_timer(time).timeout
		camera.resetCameraOffset()


# ── Dialogic Callbacks ─────────────────────────────────────────────────────────
func _on_timeline_started() -> void:
	current_world_state = "freeze"
	player = get_tree().get_first_node_in_group("Player")
	if player:
		player.FSM.force_change_state("Lock")

func _on_timeline_ended() -> void:
	current_world_state = "default"
