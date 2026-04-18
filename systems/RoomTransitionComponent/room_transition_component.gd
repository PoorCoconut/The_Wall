extends Area2D
class_name RoomTransition

@export_file("*.tscn") var next_scene_path : String
@export var door_id : String = "" ##This door's name
@export var destination_door_id : String = "" ##The door it connects to

@onready var spawn_point : Marker2D = $SpawnPoint

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if GameManager.target_door_id == door_id:
		#Waits for the scene tree to finish loading (call deferred) then teleports the player
		_teleport_player.call_deferred()

func _teleport_player() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		GameManager.teleport_player(spawn_point.global_position)
		GameManager.target_door_id = ""

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		GameManager.target_door_id = destination_door_id
		GameManager.load_next_level(next_scene_path)
