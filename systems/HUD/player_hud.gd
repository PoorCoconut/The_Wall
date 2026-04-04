extends CanvasLayer

@onready var WhiteBar = %WhiteBarTexture
@onready var BarChaser = %BarChaserTexture

@onready var AmmoBar = %AmmoBar
@onready var AmmoBarChaser = %AmmoBarChaser

func _ready():
	# Listen for the signal and connect it to a local function
	Events.player_hp_updated.connect(_on_player_hp_updated)
	Events.player_ammo_updated.connect(_on_player_ammo_updated)

# This runs automatically whenever the Player emits the signal
func _on_player_hp_updated(current_hp: float, max_hp: float):
	WhiteBar.max_value = max_hp
	BarChaser.max_value = max_hp
	WhiteBar.value = current_hp
	
	WhiteBar.modulate = Color.GREEN.lerp(Color.RED, 1.0 - ( current_hp / max_hp))
	var tween = create_tween()
	tween.tween_interval(0.4)
	tween.tween_property(BarChaser, "value", current_hp, 0.5).set_trans(Tween.TRANS_SINE)
	#if WhiteBar.value < 25:
		#var tween2 = create_tween()
		#tween2.tween_property($"HealthDisplay", "modulate:a", 0.5, 0.5)
	#else:
		#var tween3 = create_tween()
		#tween3.tween_property($"HealthDisplay", "modulate:a", 1, 0.5)

func _on_player_ammo_updated(current_bullets: float, max_bullets: float):
	AmmoBar.max_value = max_bullets
	AmmoBarChaser.max_value = max_bullets
	AmmoBar.value = current_bullets
	
	var tween = create_tween()
	tween.tween_interval(0.4)
	tween.tween_property(AmmoBarChaser, "value", current_bullets, 0.5).set_trans(Tween.TRANS_SINE)
	#if AmmoBar.value < 25:
		#var tween2 = create_tween()
		#tween2.tween_property($AmmoDisplay, "modulate:a", 0.5, 0.5)
	#else:
		#var tween3 = create_tween()
		#tween3.tween_property($AmmoDisplay, "modulate:a", 1, 0.5)
