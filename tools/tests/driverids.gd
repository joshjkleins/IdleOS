extends Node
## 2026-11-14: renamed drivers show and accept their new ids (clean_exit, ghost_protocol); old ids still work
func _ready() -> void:
	for a in ["clean_exit", "Clean Exit", "cool_head", "ghost_protocol", "payload_recycler", "long_haul"]:
		print(">>> _find('%s') -> %s  shown %s" % [a, Drivers._find(a), Drivers.shown_id(Drivers._find(a))])
	var keep = Drivers.owned.duplicate(true)
	Drivers.owned["cool_head"] = Drivers.owned.get("cool_head", {"xp": 0}) if Drivers.owned is Dictionary else null
	var t = ContextCommands.strip_bbcode(Drivers.ls_text("payload_recycler"))
	print(">>> ls ghost protocol: %s" % t.strip_edges().split("\n")[0])
	print(">>> ...%s" % t.substr(t.find("owned, not")).split("\n")[0] if t.find("owned, not") >= 0 else ">>> (not owned in this save)")
	var comps = CommandRegistry.main_candidates().filter(func(c): return str(c).begins_with("driver -add"))
	print(">>> completions: %s" % [comps])
	Drivers.owned = keep
	get_tree().quit()
