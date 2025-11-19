extends CanvasLayer

##Player Debugs
var plast_dir : Vector2
var plast_dir_x : float
var plast_dir_y : float
var plast_dir_last : Vector2
var plast_dir_text : String
var pcur_dir : Vector2
var pvelocity : Vector2
var top_pvelocity : Vector2 = Vector2.ZERO
var pcur_state : String
var pchain : int

func _ready() -> void:
	#visible = false #Enable me to hide DEBUG MENU when READYING
	pass

func _process(_delta: float) -> void:
	if pvelocity >= top_pvelocity:
		top_pvelocity = pvelocity
	plast_dir_last = Vector2(plast_dir_x, plast_dir_y)
	
	if(Input.is_action_just_pressed("debug")):
		visible = !visible
	
	##Player Debug
	player_lastdir_string()
	%last_dir.text = "Last Dir:" + str(plast_dir) + " " + plast_dir_text
	%unq_last_dir.text = "Uniq last Dir: " + str(plast_dir_last)
	%cur_dir.text = "Cur Dir:" + str(pcur_dir)
	%velocity.text = "V:" + str(pvelocity)
	%top_v.text = "Top V:" + str(top_pvelocity)
	%cur_state.text = "Mov State: " + pcur_state
	%dash_chain.text = "Chains: " + str(pchain)

func player_lastdir_string():
	if plast_dir == Vector2(1,0):
		plast_dir_text = "Right"
	elif plast_dir == Vector2(-1,0):
		plast_dir_text = "Left"
	elif plast_dir == Vector2(0,-1):
		plast_dir_text = "Up"
	elif plast_dir == Vector2(0,1):
		plast_dir_text = "Down"
