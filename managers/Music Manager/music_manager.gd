extends Node

const MIN_VOL_DB = -60.0 # Effectively silent
const MAX_VOL_DB = 0.0   # Full volume
const FADE_TIME = 1.5    # How long the crossfade takes

# Your Layer Definitions
var FOREST_CALM := [0, 1]
var FOREST_REG := [2, 3, 4, 5, 6]
var FOREST_THREAT_MED := [7, 8]
var FOREST_THREAT_HIGH := [9, 10]

func _ready():
	# 1. Connect to the GameManager's signal
	GameManager.threat_level_changed.connect(_on_threat_changed)
	
	# Initial call to set music correctly when the game starts
	_on_update_music_state()

# 2. This is the receiver function
func _on_threat_changed(new_level: int):
	# When the threat changes, we just run the update logic again
	_on_update_music_state()

func _on_update_music_state():
	var current_location_name = GameManager.LOCATION.keys()[GameManager.current_location].to_lower()
	
	for child in get_children():
		if child is AudioStreamPlayer and child.name.to_lower() == current_location_name:
			
			# 1. Ensure the player itself is playing and audible
			if not child.is_playing():
				child.volume_db = MAX_VOL_DB # Set master vol to max, we control layers now
				child.play()
			
			# 2. Determine which layers *should* be active based on threat
			var target_active_indices: Array = []
			
			# Additive Logic: Higher threats include lower threat layers
			if GameManager.threat_level >= 0:
				target_active_indices.append_array(FOREST_CALM)
			
			if GameManager.threat_level >= 1:
				target_active_indices.append_array(FOREST_REG)
				
			if GameManager.threat_level >= 3:
				target_active_indices.append_array(FOREST_THREAT_MED)
				
			if GameManager.threat_level >= 5:
				target_active_indices.append_array(FOREST_THREAT_HIGH)

			# 3. Update the layers
			update_stream_layers(child, target_active_indices)
			
		else:
			# Optional: Fade out players that aren't for the current location
			if child is AudioStreamPlayer and child.is_playing():
				fade_out_player(child)

# This function iterates through EVERY layer in the stream
# If the layer is in our "active" list, fade it IN. If not, fade it OUT.
func update_stream_layers(player: AudioStreamPlayer, active_indices: Array):
	var stream = player.stream as AudioStreamSynchronized
	if not stream:
		push_error("Music player does not have an AudioStreamSynchronized resource!")
		return

	var stream_count = stream.stream_count
	
	for i in range(stream_count):
		var target_vol = MIN_VOL_DB
		
		# If this index is in our list of active layers, set target to MAX
		if i in active_indices:
			target_vol = MAX_VOL_DB
			
		# Perform the fade for this specific layer index
		fade_layer(stream, i, target_vol)

# Helper to tween a specific layer index
func fade_layer(stream: AudioStreamSynchronized, layer_index: int, target_vol: float):
	var current_vol = stream.get_sync_stream_volume(layer_index)
	
	# Optimization: Don't tween if we are already roughly at the target volume
	if abs(current_vol - target_vol) < 0.1:
		return

	var tween = get_tree().create_tween()
	
	# We use tween_method because set_sync_stream_volume is a function, not a property
	tween.tween_method(
		func(vol): stream.set_sync_stream_volume(layer_index, vol),
		current_vol,
		target_vol,
		FADE_TIME
	)

# Your original player fade out (renamed for clarity)
func fade_out_player(mplayer: AudioStreamPlayer):
	var tween = get_tree().create_tween()
	tween.tween_property(mplayer, "volume_db", MIN_VOL_DB, 0.5)
	tween.tween_callback(mplayer.stop) # Stop after fading out


#const MIN_VOL : float = -60.0
#const MAX_VOL : float = 0.0
#
##These are the indices of the tracks for the different layers of a track
###FOREST
#var FOREST_CALM := [0, 1]
#var FOREST_REG := [2, 3, 4, 5, 6]
#var FOREST_THREAT_MED := [7, 8]
#var FPREST_THREAT_HIGH := [9, 10]
#
#func _ready() -> void:
	#pass
#
#func play_music():
	#for child in get_children():
		#if child.name.to_lower() == GameManager.LOCATION.keys()[GameManager.current_location].to_lower():
			#print("THIS WORKS!")
			#fade_in(child)
			#for stream in child.get_stream_count():
				#if GameManager.threat_level >= 0:
					#pass
				#elif GameManager.threat_level >= 1:
					#pass
				#elif GameManager.threat_level >= 3:
					#pass
				#elif GameManager.threat_level >= 5:
					#pass
		#else:
			#print(child.name.to_lower() ," does not equal to ", GameManager.current_location.name.to_lower())
#
#func fade_in(mplayer : AudioStreamPlayer):
	#if mplayer.is_playing():
		#return
	#
	#var tween = get_tree().create_tween()
	#tween.tween_property(mplayer, "volume_db", MAX_VOL, 0.5)
	#mplayer.play()
#
#func fade_out(mplayer : AudioStreamPlayer):
	#var tween = get_tree().create_tween()
	#tween.tween_property(mplayer, "volume_db", MIN_VOL, 0.5)
	#mplayer.play()
#
#func _process(delta: float) -> void:
	#pass
