extends Node
class_name StateMachine

@export var initial_state : State;
var STATES : Dictionary = {};
var current_state;

func _ready() -> void:
	for child in get_children():
		if child is State:
			STATES[child.name.to_lower()] = child;
			child.transition.connect(change_state)
	
	if initial_state:
		initial_state.enter();
		current_state = initial_state;

func change_state(old_state:State, new_state_name:String):
	#print("Old state: " + old_state.name)
	#print("Current state: " + current_state.name)
	if old_state != current_state:
		print("Invalid change_state, trying from: " + old_state.name + " but currently in: " + current_state.name);
		return
	
	var new_state = STATES.get(new_state_name.to_lower())
	if !new_state:
		print("New state is empty");
		return
	
	if current_state:
		current_state.exit();
	
	new_state.enter();
	current_state = new_state;

#This is quite dangerous and unstable ... Call using force_change_state("name")
func force_change_state(new_state : String):
	var newState = STATES.get(new_state.to_lower())
	
	if !new_state:
		print("New state is empty");
		return
	
	if current_state == newState:
		print("State is same, aborting")
		return
	
	if current_state:
		var exit_callable = Callable(current_state, "exit")
		exit_callable.call_deferred()
	
	newState.enter()
	current_state = newState

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta);
