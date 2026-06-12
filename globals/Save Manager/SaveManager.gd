## SaveManager.gd
## Autoload — owns every FileAccess call in the project.
##
## Responsibilities
##   • Read / write the three game-save slots  (user://save_slot_X.json)
##   • Read / write settings                   (user://settings.json)
##   • Read / write keybind config             (user://settings.cfg)
##
## Neither GameManager nor SettingsManager touch the disk directly anymore;
## they call helpers here and work with plain Dictionaries.

extends Node

# ── Paths ──────────────────────────────────────────────────────────────────────
const SETTINGS_JSON_PATH : String = "user://settings.json"
const KEYBINDS_CFG_PATH  : String = "user://settings.cfg"

## Returns the file path for a given slot index (1-based: 1, 2, or 3).
func slot_path(slot: int) -> String:
	return "user://save_slot_%d.json" % slot


# ── Game Save I/O ──────────────────────────────────────────────────────────────

## Writes save_data (Dictionary) to the given slot.
## Also syncs Dialogic narrative data to a matching Dialogic slot.
func write_save(slot: int, save_data: Dictionary) -> void:
	var path := slot_path(slot)
	var file  := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: could not open '%s' for writing." % path)
		return
	file.store_string(JSON.stringify(save_data, "\t"))

	# Sync Dialogic narrative data
	Dialogic.Save.save("dialogic_slot_%d" % slot)


## Reads and returns the Dictionary stored in the given slot.
## Returns null if the slot file does not exist or is unreadable.
func read_save(slot: int) -> Variant:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveManager: could not open '%s' for reading." % path)
		return null

	var data = JSON.parse_string(file.get_as_text())
	if data == null:
		push_error("SaveManager: JSON parse failed for '%s'." % path)
		return null

	# Sync Dialogic narrative data
	var dialogic_slot := "dialogic_slot_%d" % slot
	if Dialogic.Save.has_slot(dialogic_slot):
		Dialogic.Save.load(dialogic_slot)

	return data


## Returns true when a save file exists for the given slot.
func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


## Deletes the save file (and matching Dialogic slot) for the given slot.
func delete_save(slot: int) -> void:
	var path := slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

	var dialogic_slot := "dialogic_slot_%d" % slot
	if Dialogic.Save.has_slot(dialogic_slot):
		Dialogic.Save.delete_slot(dialogic_slot)


## Returns a lightweight summary Dictionary for each slot — useful for a
## save-select screen.  Fields: exists, player_name, area_name, save_time,
## has_dash, has_glow, has_strike.
func get_all_slot_summaries() -> Array:
	var summaries := []
	for slot in range(1, 4):
		var data = read_save(slot)
		if data == null:
			summaries.append({ "exists": false, "slot": slot })
		else:
			summaries.append({
				"exists"      : true,
				"slot"        : slot,
				"player_name" : data.get("player_name", "Unknown"),
				"area_name"   : data.get("area_name",   "Unknown Area"),
				"playtime"    : data.get("playtime_seconds", 0.0),
				"scene_path"  : data.get("scene_path",  ""),
				"has_dash"    : data.get("dash",         false),
				"has_glow"    : data.get("glow",         false),
				"has_strike"  : data.get("strike",       false),
			})
	return summaries


# ── Settings I/O ───────────────────────────────────────────────────────────────

## Writes the settings Dictionary to disk.
func write_settings(data: Dictionary) -> void:
	var file := FileAccess.open(SETTINGS_JSON_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: could not open settings file for writing.")
		return
	file.store_string(JSON.stringify(data, "\t"))


## Reads and returns the settings Dictionary.
## Returns null if the file does not exist.
func read_settings() -> Variant:
	if not FileAccess.file_exists(SETTINGS_JSON_PATH):
		return null

	var file := FileAccess.open(SETTINGS_JSON_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: could not open settings file for reading.")
		return null

	return JSON.parse_string(file.get_as_text())


# ── Keybind Config I/O ─────────────────────────────────────────────────────────

## Saves keybind slot data via ConfigFile and returns the ConfigFile instance.
func write_keybinds(slotted_binds: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("Keybinds", "slots", slotted_binds)
	var err := cfg.save(KEYBINDS_CFG_PATH)
	if err != OK:
		push_error("SaveManager: failed to save keybinds, error %d." % err)


## Returns a [ConfigFile, error_code] pair. Caller checks error_code == OK.
func read_keybinds() -> Array:
	var cfg := ConfigFile.new()
	var err  := cfg.load(KEYBINDS_CFG_PATH)
	return [cfg, err]
