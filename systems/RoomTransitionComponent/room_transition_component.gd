@tool
class_name RoomTransitionComponent
extends Area2D
## RoomTransitionComponent (RTC)
## ─────────────────────────────────────────────────────────────────
## Drop into any scene. Wire RTCs together using my_id / target_id.
##
## Scene tree structure:
##   RoomTransitionComponent   ← this script (Area2D)
##     └── CollisionShape2D    ← defines the trigger zone
##
## Autoload required:
##   res://spawn_data.gd  →  registered as "SpawnData"
##
## Player setup — call once in your player's _ready():
##   RoomTransitionComponent.apply_spawn_to_player(self)
##
## ── ID system ────────────────────────────────────────────────────
##   my_id      — this RTC's unique name within its scene
##   target_id  — the my_id of the RTC to spawn at in the next room
##
##   Room 1 RTC:  my_id = "cave_left"    target_id = "cave_right"
##   Room 2 RTC:  my_id = "cave_right"   target_id = "cave_left"
##
## ── Same-scene transitions ────────────────────────────────────────
##   Leave next_room empty (or set it to the current scene's path).
##   Skips GameManager entirely and teleports the player directly.
## ─────────────────────────────────────────────────────────────────

## This RTC's unique identifier within its scene.
@export var my_id: String = ""

## The my_id of the RTC to spawn at in the destination scene.
## Leave empty to disable this RTC (it won't trigger any transition).
@export var target_id: String = ""

## Scene to transition to. Leave empty for a same-scene teleport.
@export_file("*.tscn") var next_room: String = ""

## Extra pixels pushed beyond the RTC's edge on arrival.
## Raise this if the player re-triggers the zone on spawn.
@export var spawn_padding: float = 24.0

## Group your player node belongs to.
@export var player_group: String = "Player"

## Prevents re-entry immediately after a transition fires.
@export var use_cooldown: bool = true
@export var cooldown_duration: float = 0.5

var _on_cooldown: bool = false
var _cooldown_timer: float = 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)
	if get_child_count() == 0:
		push_warning("RTC '%s': no CollisionShape2D child found." % name)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _on_cooldown:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0.0:
			_on_cooldown = false


# ── Entry ─────────────────────────────────────────────────────────

func _on_body_entered(body: Node2D) -> void:
	if _on_cooldown:
		return
	if not body.is_in_group(player_group):
		return
	if target_id.is_empty():
		return
	if my_id.is_empty():
		push_warning("RTC '%s': my_id is not set. Return transitions won't work." % name)
	_trigger_transition(body)


func _trigger_transition(player: Node2D) -> void:
	## Capture spawn data BEFORE the scene unloads.
	## We store:
	##   dominant_axis — "x" or "y", whichever the player crossed
	##   perp_offset   — the player's offset along the OTHER axis,
	##                   relative to this RTC's center.
	##                   The destination RTC applies the same offset
	##                   relative to its own center, preserving the
	##                   player's lane (hallway position).
	##   push_sign     — +1 or -1, which side to push out of the dest RTC

	var diff := global_position - player.global_position
	var dominant_axis: String
	var perp_offset: float
	var push_sign: float

	if abs(diff.x) >= abs(diff.y):
		# Player crossed a left/right boundary
		dominant_axis = "x"
		push_sign     = sign(diff.x)          # push away from dest RTC on X
		perp_offset   = player.global_position.y - global_position.y  # preserve Y lane
	else:
		# Player crossed a top/bottom boundary
		dominant_axis = "y"
		push_sign     = sign(diff.y)          # push away from dest RTC on Y
		perp_offset   = player.global_position.x - global_position.x  # preserve X lane

	var current_scene_path: String = get_tree().current_scene.scene_file_path
	var is_same_scene := next_room.is_empty() or next_room == current_scene_path

	if is_same_scene:
		_teleport_same_scene(player, dominant_axis, perp_offset, push_sign)
		return

	SpawnData.set_spawn(target_id, dominant_axis, perp_offset, push_sign)
	if use_cooldown:
		_start_cooldown()
	GameManager.load_next_level(next_room)


func _teleport_same_scene(
		player: Node2D,
		dominant_axis: String,
		perp_offset: float,
		push_sign: float) -> void:

	var target := _find_rtc_by_id(get_tree().root, target_id)
	if target == null:
		push_warning(
			"RTC '%s': same-scene teleport failed — no RTC with my_id '%s' found."
			% [name, target_id]
		)
		return

	_place_player(player, target, dominant_axis, perp_offset, push_sign)
	target._start_cooldown()
	if use_cooldown:
		_start_cooldown()


func _start_cooldown() -> void:
	_on_cooldown = true
	_cooldown_timer = cooldown_duration


# ── Static helpers ────────────────────────────────────────────────

static func apply_spawn_to_player(player: Node2D) -> void:
	## Call from your player's _ready():
	##     RoomTransitionComponent.apply_spawn_to_player(self)
	var spawn := SpawnData.consume_spawn()
	if spawn.is_empty():
		return

	var tid: String           = spawn["target_id"]
	var dominant_axis: String = spawn["dominant_axis"]
	var perp_offset: float    = spawn["perp_offset"]
	var push_sign: float      = spawn["push_sign"]

	var target := _find_rtc_by_id(player.get_tree().root, tid)
	if target == null:
		push_warning(
			"apply_spawn_to_player: No RTC with my_id '%s' found. Player position unchanged." % tid
		)
		return

	_place_player(player, target, dominant_axis, perp_offset, push_sign)
	target._start_cooldown()


static func _place_player(
		player: Node2D,
		target: RoomTransitionComponent,
		dominant_axis: String,
		perp_offset: float,
		push_sign: float) -> void:
	## Places the player just outside the target RTC along the dominant axis,
	## while preserving their exact lane offset on the perpendicular axis.
	##
	## dominant_axis — "x" or "y" — the axis the player was travelling along
	## perp_offset   — player's offset from the ORIGIN RTC center on the other axis
	##                 applied identically relative to the DEST RTC center
	## push_sign     — direction to push out of the dest RTC (+1 / -1)

	var extent := _get_rtc_half_extent(target, dominant_axis)
	var push_dist := extent + target.spawn_padding
	var pos := target.global_position

	if dominant_axis == "x":
		pos.x += push_sign * push_dist
		pos.y  = target.global_position.y + perp_offset   # preserve Y lane
	else:
		pos.y += push_sign * push_dist
		pos.x  = target.global_position.x + perp_offset   # preserve X lane

	player.global_position = pos

	## Depenetration pass — nudges the player out of any wall they may have
	## landed inside due to irregular collision geometry.
	## CharacterBody2D.move_and_collide(Vector2.ZERO) asks the physics engine
	## to resolve any existing overlap without actually moving the body,
	## which safely pushes the player clear of walls in one frame.
	if player is CharacterBody2D:
		player.move_and_collide(Vector2.ZERO)


static func _find_rtc_by_id(root: Node, id: String) -> RoomTransitionComponent:
	for child in root.get_children():
		if child is RoomTransitionComponent and child.my_id == id:
			return child
		var found := _find_rtc_by_id(child, id)
		if found:
			return found
	return null


static func _get_rtc_half_extent(rtc: RoomTransitionComponent, axis: String) -> float:
	## Returns the half-extent along the dominant axis only.
	## For a vertical crossing (axis = "y") we want the RTC's half-height.
	## For a horizontal crossing (axis = "x") we want the RTC's half-width.
	## Falls back to 32px if shape is missing or unrecognised.
	for child in rtc.get_children():
		if child is CollisionShape2D and child.shape != null:
			var shape: Shape2D = child.shape
			if shape is RectangleShape2D:
				if axis == "x":
					return shape.size.x * 0.5
				else:
					return shape.size.y * 0.5
			elif shape is CircleShape2D:
				return shape.radius
			elif shape is CapsuleShape2D:
				if axis == "x":
					return shape.radius
				else:
					return shape.height * 0.5
	return 32.0
