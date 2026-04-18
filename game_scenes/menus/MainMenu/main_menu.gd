extends Control

@onready var button_play: Button = %Button_NewGame
@onready var button_continue: Button = %Button_Continue
@onready var button_settings: Button = %Button_Settings
@onready var button_credits: Button = %Button_Credits
@onready var button_exit: Button = %Button_Exit

@onready var slider_ma_vol: HSlider = %Slider_MaVol
@onready var slider_mu_vol: HSlider = %Slider_MuVol
@onready var slider_s_vol: HSlider = %Slider_SVol

@export_file("*.tscn") var next_level_path : String
@export_file("*.tscn") var credits_path : String

func _ready() -> void:
	if GameManager.launched_game == false:
		%Anim_IntroScene.play("IntroScene")
		GameManager.launched_game = true
	else:
		%Anim_IntroScene.play("set_ready_menu")
		%Music.play(8.7)
	
	slider_ma_vol.value = SettingsManager.master_vol
	slider_mu_vol.value = SettingsManager.music_vol
	slider_s_vol.value = SettingsManager.sfx_vol

func _on_button_new_game_pressed() -> void:
	pass # Replace with function body.

func _on_button_play_pressed() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(%Music, "volume_db", -80, 1)
	%Anim_TransitionContinue.play("transition")

func _on_anim_transition_continue_animation_finished(_anim_name: StringName) -> void:
	GameManager.load_next_level(next_level_path)

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

func _on_slider_ma_vol_value_changed(value: float) -> void:
	SettingsManager.master_vol = value
	SettingsManager.save_settings()

func _on_slider_mu_vol_value_changed(value: float) -> void:
	SettingsManager.music_vol = value
	SettingsManager.save_settings()

func _on_slider_s_vol_value_changed(value: float) -> void:
	SettingsManager.sfx_vol = value
	SettingsManager.save_settings()

func _on_nuke_button_pressed() -> void:
	#Reset ALL Settings to default, including player position
	%WarningLabel.hide()
	%NukeButton.hide()
	%ResetButton.show()
	
	#RESETTING AUDIO
	SettingsManager.master_vol = 1.0
	SettingsManager.music_vol = 1.0
	SettingsManager.sfx_vol = 1.0
	SettingsManager.save_settings()
	
	slider_ma_vol.value = SettingsManager.master_vol
	slider_mu_vol.value = SettingsManager.music_vol
	slider_s_vol.value = SettingsManager.sfx_vol
	
	#PLAYER POSITION [ALSO CALL YOUR "RESET PLAYER STATS" HERE]
	# Check if the save file exists, and if it does, delete it forever.
	var save_path = "user://savegame.json"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
		print("Save data wiped! Next run starts from the bottom.")
	
	#RESET KEYBINDS
	SettingsManager.reset_keybinds_to_default()


func _on_button_1080p_pressed() -> void:
	print("CLICKED 1080p BUTTON")
	DisplayServer.window_set_size(Vector2i(1980, 1080))

func _on_button_720p_pressed() -> void:
	print("CLICKED 720p BUTTON")
	DisplayServer.window_set_size(Vector2i(1280, 720))

func _on_button_540p_pressed() -> void:
	print("CLICKED 540p BUTTON")
	DisplayServer.window_set_size(Vector2i(990, 540))

func _on_button_windowed_pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_button_fullscreen_pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_button_exclusive_fullscreen_pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

##CONTROLS SETTINGS AND STUFF
@onready var action_list_container : GridContainer = %RebindContainer
func _on_controls_reset_pressed() -> void:
	SettingsManager.reset_keybinds_to_default()
