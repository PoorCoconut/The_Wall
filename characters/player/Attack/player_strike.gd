extends Area2D

@onready var Sprite : AnimatedSprite2D = $AttackSprite
@onready var Collision : CollisionShape2D = $Collision
@export var radius : int = 25
@onready var player : CharacterBody2D = get_parent()

func _process(delta: float) -> void:
	Sprite.look_at(get_global_mouse_position())
	var mouse_pos = get_global_mouse_position()
	var player_pos = player.transform.origin 
	var mouse_dir = (mouse_pos-player_pos).normalized()
	self.transform.origin = (mouse_dir * radius)

func attack():
	Sprite.play()
	$Collision.disabled = false

func _on_attack_sprite_animation_finished() -> void:
	$Collision.disabled = true
