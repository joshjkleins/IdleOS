extends Node
## 2026-11-03 (Josh): demo veteran bonus. A demo's save (the old user folder's savegame.json, demo-nextfest builds)
## is read once. The first NEW profile made after that gets the bonus, delivered when its tutorial is done:
##  - each skill to its demo level (max 10, the demo's cap; never lowered), +1 VM token of that skill per level
##    (Hacking has no VM token: level only)
##  - the demo's School upload goal completed: +100 of each School basic item
##  - every demo rare the player had uploaded comes back (same amounts)
## The profile gets a DEMO VETERAN tag on its launcher card. Account-wide state: user://demo_veteran.cfg.

const FILE := "user://demo_veteran.cfg"
const LEVEL_CAP := 10
const BASIC_GIFT := 100
const SKILL_KEYS := {"mining": "Mining", "parsing": "Parsing", "cracking": "Cracking", "matching": "Matching",
	"phishing": "Phishing", "decoding": "Decoding", "compiling": "Compiling", "hacking": "Hacking"}

var found := {}        # from the demo save: {"levels": {skill: lvl}, "tier_done": bool, "rares": {item id: n}}
var claimed_slot := 0  # the profile that got it (0 = not given to one yet)
var scanned := false
var state := ""        # this profile: "" (none), "pending" (after the tutorial), "given"
var _accum := 0.0

func _ready() -> void:
	_load()
	if found.is_empty(): # (looks again each launch until a demo save turns up; cheap)
		_scan()

func pending_for_new_profile() -> bool:
	return !found.is_empty() and claimed_slot == 0

## the launcher: a new profile in <slot> takes the bonus
func claim(slot: int) -> void:
	if !pending_for_new_profile():
		return
	claimed_slot = slot
	state = "pending"
	_save()

func _scan() -> void:
	scanned = true
	var path = SaveManager.old_user_dir().path_join("savegame.json")
	if FileAccess.file_exists(path):
		var f = FileAccess.open(path, FileAccess.READ)
		var d = JSON.parse_string(f.get_as_text()) if f else null
		if f: f.close()
		if d is Dictionary and !d.has("meta"): # a demo / pre-profile save (profile saves have a meta block)
			var levels := {}
			for k in SKILL_KEYS:
				var lv = int(d.get(k, {}).get("skill_level", 1)) if d.get(k) is Dictionary else 1
				levels[SKILL_KEYS[k]] = clampi(lv, 1, LEVEL_CAP)
			var up: Dictionary = d.get("uploads", {})
			var uploaded: Dictionary = up.get("uploaded", {})
			var rares := {}
			for r in Uploads.get_tier_rares(1):
				var n = int(uploaded.get(str(r.id), uploaded.get(r.id, 0)))
				if n > 0:
					rares[str(r.id)] = n
			found = {"levels": levels, "tier_done": 1 in Array(up.get("completed_tiers", [])).map(func(x): return int(x)), "rares": rares}
			print("DemoVeteran: demo save found ", found)
	_save()

func _process(delta: float) -> void:
	if state != "pending":
		return
	_accum += delta
	if _accum < 1.0:
		return
	_accum = 0.0
	if SaveManager.session_active and Tutorial.is_tutorial_complete():
		_deliver()

func _deliver() -> void:
	state = "given"
	var lines = []
	for sk in found.get("levels", {}):
		var node = get_node_or_null("/root/" + sk)
		var lv = int(found.levels[sk])
		if node == null or lv <= 1:
			continue
		if int(node.SKILL.level) < lv:
			node.SKILL.level = lv
			node.SKILL.experience = max(int(node.SKILL.experience), Exp.xp_for_level(lv))
			Exp.refresh_efficiency(node)
			node.SKILL["level up signal"].emit()
		if node != Hacking:
			Inventory.add_resource(node.vm_token, lv)
		lines.append("%s %d%s" % [sk, lv, "" if node == Hacking else " (+%d %s)" % [lv, node.vm_token.name]])
	var items = []
	if found.get("tier_done", false):
		for it in Decoding.get_tier_resources(1):
			Inventory.add_resource(it, BASIC_GIFT)
		items.append("+%d of every School resource" % BASIC_GIFT)
	for id in found.get("rares", {}):
		var it = Items.ITEM_MAP.get(int(id))
		if it:
			Inventory.add_resource(it, int(found.rares[id]))
			items.append("+%d %s" % [int(found.rares[id]), it.name])
	SaveManager.mark_dirty()
	var t = "\n[color=#ffc24a]DEMO VETERAN[/color]  Welcome back, operative: your demo progress has been restored.\n"
	if !lines.is_empty():
		t += "[color=#888888]  skills: %s[/color]\n" % ", ".join(lines)
	if !items.is_empty():
		t += "[color=#888888]  items: %s[/color]\n" % ", ".join(items)
	Signals.system_message_signal.emit(t)

## per profile (SaveManager)
func save_data() -> Dictionary:
	return {"state": state}

func load_data(d: Dictionary) -> void:
	state = str(d.get("state", ""))

func _save() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("demo", "scanned", scanned)
	cfg.set_value("demo", "found", found)
	cfg.set_value("demo", "claimed_slot", claimed_slot)
	cfg.save(FILE)

func _load() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(FILE) != OK:
		return
	scanned = bool(cfg.get_value("demo", "scanned", false))
	found = cfg.get_value("demo", "found", {})
	claimed_slot = int(cfg.get_value("demo", "claimed_slot", 0))
