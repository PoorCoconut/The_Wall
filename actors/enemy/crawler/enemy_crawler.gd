extends Enemy
class_name enemyCrawler

var target = null
var detected : bool = false
var target_pos : Vector2
@onready var STATS : Stats_Component = %Stats_Component
@export var FSM : StateMachine
var enem_knockback : float

func _ready() -> void:
	%HPbar.max_value = STATS.MAX_HP

func _process(delta: float) -> void:
	%HPbar.value = STATS.CUR_HP

func _on_detection_range_body_entered(body: Node2D) -> void:
	target = body
	detected = true

func _on_detection_range_body_exited(body: Node2D) -> void:
	if target == body:
		target = null

func _on_hit_box_area_entered(area: Area2D) -> void:
	pass

func got_hit(damage:int, knockback:float): #Forces a STATE CHANGE
	print("Player got hit for ", damage, " damage and ", knockback, " knockback strength")
	enem_knockback = knockback
	STATS.CUR_HP = clamp(STATS.CUR_HP - damage, 0, STATS.MAX_HP)
	%HP_BAR.value = STATS.CUR_HP
	%HurtBox.set_deferred("monitorable", false)
	%IFrame.start()
	FSM.force_change_state("Hurt")

func _on_attack_range_area_entered(area: Area2D) -> void: ##WHEN DEATH OCCURS, EXPLODE AND DEAL DAMAGE TO ALL
	deal_damage.emit(STATS.CONTACT_DMG, STATS.KNOCKBACK)
	GameManager.enemyhitpos = self.global_position
