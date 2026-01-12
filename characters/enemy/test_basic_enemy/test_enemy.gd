extends CharacterBody2D
@export var STATS : Stats_Component
@export var particle_path_gore : PackedScene
@export var particle_path_explosion : PackedScene
@export var sound_bank_path : PackedScene 

func _ready() -> void:
	%HealthBar.max_value = STATS.MAX_HP
	%HealthBar.value = STATS.CUR_HP

func get_damage():
	return STATS.MELEE_DMG

func take_damage(damage : int):
	print(name + " took ", damage,  " damage!")
	update_hp(damage)
	play_hit_sound()

func update_hp(damage : int):
	STATS.CUR_HP -= damage
	%HealthBar.value = STATS.CUR_HP
	if STATS.CUR_HP <= 0:
		death()

func play_hit_sound() -> void:
	var sound_bank = sound_bank_path.instantiate()
	get_tree().root.add_child(sound_bank)
	if randi_range(1, 2) == 1:
		sound_bank.play("hit_metal1")
	else:
		sound_bank.play("hit_metal2")

func death():
	var particle_gore = particle_path_gore.instantiate()
	var particle_explosion = particle_path_explosion.instantiate()
	particle_gore.global_position = global_position
	particle_explosion.global_position = global_position
	get_tree().root.add_child(particle_gore)
	get_tree().root.add_child(particle_explosion)
	
	#var sound_bank = sound_bank_path.instantiate()
	#get_tree().root.add_child(sound_bank)
	#sound_bank.play("explosion")
	queue_free()
