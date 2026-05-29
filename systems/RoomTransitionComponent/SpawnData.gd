extends Node
## SpawnData — Autoload singleton
## Ferries spawn info across scene loads.
## Add to Project > Autoloads as "SpawnData".

var _pending_target_id: String = ""
var _pending_entry_direction: Vector2 = Vector2.ZERO
var _has_pending: bool = false


func set_spawn(target_id: String, entry_direction: Vector2) -> void:
	_pending_target_id = target_id
	_pending_entry_direction = entry_direction
	_has_pending = true


func consume_spawn() -> Dictionary:
	## Returns { target_id, entry_direction } or empty dict if nothing pending.
	if not _has_pending:
		return {}
	var data := {
		"target_id": _pending_target_id,
		"entry_direction": _pending_entry_direction,
	}
	_pending_target_id = ""
	_pending_entry_direction = Vector2.ZERO
	_has_pending = false
	return data


func clear() -> void:
	_pending_target_id = ""
	_pending_entry_direction = Vector2.ZERO
	_has_pending = false
