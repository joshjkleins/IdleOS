extends Node

var max_mods: int = 2
var current_mods_count: int = 0

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
}

var current_mods = {}

var MAX_DURATION: int = 10

#func _ready():
	#add_mod(Items.LOGS)

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
	if current_mods.has(mod):
		return current_mods[mod].value
	return 0
