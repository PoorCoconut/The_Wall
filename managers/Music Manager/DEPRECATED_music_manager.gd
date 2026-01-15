extends Node
##DEPRECATED
@export var current_track : MusicTrack
@onready var mplayer: AudioStreamPlayer = $MusicController

const SILENT_DB := -80.0
const FULL_DB := 0.0

enum MusicMode {
	CALM,
	REGULAR,
	THREAT_MED,
	THREAT_HIGH
}

func play_track(track: MusicTrack):
	current_track = track
	mplayer.stream = track.stream
	mplayer.play()

func set_music_mode(mode : MusicMode):
	var sync := mplayer.stream as AudioStreamSynchronized
	
	for i in range(sync.get_stream_count()):
		sync. set_strem_volume_db(i, -80.0)
	
	for i in current_track.layer_map.get(mode, []):
		sync.set_stream_volume_db(i, 0.0)

func fade_layer(sync:AudioStreamSynchronized, layer:int, target_db: float, time := 1.0):
	var tween := create_tween()
	tween.tween_method(
		func(db): sync.set_stream_volume_db(layer, db),
		sync.get_stream_volume_db(layer),
		target_db,
		time
	)
