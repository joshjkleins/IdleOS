extends Node

## Heat plan: heat multiplier by the tier being worked on (see BaseTerminal.heat_tier_mult)
const HEAT_BY_TIER := [1.111, 1.261, 1.56, 1.962, 4.667, 6.818]

signal spear_cycle_completed
signal whale_cycle_completed
signal xp_gained
signal phishing_level_up_signal

# When the player earns the bonus
var bonus_expires_at: int
var vm_token = Items.VM_PHISHING_TOKEN
@onready var MAX_VMS = 7
@onready var VM_UPTIME = 60.0
var CURRENT_VMS = 0

var terminal_scene = preload("res://scenes/phishing_terminal.tscn")

var max_lines: int = 5

## Modifier commands unlocked by Phishing capstones (see Mining.MODIFIERS for how they work).
## They don't apply to setting a Trap (PhishingTerminal.modifier_block_reason).
const MODIFIERS = [
	{"command": "lure", "name": "Lure", "package": "phishing.lure", "speed": 0.5, "heat": 1.5,
		"effect": "-50% speed, heat x1.5. Each catch has a 3% chance to also hook a hacking mod."},
	{"command": "chum", "name": "Chum", "package": "phishing.chum", "speed": 0.6, "heat": 2.0,
		"effect": "-40% speed, heat x2. Catches doubled and VM token chance x2."},
	{"command": "survey", "name": "Survey", "package": "phishing.survey", "speed": 1.0, "heat": 1.0,
		"effect": "Half catches, +100% Phishing XP."},
]
const LURE_CHANCE := 0.03
## Deep Water: overclock and the modifiers add no extra heat
const COOL_PACKAGE := "phishing.deep_water"
var current_lines = []

#GENERAL MODULE DATA
var SKILL = {
	"name": "Phishing",
	"level": 1,
	"experience": 0,
	"color": Color("#3B82F6"),
	"level up signal": phishing_level_up_signal,
	"efficiency description": "Chance for successful bite",
	"command": "cd phishing",
	"sfx": "phishing_item_received"
}

## Styles ("style" key) — how phishing_terminal.gd / phishing_line.gd run a process:
##   lines: every line casts on its own (Spear, Mod)
##   whale: all lines go onto one whale; each line shortens the reel; the catch is a bundle (Whaling)
##   smish: one blast of texts (texts per line x lines); replies trickle in as intel on a target (Smish)
##   trap:  a one-minute setup, then it fills in the background on real time; collect it later (Trap)
## Bait: any basic resource (any tier), BAIT_PER_CAST per cast (whale / blast / trap), doubles what that cast brings in.
## VM tokens are a bonus on top of the catch: "vm token chance" per attempt at base speed (3 lines for Spear /
## Mod), rolled on time spent like every skill, so speed and extra lines don't change tokens per hour.
const BASE_LINES := 5
var SPEAR = {
	"name": "Spear",
	"tier name": "TIER I | SPEAR",
	"style": "lines",
	"level": 1,
	"experience": 0,
	"experience per level": 60,
	"command": "phish -spear",
	"display command": "phish -spear [bait=<item>]",
	"example commands": [
		{ 'cmd': 'phish -spear', 'description': 'Cast every line' },
		{ 'cmd': 'phish -spear bait=logs', 'description': 'Each cast uses 10 of a basic resource: bite chance up, a bite catches double' },
	],
	"efficiency": 0.3,
	"efficiency rate": 0.003,
	"unlocked": true,
	"unlock tier": 1, # 2026-10-26: opens with this tier's location (1 = from the start)
	"efficiency level": 1, # efficiency grows from this skill level (its old unlock level)
	"cast time": 2.0,
	"overclock cast time": 1.0,
	"overheat cast time": 7.0,
	"wait time min": 5.0,
	"wait time max": 10.0,
	"download time": 7.5,
	"overclocked download time": 3.75,
	"overheated download time": 22.5,
	"heat": 0.3,
	"overclock heat": 0.6,
	"overheat heat": 0.1,
	"vm token chance": 0.0033, # per attempt at base speed (rolled on time spent, like every skill)
	"vm token per": "per cast",
	"requirements": {},
	"resource gained": [
		{ "item": Items.SQL_INJECTOR, "min": 1, "max": 2, "weight": 90 },
		{ "item": Items.PACKET_SPOOF, "min": 1, "max": 2, "weight": 10 },
	],
	"resource amount gained": 1,
	"description": "Harvest SQL Injectors and Packet Spoofs through targeted phishing emails",
	"efficiency description": "Chance for successful bite",
	"signal": spear_cycle_completed
}

var WHALING = {
	"name": "Whaling",
	"tier name": "TIER II | WHALING",
	"style": "whale",
	"level": 1,
	"experience": 0,
	"experience per level": 900, # per whale landed (a bundle of ~14 items)
	"command": "phish -whale",
	"display command": "phish -whale [bait=<item>]",
	"example commands": [
		{ 'cmd': 'phish -whale', 'description': 'All lines on one whale: wait, bite roll, then a reel split across your lines for a bundle of 10-24 SQL / Spoofs' },
		{ 'cmd': 'phish -whale bait=logs', 'description': 'Each whale cast uses 10 of a basic resource: bite chance up, bundle doubled' },
	],
	"efficiency": 0.4,
	"efficiency rate": 0.003,
	"unlocked": false,
	"unlock tier": 2, # 2026-10-26: opens with this tier's location (1 = from the start)
	"efficiency level": 15, # efficiency grows from this skill level (its old unlock level)
	"cast time": 6.0,
	"overclock cast time": 3.0,
	"overheat cast time": 15.0,
	"wait time min": 30.0,
	"wait time max": 60.0,
	"download time": 120.0, # total reel time, divided by the lines on the whale
	"overclocked download time": 60.0,
	"overheated download time": 300.0,
	"heat": 4.05,
	"overclock heat": 8.1,
	"overheat heat": 1.35,
	"vm token chance": 0.05, # per attempt at base speed (rolled on time spent, like every skill)
	"vm token per": "per whale",
	"bundle min": 10,
	"bundle max": 24,
	"exploit chance": 0.05, # per whale: also lands one of an unlocked tier's one-time items
	"requirements": {},
	"resource gained": [
		{ "item": Items.SQL_INJECTOR, "min": 1, "max": 1, "weight": 85 },
		{ "item": Items.PACKET_SPOOF, "min": 1, "max": 1, "weight": 15 },
	],
	"resource amount gained": 1,
	"description": "Puts every line on one whale for a big bundle of SQL Injectors and Packet Spoofs, with a small chance of an Exploit. More lines reel it in faster.",
	"efficiency description": "Chance the whale bites",
	"signal": whale_cycle_completed
}

var SMISH = {
	"name": "Smish",
	"tier name": "TIER III | SMISH",
	"style": "smish",
	"level": 1,
	"experience": 0,
	"experience per level": 350, # per reply
	"command": "phish -smish",
	"display command": "phish -smish [target=<target>] [bait=<item>]",
	"example commands": [
		{ 'cmd': 'phish -smish', 'description': 'Replies become intel on a random unlocked target that is not maxed' },
		{ 'cmd': 'phish -smish target=student', 'description': 'Replies become intel on the Student' },
		{ 'cmd': 'phish -smish bait=logs', 'description': 'Each blast uses 10 of a basic resource: reply chance up, every reply counts twice' },
	],
	"efficiency": 0.03,
	"efficiency rate": 0.0005,
	"unlocked": false,
	"unlock tier": 3, # 2026-10-26: opens with this tier's location (1 = from the start)
	"efficiency level": 30, # efficiency grows from this skill level (its old unlock level)
	"texts per line": 8,
	"cast time": 10.0, # sending the whole blast
	"overclock cast time": 5.0,
	"overheat cast time": 25.0,
	"wait time min": 60.0, # replies arrive at random times within this window
	"wait time max": 60.0,
	"overclock wait time": 30.0,
	"overheat wait time": 120.0,
	"heat": 0.6,
	"overclock heat": 1.2,
	"overheat heat": 0.2,
	"vm token chance": 0.04, # per attempt at base speed (rolled on time spent, like every skill)
	"vm token per": "per blast",
	"requirements": {},
	"resource gained": "Intel points on a hacking target (see 'intel'). When every target is maxed, replies bring SQL Injectors.",
	"resource amount gained": 1,
	"description": "Blasts out texts (8 per line). Each text has a small chance to get a reply, and each reply is 1 intel point on a hacking target.",
	"efficiency description": "Chance per text to get a reply",
	"signal": whale_cycle_completed
}

var TRAP = {
	"name": "Trap",
	"tier name": "TIER IV | TRAP",
	"style": "trap",
	"level": 1,
	"experience": 0,
	"experience per level": 24000, # for a full trap (scales with how full it was)
	"command": "phish -trap",
	"display command": "phish -trap [bait=<item>]",
	"example commands": [
		{ 'cmd': 'phish -trap', 'description': 'Sets a watering-hole trap (1 min). Shows its status once set' },
		{ 'cmd': 'phish -trap bait=logs', 'description': 'Uses 10 of a basic resource: haul doubled, rare chance up' },
		{ 'cmd': 'trap collect', 'description': 'Collects it from anywhere (early = partial haul, no rare rolls)' },
	],
	"efficiency": 0.15,
	"efficiency rate": 0.0010204, # 25% at level 99
	"unlocked": false,
	"unlock tier": 4, # 2026-10-26: opens with this tier's location (1 = from the start)
	"efficiency level": 45, # efficiency grows from this skill level (its old unlock level)
	"cast time": 60.0, # setting the trap
	"overclock cast time": 30.0,
	"overheat cast time": 150.0,
	"trap minutes": 45.0, # real time to fill; it fills while the game is closed too
	"trap sql": 70, # full haul
	"trap spoofs": 15,
	"heat": 1.0,
	"overclock heat": 2.0,
	"overheat heat": 0.3,
	"vm token chance": 1.0, # per attempt at base speed (rolled on time spent, like every skill)
	"vm token per": "on a full trap",
	"requirements": {},
	"resource gained": [
		{ "item": Items.SQL_INJECTOR, "min": 70, "max": 70, "weight": 100 },
		{ "item": Items.PACKET_SPOOF, "min": 15, "max": 15, "weight": 100 },
	],
	"resource amount gained": 1,
	"description": "Plants a watering-hole trap that fills over 45 minutes of real time, even offline. A full trap hauls 70 SQL Injectors and 15 Packet Spoofs, plus rare rolls: efficiency is the chance of an Exploit, a fifth of it the chance of a hacking mod.",
	"efficiency description": "Rare roll chance on a full trap",
	"signal": whale_cycle_completed
}

## Utility: the mod pool grows with the locations you unlock (each hacking mod item's "tier").
var MOD = {
	"name": "Mod",
	"tier name": "UTILITY | MOD",
	"style": "lines",
	"level": 1,
	"experience": 0,
	"experience per level": 1000,
	"command": "phish -mod",
	"display command": "phish -mod [bait=<item>]",
	"example commands": [
		{ 'cmd': 'phish -mod', 'description': 'Cast every line' },
		{ 'cmd': 'phish -mod bait=logs', 'description': 'Each cast uses 10 of a basic resource: bite chance up, a bite catches double' },
	],
	"efficiency": 0.015, # 1.5% bite chance at L1 (2026-10-23: was 1%, mods now last 5 hacks)
	"efficiency rate": 0.0001,
	"unlocked": false,
	"unlock tier": 1, # 2026-10-26: opens with this tier's location (1 = from the start)
	"efficiency level": 5, # efficiency grows from this skill level (its old unlock level)
	"cast time": 4.0,
	"overclock cast time": 1.5,
	"overheat cast time": 9.0,
	"wait time min": 7.0,
	"wait time max": 13.0,
	"download time": 35.0,
	"overclocked download time": 27.5,
	"overheated download time": 75.5,
	"heat": 0.45,
	"overclock heat": 0.9,
	"overheat heat": 0.15,
	"vm token chance": 0.009, # per attempt at base speed (rolled on time spent, like every skill)
	"vm token per": "per cast",
	"requirements": {},
	"resource gained": [], # filled from the hacking mod items in _ready (see mod_pool)
	"resource amount gained": 1,
	"description": "A risky phishing attempt with a slim chance of uncovering a powerful Hacking Modification. More mods join the pool as locations unlock.",
	"efficiency description": "Chance for successful bite",
	"signal": spear_cycle_completed
}

const BAIT_PER_CAST := 10
## Bait also multiplies the bite chance: x1.10 (a School resource, tier 1) up to x1.35 (a Government one, tier 6)
const BAIT_BASE_BONUS = 0.05
const BAIT_BONUS_PER_TIER = 0.05

## Bait Power adds to it (+5% per level)
func get_bait_multiplier(bait: ItemData) -> float:
	return 1.0 + BAIT_BASE_BONUS + BAIT_BONUS_PER_TIER * bait_tier(bait) + Upgrades.cur("phishing.bait_power") if bait else 1.0

## Process efficiency with the Efficiency track: +X% of the process's own efficiency (x1.20 at max)
func get_efficiency(p: Dictionary) -> float:
	return float(p["efficiency"]) * (1.0 + Upgrades.cur("phishing.efficiency"))

## 2026-10-23: any basic resource of any tier is bait (it was Mining items only): a sink for surplus basics
func is_bait(item: ItemData) -> bool:
	return item != null and Decoding.get_resource_tier(item) > 0

## the bait's location tier (1 School ... 6 Government)
func bait_tier(bait: ItemData) -> int:
	return max(1, Decoding.get_resource_tier(bait)) if bait else 1

## "phish -smish target=student hard bait=logs" -> {command, bait, target, error}. Options can come in any order.
func parse_bait(text: String) -> Dictionary:
	var out = {"command": text.strip_edges(), "bait": null, "target": {}, "error": ""}
	var opts := {}
	var cut := text.length()
	for key in ["bait", "target"]:
		var at = text.find(" " + key + "=")
		if at != -1:
			cut = min(cut, at)
	if cut == text.length():
		return out
	out.command = text.substr(0, cut).strip_edges()
	var rest = text.substr(cut).strip_edges()
	var current := ""
	for word in rest.split(" ", false):
		var eq = word.find("=")
		if eq != -1 and word.substr(0, eq) in ["bait", "target"]:
			current = word.substr(0, eq)
			opts[current] = word.substr(eq + 1)
		elif current != "":
			opts[current] += " " + word
	if opts.has("bait"):
		var bait = Inventory.get_item_by_name(opts.bait.strip_edges())
		if bait == null:
			out.error = "Bait item not found: " + opts.bait
		elif Uploads.is_rare(bait) and (" -mod" in " " + out.command or out.command.ends_with(" mod")):
			if is_rare_bait(bait):
				out.bait = bait
			else:
				out.error = "%s becomes Mod Phishing bait once its %s upload goal is met (%d/%d uploaded)." % [bait.name, Uploads.get_location_name(Inventory.item_tier(bait)), Uploads.get_uploaded(bait), Uploads.get_goal_amount(bait, Inventory.item_tier(bait))]
		elif !is_bait(bait):
			out.error = bait.name + " can't be used as bait. Any basic resource works (logs, IP addresses, passwords, credentials...)." + (" Rare items work for 'phish -mod' once their upload goal is met." if Uploads.is_rare(bait) else "")
		else:
			out.bait = bait
	if opts.has("target") and out.error == "":
		out.target = Decoding.find_target(opts.target)
		if out.target.is_empty():
			out.error = "No unlocked target named '%s'. [color=#666666]ex. target=student  |  target=student hard[/color]" % opts.target.strip_edges()
	return out

## Every hacking mod item; mod_pool() keeps the ones whose tier is unlocked.
## 2026-10-25: the list is built deferred (Items is a later autoload), but Offline.compute() runs in the same
## boot frame, before deferred calls: it saw an empty pool and offline Mod Phishing caught nothing
func _ensure_mod_list() -> void:
	if MOD["resource gained"].is_empty():
		_build_mod_list()

func _build_mod_list() -> void:
	var mods = []
	for item in HackingMods.pool_items(): # retired mods don't drop
		mods.append({"item": item, "min": 1, "max": 1, "weight": 100})
	MOD["resource gained"] = mods

## one tier's mods as a reward list (rare bait guarantees one of these)
func tier_mod_pool(tier: int) -> Array:
	_ensure_mod_list()
	return MOD["resource gained"].filter(func(e): return int(e.item.tier) == tier)

## 2026-10-23: a rare item whose upload goal is met is bait for 'phish -mod': 1 per cast, and every cast
## lands a mod from the rare's tier
const RARE_BAIT_PER_CAST := 1
func is_rare_bait(item: ItemData) -> bool:
	if item == null or !Uploads.is_rare(item):
		return false
	var tier = Inventory.item_tier(item)
	var need = Uploads.get_goal_amount(item, tier)
	return need > 0 and Uploads.get_uploaded(item) >= need

## what one cast uses of <bait>
func bait_cost(bait: ItemData) -> int:
	return RARE_BAIT_PER_CAST if is_rare_bait(bait) else BAIT_PER_CAST

func mod_pool() -> Array:
	_ensure_mod_list()
	return MOD["resource gained"].filter(func(e): return Upgrades.tier_unlocked(e.item.tier))

## Tiers whose location is unlocked (1..6)
func unlocked_tiers() -> Array:
	var out = []
	for t in range(1, 7):
		if Upgrades.tier_unlocked(t):
			out.append(t)
	return out

## A random one-time exploit item from an unlocked tier, or null
func roll_exploit_item() -> ItemData:
	var pool = []
	for t in unlocked_tiers():
		pool.append_array(Exploits.tier_items(t))
	return pool.pick_random() if !pool.is_empty() else null

## Smish: the target a reply lands on (the chosen one while it isn't maxed, else a random unlocked one that isn't)
func smish_target(chosen: Dictionary) -> Dictionary:
	if !chosen.is_empty() and !Decoding.is_intel_maxed(chosen):
		return chosen
	var open = []
	for loc in Stats.hacking_targets:
		var l = Stats.hacking_targets[loc]
		if !l.get("unlocked", true):
			continue
		for t in l.get("targets", []):
			if t.get("unlocked", false) and !Decoding.is_intel_maxed(t):
				open.append(t)
	return open.pick_random() if !open.is_empty() else {}

## Seconds one attempt takes at base speed, with the catch (what "vm token chance" is per)
func base_attempt_seconds(p: Dictionary) -> float:
	match p.get("style", "lines"):
		"trap":
			return trap_seconds_total()
		"smish":
			return p["cast time"] + p["wait time max"] + 2.0
		"whale":
			return p["cast time"] + (p["wait time min"] + p["wait time max"]) / 2.0 + p["download time"] / BASE_LINES + 2.0
		_:
			return p["cast time"] + (p["wait time min"] + p["wait time max"]) / 2.0 + p["download time"] + 1.0

## VM tokens for <expected> tokens: the whole part, plus a chance at one more
func roll_tokens(expected: float) -> int:
	var n = int(expected)
	if randf() < expected - n:
		n += 1
	return n

#region trap
## The trap fills on real time (unix seconds), so it keeps filling while the game is closed.
var trap: Dictionary = {} # {} = no trap set; else {"set_at": int, "baited": bool}
signal trap_changed

func has_trap() -> bool:
	return !trap.is_empty()

func trap_seconds_total() -> float:
	return float(TRAP["trap minutes"]) * 60.0

func trap_progress() -> float:
	if !has_trap():
		return 0.0
	var elapsed = Time.get_unix_time_from_system() - float(trap.set_at)
	return clamp(elapsed / trap_seconds_total(), 0.0, 1.0)

func trap_seconds_left() -> float:
	return max(0.0, trap_seconds_total() * (1.0 - trap_progress()))

## bait: the basic resource used (already taken), or null
func set_trap(bait: ItemData) -> void:
	trap = {"set_at": int(Time.get_unix_time_from_system()), "baited": bait != null, "bait_mult": get_bait_multiplier(bait)}
	SaveManager.mark_dirty()
	trap_changed.emit()

## Collects the trap: basics scale with how full it is; rare rolls and full XP only when full.
## Returns [{item, amount}] that were added (tokens included).
func collect_trap() -> Array:
	if !has_trap():
		return []
	var p = trap_progress()
	var mult = 2 if trap.get("baited", false) else 1
	var got = []
	var add = func(item: ItemData, amount: int):
		if item and amount > 0:
			Inventory.add_resource(item, amount)
			got.append({"item": item, "amount": amount})
	add.call(Items.SQL_INJECTOR, int(round(TRAP["trap sql"] * p)) * mult)
	add.call(Items.PACKET_SPOOF, int(round(TRAP["trap spoofs"] * p)) * mult)
	if p >= 1.0:
		var eff = min(get_efficiency(TRAP) * float(trap.get("bait_mult", 1.0)), 1.0)
		for i in mult:
			if randf() < eff:
				add.call(roll_exploit_item(), 1)
			var pool = mod_pool()
			if !pool.is_empty() and randf() < eff / 5.0:
				add.call(pool.pick_random().item, 1)
	add.call(vm_token, roll_tokens(TRAP["vm token chance"] * p * (2.0 if Upgrades.has("phishing.tackle_box") else 1.0)))
	for g in got:
		Signals.phishing_item_caught_item(g.item)
	TRAP.signal.emit(1)
	Exp.add_xp(self, TRAP, int(TRAP["experience per level"] * p))
	Signals.update_hud(self)
	trap = {}
	SaveManager.mark_dirty()
	trap_changed.emit()
	return got

## One line for the terminal: "Trap 62% full · 17m left" / "Trap full: 'trap collect'"
func trap_status_text() -> String:
	if !has_trap():
		return "No trap set. Use 'phish -trap' in Phishing to set one." if TRAP.unlocked else "Trap opens with %s access." % Upgrades.tier_name(int(TRAP.get("unlock tier", 1)))
	var p = trap_progress()
	var baited = " (baited)" if trap.get("baited", false) else ""
	if p >= 1.0:
		return "Trap%s is full. Collect it with 'trap collect'." % baited
	return "Trap%s %d%% full, %s left. 'trap collect' now gives a partial haul (no rare rolls)." % [baited, int(p * 100), format_minutes(trap_seconds_left())]

static func format_minutes(seconds: float) -> String:
	var m = int(ceil(seconds / 60.0))
	return "%dh %02dm" % [m / 60, m % 60] if m >= 60 else "%dm" % m

## 'trap' / 'trap collect' (works from any context)
func trap_command_text(arg: String) -> String:
	arg = arg.strip_edges()
	if arg == "collect":
		if !has_trap():
			return trap_status_text()
		var p = trap_progress()
		var got = collect_trap()
		var parts = got.map(func(g): return "%s x%d" % [g.item.name, g.amount])
		var head = "Trap collected (%d%% full)" % int(p * 100)
		return head + (": " + ", ".join(parts) if !parts.is_empty() else ": nothing yet.")
	return trap_status_text()
#endregion

var minor_processes = [
	SPEAR,
	WHALING,
	SMISH,
	TRAP,
	MOD,
]

func _ready() -> void:
	_build_mod_list.call_deferred() # Items is a later autoload

func add_line(line):
	current_lines.append(line)

func remove_line(line):
	if current_lines.has(line):
		current_lines.erase(line)

func signal_exp(_amount: int):
	xp_gained.emit()
	SaveManager.mark_dirty()

#var process_upgrades = {
	#"max lines": { "id": 1, "name": "Max lines", "level": 0, "amount": 0, "increase per level": 1 },
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

func has_requirements(_minor_process) -> bool:
	return true

func missing_requirements_text(_minor_process) -> String:
	return ""

func create_vm_window(minor_process, repeat, bait: ItemData = null, target: Dictionary = {}) -> VMWindow:
	var setup = func(t):
		t.vm_cast_all_lines(minor_process, true, bait, target)
	return VMManager.open(self, minor_process, terminal_scene.instantiate(), setup, repeat)


func save_data() -> Dictionary:
	return {
		"processes": Exp.processes_save_data(self),
		"bonus_expires_at": bonus_expires_at,
		"skill_level": SKILL["level"],
		"skill_experience": SKILL["experience"],
		"spear_level": SPEAR["level"],
		"spear_experience": SPEAR["experience"],
		"trap": trap,
	}

func load_data(data: Dictionary) -> void:
	bonus_expires_at = int(data.get("bonus_expires_at", bonus_expires_at))
	SKILL["level"] = int(data.get("skill_level", SKILL["level"]))
	SKILL["experience"] = int(data.get("skill_experience", SKILL["experience"]))
	SPEAR["level"] = int(data.get("spear_level", SPEAR["level"]))
	SPEAR["experience"] = int(data.get("spear_experience", SPEAR["experience"]))
	# (legacy "<process>_efficiency" is ignored: efficiency is rebuilt from level in Exp.processes_load_data)
	Exp.processes_load_data(self, data.get("processes", {})) # all processes (legacy keys above cover old saves)
	var t = data.get("trap", {})
	trap = {"set_at": int(t.set_at), "baited": bool(t.get("baited", false)), "bait_mult": float(t.get("bait_mult", 1.0))} if t is Dictionary and t.has("set_at") else {}
	trap_changed.emit()
