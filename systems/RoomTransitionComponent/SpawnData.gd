extends Node
## SpawnData — Autoload singleton
## Ferries spawn info across scene loads.
## Add to Project > Autoloads as "SpawnData".

var _pending_target_id: String    = ""
var _pending_dominant_axis: String = ""  # "x" or "y"
var _pending_perp_offset: float   = 0.0  # player's lane offset on the non-travel axis
var _pending_push_sign: float     = 0.0  # +1 or -1, which side to exit the dest RTC
var _has_pending: bool            = false


func set_spawn(
		target_id: String,
		dominant_axis: String,
		perp_offset: float,
		push_sign: float) -> void:
	_pending_target_id     = target_id
	_pending_dominant_axis = dominant_axis
	_pending_perp_offset   = perp_offset
	_pending_push_sign     = push_sign
	_has_pending           = true


func consume_spawn() -> Dictionary:
	if not _has_pending:
		return {}
	var data := {
		"target_id"    : _pending_target_id,
		"dominant_axis": _pending_dominant_axis,
		"perp_offset"  : _pending_perp_offset,
		"push_sign"    : _pending_push_sign,
	}
	clear()
	return data


func clear() -> void:
	_pending_target_id     = ""
	_pending_dominant_axis = ""
	_pending_perp_offset   = 0.0
	_pending_push_sign     = 0.0
	_has_pending           = false
