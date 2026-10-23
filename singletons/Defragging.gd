extends Node

signal on_cooldown_signal #used to trigger HUD countdown in defragging view

#GENERAL MODULE DATA
var SKILL = {
	"name": "Defragging",
	"color": Color("#EF4444"),
	"cooldown": 0,
	"command": "cd defragging"
}

## Defragging grants short system-wide boosts (one at a time: they share the cooldown).
## Each process: "bonus time" minutes, its effect read through the get_*() helpers below.
## "expires_at" is the unix time the boost ends (saved). Defragging costs no items; the shared cooldown is the limit.
var COOLING = {
	"name": "Cooling",
	"unlocked": true,
	"requirements": {}, # free (2026-10-22: no item cost)
	"color": Color("#4ec9b0"),
	"bonus time": 10,
	"bonus cooling": 0.5, # extra °C cooled per second
	"bonus label": "+0.5°C/s",
	"bonus text": "Cooling increased by 0.5°C per second",
	"description": "System cooling increased by 0.5°C/s.",
	"command": "defrag -cooling",
	"expires_at": 0,
}

var VM = {
	"name": "VM",
	"unlocked": true,
	"requirements": {}, # free (2026-10-22: no item cost)
	"color": Color("#7aa2f7"),
	"bonus time": 10,
	"bonus vm uptime": 30.0, # extra seconds per VM token (30 -> 60)
	"bonus label": "+30s/tok",
	"bonus text": "VM tokens last an additional 30 seconds",
	"description": "Each VM token runs 30 seconds longer.",
	"command": "defrag -vm",
	"expires_at": 0,
}

var UPLOAD = {
	"name": "Upload",
	"unlocked": true,
	"requirements": {}, # free (2026-10-22: no item cost)
	"color": Color("#e0c068"),
	"bonus time": 10,
	"bonus upload speed": 0.2, # uploads take 20% less time
	"bonus label": "-20% time",
	"bonus text": "Uploads 20% faster",
	"description": "Uploads are 20% faster.",
	"command": "defrag -upload",
	"expires_at": 0,
}

var HEAT = {
	"name": "Heat",
	"unlocked": true,
	"requirements": {}, # free (2026-10-22: no item cost)
	"color": Color("#ef8a5a"),
	"bonus time": 10,
	"bonus heat reduction": 0.2, # percent removed from every heat gain (20%)
	"bonus label": "-20% heat",
	"bonus text": "All heat applications reduced by 20%",
	"description": "Every time heat is added to the system, it's reduced by 20%.",
	"command": "defrag -heat",
	"expires_at": 0,
}

var minor_processes = [COOLING, VM, UPLOAD, HEAT]

func is_active(process: Dictionary) -> bool:
	return Time.get_unix_time_from_system() < process.get("expires_at", 0)

func get_active() -> Array:
	return minor_processes.filter(func(p): return is_active(p))

func get_bonus_cooling() -> float:
	return COOLING["bonus cooling"] if is_active(COOLING) else 0.0

func get_vm_uptime_bonus() -> float:
	return VM["bonus vm uptime"] if is_active(VM) else 0.0

func get_upload_time_multiplier() -> float:
	return 1.0 - UPLOAD["bonus upload speed"] if is_active(UPLOAD) else 1.0

func get_heat_reduction() -> float:
	return HEAT["bonus heat reduction"] if is_active(HEAT) else 0.0

func add_xp(amount: int, _type: Dictionary):
	SKILL["experience"] += amount


func has_requirements(skill: Dictionary):
	if skill.get("requirements", {}).is_empty():
		return true
	var item = skill["requirements"]["item"]
	var amount = skill["requirements"]["amount"]
	if Inventory.get_amount(item) < amount:
		return false
	return true

## Shared cooldown: 40 min at v0.0, lowered by System's Defrag Cooldown upgrade (meets the boost duration at max).
func get_cooldown_minutes() -> float:
	return Upgrades.get_defrag_cooldown_minutes()

func activate_cooldown():
	SKILL["on cooldown"] = true
	var now = Time.get_unix_time_from_system()
	SKILL["cooldown"] = now + int(get_cooldown_minutes() * 60)
	on_cooldown_signal.emit()

## 0.0 right after defragging -> 1.0 when defragging is available again (header "charging" bar).
func get_cooldown_progress() -> float:
	if !on_cooldown():
		return 1.0
	var remaining = SKILL["cooldown"] - Time.get_unix_time_from_system()
	return clamp(1.0 - remaining / (get_cooldown_minutes() * 60.0), 0.0, 1.0)

func on_cooldown() -> bool:
	return Time.get_unix_time_from_system() < SKILL["cooldown"]

func get_cd_time_remaining(time) -> int:
	return max(0, time - Time.get_unix_time_from_system())

func get_cd_time_text() -> String:
	var remaining = get_cd_time_remaining(SKILL["cooldown"])

	var minutes = remaining / 60
	var seconds = remaining % 60

	return "%02d:%02d" % [minutes, seconds]


func save_data() -> Dictionary:
	var boosts := {}
	for p in minor_processes:
		boosts[p.name.to_lower()] = {"unlocked": p.unlocked, "expires_at": p.expires_at}
	return {
		"skill": {
			"experience": SKILL.get("experience", 0),
			"level": SKILL.get("level", 1),
			"cooldown": SKILL.get("cooldown", 0),
			"on cooldown": SKILL.get("on cooldown", false)
		},
		"boosts": boosts,
	}

func load_data(data: Dictionary):
	if data.has("skill"):
		var skill_data = data["skill"]
		SKILL["experience"] = skill_data.get("experience", 0)
		SKILL["level"] = skill_data.get("level", 1)
		SKILL["cooldown"] = skill_data.get("cooldown", 0)
		SKILL["on cooldown"] = skill_data.get("on cooldown", false)
	var boosts: Dictionary = data.get("boosts", {})
	for p in minor_processes:
		var b: Dictionary = boosts.get(p.name.to_lower(), {})
		p["unlocked"] = bool(b.get("unlocked", p.unlocked))
		p["expires_at"] = int(b.get("expires_at", 0))
