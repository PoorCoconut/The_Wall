extends CanvasLayer

@onready var WhiteBar = %WhiteBarTexture
@onready var BarChaser = %BarChaserTexture

@onready var AmmoBar = %AmmoBar
@onready var AmmoBarChaser = %AmmoBarChaser

var bullet_block_path : PackedScene = preload("res://systems/HUD/bullet_block.tscn")

func _ready():
	# Listen for the signal and connect it to a local function
	Events.player_hp_updated.connect(_on_player_hp_updated)
	Events.player_ammo_updated.connect(_on_player_ammo_updated)

# This runs automatically whenever the Player emits the signal
func _on_player_hp_updated(current_hp: float, max_hp: float):
	WhiteBar.max_value = max_hp
	BarChaser.max_value = max_hp
	WhiteBar.value = current_hp
	
	var tween2 = get_tree().create_tween()
	tween2.tween_method(SetShader_BlinkIntensity, 1.0, 0.0, 0.5)
	
	#WhiteBar.modulate = Color.GREEN.lerp(Color.RED, 1.0 - ( current_hp / max_hp))
	var tween = create_tween()
	tween.tween_interval(0.4)
	tween.tween_property(BarChaser, "value", current_hp, 0.5).set_trans(Tween.TRANS_SINE)
	#if WhiteBar.value < 25:
		#var tween2 = create_tween()
		#tween2.tween_property($"HealthDisplay", "modulate:a", 0.5, 0.5)
	#else:
		#var tween3 = create_tween()
		#tween3.tween_property($"HealthDisplay", "modulate:a", 1, 0.5)

func _on_player_ammo_updated(current_bullets: float, max_bullets: float) -> void:
	# 1. Completely clear out both containers so we start fresh
	for child in %BulletContainer.get_children():
		child.queue_free()
	for child in %BulletBackContainer.get_children():
		child.queue_free()
		
	# 2. Rebuild the exact amount of bullets we need
	for i in int(max_bullets):
		# Instantiate and add the BLACK background bullet
		var back_bullet : TextureRect = bullet_block_path.instantiate()
		back_bullet.modulate = Color(0, 0, 0, 1) # Sets it to pure black
		%BulletBackContainer.add_child(back_bullet)
		
		# If this loop iteration is within our current ammo count, add a colored foreground bullet
		if i < int(current_bullets):
			var front_bullet : TextureRect = bullet_block_path.instantiate()
			%BulletContainer.add_child(front_bullet)
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

func SetShader_BlinkIntensity(newValue: float):
	%WhiteBarTexture.material.set_shader_parameter("blink_intensity", newValue)
	%BarChaserTexture.material.set_shader_parameter("blink_intensity", newValue)
