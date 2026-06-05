extends Node

signal basic_cycle_completed
signal cred_cycle_complete

# When the player earns the bonus
var bonus_expires_at: int

func grant_bonus():
	var now = Time.get_unix_time_from_system()
	bonus_expires_at = now + (30 * 60) # 30 minutes from now

func has_bonus() -> bool:
	return Time.get_unix_time_from_system() < bonus_expires_at

func get_bonus_time_remaining() -> int:
	return max(0, bonus_expires_at - Time.get_unix_time_from_system())

func get_bonus_time_text() -> String:
	var remaining = get_bonus_time_remaining()

	var minutes = remaining / 60
	var seconds = remaining % 60

	return "%02d:%02d" % [minutes, seconds]

#GENERAL MODULE DATA
var SKILL = {
	"name": "Parsing",
	"level": 1,
	"experience": 0,
	"color": Color("#7F77DD")
}

var LOGS = {
	"name": "Basic",
	"tier name": "TIER I | LOGS",
	"level": 1,
	"experience": 0,
	"experience per level": 200,
	"command": "data-mining",
	"efficiency": 0.05,
	"efficiency rate": 0.0012,
	"unlocked": true,
	"base speed": 0.4,
	"overclock speed": 0.1,
	"overheat speed": 3.0,
	"heat": 3,
	"overclock heat": 3,
	"overheat heat": 1,
	"requirements": Items.LOGS,
	"item pool": [
		{ "item": Items.DATA, "min": 5, "max": 25 },
		{ "item": Items.ENCRYPTED_PASSWORDS, "min": 1, "max": 2 },
		{ "item": Items.ENCRYPTED_PINS, "min": 1, "max": 2 },
		{ "item": Items.REFRESH_TOKEN, "min": 1, "max": 2 },
	],
	"description": "Parses through logs for a chance to gain random resources. Requires Logs.",
	"efficiency description": "Increases chance of finding a resource per row.",
	"signal": basic_cycle_completed
}

var CRED_LOGS = {
	"name": "Credential",
	"tier name": "TIER I | LOGS",
	"level": 1,
	"experience": 0,
	"experience per level": 200,
	"command": "data-mining",
	"efficiency": 0.05,
	"efficiency rate": 0.01,
	"unlocked": true,
	"base speed": 0.8,
	"overclock speed": 0.2,
	"overheat speed": 5.0,
	"heat": 3,
	"overclock heat": 4,
	"overheat heat": 1,
	"requirements": Items.LOGS,
	"item pool": [
		{ "item": Items.USERNAMES, "min": 1, "max": 2 },
		{ "item": Items.PINS, "min": 1, "max": 2 },
		{ "item": Items.ACCOUNT_NUMBERS, "min": 1, "max": 2 },
		{ "item": Items.PASSWORDS, "min": 1, "max": 2 },
	],
	"description": "Parses through logs for a chance to gain random resources. Requires Logs.",
	"efficiency description": "Increases chance of finding a resource per row.",
	"signal": cred_cycle_complete
}

var minor_processes = [
	LOGS,
	CRED_LOGS
]

func add_xp(amount: int, type: Dictionary):
	SKILL["experience"] += amount
	type["experience"] += amount

var process_upgrades = {
	"speed": { "id": 1, "name": "Speed", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	"efficiency": { "id": 2, "name": "Efficiency", "level": 0, "amount": 1.0, "increase per level": 0.15 },
	"experience": { "id": 3, "name": "Experience", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	"offline": { "id": 4, "name": "Offline progression", "level": 0, "amount": 0, "increase per level": 60 },
}

func get_upgrade_cost(upgrade_stat: String) -> int:
	return process_upgrades[upgrade_stat]["level"] * 800 + 100

func upgraded(upgrade_stat: Dictionary):
	upgrade_stat["level"] += 1
	upgrade_stat["amount"] += upgrade_stat["increase per level"]

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
