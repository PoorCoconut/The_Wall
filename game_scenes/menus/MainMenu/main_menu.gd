## MainMenu.gd

extends Control

@onready var button_play     : Button  = %Button_NewGame
@onready var button_continue : Button  = %Button_Continue
@onready var button_settings : Button  = %Button_Settings
@onready var button_credits  : Button  = %Button_Credits
@onready var button_exit     : Button  = %Button_Exit

@onready var slider_ma_vol : HSlider = %Slider_MaVol
@onready var slider_mu_vol : HSlider = %Slider_MuVol
@onready var slider_s_vol  : HSlider = %Slider_SVol

@export_file("*.tscn") var next_level_path : String  # used by New Game only
@export_file("*.tscn") var credits_path    : String

# Slot UI node references — built from the pattern Slot{N}Dash / Slot{N}Glow / etc.
# Keyed by slot number (1-3) for easy iteration.
@onready var slot_nodes := {
	1: {
		"graphic"   : %Slot1Graphic,
		"powerups"  : %Slot1PowerUpContainer,
		"dash"      : %Slot1Dash,
		"slash"     : %Slot1Slash,
		"glow"      : %Slot1Glow,
		"text"      : %TextSlot1,
		"info"      : %Slot1Information,
		"area_name" : %Slot1AreaName,
		"time"      : %Slot1Time,
	},
	2: {
		"graphic"   : %Slot2Graphic,
		"powerups"  : %Slot2PowerUpContainer,
		"dash"      : %Slot2Dash,
		"slash"     : %Slot2Slash,
		"glow"      : %Slot2Glow,
		"text"      : %TextSlot2,
		"info"      : %Slot2Information,
		"area_name" : %Slot2AreaName,
		"time"      : %Slot2Time,
	},
	3: {
		"graphic"   : %Slot3Graphic,
		"powerups"  : %Slot3PowerUpContainer,
		"dash"      : %Slot3Dash,
		"slash"     : %Slot3Slash,
		"glow"      : %Slot3Glow,
		"text"      : %TextSlot3,
		"info"      : %Slot3Information,
		"area_name" : %Slot3AreaName,
		"time"      : %Slot3Time,
	},
}

## Tracks which slot the player clicked so the transition callback knows
## which scene to load.  -1 = no slot chosen yet.
var _pending_slot : int = -1


# ── Lifecycle ──────────────────────────────────────────────────────────────────
func _ready() -> void:
	if GameManager.launched_game == false:
		%Anim_IntroScene.play("IntroScene")
		GameManager.launched_game = true
	else:
		%Anim_IntroScene.play("set_ready_menu")
		%Music.play(8.7)

	slider_ma_vol.value = SettingsManager.master_vol
	slider_mu_vol.value = SettingsManager.music_vol
	slider_s_vol.value  = SettingsManager.sfx_vol

	_refresh_saves_ui()


# ── Save Slot UI ───────────────────────────────────────────────────────────────

## Reads all three slots from disk and updates every node in the SavesContainer.
func _refresh_saves_ui() -> void:
	var summaries : Array = SaveManager.get_all_slot_summaries()

	for summary in summaries:
		var n     : int        = summary["slot"]
		var nodes : Dictionary = slot_nodes[n]

		if not summary["exists"]:
			# Empty slot — hide everything except the centre label.
			nodes["powerups"].hide()
			nodes["info"].hide()
			nodes["text"].text = "EMPTY SLOT"
			nodes["text"].show()
		else:
			# Populated slot.
			nodes["text"].text = "CONTINUE SLOT %d" % n
			nodes["text"].show()

			# Power-up icons: show only acquired ones.
			nodes["dash"].visible  = summary["has_dash"]
			nodes["glow"].visible  = summary["has_glow"]
			# "slash" maps to has_strike in the save data.
			nodes["slash"].visible = summary["has_strike"]
			nodes["powerups"].show()

			# Area name and accumulated playtime.
			nodes["area_name"].text = summary["area_name"]
			nodes["time"].text      = GameManager.format_playtime(summary["playtime"])
			nodes["info"].show()


func _on_close_saves_container_pressed() -> void:
	%SavesContainer.visible = false


# ── Slot Button Callbacks ──────────────────────────────────────────────────────

func _on_save_slot_1_pressed() -> void:
	_select_slot(1)

func _on_save_slot_2_pressed() -> void:
	_select_slot(2)

func _on_save_slot_3_pressed() -> void:
	_select_slot(3)

## Shared logic for all three slot buttons.
func _select_slot(slot: int) -> void:
	if not SaveManager.slot_exists(slot):
		return  # Button pressed on an empty slot — do nothing.

	_pending_slot = slot
	%SavesContainer.hide()

	var tween = get_tree().create_tween()
	tween.tween_property(%Music, "volume_db", -80, 1)
	%Anim_TransitionContinue.play("transition")
	# Execution continues in _on_anim_transition_continue_animation_finished().


# ── Animation Callbacks ────────────────────────────────────────────────────────

func _on_anim_transition_continue_animation_finished(_anim_name: StringName) -> void:
	if _pending_slot != -1:
		# Continue — load the scene stored in the chosen save slot.
		GameManager.load_saved_scene(_pending_slot, next_level_path)
		_pending_slot = -1
	else:
		# New Game — load the default starting scene.
		GameManager.load_next_level(next_level_path)


# ── Main Menu Buttons ──────────────────────────────────────────────────────────

func _on_button_new_game_pressed() -> void:
	# Plays the intro cutscene transition into the starting scene.
	_pending_slot = -1
	var tween = get_tree().create_tween()
	tween.tween_property(%Music, "volume_db", -80, 1)
	%Anim_TransitionContinue.play("transition")

func _on_button_play_pressed() -> void:
	# Opens the save slot picker.
	%SavesContainer.visible = true

func _on_button_settings_pressed() -> void:
	%SettingsContainer.show()

func _on_button_credits_pressed() -> void:
	pass

func _on_button_exit_pressed() -> void:
	get_tree().quit()

func _on_back_button_pressed() -> void:
	%SettingsContainer.hide()
	%WarningLabel.hide()
	%NukeButton.hide()
	%ResetButton.show()

func _on_reset_button_pressed() -> void:
	%WarningLabel.show()
	%NukeButton.show()
	%ResetButton.hide()


# ── Audio Sliders ──────────────────────────────────────────────────────────────

func _on_slider_ma_vol_value_changed(value: float) -> void:
	SettingsManager.master_vol = value
	SettingsManager.save_settings()

func _on_slider_mu_vol_value_changed(value: float) -> void:
	SettingsManager.music_vol = value
	SettingsManager.save_settings()

func _on_slider_s_vol_value_changed(value: float) -> void:
	SettingsManager.sfx_vol = value
	SettingsManager.save_settings()


# ── Nuke Button (reset everything) ────────────────────────────────────────────

func _on_nuke_button_pressed() -> void:
	%WarningLabel.hide()
	%NukeButton.hide()
	%ResetButton.show()

	# Reset audio.
	SettingsManager.master_vol = 1.0
	SettingsManager.music_vol  = 1.0
	SettingsManager.sfx_vol    = 1.0
	SettingsManager.save_settings()

	slider_ma_vol.value = SettingsManager.master_vol
	slider_mu_vol.value = SettingsManager.music_vol
	slider_s_vol.value  = SettingsManager.sfx_vol

	# Wipe all three save slots via SaveManager.
	for slot in range(1, 4):
		SaveManager.delete_save(slot)

	# Refresh slot UI to show "EMPTY SLOT" everywhere.
	_refresh_saves_ui()

	# Reset keybinds.
	SettingsManager.reset_keybinds_to_default()


# ── Resolution / Window Buttons ────────────────────────────────────────────────

func _on_button_1080p_pressed() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))

func _on_button_720p_pressed() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))

func _on_button_540p_pressed() -> void:
	DisplayServer.window_set_size(Vector2i(990, 540))

func _on_button_windowed_pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_button_fullscreen_pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_button_exclusive_fullscreen_pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


# ── Controls Settings ──────────────────────────────────────────────────────────

@onready var action_list_container : GridContainer = %RebindContainer

func _on_controls_reset_pressed() -> void:
	SettingsManager.reset_keybinds_to_default()
