extends Node
## AudioManager — add as AutoLoad (Project Settings > Globals) named "AudioManager".
## Usage:
##   AudioManager.play_sfx("upgrade")
##   AudioManager.play_music("main_theme")
##   AudioManager.unlock_track("boss_theme")

# ---------- CONFIG ----------
# Point these at your actual files. Missing paths are skipped with a warning.
const SFX := {
	"overheat_sfx": "res://audio/sfx/overheat_sfx.mp3",
	"overheat_finished_sfx": "res://audio/sfx/overheat_finished_sfx.mp3",
	"level_up": "res://audio/sfx/level_up.mp3",
	"mining_item_received": "res://audio/sfx/mining_item_received.mp3",
	"parsing_item_received": "res://audio/sfx/parsing_item_received.mp3",
	"cracking_item_received": "res://audio/sfx/cracking_item_received.mp3",
	"matching_item_received": "res://audio/sfx/matching_item_received.mp3",
	"phishing_item_received": "res://audio/sfx/phishing_item_received.mp3",
	"compiling_item_received": "res://audio/sfx/compiling_item_received.mp3",
}

const MUSIC := {
	"main_theme": "res://audio/music/background_music_1.mp3",
}

# Tracks available from the start. Everything else needs unlock_track().
const DEFAULT_UNLOCKED: Array[String] = ["main_theme"]

const SFX_POOL_SIZE := 8          # how many SFX can overlap at once
const DEFAULT_FADE := 1.0         # seconds for music crossfade

# ---------- STATE ----------
var unlocked_tracks: Array[String] = []
var current_track: String = ""
var _sfx_active: Dictionary = {} 

const SFX_MIN_INTERVAL_MS := 50
var _last_played: Dictionary = {}  # name -> ticks msec

var _sfx_streams: Dictionary = {}
var _music_streams: Dictionary = {}
var _sfx_pool: Array[AudioStreamPlayer] = []
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active_music: AudioStreamPlayer
var _fade_tween: Tween

signal track_unlocked(track_name: String)
signal music_changed(track_name: String)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep music running while paused
	unlocked_tracks = DEFAULT_UNLOCKED.duplicate()
	_preload(SFX, _sfx_streams)
	_preload(MUSIC, _music_streams)

	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX" if _bus_exists("SFX") else "Master"
		add_child(p)
		_sfx_pool.append(p)

	_music_a = _make_music_player()
	_music_b = _make_music_player()
	_active_music = _music_a


func play_sfx(name: String, pitch_variation: float = 0.0, volume_db: float = 0.0) -> void:
	if not _sfx_streams.has(name):
		push_warning("AudioManager: unknown SFX '%s'" % name)
		return
	var now := Time.get_ticks_msec()
	if now - _last_played.get(name, -9999) < SFX_MIN_INTERVAL_MS:
		return
	_last_played[name] = now

	var player := _get_free_sfx_player()
	player.stream = _sfx_streams[name]
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.play()
	_sfx_active[name] = player


# Convenience wrappers
func upgrade() -> void:       play_sfx("upgrade", 0.05)
func item_received() -> void: play_sfx("item_received", 0.05)
func error() -> void:         play_sfx("error")


# ---------- MUSIC ----------
func play_music(name: String, fade: float = DEFAULT_FADE) -> void:
	if name == current_track:
		return
	if not _music_streams.has(name):
		push_warning("AudioManager: unknown track '%s'" % name)
		return
	if not is_track_unlocked(name):
		push_warning("AudioManager: track '%s' is locked" % name)
		return

	var next := _music_b if _active_music == _music_a else _music_a
	next.stream = _music_streams[name]
	next.volume_db = -80.0
	next.play()

	if _fade_tween: _fade_tween.kill()
	_fade_tween = create_tween().set_parallel(true)
	_fade_tween.tween_property(next, "volume_db", 0.0, fade)
	_fade_tween.tween_property(_active_music, "volume_db", -80.0, fade)
	_fade_tween.chain().tween_callback(_active_music.stop)

	_active_music = next
	current_track = name
	music_changed.emit(name)


func stop_music(fade: float = DEFAULT_FADE) -> void:
	if _fade_tween: _fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_active_music, "volume_db", -80.0, fade)
	_fade_tween.tween_callback(_active_music.stop)
	current_track = ""


func next_track() -> void:
	## Cycles through unlocked tracks — handy for a jukebox button.
	if unlocked_tracks.is_empty(): return
	var i := unlocked_tracks.find(current_track)
	play_music(unlocked_tracks[(i + 1) % unlocked_tracks.size()])


# ---------- UNLOCKS ----------
func unlock_track(name: String) -> void:
	if name in unlocked_tracks or not _music_streams.has(name):
		return
	unlocked_tracks.append(name)
	track_unlocked.emit(name)


func is_track_unlocked(name: String) -> bool:
	return name in unlocked_tracks


func get_all_tracks() -> Array:
	return _music_streams.keys()


# ---------- VOLUME (0.0 – 1.0) ----------
func set_master_volume(v: float) -> void: _set_bus_volume("Master", v)
func set_music_volume(v: float) -> void:  _set_bus_volume("Music", v)
func set_sfx_volume(v: float) -> void:    _set_bus_volume("SFX", v)


# ---------- INTERNAL ----------
func _preload(table: Dictionary, target: Dictionary) -> void:
	for key in table:
		var path: String = table[key]
		if ResourceLoader.exists(path):
			target[key] = load(path)
		else:
			push_warning("AudioManager: file not found for '%s' (%s)" % [key, path])


func _make_music_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "Music" if _bus_exists("Music") else "Master"
	p.finished.connect(func(): if p == _active_music and p.stream: p.play())  # loop fallback
	add_child(p)
	return p


func _get_free_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_pool:
		if not p.playing:
			return p
	return _sfx_pool[0]  # all busy: steal the first one


func _bus_exists(bus: String) -> bool:
	return AudioServer.get_bus_index(bus) != -1


func _set_bus_volume(bus: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx == -1: return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clamp(linear, 0.0001, 1.0)))


func stop_sfx(name: String, fade: float = 0.3) -> void:
	## Fades out the most recent instance of a sound instead of cutting it.
	var player: AudioStreamPlayer = _sfx_active.get(name)
	if player == null or not player.playing:
		return
	_sfx_active.erase(name)
	var t := create_tween()
	t.tween_property(player, "volume_db", -80.0, fade)
	t.tween_callback(func():
		player.stop()
		player.volume_db = 0.0  # reset so the next sound on this player isn't silent
	)


func stop_all_sfx(fade: float = 0.3) -> void:
	for p in _sfx_pool:
		if p.playing:
			var t := create_tween()
			t.tween_property(p, "volume_db", -80.0, fade)
			t.tween_callback(func():
				p.stop()
				p.volume_db = 0.0
			)
	_sfx_active.clear()

func get_sfx_from_item(item: ItemData) -> String:
	if item.obtained_from.is_empty():
		return ""

	match item.obtained_from[0]:
		ItemData.ItemColor.DEFAULT:
			return ""
		ItemData.ItemColor.MINING:
			return Mining.SKILL.sfx
		ItemData.ItemColor.PARSING:
			return Parsing.SKILL.sfx
		ItemData.ItemColor.CRACKING:
			return Cracking.SKILL.sfx
		ItemData.ItemColor.MATCHING:
			return Matching.SKILL.sfx
		ItemData.ItemColor.PHISHING:
			return Phishing.SKILL.sfx
		ItemData.ItemColor.HACKING:
			return Hacking.SKILL.sfx
		ItemData.ItemColor.DECODING:
			return Decoding.SKILL.sfx
		ItemData.ItemColor.COMPILING:
			return Compiling.SKILL.sfx
		ItemData.ItemColor.UPGRADE:
			return "upgrade"
		ItemData.ItemColor.CONSUMABLE:
			return "item_received"

	return ""


var _test_timer: Timer

## Repeatedly plays a sound until stop_test() is called.
## count = -1 plays forever. Interval is seconds between plays.
func test_sfx(name: String, interval: float = 0.5, count: int = -1, pitch_variation: float = 0.0) -> void:
	stop_test()
	_test_timer = Timer.new()
	_test_timer.wait_time = interval
	_test_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_test_timer)

	var remaining := count
	_test_timer.timeout.connect(func():
		play_sfx(name, pitch_variation)
		if remaining > 0:
			remaining -= 1
			if remaining == 0:
				stop_test()
	)
	_test_timer.start()
	play_sfx(name, pitch_variation)  # fire once immediately


func stop_test() -> void:
	if _test_timer:
		_test_timer.queue_free()
		_test_timer = null
