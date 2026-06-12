extends Node2D
@onready var camera : WorldCamera = %WorldCameraComponent
@onready var boss := %LAZIK
@onready var spawners: Node = $Spawners
@onready var spawn_crawler_timer: Timer = $SpawnCrawlerTimer

var crawler_path := preload("res://actors/enemy/Crawler/crawler.tscn")
var boss_defeated : bool = false
@export var cam_zoom : float = 1.0


func _ready() -> void:
	GameManager.current_location = GameManager.LOCATION.FOREST
	MusicManager.change_music("forest", 0)
	MusicManager.set_intensity(1.0, 5)


func _on_player_detector_body_entered(_body: Node2D) -> void:
	if boss == null:
		printerr("FATAL ERROR! BOSS...MISSING!?")
		return
	elif boss_defeated:
		return
	camera.camera_mode = camera.CameraMode.ENTITY_MIDPOINT
	camera.target2 = boss
	var tween = get_tree().create_tween()
	tween.tween_property(camera, "zoom", Vector2(cam_zoom, cam_zoom), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	spawn_crawler_timer.start()

func _on_timer_timeout() -> void:
	for spawner in spawners.get_children():
		if randi_range(1,5) == 1:
			return
		var crawler : Crawler = crawler_path.instantiate()
		crawler.global_position = spawner.global_position
		add_child(crawler)
	pass # Replace with function body.

func _on_lazik_boss_dead() -> void:
	boss_defeated = true
	camera.target = boss
	spawn_crawler_timer.stop()
	var tween = get_tree().create_tween()
	tween.tween_property(camera, "zoom", Vector2(1.5, 1.5),4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await get_tree().create_timer(4.0).timeout
	camera.target = get_tree().get_first_node_in_group("Player")
	pass # Replace with function body.
