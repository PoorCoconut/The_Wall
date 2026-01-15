extends CanvasLayer
class_name PlayerHUD
#Don't Forget about the BULLET BAR [Bullets are already stored in STATS]

func update_health_visual(MAX_HP : int, CUR_HP : int):
	%HP_Bar.max_value = MAX_HP
	%HP_Bar.value = CUR_HP

func update_bullets_visual(MAX_BULLETS : int, CUR_BULLETS : int):
	%Bullet_Bar.max_value = MAX_BULLETS
	%Bullet_Bar.value = CUR_BULLETS
