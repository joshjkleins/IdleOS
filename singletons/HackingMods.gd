extends Node

## Mod slots: 1 to start, +1 per tier from the 'hacking.mod_slots' upgrade (one level per tier), max 7.
const BASE_MOD_SLOTS := 2 # DEMO: Student (Hard) expects 2 mods and the demo has no Hacking upgrades (full game: 1)
const MAX_MOD_SLOTS := 7
var max_mods: int = BASE_MOD_SLOTS

## recompute slots from the upgrade (called on load and when an upgrade is installed)
func refresh_slots() -> void:
	var extra = 0
	# looked up at runtime: a direct 'Upgrades' reference makes a script cycle (Upgrades -> Items -> ItemData -> HackingMods)
	var up = get_node_or_null("/root/Upgrades")
	var p = up.get_package_info("hacking.mod_slots") if up else null
	if p != null:
		extra = int(p.current)
	max_mods = clamp(BASE_MOD_SLOTS + extra, 1, MAX_MOD_SLOTS)

enum MOD_TYPE {
	DAMAGE,               #logs | parents CC
	EFFICIENCY,           #pw, e-pw
	FIREWALL_REDUCTION,   #usernames
	FIREWALL_DAMAGE,      #IP address
	RESTORE,              #packet spoof
	BAND_RATE,            #school payload
	ATTACK_SPEED,         #credentials
	DAMAGE_REDUCTION,     #student cache
	COUNTER_SLOW,         #sql injector
	NONE,
}

var current_mods = {}

## Every equipped mod adds bandwidth cost to each SQL Injector attack, by the tier of the items it was
## made from. Tier 1 = +2 (2 mods at tier 1 = +4, so 6 + 4 = 10 = all of the starting bandwidth).
## Tiers 2-6 are placeholders until each tier's bandwidth upgrades are balanced.
const MOD_BW_COST_BY_TIER = {1: 2, 2: 2, 3: 2, 4: 2, 5: 2, 6: 2}

func get_mod_bandwidth_cost(mod) -> int:
	if !current_mods.has(mod):
		return 0
	return int(MOD_BW_COST_BY_TIER.get(int(current_mods[mod].get("tier", 1)), 2))

## total extra SQL Injector bandwidth cost from all equipped mods
func get_bandwidth_cost() -> int:
	var total = 0
	for m in current_mods:
		total += get_mod_bandwidth_cost(m)
	return total

func _ready():
	refresh_slots.call_deferred() # Upgrades may load after this autoload

func get_mod_description(mod: MOD_TYPE) -> String:
	match mod:
		MOD_TYPE.DAMAGE:
			return "Increases damage of SQL Injectors"
		MOD_TYPE.EFFICIENCY:
			return "Increases efficiency"
		MOD_TYPE.FIREWALL_REDUCTION:
			return "Reduces target firewall by flat amount"
		MOD_TYPE.FIREWALL_DAMAGE:
			return "Increases firewall damage"
		MOD_TYPE.RESTORE:
			return "Increases Packet Spoof restore"
		MOD_TYPE.BAND_RATE:
			return "Increases bandwith restore amount"
		MOD_TYPE.ATTACK_SPEED:
			return "Increases attack speed"
		MOD_TYPE.DAMAGE_REDUCTION:
			return "Gives flat countermeasures reduction"
		MOD_TYPE.COUNTER_SLOW:
			return "Slows counterattack measures"
		_:
			return ""

func get_mod_name(mod: MOD_TYPE) -> String:
	match mod:
		MOD_TYPE.DAMAGE:
			return "SQL Damage"
		MOD_TYPE.EFFICIENCY:
			return "Efficiency"
		MOD_TYPE.FIREWALL_REDUCTION:
			return "Target Firewall Reduction"
		MOD_TYPE.FIREWALL_DAMAGE:
			return "SQL Firewall Damage"
		MOD_TYPE.RESTORE:
			return "Packet Spoof Amount"
		MOD_TYPE.BAND_RATE:
			return "Bandwith Restore Amount"
		MOD_TYPE.ATTACK_SPEED:
			return "SQL Attack Speed"
		MOD_TYPE.DAMAGE_REDUCTION:
			return "Countermeasures Flat Reduction"
		MOD_TYPE.COUNTER_SLOW:
			return "Countermeasures Slow"
		_:
			return ""


func get_mod_value_text(mod: MOD_TYPE, value: float) -> String:
	match mod:
		MOD_TYPE.DAMAGE:
			return "+" + str(int(value))
		MOD_TYPE.EFFICIENCY:
			return "+%.f%%" % (value * 100.0)
		MOD_TYPE.FIREWALL_REDUCTION:
			return "-" + str(int(value))
		MOD_TYPE.FIREWALL_DAMAGE:
			return "+" + str(int(value))
		MOD_TYPE.RESTORE:
			return "+" + str(int(value))
		MOD_TYPE.BAND_RATE:
			return "+" + str(int(value))
		MOD_TYPE.ATTACK_SPEED:
			return "+" + "%.f%%" % (value * 100.0)
		MOD_TYPE.DAMAGE_REDUCTION:
			return "-" + str(int(value))
		MOD_TYPE.COUNTER_SLOW:
			return "-" + "%.f%%" % (value * 100.0)
		_:
			return str(0)


#MOD_TYPE.DAMAGE: {
	#"duration": 5,
	#"value": 10,
#}
func add_mod(item: ItemData) -> void:
	if at_max_mods():
		return
	
	var mod = item.hacking_mod_type
	var mod_value = item.hacking_mod_value
	var mod_duration = item.hacking_mod_duration
	current_mods[mod] = {
		"duration": mod_duration,
		"value": mod_value,
		"tier": item.tier, # sets the extra SQL Injector bandwidth cost (MOD_BW_COST_BY_TIER)
	}

func remove_duration() -> void:
	for mod in current_mods:
		current_mods[mod].duration -= 1
		if current_mods[mod].duration <= 0:
			remove_mod(mod)

func remove_mod(mod: MOD_TYPE) -> void:
	if has_mod(mod):
		current_mods.erase(mod)

func has_mod(mod: MOD_TYPE) -> bool:
	if current_mods.has(mod):
		return true
	return false

func at_max_mods() -> bool:
	if current_mods.size() >= max_mods:
		return true
	return false

func get_mod_value(mod: MOD_TYPE):
	if current_mods.has(mod):
		return current_mods[mod].value
	return 0


func save_data() -> Dictionary:
	return {
		"current_mods": current_mods,
		"max_mods": max_mods
	}

func load_data(data: Dictionary) -> void:
	var loaded_mods: Dictionary = data.get("current_mods", {})

	current_mods.clear()

	for mod_type in loaded_mods:
		var mod: Dictionary = loaded_mods[mod_type]

		mod["duration"] = int(mod.get("duration", 0))
		mod["tier"] = int(mod.get("tier", 1))

		current_mods[int(mod_type)] = mod

	refresh_slots() # slots come from upgrades, not the save (mods already equipped are kept)
