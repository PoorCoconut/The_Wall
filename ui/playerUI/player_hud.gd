extends CanvasLayer
class_name PlayerHUD
#Don't Forget about the BULLET BAR [Bullets are already stored in STATS]
var STATS : Stats_Component
var HURT : State 
var MAX_HP : int
var CUR_HP : int

func _ready() -> void:
	#var player = get_tree().get_first_node_in_group("Player")
	#if player:
		#player.connect("got_hurt", Callable(self, "sig_got_hurt"))
	pass

func _process(_delta: float) -> void:
	update_visual()

func sig_got_hurt(MAX_HEALTH : int, CUR_HEALTH : int):
	update_visual()

func update_visual():
	#MAX_HP = STATS.MAX_HP
	#CUR_HP = STATS.CUR_HP
	%HP_Bar.max_value = MAX_HP
	%HP_Bar.value = CUR_HP
