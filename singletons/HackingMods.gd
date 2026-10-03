extends Node

#how mods work
#player can consume an item x100 for its Mod type/value/duration
#Once a mod exists for the player, it cannot be modified
#cmmand compile -mod item=logs amount=max 
#Logs x 10 = Damage, 1, 1, #Logs x 50 = Damage, 5, 5, #Logs x 100 = Damage, 10, 10 (max)
#Player can only do a max of 100 per item per mod
#Option A
#If another Item is compiled with similar Type then simply replace or message that a type already exists with that bonus
#
#Option B
#If another item is compiled with similar Type then 

var max_mods: int = 2
var current_mods_count: int = 0

enum MOD_TYPE {
	DAMAGE,
	EFFICIENCY,
	FIREWALL_REDUCTION,
	FIREWALL_DAMAGE,
	RESTORE,
	BAND_RATE,
	ATTACK_SPEED,
	DAMAGE_REDUCTION,
	COUNTER_SLOW,
}

var current_mods = {}

var MAX_DURATION: int = 10

#func _ready():
	#add_mod(MOD_TYPE.DAMAGE, 5, 5)
	#add_mod(MOD_TYPE.ATTACK_SPEED, 7, 0.2)
	#add_mod(MOD_TYPE.EFFICIENCY, 3, 0.3)

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
			return "Increases bandwith restore rate"
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
			return "Bandwith Restore Rate"
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
			return str(int(value))
		MOD_TYPE.EFFICIENCY:
			return str(value * 100.0) + "%"
		MOD_TYPE.FIREWALL_REDUCTION:
			return str(int(value))
		MOD_TYPE.FIREWALL_DAMAGE:
			return str(int(value))
		MOD_TYPE.RESTORE:
			return str(int(value))
		MOD_TYPE.BAND_RATE:
			return str(int(value))
		MOD_TYPE.ATTACK_SPEED:
			return str(value * 100.0) + "%"
		MOD_TYPE.DAMAGE_REDUCTION:
			return str(int(value))
		MOD_TYPE.COUNTER_SLOW:
			return str(value * 100.0) + "%"
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
		"value": mod_value
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
	if current_mods.has_mod(mod):
		return current_mods[mod].value
	return 0
