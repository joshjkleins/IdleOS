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
	"unlocked": false,
	"unlock tier": 5, # 2026-10-31: was 3
	"requirements": {}, # free (2026-10-22: no item cost)
	"color": Color("#4ec9b0"),
	"bonus time": 10,
	"bonus cooling mult": 3.0, # 2026-10-31: x3 (was x2; 2026-10-30: was +0.5°C/s)
	"bonus label": "x3 cooling",
	"bonus text": "System cooling tripled",
	"description": "System cooling is tripled (every cooling source, upgrades included).",
	"command": "defrag -cooling",
	"expires_at": 0,
}

var VM = {
	"name": "VM",
	"unlocked": true,
	"unlock tier": 1, # 2026-10-31: order VM T1, Sync T2, (none at Hospital), Upload T4, Cooling T5, XP T6
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
	"unlocked": false,
	"unlock tier": 4, # 2026-10-31: was 2
	"requirements": {}, # free (2026-10-22: no item cost)
	"color": Color("#e0c068"),
	"bonus time": 10,
	"bonus upload speed": 1.0, # +100% upload speed: each item takes half the time (2026-10-26: was 20%)
	"bonus label": "x2 speed",
	"bonus text": "Uploads 100% faster",
	"description": "Uploads are 100% faster.",
	"command": "defrag -upload",
	"expires_at": 0,
}

var HEAT = { # 2026-10-31: Sync (was Heat, -20% heat - far weaker than Cooling's x2). The var keeps its name.
	"name": "Sync",
	"unlocked": false,
	"unlock tier": 2, # 2026-10-31: was 4 (as Heat)
	"requirements": {}, # free (2026-10-22: no item cost)
	"color": Color("#ef8a5a"),
	"bonus time": 10,
	"bonus label": "sync",
	"bonus text": "VMs running your main process share its overclock, without extra heat",
	"description": "VMs running the same process as your main terminal inherit its overclock status while producing no extra heat.",
	"command": "defrag -sync",
	"expires_at": 0,
}


## 2026-10-26: Police's Defrag process; 2026-10-30: moved to Government (Police Station gets a new one)
var XP = {
	"name": "XP",
	"unlocked": false,
	"unlock tier": 6,
	"requirements": {},
	"color": Color("#c084fc"),
	"bonus time": 10,
	"bonus xp": 0.5, # +50% skill XP from every process
	"bonus label": "+50% XP",
	"bonus text": "Skill XP increased by 50%",
	"description": "Every process gives 50% more skill XP.",
	"command": "defrag -xp",
	"expires_at": 0,
}

var minor_processes = [VM, HEAT, UPLOAD, COOLING, XP] # in unlock order (HEAT = Sync)

func is_active(process: Dictionary) -> bool:
	return Time.get_unix_time_from_system() < process.get("expires_at", 0)

func get_active() -> Array:
	return minor_processes.filter(func(p): return is_active(p))

## system cooling multiplier while Cooling runs (2026-10-30: x2, was a flat +0.5°C/s)
func get_cooling_mult() -> float:
	return float(COOLING["bonus cooling mult"]) if is_active(COOLING) else 1.0

func get_vm_uptime_bonus() -> float:
	return VM["bonus vm uptime"] if is_active(VM) else 0.0

func get_upload_time_multiplier() -> float:
	return 1.0 / (1.0 + UPLOAD["bonus upload speed"]) if is_active(UPLOAD) else 1.0

func get_xp_multiplier() -> float:
	return 1.0 + XP["bonus xp"] if is_active(XP) else 1.0

## unlocks follow the tiers (Exp.refresh_all_process_unlocks), never the save
func refresh_unlocks() -> void:
	for p in minor_processes:
		p["unlocked"] = Upgrades.tier_unlocked(int(p.get("unlock tier", 1)))

func get_heat_reduction() -> float:
	return 0.0 # Heat's -20% retired (2026-10-31, now Sync)

func sync_active() -> bool:
	return is_active(HEAT)

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
		var b: Dictionary = boosts.get(p.name.to_lower(), boosts.get("heat", {}) if p == HEAT else {}) # Sync was saved as "heat"
		p["expires_at"] = int(b.get("expires_at", 0))
