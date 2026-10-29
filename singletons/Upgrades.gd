extends Node
## Upgrade packages ('apt'), loaded from data/upgrades.json.
## That file is exported from tools/upgrades/idleos_upgrades.xlsx (the balance sheet):
##   python3 tools/upgrades/export_upgrades.py tools/upgrades/idleos_upgrades.xlsx data/upgrades.json
##
## Model: 9 groups (System + 8 skills) x 6 tiers x 10 installs. Every install is +0.1 version, so a
## finished tier lands on a clean v1.0 ... v6.0. A package is one track ("mining.speed") whose levels
## span the tiers; capstones are one-level packages. A tier's installs open when that location is
## unlocked (upload goal), and can be bought in any order; the tier's 10th install is its MAJOR release.
##
## Callers read effects with get_package_info(id).current (sum of installed values, or true for a
## capstone) or the helpers below.

const DATA_PATH := "res://data/upgrades.json"
const INSTALLS_PER_TIER := 10
const VM_TOKEN_COST := "@vm_tokens" # cost paid with any VM tokens

## TESTING: every tier's installs are open without unlocking locations. Turn off before release.
const DEV_UNLOCK_ALL_TIERS := false

## Groups whose effects are wired up in code. The rest are listed in apt but can't be installed yet
## (skills are migrated one at a time).
const WIRED_GROUPS := ["System", "Mining", "Parsing", "Cracking", "Matching", "Phishing", "Decoding", "Compiling", "Hacking"]


const BASE_COOLING := -0.2          # C per cooling tick before upgrades (2026-10-20 demo playtest: was -0.1)
const BASE_VM_WINDOWS := 1
const BASE_OVERHEAT_CLEAR := 80.0   # overheat clears at this temp (Thermal Paste raises it)
const BASE_DEFRAG_MINUTES := 10.0   # Defrag Duration raises it
const BASE_DEFRAG_COOLDOWN := 40.0  # Defrag Cooldown lowers it; they meet at max (25/25)

signal installed(package: Dictionary, level: Dictionary)

var groups: Array = []          # group names in display order
var packages: Dictionary = {}   # id -> package
var _by_group: Dictionary = {}  # group -> [package ids], in sheet order
var _items: Dictionary = {}     # item name (lower) -> ItemData, filled on first use

func _init() -> void:
	_load_data() # in _init so autoloads that read upgrades in their _ready (Stats) see the packages

func _ready() -> void:
	apply_effects.call_deferred()

#region data
func _load_data() -> void:
	var f = FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		push_error("Upgrades: can't open " + DATA_PATH)
		return
	var d = JSON.parse_string(f.get_as_text())
	if !(d is Dictionary):
		push_error("Upgrades: bad JSON in " + DATA_PATH)
		return
	groups = d.get("groups", [])
	for p in d.get("packages", []):
		p["installed"] = 0
		p["current"] = false if p.type == "capstone" else 0.0
		packages[p.id] = p
		if !_by_group.has(p.group):
			_by_group[p.group] = []
		_by_group[p.group].append(p.id)

## ItemData for a cost name (case-insensitive), or null.
func get_item(name: String) -> ItemData:
	if _items.is_empty():
		for i in Items.ITEM_MAP.values():
			_items[i.name.to_lower()] = i
	return _items.get(name.to_lower())

func group_packages(group: String) -> Array:
	return _by_group.get(group, []).map(func(id): return packages[id])

func get_package_info(id: String) -> Dictionary:
	if packages.has(id):
		return packages[id]
	return {"id": id, "current": 0}

func is_valid_package(id: String) -> bool:
	return packages.has(id)

## numeric total of a track (0 when not installed)
func cur(id: String) -> float:
	var p = packages.get(id)
	if p == null or p.type == "capstone":
		return 0.0
	return float(p.current)

## true once a capstone is installed
func has(id: String) -> bool:
	var p = packages.get(id)
	return p != null and p.installed > 0
#endregion

#region groups, versions, tiers
var _skills: Dictionary = {}
func skill_for_group(group: String) -> Node:
	if _skills.is_empty():
		for s in [System, Mining, Parsing, Cracking, Matching, Phishing, Decoding, Compiling, Hacking]:
			_skills[s.SKILL.name] = s
	return _skills.get(group)

func group_for_skill(skill: Node) -> String:
	return skill.SKILL.name if skill and "SKILL" in skill else ""

func group_color(group: String) -> Color:
	var s = skill_for_group(group)
	return s.SKILL.color if s else Color.WHITE

func installed_count(group: String) -> int:
	var n = 0
	for p in group_packages(group):
		n += p.installed
	return n

func version(group: String) -> float:
	return installed_count(group) / float(INSTALLS_PER_TIER)

func version_text(group: String) -> String:
	return "v%.1f" % version(group)

## older callers: version of a skill node
func get_skill_version(skill: Node) -> String:
	return version_text(group_for_skill(skill))

## how many of <group>'s installs in <tier> are done (0-10)
func tier_installed(group: String, tier: int) -> int:
	var n = 0
	for p in group_packages(group):
		for i in p.installed:
			if int(p.levels[i].tier) == tier:
				n += 1
	return n

func tier_unlocked(tier: int) -> bool:
	if DEV_UNLOCK_ALL_TIERS:
		return true
	var locs = Stats.hacking_targets.values()
	return tier >= 1 and tier <= locs.size() and locs[tier - 1].get("unlocked", false)

func tier_name(tier: int) -> String:
	var keys = Stats.hacking_targets.keys()
	return keys[tier - 1] if tier >= 1 and tier <= keys.size() else "Tier %d" % tier

## lowest tier of <group> that isn't finished (7 when everything is installed)
func working_tier(group: String) -> int:
	for t in range(1, 7):
		if tier_installed(group, t) < INSTALLS_PER_TIER:
			return t
	return 7

func is_wired(group: String) -> bool:
	return group in WIRED_GROUPS
#endregion

#region installing
func next_level(p: Dictionary) -> Dictionary:
	return p.levels[p.installed] if p.installed < p.levels.size() else {}

func is_at_max_level(id: String) -> bool:
	var p = packages.get(id)
	return p == null or p.installed >= p.levels.size()

## [{name, have, need}] for a level's costs
func cost_rows(level: Dictionary) -> Array:
	var rows = []
	for c in level.get("costs", []):
		if c.item == VM_TOKEN_COST:
			rows.append({"name": "VM tokens (any)", "have": vm_token_total(), "need": int(c.amount)})
		else:
			var it = get_item(c.item)
			rows.append({"name": it.name if it else c.item + " (?)", "have": Inventory.get_amount(it) if it else 0, "need": int(c.amount)})
	return rows

func can_afford(level: Dictionary) -> bool:
	for r in cost_rows(level):
		if r.have < r.need:
			return false
	return true

## "" when <p>'s next level can be installed now, otherwise the reason
func install_block_reason(p: Dictionary) -> String:
	if !is_wired(p.group):
		return "%s upgrades arrive in a later update (not wired up yet)." % p.group
	var lvl = next_level(p)
	if lvl.is_empty():
		return "Package fully upgraded."
	if !tier_unlocked(int(lvl.tier)):
		return "Requires %s access (Tier %d)." % [tier_name(int(lvl.tier)), int(lvl.tier)]
	if int(lvl.tier) > working_tier(p.group):
		return "Finish Tier %d first (%s v%d.0)." % [working_tier(p.group), p.group, working_tier(p.group)]
	if !can_afford(lvl):
		return "Missing requirements."
	return ""

func vm_token_total() -> int:
	var n = 0
	for t in Decoding.vm_tokens():
		n += Inventory.get_amount(t)
	return n

## pays <amount> VM tokens, taking from the largest stacks first
func _pay_vm_tokens(amount: int) -> void:
	var left = amount
	while left > 0:
		var best: ItemData = null
		for t in Decoding.vm_tokens():
			if best == null or Inventory.get_amount(t) > Inventory.get_amount(best):
				best = t
		var take = min(left, Inventory.get_amount(best))
		if take <= 0:
			return
		Inventory.remove_resource(best, take)
		left -= take

## Installs <p>'s next level (call install_block_reason first).
## Returns {level, version_before, version_after, tier, major, before, after}.
func install(p: Dictionary) -> Dictionary:
	var lvl = next_level(p)
	var v_before = version(p.group)
	for c in lvl.costs:
		if c.item == VM_TOKEN_COST:
			_pay_vm_tokens(int(c.amount))
		else:
			Inventory.remove_resource(get_item(c.item), int(c.amount))
	p.installed += 1
	_recompute(p)
	apply_effects(p.id)
	SaveManager.mark_dirty()
	if p.group == "Mining": # tutorial: first Mining upgrade (the enum name is from when it was Overclock)
		Tutorial.complete_event(Tutorial.TutorialEvent.UNLOCK_MINING_OVERCLOCK_WITH_APT)
	installed.emit(p, lvl)
	var tier = int(lvl.tier)
	return {"level": lvl, "version_before": v_before, "version_after": version(p.group), "tier": tier,
		"major": tier_installed(p.group, tier) == INSTALLS_PER_TIER, "before": lvl.before, "after": lvl.after}

func _recompute(p: Dictionary) -> void:
	if p.type == "capstone":
		p.current = p.installed > 0
		return
	var total = 0.0
	for i in p.installed:
		total += float(p.levels[i].value)
	p.current = total

## Everything 'apt install <group>' would install right now, in order, paying as it goes:
## [{package, level}]. Resources are reserved as each one is picked, and a track's next level in the
## same tier counts once the one before it is picked.
func plan_bulk(group_list: Array) -> Array:
	var plan = []
	var spent = {} # item name -> reserved amount ("@vm_tokens" for any token)
	var picked = {} # package id -> extra levels picked
	var progress = true
	while progress:
		progress = false
		for g in group_list:
			if !is_wired(g):
				continue
			for p in group_packages(g):
				var idx = p.installed + picked.get(p.id, 0)
				if idx >= p.levels.size():
					continue
				var lvl = p.levels[idx]
				var tier = int(lvl.tier)
				if !tier_unlocked(tier) or tier > _planned_working_tier(g, plan):
					continue
				if !_affordable_with(lvl, spent):
					continue
				for c in lvl.costs:
					spent[c.item] = spent.get(c.item, 0) + int(c.amount)
				picked[p.id] = picked.get(p.id, 0) + 1
				plan.append({"package": p, "level": lvl})
				progress = true
	return plan

## working tier counting installs already in <plan>
func _planned_working_tier(group: String, plan: Array) -> int:
	for t in range(1, 7):
		var n = tier_installed(group, t)
		for e in plan:
			if e.package.group == group and int(e.level.tier) == t:
				n += 1
		if n < INSTALLS_PER_TIER:
			return t
	return 7

func _affordable_with(level: Dictionary, spent: Dictionary) -> bool:
	for c in level.costs:
		var have = vm_token_total() if c.item == VM_TOKEN_COST else Inventory.get_amount(get_item(c.item))
		if have - spent.get(c.item, 0) < int(c.amount):
			return false
	return true

## the tier's installs, for the MAJOR RELEASE changelog: [{name, after}]
func changelog(group: String, tier: int) -> Array:
	var out = []
	for p in group_packages(group):
		for i in p.installed:
			if int(p.levels[i].tier) == tier:
				out.append({"name": p.name, "after": p.levels[i].after, "type": p.type})
	return out
#endregion

#region effects
## Pushes upgrade values into the systems that cache them. <id> = the package just installed ("" = all).
func apply_effects(id: String = "") -> void:
	Stats.cooling_amount = BASE_COOLING - cur("system.cooling_amount")
	Stats.MAX_ALL_VMS = BASE_VM_WINDOWS + int(cur("system.vm_windows"))
	Stats.HEAT_REDUCTION = cur("system.heat_reduction")
	Stats.OVERHEAT_FAN = has("system.overheat_fan")
	Stats.cooling_updated()
	Stats.set_max_anon()
	HackingMods.refresh_slots()
	if id == "phishing.lines":
		Signals.phishing_lines_increase_upgrade_while_running()

func get_overheat_clear_temp() -> float:
	return BASE_OVERHEAT_CLEAR # (Thermal Paste used to raise it; replaced by VM Snapshot 2026-10-21)

## Uses one VM token, unless VM Snapshot saves it. Returns true when the token was kept.
## <amount>: tokens per uptime period (VMManager.token_cost: the process's tier). VM Snapshot keeps them all.
func spend_vm_token(token: ItemData, announce: bool = true, amount: int = 1) -> bool:
	if randf() < cur("system.vm_snapshot"):
		if announce:
			Signals.system_message_signal.emit("[color=#14B8A6]VM Snapshot: %s kept[/color]" % token.name)
		return true
	Inventory.remove_resource(token, amount)
	return false

func get_defrag_minutes() -> float:
	return BASE_DEFRAG_MINUTES + cur("system.defrag_duration")

func get_defrag_cooldown_minutes() -> float:
	return max(get_defrag_minutes(), BASE_DEFRAG_COOLDOWN - cur("system.defrag_cooldown"))

## Scheduler: VM tokens last longer
func vm_uptime_multiplier() -> float:
	return 1.0 + cur("system.scheduler")

## Load Balancer / Server Rack: heat from processes running in VMs
func vm_heat_multiplier() -> float:
	if has("system.server_rack"):
		return 0.0
	if has("system.load_balancer"):
		return 0.5
	return 1.0

## Background Services: hours added to the 1 h offline base (Offline.cap_seconds, 24 h max)
func offline_cap_hours() -> float:
	return cur("system.background_services")

func can_overclock(skill: Node) -> bool:
	if skill == null:
		return false
	if skill == Hacking:
		return true
	return has(group_for_skill(skill).to_lower() + ".overclock")

func any_overclock_unlocked() -> bool:
	for g in groups:
		if has(g.to_lower() + ".overclock"):
			return true
	return false
#endregion

#region save
func save_data() -> Dictionary:
	var installed_counts = {}
	for id in packages:
		if packages[id].installed > 0:
			installed_counts[id] = packages[id].installed
	return {"format": 3, "installed": installed_counts}

## Packages that were replaced: an old save's install carries over to the new one
const RENAMED = {"hacking.clean_exit": "hacking.second_wind", "system.thermal_paste": "system.vm_snapshot",
	"compiling.mod_tuning": "compiling.code_signing", # 2026-10-23: compile -mod retired, its slot is Code Signing
	"decoding.compression": "decoding.salvage_sweep", # 2026-10-28: Compression doubled Yield; its slot is Salvage Sweep
	"decoding.batch_decode": "decoding.salvage_sweep"}

## Saves from the old upgrade system (no "format": 2) start fresh at v0.0.
func load_data(data: Dictionary) -> void:
	for id in packages:
		packages[id].installed = 0
		_recompute(packages[id])
	var fmt = int(data.get("format", 0))
	if fmt >= 2:
		var saved: Dictionary = data.get("installed", {})
		for saved_id in saved:
			var id = RENAMED.get(saved_id, saved_id)
			if packages.has(id):
				var p = packages[id]
				var n = int(saved[saved_id])
				# format 2 -> 3: Background Services went from 2 installs per tier to 1 (its 2nd slot is Kernel Modules)
				if fmt == 2 and id == "system.background_services":
					n = int(ceil(n / 2.0))
				p.installed = clamp(n, 0, p.levels.size())
				_recompute(p)
	apply_effects()

func installed_package_ids() -> Array:
	return packages.keys().filter(func(id): return packages[id].installed > 0)
#endregion
