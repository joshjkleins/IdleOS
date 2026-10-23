extends Node

## Mod slots: 1 to start, +1 per tier from the 'hacking.mod_slots' upgrade (one level per tier), max 7.
const BASE_MOD_SLOTS := 1
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
	BAND_RATE,            #Falsified transcript-style rares (payloads moved to COUNTER_RESET)
	ATTACK_SPEED,         #credentials
	DAMAGE_REDUCTION,     #student cache
	COUNTER_SLOW,         #sql injector
	NONE,
	# equippable mods (Phishing Mod / Corruption drops, 3 per tier; values are % so they stay strong all game)
	SQL_BOOST,
	FW_BREAK_SLOW,
	BW_PCT_REGEN,
	FW_NO_REBOOT,
	DAMAGE_PCT,
	CRIT_CHANCE_MULT,
	CRIT_DAMAGE_MULT,
	SPOOF_HEAL_MULT,
	SPOOF_FREE,
	IGNORE_COUNTERS,
	FW_PCT_HIT,
	COUNTER_SLOW_PCT,
	STEALTH_START,
	SPOOF_SPEED,
	EXPLOIT_FULL,
	FW_BREAK_INTEGRITY,
	COUNTER_REFLECT,
	COLD_BOOT,
	COUNTER_RESET,        #payloads (2026-10-21): chance per SQL attack to reset the enemy's countermeasure bar
	FW_OPENER,            #Handshake Exploit (2026-10-23): first hit on a new firewall +N firewall damage
	# 2026-10-23 mods pass (5 equippable mods per tier)
	FW_START_PCT,         #Backdoor: firewall starts X% lower (each hack and reboot)
	COUNTER_DMG_PCT,      #Hardened Shell: countermeasures deal X% less
	START_ANON,           #Fresh Start: +X% max anonymity at the start of each hack
	SPOOF_OPENER,         #Opening Spoof: a Packet Spoof engages at the start of each hack
	CRIT_RAMP,            #Hot Streak: +X crit chance per non-crit, reset on crit
	DOUBLE_TAP,           #Double Tap: X slower attacks, 2 SQL per attack, double damage
	BLEED,                #Bleed: X of each hit again over 3s
	FW_BREAK_HASTE,       #Breach Momentum: +X attack speed for 3 attacks after a firewall break
	LEECH,                #Leech: X of max anonymity per SQL hit
	COUNTER_STACK_SLOW,   #Jitter: each countermeasure slows the next by X (max 50%)
	FAILSAFE,             #Failsafe: the first trace of a hack restores X instead
	EXTRA_CACHE,          #Data Hoarder: X chance of an extra cache per breach
}


## Equippable mods: name, effect, value format (pct = +X%, x = xN, n = count, s = seconds, on = no value)
const EQUIP_INFO = {
	MOD_TYPE.SQL_BOOST: ["SQL Booster", "SQL Injectors attack faster", "pct"],
	MOD_TYPE.FW_BREAK_SLOW: ["Shatter Protocol", "Breaking the firewall slows enemy countermeasures by an extra 25% (75% total).", "pct"],
	MOD_TYPE.BW_PCT_REGEN: ["Burst Buffer", "Regenerates an extra 20% of max bandwidth per second.", "pct"],
	MOD_TYPE.FW_NO_REBOOT: ["Firmware Brick", "Once the firewall is broken it never reboots for the rest of the hack.", "on"],
	MOD_TYPE.DAMAGE_PCT: ["Payload Amplifier", "SQL Injectors deal 25% more damage.", "pct"],
	MOD_TYPE.CRIT_CHANCE_MULT: ["Vuln Scanner", "Doubles your crit chance.", "x"],
	MOD_TYPE.CRIT_DAMAGE_MULT: ["Critical Overflow", "Crits deal double again: x4 instead of x2.", "x"],
	MOD_TYPE.SPOOF_HEAL_MULT: ["Proxy Chain", "Packet Spoofs heal double.", "x"],
	MOD_TYPE.SPOOF_FREE: ["Ghost Packet", "Packet Spoofs cost no bandwidth.", "on"],
	MOD_TYPE.IGNORE_COUNTERS: ["Decoy Traffic", "The first 3 countermeasures of each hack miss.", "n"],
	MOD_TYPE.FW_PCT_HIT: ["Packet Shredder", "Every hit also deals 10% of the target's max firewall.", "pct"],
	MOD_TYPE.COUNTER_SLOW_PCT: ["Latency Injector", "Enemy countermeasures are 20% slower.", "pct"],
	MOD_TYPE.STEALTH_START: ["Silent Entry", "The first 10 seconds of each hack go unnoticed: no countermeasures.", "s"],
	MOD_TYPE.SPOOF_SPEED: ["IP Rotator", "Packet Spoofs fill 80% faster.", "pct"],
	MOD_TYPE.EXPLOIT_FULL: ["Zero Hour", "The EXPLOIT meter starts full at the start of each hack.", "on"],
	MOD_TYPE.FW_BREAK_INTEGRITY: ["Cascade", "Breaking the firewall also deals 15% of the target's max integrity.", "pct"],
	MOD_TYPE.COUNTER_REFLECT: ["Mirror", "25% of every countermeasure's damage is reflected to the target's integrity.", "pct"],
	MOD_TYPE.COLD_BOOT: ["Cold Boot", "Overclock adds no extra heat, and overheating doesn't speed up the enemy.", "on"],
	MOD_TYPE.COUNTER_RESET: ["Reset Loop", "Each SQL Injector hit has a 10% chance to reset the countermeasure bar.", "pct"],
	MOD_TYPE.FW_START_PCT: ["Backdoor", "The target's firewall starts 25% lower (every hack and every reboot).", "neg"],
	MOD_TYPE.COUNTER_DMG_PCT: ["Hardened Shell", "Countermeasures deal 15% less damage.", "neg"],
	MOD_TYPE.START_ANON: ["Fresh Start", "Restores 15% of max anonymity at the start of each hack.", "pct"],
	MOD_TYPE.SPOOF_OPENER: ["Opening Spoof", "A Packet Spoof engages at the start of each hack.", "on"],
	MOD_TYPE.CRIT_RAMP: ["Hot Streak", "Every non-crit hit adds +10% crit chance; resets on a crit.", "pct"],
	MOD_TYPE.DOUBLE_TAP: ["Double Tap", "Attacks 30% slower, but each fires 2 SQL Injectors for double damage.", "on"],
	MOD_TYPE.BLEED: ["Bleed", "Every SQL hit deals another 10% of its damage over 3 seconds.", "pct"],
	MOD_TYPE.FW_BREAK_HASTE: ["Breach Momentum", "Breaking the firewall makes your next 3 attacks 100% faster.", "pct"],
	MOD_TYPE.LEECH: ["Leech", "Every SQL hit restores 2% of max anonymity.", "pct"],
	MOD_TYPE.COUNTER_STACK_SLOW: ["Jitter", "Every countermeasure slows the next ones by 5% (up to 50%).", "pct"],
	MOD_TYPE.FAILSAFE: ["Failsafe", "The first time you'd be traced in a hack, restore 20% of max anonymity instead.", "pct"],
	MOD_TYPE.EXTRA_CACHE: ["Data Hoarder", "Each breach has a 20% chance to win an extra cache.", "pct"],
	MOD_TYPE.FW_OPENER: ["Handshake Exploit", "The first hit against a new firewall (each hack, and after every reboot) deals +10 firewall damage.", "flat"],
}

var current_mods = {}

## Mod items that no longer drop (2026-10-23 lineup: 5 per tier). Owned ones still equip and work.
const RETIRED_MOD_ITEMS = [340, 347] # Shatter Protocol, Ghost Packet

## mod items that can drop: tier 0 = every tier
func pool_items(tier: int = 0) -> Array:
	var out = []
	var items = get_node_or_null("/root/Items") # looked up at runtime: a direct reference is a script cycle (see refresh_slots)
	if items == null:
		return out
	for it in items.ITEM_MAP.values():
		if it and it.hacking_mod_item and !(int(it.id) in RETIRED_MOD_ITEMS) and (tier <= 0 or int(it.tier) == tier):
			out.append(it)
	out.sort_custom(func(a, b): return a.id < b.id)
	return out

## Every equipped mod adds bandwidth cost to each SQL Injector attack. Compiled mods cost by the tier of the item
## they were made from (+1 per tier: older mods are the cheap option); equippable mods always cost +2.
## A full loadout can cost more than max bandwidth: the attack then fires once the bar is full (a build trade-off).
const MOD_BW_COST_BY_TIER = {1: 2, 2: 3, 3: 4, 4: 5, 5: 6, 6: 7}
const EQUIP_BW_COST := 2

func get_mod_bandwidth_cost(mod) -> int:
	if !current_mods.has(mod):
		return 0
	if mod == MOD_TYPE.SQL_BOOST:
		return 0 # 2026-10-23: its faster attacks already spend bandwidth faster
	if EQUIP_INFO.has(mod):
		return EQUIP_BW_COST
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
			return "Packet Spoofs restore more: +X% of max anonymity"
		MOD_TYPE.BAND_RATE:
			return "Increases bandwith restore amount"
		MOD_TYPE.ATTACK_SPEED:
			return "Increases attack speed"
		MOD_TYPE.DAMAGE_REDUCTION:
			return "Gives flat countermeasures reduction"
		MOD_TYPE.COUNTER_SLOW:
			return "Slows counterattack measures"
		_:
			return EQUIP_INFO[mod][1] if EQUIP_INFO.has(mod) else ""

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
			return "Bandwidth Restore Amount"
		MOD_TYPE.ATTACK_SPEED:
			return "SQL Attack Speed"
		MOD_TYPE.DAMAGE_REDUCTION:
			return "Countermeasures Flat Reduction"
		MOD_TYPE.COUNTER_SLOW:
			return "Countermeasures Slow"
		_:
			return EQUIP_INFO[mod][0] if EQUIP_INFO.has(mod) else ""


## short "what the value changes" label for the 'mod' tables (EFFECT column)
const STAT_LABEL = {
	MOD_TYPE.DAMAGE: "SQL damage",
	MOD_TYPE.EFFICIENCY: "crit chance",
	MOD_TYPE.FIREWALL_REDUCTION: "target firewall",
	MOD_TYPE.FIREWALL_DAMAGE: "SQL firewall damage",
	MOD_TYPE.RESTORE: "spoof restore (of max anon)",
	MOD_TYPE.BAND_RATE: "bandwidth regen",
	MOD_TYPE.ATTACK_SPEED: "SQL attack speed",
	MOD_TYPE.DAMAGE_REDUCTION: "countermeasure damage",
	MOD_TYPE.COUNTER_SLOW: "countermeasure speed",
	MOD_TYPE.COUNTER_RESET: "counter reset chance / attack",
	MOD_TYPE.SQL_BOOST: "SQL attack speed",
	MOD_TYPE.FW_BREAK_SLOW: "counter slow on firewall break",
	MOD_TYPE.BW_PCT_REGEN: "bandwidth regen (of max) / s",
	MOD_TYPE.FW_NO_REBOOT: "firewall never reboots",
	MOD_TYPE.DAMAGE_PCT: "SQL damage",
	MOD_TYPE.CRIT_CHANCE_MULT: "crit chance",
	MOD_TYPE.CRIT_DAMAGE_MULT: "crit damage",
	MOD_TYPE.SPOOF_HEAL_MULT: "spoof restore",
	MOD_TYPE.SPOOF_FREE: "spoofs cost no bandwidth",
	MOD_TYPE.IGNORE_COUNTERS: "countermeasures that miss",
	MOD_TYPE.FW_PCT_HIT: "max firewall dmg / hit",
	MOD_TYPE.COUNTER_SLOW_PCT: "countermeasure speed",
	MOD_TYPE.STEALTH_START: "undetected at hack start",
	MOD_TYPE.SPOOF_SPEED: "spoof fill speed",
	MOD_TYPE.EXPLOIT_FULL: "EXPLOIT meter starts full",
	MOD_TYPE.FW_BREAK_INTEGRITY: "max integrity on fw break",
	MOD_TYPE.COUNTER_REFLECT: "countermeasure dmg reflected",
	MOD_TYPE.COLD_BOOT: "overclock adds no heat",
	MOD_TYPE.FW_OPENER: "fw dmg, 1st hit on new firewall",
	MOD_TYPE.FW_START_PCT: "target firewall at start / reboot",
	MOD_TYPE.COUNTER_DMG_PCT: "countermeasure damage",
	MOD_TYPE.START_ANON: "anonymity at hack start",
	MOD_TYPE.SPOOF_OPENER: "spoof engages at hack start",
	MOD_TYPE.CRIT_RAMP: "crit chance per non-crit",
	MOD_TYPE.DOUBLE_TAP: "2 SQL per attack, 30% slower",
	MOD_TYPE.BLEED: "extra damage over 3s / hit",
	MOD_TYPE.FW_BREAK_HASTE: "attack speed x3 after fw break",
	MOD_TYPE.LEECH: "anonymity (of max) per hit",
	MOD_TYPE.COUNTER_STACK_SLOW: "counter slow per counter",
	MOD_TYPE.FAILSAFE: "anonymity on first trace",
	MOD_TYPE.EXTRA_CACHE: "extra cache chance / breach",
}

func get_mod_stat(mod) -> String:
	return STAT_LABEL.get(mod, "")

func get_mod_value_text(mod: MOD_TYPE, value: float) -> String:
	match mod:
		MOD_TYPE.COUNTER_SLOW_PCT:
			return "-%.f%%" % (value * 100.0) # countermeasures slower
		MOD_TYPE.DAMAGE:
			return "+" + str(int(value))
		MOD_TYPE.EFFICIENCY:
			return "+%s%%" % str(snappedf(value * 100.0, 0.1)).trim_suffix(".0")
		MOD_TYPE.FIREWALL_REDUCTION:
			return "-" + str(int(value))
		MOD_TYPE.FIREWALL_DAMAGE:
			return "+" + str(int(value))
		MOD_TYPE.RESTORE:
			return "+%d%%" % int(value) # percentage points of max anonymity
		MOD_TYPE.BAND_RATE:
			return "+" + str(int(value))
		MOD_TYPE.ATTACK_SPEED:
			return "+" + "%.f%%" % (value * 100.0)
		MOD_TYPE.DAMAGE_REDUCTION:
			return "-" + str(int(value))
		MOD_TYPE.COUNTER_SLOW:
			return "-" + "%.f%%" % (value * 100.0)
		_:
			if EQUIP_INFO.has(mod):
				match EQUIP_INFO[mod][2]:
					"pct": return "+%.f%%" % (value * 100.0)
					"x": return "x%s" % str(value).trim_suffix(".0")
					"n": return str(int(value))
					"s": return "%ds" % int(value)
					"flat": return "+%d" % int(value)
					"neg": return "-%.f%%" % (value * 100.0)
				return "on"
			return str(0)


#MOD_TYPE.DAMAGE: {
	#"duration": 5,
	#"value": 10,
#}
## hacks a mod item lasts once equipped: its own duration + System's Kernel Modules (+1 per tier)
func mod_duration(item) -> int: # item: ItemData (untyped: see the cycle note in refresh_slots)
	var up = get_node_or_null("/root/Upgrades")
	return int(item.hacking_mod_duration) + (int(up.cur("system.kernel_modules")) if up else 0)

func add_mod(item: ItemData) -> void:
	if at_max_mods():
		return
	
	var mod = item.hacking_mod_type
	var mod_value = item.hacking_mod_value
	var mod_duration = mod_duration(item)
	current_mods[mod] = {
		"duration": mod_duration,
		"value": mod_value,
		"tier": item.tier, # sets the extra SQL Injector bandwidth cost (MOD_BW_COST_BY_TIER)
	}

## Compiling's Mod process: one fill adds one hack. Equips the mod on the first fill (needs a free slot),
## then extends it up to <cap> hacks; a stronger value (Mod Tuning) replaces a weaker one.
## Returns the mod's hacks after the fill, or 0 when it couldn't be added (no slot).
func extend_mod(item, value_mult: float, cap: int) -> int: # item: ItemData (untyped: ItemData refers to HackingMods)
	var mod = item.hacking_mod_type
	var value = item.hacking_mod_value * value_mult
	if !current_mods.has(mod):
		if at_max_mods():
			return 0
		current_mods[mod] = {"duration": 1, "value": value, "tier": item.tier}
	else:
		var m = current_mods[mod]
		m.duration = min(max(int(m.duration), cap), int(m.duration) + 1)
		m.value = max(float(m.value), value)
	return int(current_mods[mod].duration) # (the caller marks the save dirty: SaveManager here would be a cyclic reference)

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
