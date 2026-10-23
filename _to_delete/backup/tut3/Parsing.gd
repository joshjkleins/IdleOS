extends Node

## Heat plan: heat multiplier by the tier being worked on (see BaseTerminal.heat_tier_mult)
const HEAT_BY_TIER := [0.667, 1.067, 1.702, 2.55, 6.222, 9.375]
## Pace plan: higher-tier Mining items are harder data, offsetting the earlier tiers' Parsing upgrades so every tier
## arrives at the same pace: Footprint / Extraction lines (the payload chain) take longer (incl. the 1.5x-per-tier base
## slowdown every skill has) and find less often. Corruption / Network and caches aren't affected. (tools/balance/pace_calibrate.py)
const TIME_BY_TIER := [1.0, 1.4712, 2.1729, 3.4399, 6.2133, 11.3498]
const FIND_BY_TIER := [1.0, 0.4913, 0.2989, 0.1934, 0.1368, 0.0995]

func item_time_mult(process: Dictionary, item: ItemData) -> float:
	if item == null or item is CacheData or !(process == FOOTPRINT or process == EXTRACTION):
		return 1.0
	return Stats.tier_heat(TIME_BY_TIER, item.tier)

func item_find_mult(process: Dictionary, item: ItemData) -> float:
	if item == null or item is CacheData or !(process == FOOTPRINT or process == EXTRACTION):
		return 1.0
	return Stats.tier_heat(FIND_BY_TIER, item.tier)

signal basic_cycle_completed
signal cred_cycle_complete
signal quality_cycle_completed
signal xp_gained
signal parsing_level_up_signal

# When the player earns the bonus
var bonus_expires_at: int #defrag bonus
var vm_token = Items.VM_PARSING_TOKEN
@onready var MAX_VMS = 7
@onready var VM_UPTIME = 60.0

## Modifier commands unlocked by Parsing capstones (see Mining.MODIFIERS for how they work).
const MODIFIERS = [
	{"command": "plaintext", "name": "Plaintext", "package": "parsing.plaintext", "speed": 0.5, "heat": 1.5,
		"effect": "-50% speed, heat x1.5. Each encrypted find has a 10% chance to come out already cracked."},
	{"command": "deep-read", "name": "Deep Read", "package": "parsing.deep_read", "speed": 0.6, "heat": 2.0,
		"effect": "-40% speed, heat x2. Line find chance x2 (not Network finds) and VM token chance x2."},
	{"command": "survey", "name": "Survey", "package": "parsing.survey", "speed": 1.0, "heat": 1.0,
		"effect": "Half finds, +100% Parsing XP."},
]
const PLAINTEXT_CHANCE := 0.10
## Cold Cache: overclock and the modifiers add no extra heat
const COOL_PACKAGE := "parsing.cold_cache"

## the cracked item an encrypted item becomes (Encrypted passwords -> Passwords), or null
func cracked_version(item: ItemData) -> ItemData:
	for p in Cracking.minor_processes:
		var req = p.get("requirements", {})
		if req is Dictionary and req.has(item):
			return p["resource gained"]
	return null
var CURRENT_VMS = 0

var terminal_scene = preload("res://scenes/log_parsing_terminal.tscn")

#GENERAL MODULE DATA
var SKILL = {
	"name": "Parsing",
	"level": 1,
	"experience": 0,
	"color": Color("#EC4899"),
	"level up signal": parsing_level_up_signal,
	"efficiency description": "Increases chance of finding a resource per row.",
	"command": "cd parsing",
	"sfx": "parsing_item_received"
}

#TIER I
#Footprint - 
# From Mining Item: chance for 1 of 5 items (typically related to all other Skills to be used)
# From Cache: changes type from Student Cache to Student Cache (footprint) - Doubles IP address, username, encrypted password, password found in caches
#TIER II
#Corruption -
# From Mining Item: small chance for hacking items (SQL injectors, packet spoof, hacking upgrade items)
# From Cache: Much higher chance to find items in cache, but 20% chance to destroy cache after each its found.
#Tier III
#Network -
# From Mining Item: small chance to find random VM token
# From Cache Item: caches now have a chance to find VM tokens
#Tier IV
#Extraction -
# From Mining Item: take additional argument to start, looks for that specific item
# From Cache Item: Student Cache > Student Cache (Extraction) : If a rare item is decoded, find 4 additional copies


#footprint - doubles basic resources
#corruption - high chance of finding items, 25% chance to find nothing else
#Network - doubles VM tokens found
#Extraction - rare material x 4 (if found)

## Every process works on every Mining item and turns any base cache into its variant. They aren't
## upgrades of each other: Footprint feeds the main item chain, the rest are resource sinks for specific needs.
## Pacing follows Mining: each tier's line is 1.5x slower, tuned for +50% parsing speed per tier from upgrades.
## (A Mining item parses in 10 lines; "efficiency" is the chance per line.)
var FOOTPRINT = {
	"name": "Footprint",
	"tier name": "TIER I | FOOTPRINT",
	"level": 1,
	"experience": 0,
	"experience per level": 16, # xp per item parsed
	"command": "parse -footprint",
	"display command": "parse -footprint=<item>",
	"example commands": [
		{ 'cmd': 'parse -footprint=logs', 'description': 'Mining item' },
		{ 'cmd': 'parse -footprint=student cache', 'description': 'Cache item' },
		{ 'cmd': 'parse -footprint=logs, archives', 'description': 'Queueing up multiple items' },
	],
	"ssh command": "ssh parsing footprint",
	"efficiency": 0.15,
	"efficiency rate": 0.0012,
	"unlocked": true,
	"unlock level": 1,
	"base speed": 0.4,
	"overclock speed": 0.2,
	"overheat speed": 1.0,
	"heat": 0.6,
	"overclock heat": 0.8,
	"overheat heat": 0.3,
	"vm token chance": 0.01, # bonus parsing token per item parsed; scales with item length
	"requirements": "[color="+Mining.SKILL.color.to_html()+"]Mining[/color] resource x1 | Cache x1",
	"resource gained": "One of the items contained in <item>. Use 'ls <item>' to view them. [color=#666666]ex. ls logs[/color]",
	"description": "Parses through any resource gained from [color="+Mining.SKILL.color.to_html()+"]Mining[/color] for an equal chance at any item contained within. If used on a Cache it will transform it to a Footprint variant, doubling basic resources gained but removing any chance at finding the rare upgrade material inside the cache.",
	"efficiency description": "Chance to find an item per line.",
	"signal": basic_cycle_completed
}

var CORRUPTION = {
	"name": "Corruption",
	"tier name": "TIER II | CORRUPTION",
	"level": 1,
	"experience": 0,
	"experience per level": 37, # xp per item parsed
	"command": "parse -corruption",
	"display command": "parse -corruption=<item>",
	"example commands": [
		{ 'cmd': 'parse -corruption=logs', 'description': 'Mining item' },
		{ 'cmd': 'parse -corruption=student cache', 'description': 'Cache item' },
	],
	"ssh command": "ssh parsing corruption",
	"efficiency": 0.05,
	"efficiency rate": 0.001,
	"unlocked": false,
	"unlock level": 15,
	"base speed": 0.6,
	"overclock speed": 0.3,
	"overheat speed": 1.5,
	"heat": 0.9,
	"overclock heat": 1.2,
	"overheat heat": 0.45,
	"vm token chance": 0.015, # bonus parsing token per item parsed; scales with item length
	"requirements": "[color="+Mining.SKILL.color.to_html()+"]Mining[/color] resource x1 | Cache x1",
	"resource gained": "SQL Injector 60% | Packet Spoof 38% | Hacking Mod of the item's tier 2%",
	"description": "Corrupts any resource gained from [color="+Mining.SKILL.color.to_html()+"]Mining[/color] for a small chance at hacking resources: SQL Injectors (60%), Packet Spoofs (38%) or a random Hacking Mod of the item's tier (2%). Higher tier Mining items give +1% chance per line per tier. If used on a Cache it will transform it to a Corruption variant, significantly increasing the chance of decoding each item but with a chance to destroy the rest of the cache after each item decoded.",
	"efficiency description": "Chance to find a hacking resource per line.",
	"signal": basic_cycle_completed
}

var NETWORK = {
	"name": "Network",
	"tier name": "TIER III | NETWORK",
	"level": 1,
	"experience": 0,
	"experience per level": 83, # xp per item parsed
	"command": "parse -network",
	"display command": "parse -network=<item>",
	"example commands": [
		{ 'cmd': 'parse -network=logs', 'description': 'Mining item' },
		{ 'cmd': 'parse -network=student cache', 'description': 'Cache item' },
	],
	"ssh command": "ssh parsing network",
	# Network is a resource sink: ~0.5% per line at level 1, ~2.5% at 99, +1% from max upgrades, +0.3% per Mining tier
	# (Databases +1.5%) -> about 5% at the very top. Deep Read doesn't double these finds.
	"efficiency": 0.005,
	"efficiency rate": 0.0002,
	"efficiency upgrade scale": 0.05, # parsing efficiency upgrades count at 5% here (+1% at max)
	"unlocked": false,
	"unlock level": 35,
	"base speed": 0.9,
	"overclock speed": 0.45,
	"overheat speed": 2.25,
	"heat": 1.35,
	"overclock heat": 1.8,
	"overheat heat": 0.67,
	"vm token chance": 0.0225, # bonus parsing token per item parsed; scales with item length
	"requirements": "[color="+Mining.SKILL.color.to_html()+"]Mining[/color] resource x1 | Cache x1",
	"resource gained": "Random VM token (any skill), x Mining tier per find",
	"description": "Sniffs any resource gained from [color="+Mining.SKILL.color.to_html()+"]Mining[/color] for a small chance at a random VM token. Higher tier Mining items give +0.3% chance per line per tier. If used on a Cache it will transform it to a Network variant, giving it a chance to hold a stack of VM tokens.",
	"efficiency description": "Chance to find a VM token per line.",
	"signal": basic_cycle_completed
}

var EXTRACTION = {
	"name": "Extraction",
	"tier name": "TIER IV | EXTRACTION",
	"level": 1,
	"experience": 0,
	"experience per level": 149, # xp per item parsed
	"command": "parse -extraction",
	"display command": "parse -extraction=<item> target=<item>",
	"example commands": [
		{ 'cmd': 'parse -extraction=logs target=usernames', 'description': 'Only look for Usernames in Logs' },
		{ 'cmd': 'parse -extraction=logs, archives target=ip address', 'description': 'target must be inside every item listed' },
		{ 'cmd': 'parse -extraction=student cache', 'description': 'Cache item (no target needed)' },
	],
	"ssh command": "ssh parsing extraction",
	"efficiency": 0.08,
	"efficiency rate": 0.0008,
	"unlocked": false,
	"unlock level": 55,
	"base speed": 1.35,
	"overclock speed": 0.675,
	"overheat speed": 3.375,
	"heat": 2.02,
	"overclock heat": 2.7,
	"overheat heat": 1.01,
	"vm token chance": 0.0338, # bonus parsing token per item parsed; scales with item length
	"requirements": "[color="+Mining.SKILL.color.to_html()+"]Mining[/color] resource x1 | Cache x1",
	"resource gained": "Only the target item",
	"description": "Hunts through a [color="+Mining.SKILL.color.to_html()+"]Mining[/color] resource for one specific item you choose with target=<item> (use 'ls <item>' to see what it holds). If used on a Cache it will transform it to an Extraction variant, giving 4 additional copies of the rare upgrade material, if decoded.",
	"efficiency description": "Chance to find the target item per line.",
	"signal": basic_cycle_completed
}

var minor_processes = [
	FOOTPRINT,
	CORRUPTION,
	NETWORK,
	EXTRACTION
]

func signal_exp(_amount: int):
	xp_gained.emit()
	SaveManager.mark_dirty()

func add_xp(amount: int, type: Dictionary):
	SKILL["experience"] += amount
	type["experience"] += amount

#var process_upgrades = {
	#"speed": { "id": 1, "name": "Speed", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	#"efficiency": { "id": 2, "name": "Efficiency", "level": 0, "amount": 0.0, "increase per level": 0.15 },
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

func has_requirements(minor_process) -> bool:
	if Inventory.get_amount(minor_process["requirements"]) > 0:
		return true
	return false

func missing_requirements_text(minor_process) -> String:
	return "Missing " + minor_process["requirements"].name

func get_weighted_item(pool: Array) -> Dictionary:
	var total_weight = 0
	for item in pool:
		total_weight += item["weight"]
		
	var roll = randi_range(1, total_weight)
	for item in pool:
		roll -= item["weight"]
		if roll <= 0:
			return item
			
	return pool[0]

func filter_parsable_items(items_arr: Array[ItemData]) -> Array[ItemData]:
	var return_items: Array[ItemData] = []
	for item in items_arr:
		if item.parsable:
			return_items.append(item)
		
	return return_items

#Takes player command (parse -footprint=logs) and checks if item is legit, can be parsed, player has in inventory, and returns relavent message
func parse_through_parse_start_command(command: String, process: Dictionary) -> Dictionary:
	var return_dictionary = { "valid": false, "items_to_parse": [], "message": "", "target": null }
	
	#PARSE OUT ITEMS
	var items_string
	if command.begins_with('ssh'):
		items_string = command.trim_prefix(process['ssh command'])
	else:
		items_string = command.trim_prefix(process['command'])

	if !items_string.begins_with("="):
		if command.begins_with('ssh'):
			return_dictionary.message = "Command not recognized. [color=666666]example ssh parse command: ssh parsing footprint=logs[/color]"
		else:
			return_dictionary.message = "Command not recognized. [color=666666]example parse command: parse -footprint=logs[/color]"
		return return_dictionary
	
	#EXTRACTION: "parse -extraction=logs target=usernames"
	var target: ItemData = null
	var target_at = items_string.find(" target=")
	if target_at != -1:
		var target_name = items_string.substr(target_at + " target=".length())
		items_string = items_string.substr(0, target_at)
		if process != EXTRACTION:
			return_dictionary.message = "target= only works with Extraction."
			return return_dictionary
		target = Inventory.get_item_by_name(target_name)
		if target == null:
			return_dictionary.message = "Target item not found: " + target_name.strip_edges()
			return return_dictionary
	
	var items = items_string.trim_prefix("=").split(",")
	var items_arr: Array[ItemData] = []
	for item in items:
		var current_item = Inventory.get_item_by_name(item)
		if current_item != null:
			items_arr.append(current_item)
	
	#CHECK IF THEY PROVIDED ACTUAL ITEM
	if items_arr.is_empty():
		if command.begins_with('ssh'):
			return_dictionary.message = "Item not found. [color=666666]example ssh parse command: ssh parsing footprint=logs[/color]"
		else:
			return_dictionary.message = "Item not found. [color=666666]example parse command: parse -footprint=logs[/color]"
		return return_dictionary
	
	var parsable_items = filter_parsable_items(items_arr)
	
	#CHECK IF ITEM PROVIDED IS PARSABLE
	if parsable_items.is_empty():
		return_dictionary.message = "ERROR: items provided are not compatable with parsing."
		return return_dictionary
	
	#IF NOT ALL ITEMS ARE PARSABLE JUST REMOVE THOSE AND LET USER KNOW
	if items_arr != parsable_items:
		return_dictionary.message = "Not all items provided are compatable with parsing. \nWill parse the following items \n-------------------------------------------------------\n"
		for item in parsable_items:
			return_dictionary.message += item.name + "\n"
	
	#EXTRACTION needs a target that every Mining item listed actually contains (caches don't need one)
	if process == EXTRACTION:
		for item in parsable_items:
			if item is CacheData:
				continue
			if target == null:
				return_dictionary.message = "Extraction needs a target. [color=#666666]ex. parse -extraction=" + item.name.to_lower() + " target=" + item.contained_items[0].name.to_lower() + "[/color]"
				return return_dictionary
			if !item.contained_items.has(target):
				var names = item.contained_items.map(func(c): return c.name.to_lower())
				return_dictionary.message = item.name + " doesn't contain " + target.name + ". It holds: " + ", ".join(names)
				return return_dictionary
	
	return_dictionary.valid = true
	return_dictionary.items_to_parse = parsable_items
	return_dictionary.target = target
	
	return return_dictionary

#region drops
## Corruption's finds, weights out of 100. "item": null = a random Hacking Mod.
func get_corruption_pool() -> Array:
	return [
		{ "item": Items.SQL_INJECTOR, "weight": 60 },
		{ "item": Items.PACKET_SPOOF, "weight": 38 },
		{ "item": null, "weight": 2 },
	]

const CORRUPTION_TIER_BONUS = 0.01 # +1% chance per line for each Mining tier above Logs
const NETWORK_TIER_BONUS = 0.003 # +0.3% chance per line for each Mining tier above Logs

## Hacking mods Corruption can find in a Mining item of <tier>: that tier's mods. Until a tier has its
## own mods it falls back to the highest tier below it that has some (today only tier 1: SQL Booster).
func get_hacking_mod_items(tier: int = 0) -> Array:
	var by_tier := {}
	for item in Items.ITEM_MAP.values():
		if item and item.hacking_mod_item:
			by_tier.get_or_add(item.tier, []).append(item)
	if tier <= 0:
		var all := []
		for t in by_tier: all.append_array(by_tier[t])
		return all
	for t in range(tier, 0, -1):
		if by_tier.has(t):
			return by_tier[t]
	return []

func _pool_tier(pool: Array, fallback: int) -> int:
	return pool[0].tier if !pool.is_empty() else fallback

## Extra chance per line from the Mining item's tier (Corruption and Network).
func get_line_chance_bonus(process: Dictionary, item: ItemData) -> float:
	if item is CacheData:
		return 0.0
	if process == CORRUPTION:
		return CORRUPTION_TIER_BONUS * (item.tier - 1)
	if process == NETWORK:
		return NETWORK_TIER_BONUS * (item.tier - 1)
	return 0.0

## How many of the found item one successful line gives (always 1; tiers raise the chance instead).
func get_find_amount(_process: Dictionary, _item: ItemData) -> int:
	return 1

func get_vm_tokens() -> Array:
	return [Items.VM_MINING_TOKEN, Items.VM_PARSING_TOKEN, Items.VM_CRACKING_TOKEN, Items.VM_MATCHING_TOKEN,
		Items.VM_PHISHING_TOKEN, Items.VM_DECODING_TOKEN, Items.VM_COMPILING_TOKEN]

## What one successful line finds when <process> parses Mining item <item>.
func roll_find(process: Dictionary, item: ItemData, target: ItemData = null) -> ItemData:
	match process:
		CORRUPTION:
			var pick = get_weighted_item(get_corruption_pool())
			if pick.item == null:
				var mods = get_hacking_mod_items(item.tier)
				return mods.pick_random() if !mods.is_empty() else Items.SQL_INJECTOR
			return pick.item
		NETWORK:
			return get_vm_tokens().pick_random()
		EXTRACTION:
			return target
	return item.contained_items.pick_random()

## Rows for the terminal's "find" labels: [{ "name", "pct", "items" (counted for the totals row) }].
func get_find_table(process: Dictionary, item: ItemData, target: ItemData = null) -> Array:
	match process:
		CORRUPTION:
			return [
				{ "name": Items.SQL_INJECTOR.name, "pct": 60, "items": [Items.SQL_INJECTOR] },
				{ "name": Items.PACKET_SPOOF.name, "pct": 38, "items": [Items.PACKET_SPOOF] },
				{ "name": "Hacking Mod (T%d)" % _pool_tier(get_hacking_mod_items(item.tier), item.tier), "pct": 2, "items": get_hacking_mod_items(item.tier) },
			]
		NETWORK:
			# one row per token so the totals row shows exactly what the player has
			var rows := []
			for tok in get_vm_tokens():
				rows.append({ "name": tok.name.replace("VM ", "").replace(" token", ""), "pct": -1, "items": [tok] })
			return rows
		EXTRACTION:
			return [{ "name": target.name, "pct": 100, "items": [target] }]
	var rows := []
	for c in item.contained_items:
		rows.append({ "name": c.name, "pct": int(100.0 / item.contained_items.size()), "items": [c] })
	return rows
#endregion

#region cache variants
var _items_by_path := {}

## The variant this process turns a base cache into (student_cache -> student_cache_network), or null.
func get_cache_transform_target(process: Dictionary, cache: CacheData) -> CacheData:
	if cache == null or cache.get_variant() != CacheData.CacheVariant.BASE:
		return null
	if _items_by_path.is_empty():
		for it in Items.ITEM_MAP.values():
			if it:
				_items_by_path[it.resource_path] = it
	var path = cache.resource_path.trim_suffix(".tres") + "_" + str(process.name).to_lower() + ".tres"
	return _items_by_path.get(path)
#endregion

func list_vm_commands() -> String:
	var first_col = 20
	var second_col = 30
	var return_text = ""
	#return_text += SKILL.name + "\n\n"
	return_text += '\nProcess' + " ".repeat(first_col - 'process'.length()) + 'Run command\n'
	return_text += "-".repeat(first_col + second_col) + "\n"
	for mp in minor_processes:
		if mp.unlocked:
			var run_command = "ssh " + Parsing.name.to_lower() + " " + mp.name.to_lower() + "=<item>" + (" target=<item>" if mp == EXTRACTION else "")
			return_text += mp.name + " ".repeat(first_col - mp.name.length()) + run_command + " ".repeat(second_col - run_command.length()) + "\n"
		else:
			return_text += "[color=#666666]" + mp.name + " ".repeat(first_col - mp.name.length()) + "LOCKED (lvl %d)[/color]\n" % mp["unlock level"]
	
	#return_text += " \n[color=#666666]usage: ssh parsing footprint=logs[/color]"
	return_text += " \n[color=#666666]tip: multiple items can be passed as long as they are comma seperated ex. ssh parsing footprint=logs, student cache[/color]"
	return return_text


func create_vm_window(minor_process, items_to_parse, target: ItemData = null) -> VMWindow:
	var setup = func(t):
		t.set_parse_type(minor_process, items_to_parse, true, target)
		t.begin()
	return VMManager.open(self, minor_process, terminal_scene.instantiate(), setup, true)


func save_data() -> Dictionary:
	return {
		"processes": Exp.processes_save_data(self),
		"bonus_expires_at": bonus_expires_at,
		"skill_level": SKILL["level"],
		"skill_experience": SKILL["experience"],
		"footprint_level": FOOTPRINT["level"],
		"footprint_experience": FOOTPRINT["experience"],
		"footprint_efficiency": FOOTPRINT["efficiency"]
	}

func load_data(data: Dictionary) -> void:
	bonus_expires_at = int(data.get("bonus_expires_at", bonus_expires_at))
	SKILL["level"] = int(data.get("skill_level", SKILL["level"]))
	SKILL["experience"] = int(data.get("skill_experience", SKILL["experience"]))
	FOOTPRINT["level"] = int(data.get("footprint_level", FOOTPRINT["level"]))
	FOOTPRINT["experience"] = int(data.get("footprint_experience", FOOTPRINT["experience"]))
	# (legacy "<process>_efficiency" is ignored: efficiency is rebuilt from level in Exp.processes_load_data)
	Exp.processes_load_data(self, data.get("processes", {})) # all processes (legacy keys above cover old saves)


var LOG_LINES = [
	# ---------------- INFO ----------------
	{"level":"INFO","service":"auth.service","message":"Login attempt from 172.16.4.23","tags":[]},
	{"level":"INFO","service":"auth.service","message":"Login success user=guest","tags":[]},
	{"level":"INFO","service":"api.gateway","message":"Request GET /status 200","tags":[]},
	{"level":"INFO","service":"api.gateway","message":"Request POST /login 401","tags":[]},
	{"level":"INFO","service":"db.cluster","message":"Query executed in 42ms","tags":[]},
	{"level":"INFO","service":"cache.node","message":"Cache miss key=user_profile_221","tags":[]},
	{"level":"INFO","service":"lambda.exec","message":"Cold start detected","tags":[]},
	{"level":"INFO","service":"s3.bucket","message":"Object read logs/2024-09-21.gz","tags":[]},
	{"level":"INFO","service":"net.router","message":"DHCP lease assigned 10.0.0.82","tags":[]},
	{"level":"INFO","service":"sys.monitor","message":"CPU usage 38%","tags":[]},
	{"level":"INFO","service":"container.docker","message":"Container redis restarted","tags":[]},
	{"level":"INFO","service":"tls.handler","message":"TLS handshake completed","tags":[]},
	{"level":"INFO","service":"email.service","message":"Outbound mail queued","tags":[]},
	{"level":"INFO","service":"firewall","message":"Allowed outbound 443","tags":[]},
	{"level":"INFO","service":"cdn.edge","message":"Edge node latency 21ms","tags":[]},
	{"level":"INFO","service":"metrics.agent","message":"Heartbeat sent","tags":[]},
	{"level":"INFO","service":"backup.agent","message":"Snapshot created","tags":[]},
	{"level":"INFO","service":"k8s.node","message":"Node worker-3 ready","tags":[]},
	{"level":"INFO","service":"queue.worker","message":"Job 88342 processed","tags":[]},
	{"level":"INFO","service":"proxy.edge","message":"Upstream response 304","tags":[]},

	# ---------------- WARN ----------------
	{"level":"WARN","service":"auth.service","message":"Multiple failed logins user=admin","tags":["suspicious"]},
	{"level":"WARN","service":"api.gateway","message":"Rate limit exceeded 192.168.2.14","tags":["suspicious"]},
	{"level":"WARN","service":"db.cluster","message":"Slow query detected 812ms","tags":["suspicious"]},
	{"level":"WARN","service":"firewall","message":"Port scan suspected from 185.22.91.7","tags":["suspicious","ip"]},
	{"level":"WARN","service":"tls.handler","message":"Self-signed certificate detected","tags":["suspicious"]},
	{"level":"WARN","service":"container.docker","message":"Container api_server exited unexpectedly","tags":["suspicious"]},
	{"level":"WARN","service":"sys.monitor","message":"CPU spike 91%","tags":["suspicious"]},
	{"level":"WARN","service":"backup.agent","message":"Snapshot integrity check failed","tags":["suspicious"]},
	{"level":"WARN","service":"queue.worker","message":"Job retry limit approaching id=9912","tags":["suspicious"]},

	# ---------------- ALERT ----------------
	{"level":"ALERT","service":"auth.service","message":"Password hash exposed in debug log","tags":["password","high_value"]},
	{"level":"ALERT","service":"auth.service","message":"Privilege escalation attempt user=guest","tags":["username","high_value"]},
	{"level":"ALERT","service":"db.cluster","message":"Unauthorized SELECT on users table","tags":["data","high_value"]},
	{"level":"ALERT","service":"api.gateway","message":"API key leaked in query string","tags":["key","high_value"]},
	{"level":"ALERT","service":"s3.bucket","message":"Public read enabled on bucket backups","tags":["data"]},
	{"level":"ALERT","service":"firewall","message":"Inbound SSH allowed from 0.0.0.0","tags":["ip","high_value"]},
	{"level":"ALERT","service":"tls.handler","message":"Private key material logged","tags":["key","high_value"]},
	{"level":"ALERT","service":"proxy.edge","message":"Session token observed in URL","tags":["token","high_value"]},
	{"level":"ALERT","service":"container.docker","message":"Container running as root","tags":["suspicious"]},
	{"level":"ALERT","service":"backup.agent","message":"Backup archive contains credentials","tags":["password","data","high_value"]},
	{"level":"ALERT","service":"config.loader","message":"Hardcoded API secret detected","tags":["key","high_value"]},
	{"level":"ALERT","service":"sys.monitor","message":"Root shell spawned pid=8821","tags":["high_value"]},

	# ---------------- ENCRYPTED ----------------
	{"level":"INFO","service":"vault.service","message":"Encrypted blob retrieved id=a8F2kL9","tags":["encrypted"]},
	{"level":"INFO","service":"kms.handler","message":"Envelope key generated","tags":["encrypted","key"]},
	{"level":"INFO","service":"tls.handler","message":"Encrypted session ticket issued","tags":["encrypted","token"]},
	{"level":"INFO","service":"backup.agent","message":"Archive encrypted AES256","tags":["encrypted"]},

	# ---------------- CORRUPTED ----------------
	{"level":"ERR","service":"parser.core","message":"Malformed entry unexpected token","tags":["corrupted"]},
	{"level":"ERR","service":"net.capture","message":"Packet decode failed","tags":["corrupted"]},
	{"level":"ERR","service":"disk.reader","message":"Sector read error retrying","tags":["corrupted"]},
	{"level":"ERR","service":"archive.reader","message":"Gzip footer mismatch","tags":["corrupted"]}
]
