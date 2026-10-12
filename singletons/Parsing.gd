extends Node

signal basic_cycle_completed
signal cred_cycle_complete
signal quality_cycle_completed
signal xp_gained
signal parsing_level_up_signal

# When the player earns the bonus
var bonus_expires_at: int #defrag bonus
var vm_token = Items.VM_PARSING_TOKEN
@onready var MAX_VMS = 7
@onready var VM_UPTIME = 30.0
var CURRENT_VMS = 0

var terminal_scene = preload("res://scenes/log_parsing_terminal.tscn")
var vm_window = preload("res://scenes/vm_window.tscn")

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
# From Cache: Much higher chance to find items in cache, but 25% chance to destroy cache after each its found.
#Tier III
#Network -
# From Mining Item: small chance to find Compiled payload of that tier
# From Cache Item: if cache contains VM Tokens, double the amount found.
#Tier IV
#Extraction -
# From Mining Item: take additional argument to start, looks for that specific item
# From Cache Item: Student Cache > Student Cache (Extraction) : If a rare item is decoded, find 4 additional copies

var FOOTPRINT = {
	"name": "Footprint",
	"tier name": "TIER I | LOGS",
	"level": 1,
	"experience": 0,
	"experience per level": 10,
	"command": "parse -footprint",
	"display command": "parse -footprint=<item>",
	"example commands": [
		{ 'cmd': 'parse -footprint=logs', 'description': 'Mining item' },
		{ 'cmd': 'parse -footprint=student cache', 'description': 'Cache item' },
		{ 'cmd': 'parse -footprint=logs, student cache', 'description': 'Queueing up multiple items' },
	],
	"ssh command": "ssh parsing footprint",
	"efficiency": 0.15,
	"efficiency rate": 0.0012,
	"unlocked": true,
	"unlock level": 1,
	"base speed": 0.4,
	"overclock speed": 0.1,
	"overheat speed": 3.0,
	"heat": 0.6,
	"overclock heat": 0.8,
	"overheat heat": 0.3,
	"requirements": "[color="+Mining.SKILL.color.to_html()+"]Mining[/color] resource x1 | Cache x1",
	"resource gained": "Dependent on <item> parsed. Use 'ls <item>' to view resources that can be parsed out. [color=#666666]ex. ls logs[/color]",
	"description": "Parses through any resource gained from [color="+Mining.SKILL.color.to_html()+"]Mining[/color] for a chance at resources contained within. If used on a Cache it will transform it to a Footprint variant, doubling basic resources gained but removing any chance at finding the rare upgrade material inside the cache.",
	"efficiency description": "Increases chance of finding a resource per row.",
	"signal": basic_cycle_completed
}

var CORRUPTION = {
	"name": "Corruption",
	"tier name": "TIER II | CORRUPTION",
	"level": 1,
	"experience": 0,
	"experience per level": 200,
	"command": "parse -corruption",
	"efficiency": 0.15,
	"efficiency rate": 0.0012,
	"unlocked": false,
	"unlock level": 25,
	"base speed": 0.4,
	"overclock speed": 0.1,
	"overheat speed": 3.0,
	"heat": 0.6,
	"overclock heat": 0.8,
	"overheat heat": 0.3,
	"requirements": "???",
	"resource gained": "Dependent on <item> parsed. Use 'ls <item>' to view resources that can be parsed out. [color=#666666]ex. ls logs[/color]",
	"description": "Parses through any resource gained from [color="+Mining.SKILL.color.to_html()+"]Mining[/color] for a chance at a hacking resources contained within. If used on a Cache it will transform it to a Corrupted variant, significantly increasing the chance of decoding an item but has a 25% chance to destroy the rest of the cache after each item decoded.",
	"efficiency description": "Increases chance of finding a resource per row.",
	"signal": basic_cycle_completed
}

var NETWORK = {
	"name": "Network",
	"tier name": "TIER III | NETWORK",
	"level": 1,
	"experience": 0,
	"experience per level": 200,
	"command": "parse -network",
	"efficiency": 0.15,
	"efficiency rate": 0.0012,
	"unlocked": false,
	"unlock level": 45,
	"base speed": 0.4,
	"overclock speed": 0.1,
	"overheat speed": 3.0,
	"heat": 0.6,
	"overclock heat": 0.8,
	"overheat heat": 0.3,
	"requirements": "???",
	"resource gained": "Dependent on <item> parsed. Use 'ls <item>' to view resources that can be parsed out. [color=#666666]ex. ls logs[/color]",
	"description": "Parses through any resource gained from [color="+Mining.SKILL.color.to_html()+"]Mining[/color] for a small chance at finding VM tokens. If used on a Cache it will transform it to a Network variant, doubling all VM tokens found within.",
	"efficiency description": "Increases chance of finding a resource per row.",
	"signal": basic_cycle_completed
}

var EXTRACTION = {
	"name": "Extraction",
	"tier name": "TIER IV | EXTRACTION",
	"level": 1,
	"experience": 0,
	"experience per level": 200,
	"command": "parse -extraction",
	"efficiency": 0.15,
	"efficiency rate": 0.0012,
	"unlocked": false,
	"unlock level": 60,
	"base speed": 0.4,
	"overclock speed": 0.1,
	"overheat speed": 3.0,
	"heat": 0.6,
	"overclock heat": 0.8,
	"overheat heat": 0.3,
	"requirements": "???",
	"resource gained": "Dependent on <item> parsed. Use 'ls <item>' to view resources that can be parsed out. [color=#666666]ex. ls logs[/color]",
	"description": "Parses through any resource gained from [color="+Mining.SKILL.color.to_html()+"]Mining[/color] with an additional argument [target=username] to only find that resource. If used on a Cache it will transform it to a Extraction variant, giving 4 additional copies of the rare upgrade material, if decoded.",
	"efficiency description": "Increases chance of finding a resource per row.",
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
	var return_dictionary = { "valid": false, "items_to_parse": [], "message": "" }
	
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
	
	return_dictionary.valid = true
	return_dictionary.items_to_parse = parsable_items
	
	return return_dictionary

func get_cache_transform_target(process: Dictionary, cache: CacheData) -> CacheData:
	if process == FOOTPRINT and cache == Items.STUDENT_CACHE:
		#Inventory.remove_resource(Items.STUDENT_CACHE, 1)
		#Inventory.add_resource(Items.STUDENT_CACHE_FOOTPRINT, 1)
		return Items.STUDENT_CACHE_FOOTPRINT
	
	return null

func list_vm_commands() -> String:
	var first_col = 20
	var second_col = 30
	var return_text = ""
	#return_text += SKILL.name + "\n\n"
	return_text += '\nProcess' + " ".repeat(first_col - 'process'.length()) + 'Run command\n'
	return_text += "-".repeat(first_col + second_col) + "\n"
	for mp in minor_processes:
		if mp.unlocked:
			var run_command = "ssh " + Parsing.name.to_lower() + " " + mp.name.to_lower() + "=<item>"
			return_text += mp.name + " ".repeat(first_col - mp.name.length()) + run_command + " ".repeat(second_col - run_command.length()) + "\n"
		else:
			return_text += "[color=#666666]" + mp.name + " ".repeat(first_col - mp.name.length()) + "DEMO LOCKED[/color]\n"
	
	#return_text += " \n[color=#666666]usage: ssh parsing footprint=logs[/color]"
	return_text += " \n[color=#666666]tip: multiple items can be passed as long as they are comma seperated ex. ssh parsing footprint=logs, student cache[/color]"
	return return_text


func create_vm_window(minor_process, items_to_parse) -> Window:
	var content_instance = terminal_scene.instantiate()
	var new_window = vm_window.instantiate()
	new_window.title = SKILL.name + " | " + minor_process.name + " | Tokens used: " + str(1)
	new_window.wrap_controls = true
	new_window.repeat = true
	
	#new_window.set_cooling_reduction(VM_COOLING_REDUCTION)
	new_window.set_repeat(true)
	new_window.set_time(VM_UPTIME)
	new_window.set_token(vm_token)
	new_window.set_processes(Parsing, minor_process)
	new_window.add_child(content_instance)
	
	new_window.close_requested.connect(func(): 
		CURRENT_VMS -= 1
		Stats.CURRENT_ALL_VMS -= 1
		new_window.queue_free()
	)
	new_window.about_to_popup.connect(func(): 
		content_instance.set_parse_type(minor_process, items_to_parse, true)
		content_instance.begin()
	)
	CURRENT_VMS += 1
	Stats.CURRENT_ALL_VMS += 1
	return new_window


func save_data() -> Dictionary:
	return {
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
	FOOTPRINT["efficiency"] = float(data.get("footprint_efficiency", FOOTPRINT["efficiency"]))


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
