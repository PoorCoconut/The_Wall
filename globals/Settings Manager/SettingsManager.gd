## SettingsManager.gd
## Autoload — owns audio / display settings and keybind remapping.
##
## File I/O has been extracted to SaveManager.
## The public API (save_settings, load_settings, apply_audio_settings, …)
## is unchanged so existing call-sites need no edits.

extends Node

# ── Settings Variables ─────────────────────────────────────────────────────────
var master_vol  : float = 1.0
var music_vol   : float = 1.0
var sfx_vol     : float = 1.0
var screen_shake: bool  = true


# ── Lifecycle ──────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Snapshot the project's default bindings before loading from disk.
	for action in InputMap.get_actions():
		slotted_binds[action] = {}
		var events := InputMap.action_get_events(action)
		for i in range(events.size()):
			slotted_binds[action][i] = events[i]

	load_settings()


# ── Audio Settings ─────────────────────────────────────────────────────────────
func save_settings() -> void:
	var data := {
		"master_vol"  : master_vol,
		"music_vol"   : music_vol,
		"sfx_vol"     : sfx_vol,
		"screen_shake": screen_shake,
	}
	SaveManager.write_settings(data)
	apply_audio_settings()


func load_settings() -> void:
	var data = SaveManager.read_settings()

	if data == null:
		# First launch — write defaults so the file exists next time.
		save_settings()
		return

	master_vol   = data.get("master_vol",   1.0)
	music_vol    = data.get("music_vol",    1.0)
	sfx_vol      = data.get("sfx_vol",      1.0)
	screen_shake = data.get("screen_shake", true)

	apply_audio_settings()
	load_keybinds()


func apply_audio_settings() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_vol))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),  linear_to_db(music_vol))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"),    linear_to_db(sfx_vol))


# ── Keybind Remapping ──────────────────────────────────────────────────────────
signal controls_reset
signal keybinds_updated

var slotted_binds : Dictionary = {}


func reset_keybinds_to_default() -> void:
	var result := SaveManager.read_keybinds()
	var cfg    : ConfigFile = result[0]
	var err    : int        = result[1]

	if err == OK and cfg.has_section("Keybinds"):
		cfg.erase_section("Keybinds")
		# Persist the erasure
		SaveManager.write_keybinds({})

	InputMap.load_from_project_settings()

	slotted_binds.clear()
	for action in InputMap.get_actions():
		slotted_binds[action] = {}
		var events := InputMap.action_get_events(action)
		for i in range(events.size()):
			slotted_binds[action][i] = events[i]

	controls_reset.emit()


func update_keybind(target_action: String, target_index: int, new_event: InputEvent) -> void:
	# Hunt down duplicates and clear them.
	for action in slotted_binds:
		if action.begins_with("ui_") and action != target_action:
			continue
		for index in slotted_binds[action]:
			var event = slotted_binds[action][index]
			if event != null and event.is_match(new_event):
				slotted_binds[action][index] = null

	# Assign to target slot.
	if not slotted_binds.has(target_action):
		slotted_binds[target_action] = {}
	slotted_binds[target_action][target_index] = new_event

	# Sync engine InputMap and persist.
	_sync_inputmap_to_slots()
	SaveManager.write_keybinds(slotted_binds)

	keybinds_updated.emit()


func _sync_inputmap_to_slots() -> void:
	for action in slotted_binds:
		InputMap.action_erase_events(action)
		for index in slotted_binds[action]:
			var event = slotted_binds[action][index]
			if event != null:
				InputMap.action_add_event(action, event)


func load_keybinds() -> void:
	var result := SaveManager.read_keybinds()
	var cfg    : ConfigFile = result[0]
	var err    : int        = result[1]

	if err == OK and cfg.has_section_key("Keybinds", "slots"):
		slotted_binds = cfg.get_value("Keybinds", "slots")
		_sync_inputmap_to_slots()
