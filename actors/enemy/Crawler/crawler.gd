extends EnemyBase
class_name Crawler

# ─────────────────────────────────────────────────────────────────
# CRAWLER-SPECIFIC EXPORTS
# ─────────────────────────────────────────────────────────────────
@export_category("Crawler Effects")
## Gore splatter on death
@export var particle_path_gore      : PackedScene
## Explosion flash on death
@export var particle_path_explosion : PackedScene

# ─────────────────────────────────────────────────────────────────
# SOUNDS
# ─────────────────────────────────────────────────────────────────
# Hit sounds are chosen randomly in play_hit_sound().
# Add more entries to the array to expand the pool.
const HIT_SOUNDS   : Array[String] = ["hit_metal1", "hit_metal2"]
const DEATH_SOUND  : String        = "kill_enemy1"

# ─────────────────────────────────────────────────────────────────
# VIRTUAL OVERRIDES
# ─────────────────────────────────────────────────────────────────

func _enemy_ready() -> void:
	# The AttackRange area sets enemy.target, which the Chase state reads.
	# Nothing extra needed here — EnemyBase._connect_signals() already wired
	# the Hurtbox. AttackRange is wired via its own signals in the scene.
	pass

func _on_enemy_damaged(_new_hp: int, _max_hp: int) -> void:
	_play_hit_sound()

func _on_enemy_death() -> void:
	_play_death_sound()
	_spawn_death_particles()

# ─────────────────────────────────────────────────────────────────
# SCENE SIGNAL CALLBACKS
# (These are connected in the scene; keep them here so the scene
#  doesn't need to know about EnemyBase internals.)
# ─────────────────────────────────────────────────────────────────

func _on_attack_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target = body   # EnemyBase.target — Chase state reads this

func _on_attack_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target = null

# ─────────────────────────────────────────────────────────────────
# PRIVATE – AUDIO & PARTICLES
# ─────────────────────────────────────────────────────────────────

func _play_hit_sound() -> void:
	SoundBank.play_sfx(HIT_SOUNDS[randi() % HIT_SOUNDS.size()], global_position)

func _play_death_sound() -> void:
	SoundBank.play_sfx(DEATH_SOUND, global_position)

func _spawn_death_particles() -> void:
	for scene in [particle_path_gore, particle_path_explosion]:
		if not scene:
			continue
		var p = scene.instantiate()
		p.global_position = global_position
		get_tree().root.add_child(p)
