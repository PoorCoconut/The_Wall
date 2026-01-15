extends CharacterBody2D
@export var STATS : Stats_Component
@export var particle_path_gore : PackedScene
@export var particle_path_explosion : PackedScene
@export var sound_bank_path : PackedScene 
@onready var looker : Marker2D = %LookerNode
@onready var sprite: AnimatedSprite2D = $Sprite2D

var knockback : Vector2 = Vector2.ZERO
var knockback_timer : float = 0.0
var target : CharacterBody2D 
var following : bool = false
var stunned : bool = false
@onready var camera = get_tree().get_first_node_in_group("Camera")

func _ready() -> void:
	%HealthBar.max_value = STATS.MAX_HP
	%HealthBar.value = STATS.CUR_HP

func _physics_process(delta: float) -> void:
	if knockback_timer > 0.0:
		velocity = knockback
		knockback_timer -= delta
		if knockback_timer <= 0.0:
			knockback = Vector2.ZERO
			stunned = true
			
	else:
		if !stunned:
			if target:
				%LookerNode.look_at(target.global_position)
			if following and target:
				velocity = Vector2(STATS.MAX_SPEED,0).rotated(looker.rotation)
			else:
				velocity = velocity.move_toward(Vector2.ZERO, STATS.FRICTION)
	
	if stunned:
		velocity = velocity.move_toward(Vector2.ZERO, STATS.FRICTION)
	move_and_slide()

func get_damage():
	return STATS.MELEE_DMG

func take_damage(damage : int):
	print(name + " took ", damage,  " damage!")
	update_hp(damage)
	
	#Blink effect
	var tween = get_tree().create_tween()
	tween.tween_method(SetShader_BlinkIntensity, 1.0, 0.0, 0.5)
	
	if following:
		%StunTimer.start()
		following = false
	play_hit_sound()

func SetShader_BlinkIntensity(newValue:float):
	sprite.material.set_shader_parameter("blink_intensity", newValue)

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
	var camera_tween = get_tree().create_tween()
	camera_tween.tween_method(camera.startCameraShake, 10.0, 1.0, 0.5)
	
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

func apply_knockback(direction: Vector2, force: float, knockback_duration: float)->void:
	knockback = direction * force
	knockback_timer = knockback_duration

func _on_attack_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target = body
		following = true

func _on_attack_range_body_exited(body: Node2D) -> void:
	print("body exited!")
	if body.is_in_group("Player"):
		target = null
		following = false

func _on_stun_timer_timeout() -> void:
	following = true
	stunned = false
