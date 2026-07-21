extends Node

signal basic_cycle_completed
signal cred_cycle_complete
signal quality_cycle_completed
signal xp_gained
signal parsing_level_up_signal

# When the player earns the bonus
var bonus_expires_at: int #defrag bonus
var vm_token = Items.VM_PARSING_TOKEN
@onready var MAX_VMS = process_upgrades["vm windows"]["amount"]
@onready var VM_UPTIME = process_upgrades["vm duration"]["amount"]
var CURRENT_VMS = 0

var terminal_scene = preload("res://scenes/log_parsing_terminal.tscn")
var vm_window = preload("res://scenes/vm_window.tscn")

#GENERAL MODULE DATA
var SKILL = {
	"name": "Parsing",
	"level": 1,
	"experience": 0,
	"color": Color("#7F77DD"),
	"level up signal": parsing_level_up_signal,
	"efficiency description": "Increases chance of finding a resource per row."
}

var LOGS = {
	"name": "Basic",
	"tier name": "TIER I | LOGS",
	"level": 1,
	"experience": 0,
	"experience per level": 200,
	"command": "parse -logs",
	"efficiency": 0.05,
	"efficiency rate": 0.0012,
	"unlocked": true,
	"unlock level": 1,
	"base speed": 0.4,
	"overclock speed": 0.1,
	"overheat speed": 3.0,
	"heat": 3,
	"overclock heat": 3,
	"overheat heat": 1,
	"requirements": Items.LOGS,
	"item pool": [
		{ "item": Items.USERNAMES, "min": 1, "max": 1, "weight": 45 },
		{ "item": Items.ENCRYPTED_PASSWORDS, "min": 1, "max": 1, "weight": 45 },
		{ "item": Items.PACKET_SPOOF, "min": 1, "max": 1, "weight": 5 },
		{ "item": Items.SQL_INJECTOR, "min": 1, "max": 1, "weight": 5 },
	],
	"description": "Parses through logs for a chance to gain random resources. Requires Logs.",
	"efficiency description": "Increases chance of finding a resource per row.",
	"signal": basic_cycle_completed
}

var QUALITY_LOGS = {
	"name": "Quality",
	"tier name": "TIER I | LOGS",
	"level": 1,
	"experience": 0,
	"experience per level": 200,
	"command": "parse -quality",
	"efficiency": 0.05,
	"efficiency rate": 0.0012,
	"unlocked": false,
	"unlock level": 15,
	"base speed": 0.8,
	"overclock speed": 0.25,
	"overheat speed": 3.0,
	"heat": 4,
	"overclock heat": 5,
	"overheat heat": 1,
	"requirements": Items.QUALITY_LOGS,
	"item pool": [
		{ "item": Items.DATA, "min": 40, "max": 60, "weight": 15 },
		{ "item": Items.ENCRYPTED_PINS, "min": 1, "max": 1, "weight": 35  },
		{ "item": Items.ACCOUNT_NUMBERS, "min": 1, "max": 1, "weight": 35  },
		{ "item": Items.SQL_INJECTOR, "min": 1, "max": 1, "weight": 15  },
	],
	"description": "Parses through logs for a chance to gain random resources. Requires Logs.",
	"efficiency description": "Increases chance of finding a resource per row.",
	"signal": quality_cycle_completed
}

var CRED_LOGS = {
	"name": "Credential",
	"tier name": "TIER I | LOGS",
	"level": 1,
	"experience": 0,
	"experience per level": 200,
	"command": "parse -cred",
	"efficiency": 0.05,
	"efficiency rate": 0.01,
	"unlocked": false,
	"unlock level": 30,
	"base speed": 0.8,
	"overclock speed": 0.2,
	"overheat speed": 5.0,
	"heat": 3,
	"overclock heat": 4,
	"overheat heat": 1,
	"requirements": Items.LOGS,
	"item pool": [
		{ "item": Items.CREDENTIALS, "min": 40, "max": 130, "weight": 30 },
		{ "item": Items.ACCOUNT_ACCESS_TOKENS, "min": 1, "max": 1, "weight": 30  },
		{ "item": Items.IP_ADDRESS, "min": 1, "max": 1, "weight": 30  },
		{ "item": Items.DDOS, "min": 1, "max": 1, "weight": 10  },
	],
	"description": "Parses through logs for a chance to gain random resources. Requires Logs.",
	"efficiency description": "Increases chance of finding a resource per row.",
	"signal": cred_cycle_complete
}

var minor_processes = [
	LOGS,
	QUALITY_LOGS,
	CRED_LOGS
]

func signal_exp(_amount: int):
	xp_gained.emit()

func add_xp(amount: int, type: Dictionary):
	SKILL["experience"] += amount
	type["experience"] += amount

var process_upgrades = {
	"speed": { "id": 1, "name": "Speed", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	"efficiency": { "id": 2, "name": "Efficiency", "level": 0, "amount": 0.0, "increase per level": 0.15 },
	"experience": { "id": 3, "name": "Experience", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	"offline": { "id": 4, "name": "Offline progression", "level": 0, "amount": 0, "increase per level": 60 },
	"vm windows": { "id": 5, "name": "VM Windows", "level": 0, "amount": 1, "increase per level": 1 },
	"vm duration": { "id": 6, "name": "VM Duration", "level": 0, "amount": 30.0, "increase per level": 30.0 },
}

func get_upgrade_cost(upgrade_stat: String) -> int:
	return process_upgrades[upgrade_stat]["level"] * 800 + 100

func upgraded(upgrade_stat: Dictionary):
	upgrade_stat["level"] += 1
	upgrade_stat["amount"] += upgrade_stat["increase per level"]
	
	if upgrade_stat["name"].to_lower() == "vm windows":
		MAX_VMS += upgrade_stat["increase per level"]
	if upgrade_stat["name"].to_lower() == "vm duration":
		VM_UPTIME += upgrade_stat["increase per level"]

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

func create_vm_window(minor_process, repeat) -> Window:
	var content_instance = terminal_scene.instantiate()
	var new_window = vm_window.instantiate()
	new_window.title = SKILL.name + " | " + minor_process.name + " | Tokens used: " + str(1)
	new_window.wrap_controls = true
	new_window.repeat = repeat
	
	new_window.set_repeat(repeat)
	new_window.set_time(VM_UPTIME)
	new_window.set_token(vm_token)
	new_window.set_processes(Parsing, minor_process)
	
	new_window.add_child(content_instance)
	
	new_window.size = content_instance.size
	new_window.min_size = content_instance.size
	
	new_window.close_requested.connect(func(): 
		CURRENT_VMS -= 1
		new_window.queue_free()
	)
	new_window.about_to_popup.connect(func(): 
		content_instance.set_parse_type(minor_process, true)
		content_instance.start()
	)
	CURRENT_VMS += 1
	return new_window


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
