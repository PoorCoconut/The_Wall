extends State
class_name EnemyState

## Base class for all enemy FSM states.
## Gives every state a typed reference to the enemy that owns it,
## so states can read flags, call helpers, and request transitions
## without casting or searching the tree.
##
## HOW TO USE:
##   1. Create a new script that extends EnemyState.
##   2. In the enemy scene, add your State nodes as children of the StateMachine node.
##   3. The StateMachine will call enter() / update(delta) / exit() automatically.
##
## EXAMPLE:
##   extends EnemyState
##   func enter():
##       enemy.look_at_target(enemy.target.global_position)
##   func update(delta):
##       enemy.move_toward_point(enemy.target.global_position, delta)
##       if enemy.target_in_attack_range:
##           transition.emit(self, "Attack")

# Set automatically by EnemyBase after the FSM is ready.
# You should never need to set this manually.
var enemy : EnemyBase

# ─────────────────────────────────────────────────────────────────
# HELPERS  (thin wrappers so state scripts stay readable)
# ─────────────────────────────────────────────────────────────────

## Emit the transition signal in one line.
## Usage: go_to("Chase")
func go_to(state_name: String) -> void:
	transition.emit(self, state_name)

## True when enemy has a live target.
func has_target() -> bool:
	return enemy != null and enemy.target != null

## Distance to target, or INF.
func dist() -> float:
	return enemy.distance_to_target() if enemy else INF
