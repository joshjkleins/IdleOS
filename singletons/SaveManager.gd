extends Node

signal save_loaded

const SAVE_PATH = "user://savegame.json"
const SAVE_VERSION = 1

var dirty: bool = false
var auto_save_interval: float = 15.0
var _timer: float = 0.0

func _process(delta: float) -> void:
	if not dirty:
		return
	_timer += delta
	if _timer >= auto_save_interval:
		save_game()
		_timer = 0.0

func mark_dirty() -> void:
	print("Marked dirty, will save.")
	dirty = true

func save_game() -> void:
	#save TEMPATURE
	var data = {
		"version": SAVE_VERSION,
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
		"tutorial": Tutorial.save_data(),
		"stats": Stats.save_data(),
	}
	
	var tracked_panel = get_tree().get_first_node_in_group("tracked_items_panel")
	if tracked_panel:
		data["tracked_items"] = tracked_panel.save_data()
	
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
	Tutorial.load_data(data.get("tutorial", {}))
	Stats.load_data(data.get("stats", {}))
	
	var tracked_panel = get_tree().get_first_node_in_group("tracked_items_panel")
	if tracked_panel:
		tracked_panel.load_data(data.get("tracked_items", {}))
	
	save_loaded.emit()
	return true

func _migrate_if_needed(data: Dictionary) -> void:
	var version: int = data.get("version", 0)
	#useless for now, but as game evolves and fields change, data can get transformed/migrated here
	pass

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()
		#if dirty:
			#save_game()
