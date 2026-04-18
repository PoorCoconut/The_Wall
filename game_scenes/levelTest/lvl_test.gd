extends Node2D

func _ready() -> void:
	GameManager.current_location = GameManager.LOCATION.FOREST
	MusicManager.change_music("forest", 0)
	GameManager.load_game()
