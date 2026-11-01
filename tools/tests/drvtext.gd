extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 20: await get_tree().process_frame
	for id in ["cheap_spoof", "salvage_rights"]:
		for r in [1,2,3]:
			print(">>> %s r%d: %s | %s" % [Drivers.DEFS[id].name, r, Drivers.value_text(id, r), Drivers.short_text(id, r)])
	Drivers.owned["salvage_rights"] = 2000000
	if !Drivers.is_equipped("salvage_rights"): Drivers.equipped.get_or_add("Decoding", []).append("salvage_rights")
	print(">>> value %s" % Drivers.value("salvage_rights"))
	for id in Exploits.DEFS:
		var it = Exploits.get_item(id)
		if it: print(">>> %s base %d -> %d" % [id, Exploits.DEFS[id].cost, Exploits.cost(it)])
	get_tree().quit()
