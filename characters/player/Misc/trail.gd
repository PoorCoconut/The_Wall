extends CPUParticles2D
#When switching to UP Dash sprites, use Offset Min = 0.2 and Offset Max = 0.4

@export var player_sprite : Sprite2D
var facing_up : bool = false
var facing_left : bool = false
var img = self.texture.get_image()
var img_safe = self.texture.get_image()
func enable_trail():
	self.emitting = true
	%TrailTimer.start()

func _physics_process(_delta: float) -> void:
	if facing_up:
		self.anim_offset_min = 0.2
		self.anim_offset_max = 0.4
		self.z_index = 1
	else:
		self.anim_offset_min = 0
		self.anim_offset_max = 0
		self.z_index = 0
	if facing_left:
		img.flip_x()
		self.texture = ImageTexture.create_from_image(img)
	else:
		self.texture = ImageTexture.create_from_image(img_safe)
	#print("Facing left:" + str(facing_left))
	#self.texture = player_sprite.texture

func _on_trail_timer_timeout() -> void:
	self.emitting = false
