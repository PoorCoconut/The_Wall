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
##   The component detects this, skips GameManager entirely, and
##   teleports the player to the matched RTC directly — useful for
##   non-Euclidean rooms, warp pads, portals, etc.
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

	# Silent no-op: target_id not configured — this RTC is inert.
	if target_id.is_empty():
		return

	# Warn loudly if my_id is missing — it won't break anything but
	# it means no RTC in the destination can find this one on return.
	if my_id.is_empty():
		push_warning("RTC '%s': my_id is not set. Return transitions won't work." % name)

	_trigger_transition(body)


func _trigger_transition(player: Node2D) -> void:
	var entry_dir := _detect_entry_direction(player)
	var current_scene_path: String = get_tree().current_scene.scene_file_path

	# ── Same-scene transition ──────────────────────────────────────
	# Fires when next_room is empty OR matches the current scene path.
	var is_same_scene := next_room.is_empty() or next_room == current_scene_path
	if is_same_scene:
		_teleport_same_scene(player, entry_dir)
		return

	# ── Cross-scene transition ─────────────────────────────────────
	SpawnData.set_spawn(target_id, entry_dir)
	if use_cooldown:
		_start_cooldown()
	GameManager.load_next_level(next_room)


func _teleport_same_scene(player: Node2D, entry_dir: Vector2) -> void:
	var target := _find_rtc_by_id(get_tree().root, target_id)
	if target == null:
		push_warning(
			"RTC '%s': same-scene teleport failed — no RTC with my_id '%s' found in scene."
			% [name, target_id]
		)
		return

	var extent := _get_rtc_half_extent(target)
	player.global_position = target.global_position + entry_dir * (extent + target.spawn_padding)

	# Give the target a cooldown so the player doesn't immediately bounce back.
	target._start_cooldown()
	if use_cooldown:
		_start_cooldown()


func _start_cooldown() -> void:
	_on_cooldown = true
	_cooldown_timer = cooldown_duration


func _detect_entry_direction(player: Node2D) -> Vector2:
	## Returns a unit vector FROM this RTC TOWARD the player (their approach side).
	## The destination RTC uses this to push the player to the opposite face.
	var diff := global_position - player.global_position
	if diff.is_zero_approx():
		return global_transform.x.normalized()
	return diff.normalized()


# ── Static helpers (called from player _ready) ────────────────────

static func apply_spawn_to_player(player: Node2D) -> void:
	## Call this from your player script's _ready() in every scene:
	##     RoomTransitionComponent.apply_spawn_to_player(self)
	##
	## Reads SpawnData, locates the target RTC, and repositions the player.
	## If no spawn is pending (normal scene start) this is a complete no-op.

	var spawn := SpawnData.consume_spawn()
	if spawn.is_empty():
		return

	var tid: String = spawn["target_id"]
	var entry_dir: Vector2 = spawn["entry_direction"]

	var target := _find_rtc_by_id(player.get_tree().root, tid)
	if target == null:
		push_warning(
			"apply_spawn_to_player: No RTC with my_id '%s' found in this scene. "
			% tid
			+ "Player position unchanged. Check that my_id is set correctly on the destination RTC."
		)
		# Don't move the player — leave them at their scene-default position.
		# SpawnData was already consumed so this won't loop.
		return

	var extent := _get_rtc_half_extent(target)
	player.global_position = target.global_position + entry_dir * (extent + target.spawn_padding)

	# Cooldown the destination RTC so the player doesn't instantly re-trigger it.
	target._start_cooldown()


static func _find_rtc_by_id(root: Node, id: String) -> RoomTransitionComponent:
	## Depth-first search for an RTC whose my_id matches.
	for child in root.get_children():
		if child is RoomTransitionComponent and child.my_id == id:
			return child
		var found := _find_rtc_by_id(child, id)
		if found:
			return found
	return null


static func _get_rtc_half_extent(rtc: RoomTransitionComponent) -> float:
	## Reads the CollisionShape2D to get the RTC's approximate half-size.
	## Falls back to 32px if the shape is unrecognised or missing.
	for child in rtc.get_children():
		if child is CollisionShape2D and child.shape != null:
			var shape : Shape2D = child.shape
			if shape is RectangleShape2D:
				return minf(shape.size.x, shape.size.y) * 0.5
			elif shape is CircleShape2D:
				return shape.radius
			elif shape is CapsuleShape2D:
				return shape.radius
	return 32.0
