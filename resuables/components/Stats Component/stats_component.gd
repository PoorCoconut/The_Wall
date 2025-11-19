extends Node
class_name Stats_Component

@export_category("Base Stats")
@export var MAX_HP : int
@export var CUR_HP : int
@export var BULLETS : int
##The amount of knockback this entity gives
@export var KNOCKBACK : float
##The greater the weight, the lesser the knockback received
@export var WEIGHT : float

@export_category("Damage Stats")
@export var MELEE_DMG : int
@export var RANGE_DMG : int
@export var CHARGE_DMG : int
@export var CONTACT_DMG : int

@export_category("Movement Stats")
@export var MAX_SPEED : int
@export var FRICTION : int
@export var ACCELERATION : int

@export_category("Specials")
@export var dash : bool = false
@export var glow : bool = false
@export var strike : bool = false

@export_category("Special Stats")
@export var DASH_DIST : int
@export var DASH_ACCEL : int
@export var DASH_FRICTION : int
##The radius of GLOW
@export var LIGHT_AURA : int
