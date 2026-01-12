extends CanvasLayer
class_name PlayerHUD
#Don't Forget about the BULLET BAR [Bullets are already stored in STATS]

func update_visual(MAX_HP : int, CUR_HP : int):
	%HP_Bar.max_value = MAX_HP
	%HP_Bar.value = CUR_HP
