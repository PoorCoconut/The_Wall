## dash_ghost.gd
extends Node2D

@export var fade_duration: float = 0.18
@export var tint_color: Color = Color(0.4, 0.8, 1.0, 0.7)

var _sprite: Sprite2D
var _elapsed: float = 0.0
var _source_global_transform: Transform2D


func setup(source: Sprite2D) -> void:
	_sprite = Sprite2D.new()
	add_child(_sprite)

	_sprite.texture  = source.texture
	_sprite.hframes  = source.hframes
	_sprite.vframes  = source.vframes
	_sprite.frame    = source.frame
	_sprite.flip_h   = source.flip_h
	_sprite.flip_v   = source.flip_v
	_sprite.centered = source.centered
	_sprite.transform = Transform2D.IDENTITY

	# Snapshot the transform NOW (before any deferred delay) so we
	# capture the correct world position even if the player moves.
	_source_global_transform = source.global_transform

	# Apply it deferred so the ghost is fully in the scene tree first —
	# this fixes the "spawns near 0,0 briefly" bug.
	call_deferred("_apply_transform")

	modulate = tint_color


func _apply_transform() -> void:
	global_transform = _source_global_transform


func _process(delta: float) -> void:
	_elapsed += delta
	var t: float = clampf(_elapsed / fade_duration, 0.0, 1.0)
	modulate.a = lerpf(tint_color.a, 0.0, t)

	if _elapsed >= fade_duration:
		queue_free()
