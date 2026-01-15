extends Camera2D

@export var target : CharacterBody2D
@export var following : bool = true

var cameraShakeNoise : FastNoiseLite

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	following = true
	global_position = target.global_position
	
	cameraShakeNoise = FastNoiseLite.new()

func _process(_delta: float) -> void:
	
	
	if following:
		follow_target()

func _physics_process(_delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	self.offset.x = (mouse_pos.x - global_position.x) / (160.0/2.0)
	self.offset.y = (mouse_pos.y - global_position.y) / (90.0/2.0)

func follow_target():
	if target:
		global_position = target.global_position

func startCameraShake(intensity:float):
	var cameraOffset = cameraShakeNoise.get_noise_1d(Time.get_ticks_msec()) * intensity
	self.offset.x = cameraOffset
	self.offset.y = cameraOffset
