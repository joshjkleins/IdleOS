extends Node

signal cache_decode_cycle_completed
signal intel_decode_cycle_completed
signal xp_gained
signal decoding_level_up_signal

# When the player earns the bonus
var bonus_expires_at: int
var vm_token = Items.VM_DECODING_TOKEN
@onready var MAX_VMS = 7
@onready var VM_UPTIME = 30.0
var CURRENT_VMS = 0

var terminal_scene = preload("res://scenes/cache_decrypt_terminal.tscn")

var first_cache_decoded: bool = false

## Chance for a cache's rare item (Decoding efficiency incl. upgrades + defrag bonus).
func get_rare_chance() -> float:
	var efficiency_upgrade = Upgrades.get_package_info("decoding.efficiency").current
	var defrag_bonus = Defragging.DECODING["bonus efficiency"] if Stats.has_bonus(Decoding) else 1.0
	return (CACHE["efficiency"] + efficiency_upgrade) * defrag_bonus

#GENERAL MODULE DATA
var SKILL = {
	"name": "Decoding",
	"level": 1,
	"experience": 0,
	"color": Color("#14B8A6"),
	"level up signal": decoding_level_up_signal,
	"efficiency description": "Chance to find rare item.",
	"command": "cd decoding",
	"sfx": "cracking_item_received"
}

var CACHE = {
	"name": "Cache",
	"level": 1,
	"experience": 0,
	"experience per level": 50,
	"command": "decode -cache",
	"display command": "decode -cache[=<cache item>]",
	"example commands": [
		{'cmd': 'decode -cache', 'description': 'Decodes every cache you have, starting with least rare.'},
		{'cmd': 'decode -cache=student cache', 'description': 'Decodes "Student Caches" and stops when done instead of moving on to other caches.'}
	],
	"efficiency": 0.1,
	"efficiency rate": 0.001,
	"unlocked": true,
	"unlock level": 1,
	"base speed": 0.2,
	"overclock speed": 0.05,
	"overheat speed": 1.0,
	"heat": 3.2,
	"overclock heat": 3.5,
	"overheat heat": 0.3,
	"requirements": "Cache x1", #handled within the decoding terminal script
	"description": "Decrypt caches gained from hacking to reveal additional items.",
	"efficiency description": "Chance to find rare item.",
	"signal": cache_decode_cycle_completed
}

var minor_processes = [
	CACHE
]

func signal_exp(_amount: int):
	xp_gained.emit()
	SaveManager.mark_dirty()

#var process_upgrades = {
	#"speed": { "id": 1, "name": "Speed", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	#"efficiency": { "id": 2, "name": "Efficiency", "level": 0, "amount": 0.0, "increase per level": 0.005 },
	#"experience": { "id": 3, "name": "Experience", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	#"offline": { "id": 4, "name": "Offline progression", "level": 0, "amount": 0, "increase per level": 60 },
	#"vm windows": { "id": 5, "name": "VM Windows", "level": 0, "amount": 1, "increase per level": 1 },
	#"vm duration": { "id": 6, "name": "VM Duration", "level": 0, "amount": 30.0, "increase per level": 30.0 },
#}
#
#func get_upgrade_cost(upgrade_stat: String) -> int:
	#return process_upgrades[upgrade_stat]["level"] * 800 + 100
#
#func upgraded(upgrade_stat: Dictionary):
	#upgrade_stat["level"] += 1
	#upgrade_stat["amount"] += upgrade_stat["increase per level"]
	#
	#if upgrade_stat["name"].to_lower() == "vm windows":
		#MAX_VMS += upgrade_stat["increase per level"]
	#if upgrade_stat["name"].to_lower() == "vm duration":
		#VM_UPTIME += upgrade_stat["increase per level"]

func has_requirements(_minor_process) -> bool:
	if Inventory.has_cache():
		return true
	return false

func missing_requirements_text(_minor_process) -> String:
	return "Missing: Cache(any)"

func create_vm_window(minor_process, repeat, cache_target: ItemData) -> VMWindow:
	var setup = func(t):
		t.set_cache_type(minor_process, true, cache_target)
		t.start_decrypting()
	return VMManager.open(self, minor_process, terminal_scene.instantiate(), setup, repeat)


func save_data() -> Dictionary:
	return {
		"bonus_expires_at": bonus_expires_at,
		"skill_level": SKILL["level"],
		"skill_experience": SKILL["experience"],
		"cache_level": CACHE["level"],
		"cache_experience": CACHE["experience"],
		"cache_efficiency": CACHE["efficiency"],
		"first_cache_decoded": first_cache_decoded
	}

func load_data(data: Dictionary) -> void:
	bonus_expires_at = int(data.get("bonus_expires_at", bonus_expires_at))
	SKILL["level"] = int(data.get("skill_level", SKILL["level"]))
	SKILL["experience"] = int(data.get("skill_experience", SKILL["experience"]))
	CACHE["level"] = int(data.get("cache_level", CACHE["level"]))
	CACHE["experience"] = int(data.get("cache_experience", CACHE["experience"]))
	CACHE["efficiency"] = float(data.get("cache_efficiency", CACHE["efficiency"]))
	first_cache_decoded = data.get("first_cache_decoded", false)

#region cache variants
## Drop rules for caches and their variants (tuning values are constants on CacheData).
## `ls <cache>` uses get_drop_table(), decoding uses roll_loot(), so the two always agree.

## Basic resources = everything except hacking mods, SQL injectors, packet spoofs, VM tokens and rare items.
func is_basic_item(item: ItemData) -> bool:
	if item.hacking_mod_item:
		return false
	if item == Items.SQL_INJECTOR or item == Items.PACKET_SPOOF:
		return false
	return not item in vm_tokens()

func vm_tokens() -> Array:
	return [Items.VM_MINING_TOKEN, Items.VM_PARSING_TOKEN, Items.VM_CRACKING_TOKEN, Items.VM_MATCHING_TOKEN,
		Items.VM_PHISHING_TOKEN, Items.VM_DECODING_TOKEN, Items.VM_COMPILING_TOKEN]

func _entry_range(cache: CacheData, entry: CacheEntry) -> Vector2i:
	var mult = 1
	if cache.get_variant() == CacheData.CacheVariant.FOOTPRINT and is_basic_item(entry.item):
		mult = CacheData.FOOTPRINT_MULTIPLIER
	return Vector2i(entry.min_quantity * mult, entry.max_quantity * mult)

func _entry_chance(cache: CacheData, entry: CacheEntry) -> float:
	var bonus = CacheData.CORRUPTION_DROP_BONUS if cache.get_variant() == CacheData.CacheVariant.CORRUPTION else 0.0
	return min(1.0, entry.drop_chance + bonus)

func get_cache_rare_chance(cache: CacheData, base_rare_chance: float) -> float:
	match cache.get_variant():
		CacheData.CacheVariant.FOOTPRINT:
			return 0.0
		CacheData.CacheVariant.CORRUPTION:
			return min(1.0, base_rare_chance + CacheData.CORRUPTION_DROP_BONUS)
	return base_rare_chance

func _rare_amount(cache: CacheData) -> int:
	if cache.get_variant() == CacheData.CacheVariant.EXTRACTION:
		return 1 + CacheData.EXTRACTION_EXTRA_RARE
	return 1

## For `ls`: [{name, min, max, chance, rare}].
func get_drop_table(cache: CacheData) -> Array:
	var rows = []
	for e in cache.entries:
		var r = _entry_range(cache, e)
		rows.append({"name": e.item.name, "min": r.x, "max": r.y, "chance": _entry_chance(cache, e), "rare": false})
	if cache.get_variant() == CacheData.CacheVariant.NETWORK:
		rows.append({"name": "Random VM token", "min": CacheData.NETWORK_VM_MIN, "max": CacheData.NETWORK_VM_MAX, "chance": CacheData.NETWORK_VM_CHANCE, "rare": false})
	var rare_chance = get_cache_rare_chance(cache, get_rare_chance())
	if rare_chance > 0.0:
		for e in cache.rare_pool:
			rows.append({"name": e.item.name, "min": _rare_amount(cache), "max": _rare_amount(cache), "chance": rare_chance, "rare": true})
	return rows

## Rolls one decode: [{item, amount, rare}] with the rare item (if any) last.
func roll_loot(cache: CacheData) -> Array:
	var loot = []
	for e in cache.entries:
		if randf() <= _entry_chance(cache, e):
			var r = _entry_range(cache, e)
			loot.append({"item": e.item, "amount": randi_range(r.x, r.y), "rare": false})
	if cache.get_variant() == CacheData.CacheVariant.NETWORK and randf() <= CacheData.NETWORK_VM_CHANCE:
		loot.append({"item": vm_tokens().pick_random(), "amount": randi_range(CacheData.NETWORK_VM_MIN, CacheData.NETWORK_VM_MAX), "rare": false})
	if !cache.rare_pool.is_empty() and randf() < get_cache_rare_chance(cache, get_rare_chance()):
		loot.append({"item": cache.rare_pool.pick_random().item, "amount": _rare_amount(cache), "rare": true})
	return loot
#endregion
