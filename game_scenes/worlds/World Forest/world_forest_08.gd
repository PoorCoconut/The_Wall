extends Node2D
@onready var camera : WorldCamera = %WorldCameraComponent
@onready var boss := %LAZIK
@onready var spawners: Node = $Spawners
@onready var spawn_crawler_timer: Timer = $SpawnCrawlerTimer

@onready var wall: TileMapLayer = $Wall
@onready var wall_2: TileMapLayer = $Wall2

var crawler_path := preload("res://actors/enemy/Crawler/crawler.tscn")
var boss_defeated : bool = false
@export var cam_zoom : float = 1.0

func _ready() -> void:
	GameManager.current_location = GameManager.LOCATION.FOREST
	MusicManager.change_music("warning", 0)

func _on_player_detector_body_entered(_body: Node2D) -> void:
	MusicManager.change_music("lazik", 0)
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
		if randi_range(1,5) != 1:
			return
		var enem_spawner : EnemySpawner = preload("res://systems/EnemySpawner/enemy_spawner.tscn").instantiate()
		get_tree().current_scene.add_child(enem_spawner)
		enem_spawner.spawn(crawler_path, spawner.global_position, get_tree().current_scene)

func _on_lazik_boss_dead() -> void:
	MusicManager.stop_music()
	boss_defeated = true
	camera.target = boss
	spawn_crawler_timer.stop()
	var tween = get_tree().create_tween()
	tween.tween_property(camera, "zoom", Vector2(1.5, 1.5),4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await get_tree().create_timer(4.0).timeout
	camera.target = $CamZone
	await get_tree().create_timer(1.0).timeout
	GameManager.do_camera_shake(8.0, 1)
	wall.queue_free()
	wall_2.visible = true
	await get_tree().create_timer(1.0).timeout
	camera.target = get_tree().get_first_node_in_group("Player")
