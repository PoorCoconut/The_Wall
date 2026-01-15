extends Node2D

func _ready() -> void:
	GameManager.current_location = GameManager.LOCATION.FOREST
	MusicManager._on_update_music_state()
