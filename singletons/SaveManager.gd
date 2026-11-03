extends Node

signal save_loaded

## 2026-11-02 (Josh): 3 save slots, picked on the launch screen. The old single save moves into slot 1 once.
const LEGACY_PATH = "user://savegame.json"
const SAVE_DIR = "user://saves"
const SLOTS = 3
var slot: int = 1                # the slot this session plays (set by the launcher before the game scene loads)
var session_active := false      # a game is loaded / started: nothing is saved before that (the launcher can't overwrite a slot)
var play_seconds: float = 0.0    # total time played on this slot
var profile_name: String = ""    # shown on the launcher card ("" = "user_<slot>")
var SAVE_PATH: String:
	get: return slot_path(slot)
## 2 = Oct 18 2026 demo (uploads woven into the tutorial). Older saves get the 'tutorial reset' notice.
const SAVE_VERSION = 2
## Version of the save that was loaded this session (0 = no save / fresh game)
var loaded_version: int = SAVE_VERSION

var dirty: bool = false
var auto_save_interval: float = 15.0
var _timer: float = 0.0

func _ready() -> void:
	_migrate_legacy()

func slot_path(n: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, n]

func slot_exists(n: int) -> bool:
	return FileAccess.file_exists(slot_path(n))

## The old user://savegame.json becomes slot 1 (kept as savegame.json.migrated, never removed)
func _migrate_legacy() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if FileAccess.file_exists(LEGACY_PATH) and !slot_exists(1):
		if DirAccess.copy_absolute(LEGACY_PATH, slot_path(1)) == OK:
			DirAccess.rename_absolute(LEGACY_PATH, LEGACY_PATH + ".migrated")
			print("SaveManager: moved the old save into slot 1")

## The snapshot a slot's card shows ({} = empty slot). Saves from before the meta block get {"legacy": true}.
func read_meta(n: int) -> Dictionary:
	if !slot_exists(n):
		return {}
	var f = FileAccess.open(slot_path(n), FileAccess.READ)
	if f == null:
		return {"corrupt": true}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if !(parsed is Dictionary):
		return {"corrupt": true}
	return parsed.get("meta", {"legacy": true})

## Profile names: letters, digits, '_' and '-', 1-16 long. "" when <nm> is fine, otherwise why not.
func name_problem(nm: String) -> String:
	if nm.length() < 1 or nm.length() > 16:
		return "Names are 1-16 characters."
	var re = RegEx.create_from_string("^[A-Za-z0-9_-]+$")
	if re.search(nm) == null:
		return "Letters, numbers, '_' and '-' only."
	return ""

## Renames a saved slot in place (only its meta block changes)
func rename_slot(n: int, nm: String) -> bool:
	var f = FileAccess.open(slot_path(n), FileAccess.READ)
	if f == null:
		return false
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if !(data is Dictionary):
		return false
	var meta: Dictionary = data.get("meta", {})
	meta["name"] = nm
	data["meta"] = meta
	f = FileAccess.open(slot_path(n), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	return true

## 'Deletes' a slot: the file moves to user://saves/deleted/ (a safety net; the launcher shows the slot empty)
func delete_slot(n: int) -> bool:
	if !slot_exists(n):
		return false
	DirAccess.make_dir_recursive_absolute(SAVE_DIR + "/deleted")
	var to = "%s/deleted/slot_%d_%d.json" % [SAVE_DIR, n, int(Time.get_unix_time_from_system())]
	return DirAccess.rename_absolute(slot_path(n), to) == OK

func display_name(n: int, meta: Dictionary = {}) -> String:
	var nm = str(meta.get("name", ""))
	return nm if nm != "" else "user_%d" % n

## What the launcher shows for this game, written with every save
func build_meta() -> Dictionary:
	var skills := []
	for sk in [Mining, Parsing, Cracking, Matching, Phishing, Decoding, Compiling, Hacking]:
		skills.append({"name": sk.SKILL.name, "level": int(sk.SKILL.level), "color": sk.SKILL.color.to_html(false),
			"firmware": Firmware.active(sk)})
	var tier = Uploads.current_tier()
	var done := 0
	var goal := 0
	for g in Uploads.get_goals(tier):
		goal += int(g.amount)
		done += min(int(g.amount), Uploads.get_uploaded(g.item))
	var off = Offline.snapshot()
	var off_cmd = ""
	if !off.is_empty():
		off_cmd = str(off.command) + ((" %d" % int(off.cycles_left)) if off.has("cycles_left") else "")
	return {"name": profile_name, "saved_at": int(Time.get_unix_time_from_system()), "play_seconds": int(play_seconds),
		"tier": tier, "location": Uploads.get_location_name(tier), "tiers_done": Uploads.completed_tiers.size(),
		"all_done": Uploads.completed_tiers.size() >= Uploads.MAX_TIER, "upload_done": done, "upload_goal": goal,
		"skills": skills, "offline": off_cmd, "offline_cap": int(Offline.cap_seconds()),
		"queue": {"running": Queue.running, "steps": Queue.steps.size(), "index": Queue.index,
			"current": str(Queue.steps[Queue.index]) if Queue.index < Queue.steps.size() else ""},
		"hat": Ending.choice}

func _process(delta: float) -> void:
	if session_active:
		play_seconds += delta
	if not dirty:
		return
	_timer += delta
	if _timer >= auto_save_interval:
		save_game()
		_timer = 0.0

func mark_dirty() -> void:
	dirty = true

func save_game() -> void:
	if !session_active:
		return # the launcher (or a boot that never got going): nothing to save
	#save TEMPATURE
	var data = {
		"version": SAVE_VERSION,
		"meta": build_meta(),
		"inventory": Inventory.save_data(),
		"upgrades": Upgrades.save_data(),
		"mining": Mining.save_data(),
		"parsing": Parsing.save_data(),
		"cracking": Cracking.save_data(),
		"phishing": Phishing.save_data(),
		"matching": Matching.save_data(),
		"decoding": Decoding.save_data(),
		"compiling": Compiling.save_data(),
		"hacking": Hacking.save_data(),
		"defragging": Defragging.save_data(),
		"tutorial": Tutorial.save_data(),
		"stats": Stats.save_data(),
		"mods": HackingMods.save_data(),
		"uploads": Uploads.save_data(),
		"exploits": Exploits.save_data(),
		"drivers": Drivers.save_data(),
		"offline": Offline.save_data(),
		"ending": Ending.save_data(),
		"firmware": Firmware.save_data(),
		"flush": Flush.save_data(),
		"queue": Queue.save_data(),
		"alert": Alert.save_data(),
	}
	
	var tracked_panel = get_tree().get_first_node_in_group("tracked_items_panel")
	if tracked_panel:
		data["tracked_items"] = tracked_panel.save_data()
	var dock = get_tree().get_first_node_in_group("system_dock")
	if dock:
		data["system_dock"] = dock.save_data()
	
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: failed to open save file for writing")
		return
	
	file.store_string(JSON.stringify(data))
	file.close()
	dirty = false
	print("Game saved.")

func debug_print_save() -> void:
	var file := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.READ)
	print(file.get_as_text())
	file.close()

func has_saved_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(content)
	if parsed == null:
		push_error("SaveManager: save file corrupted")
		return false
	
	var data: Dictionary = parsed
	loaded_version = int(data.get("version", 0))
	var meta: Dictionary = data.get("meta", {})
	play_seconds = float(meta.get("play_seconds", 0))
	profile_name = str(meta.get("name", ""))
	_migrate_if_needed(data)
	
	Inventory.load_data(data.get("inventory", {}))
	Upgrades.load_data(data.get("upgrades", {}))
	Mining.load_data(data.get("mining", {}))
	Parsing.load_data(data.get("parsing", {}))
	Cracking.load_data(data.get("cracking", {}))
	Phishing.load_data(data.get("phishing", {}))
	Matching.load_data(data.get("matching", {}))
	Decoding.load_data(data.get("decoding", {}))
	Compiling.load_data(data.get("compiling", {}))
	Hacking.load_data(data.get("hacking", {}))
	Defragging.load_data(data.get("defragging", {}))
	Tutorial.load_data(data.get("tutorial", {}))
	Stats.load_data(data.get("stats", {}))
	HackingMods.load_data(data.get("mods", {}))
	Uploads.load_data(data.get("uploads", {}))
	Exploits.load_data(data.get("exploits", {}))
	Drivers.load_data(data.get("drivers", {}))
	Offline.load_data(data.get("offline", {})) # applied by Offline.compute() once idle_os_2 is ready
	Ending.load_data(data.get("ending", {}))
	Firmware.load_data(data.get("firmware", {}))
	Flush.load_data(data.get("flush", data.get("burst", {}))) # (saved as "burst" until 2026-11-02)
	Queue.load_data(data.get("queue", {}))
	Alert.load_data(data.get("alert", {}))
	Exp.refresh_all_process_unlocks() # 2026-10-26: unlocks follow the tiers, so after Stats (locations) has loaded
	
	print(data.get("mods"))
	
	var tracked_panel = get_tree().get_first_node_in_group("tracked_items_panel")
	if tracked_panel:
		tracked_panel.load_data(data.get("tracked_items", {}))
	var dock = get_tree().get_first_node_in_group("system_dock")
	if dock:
		dock.load_data(data.get("system_dock", {}))
	
	save_loaded.emit()
	return true

func _migrate_if_needed(data: Dictionary) -> void:
	var version: int = data.get("version", 0)
	#useless for now, but as game evolves and fields change, data can get transformed/migrated here
	pass

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if what == NOTIFICATION_WM_CLOSE_REQUEST:
			get_tree().call_group("flush_on_quit", "flush_for_quit") # finish a cache being decoded (2026-10-29)
		save_game()
		#if dirty:
			#save_game()
