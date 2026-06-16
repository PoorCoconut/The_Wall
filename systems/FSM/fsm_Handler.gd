extends Node
class_name StateMachine

@export var initial_state : State

var STATES          : Dictionary = {}
var current_state   : State

func _ready() -> void:
	# Collect all State children and wire their transition signal
	for child in get_children():
		if child is State:
			STATES[child.name.to_lower()] = child
			child.transition.connect(change_state)

			# If this is an enemy state, inject the EnemyBase reference automatically.
			# The StateMachine is expected to be a child of EnemyBase (or its subclass).
			if child is EnemyState:
				var parent = get_parent()
				if parent is EnemyBase:
					child.enemy = parent

	if initial_state:
		initial_state.enter()
		current_state = initial_state

func change_state(old_state: State, new_state_name: String) -> void:
	if old_state != current_state:
		push_warning("StateMachine: invalid transition from '%s' (current is '%s')" \
			% [old_state.name, current_state.name])
		return

	var new_state : State = STATES.get(new_state_name.to_lower())
	if not new_state:
		push_warning("StateMachine: state '%s' not found." % new_state_name)
		return

	current_state.exit()
	new_state.enter()
	current_state = new_state

## Force a transition regardless of which state is current.
## Use sparingly (e.g., hit-stun interrupts from EnemyBase).
func force_change_state(new_state_name: String) -> void:
	var new_state : State = STATES.get(new_state_name.to_lower())
	if not new_state:
		push_warning("StateMachine: force target '%s' not found." % new_state_name)
		return

	if current_state == new_state:
		return   # already there, nothing to do

	if current_state:
		# Deferred exit so we don't disrupt the current physics frame
		Callable(current_state, "exit").call_deferred()

	new_state.enter()
	current_state = new_state

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)
