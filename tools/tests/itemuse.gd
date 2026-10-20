extends Node
## Recipes and USED IN text, to check item descriptions against.
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 5: await get_tree().process_frame
	var rt = RichTextLabel.new(); rt.bbcode_enabled = true; add_child(rt)
	for skill in [Cracking, Matching, Compiling]:
		for p in skill.minor_processes:
			if p.get("requirements") is Dictionary and p.get("resource gained") is ItemData:
				print("RECIPE %s: %s <- %s" % [skill.SKILL.name, p["resource gained"].name, ", ".join(p.requirements.keys().map(func(k): return "%s x%d" % [k.name, p.requirements[k]]))])
	for p in Mining.minor_processes:
		var m: ItemData = p["resource gained"]
		print("PARSE %s -> %s" % [m.name, ", ".join(m.contained_items.map(func(i): return i.name))])
	var picks = ["Logs", "Parents credit card", "Patient appointment history", "Cash Drawer Override Codes", "Student cache", "Student cache Footprint", "SQL Injector", "Packet Spoof", "VM mining token", "PINS", "School payload", "Bio Template", "SQL Booster"]
	for n in picks:
		var it = Inventory.get_item_by_name(n)
		if it == null:
			print("?? " + n); continue
		rt.text = Inventory.used_in_text(it)
		print("== %s\n%s" % [n, rt.get_parsed_text()])
	get_tree().quit()
