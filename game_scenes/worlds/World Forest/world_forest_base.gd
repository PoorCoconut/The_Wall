extends Node2D
@export var music_name : String = "forest"

func _ready() -> void:
	GameManager.current_location = GameManager.LOCATION.FOREST
	MusicManager.change_music(music_name, 1)
