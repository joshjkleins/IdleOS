extends Node
## 2026-11-14: 'mod -refresh' re-equips active mods from spares
var os
func _ready() -> void:
	_run.call_deferred()
func _f(n := 30) -> void:
	for i in n: await get_tree().process_frame
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	await _f()
	if os._booting or Tutorial.show_intro: os._finish_boot()
	await _f(60)
	os.accepting_player_inputs = true
	var keep_mods = HackingMods.current_mods.duplicate(true)
	HackingMods.current_mods.clear()
	var mods = []
	for it in Items.ITEM_MAP.values():
		if it.hacking_mod_item and int(it.tier) == 1 and mods.size() < 3 and HackingMods.free_slot_for(it.hacking_mod_type) != -1:
			HackingMods.add_mod(it)
			mods.append(it)
	var m = mods[0]
	var key = m.hacking_mod_type
	print(">>> mod: %s  (full = %d hacks)" % [m.name, HackingMods.mod_duration(m)])
	HackingMods.current_mods[key].duration = 1
	Inventory.add_resource(m, 1 - Inventory.get_amount(m))
	os.universal_commands("mod -refresh")
	print(">>> worn (1 hack) + 1 spare -> hacks %d, spares %d" % [HackingMods.current_mods[key].duration, Inventory.get_amount(m)])
	os.universal_commands("mod -refresh")
	print(">>> full, no spare -> hacks %d, spares %d" % [HackingMods.current_mods[key].duration, Inventory.get_amount(m)])
	Inventory.add_resource(m, 3)
	os.universal_commands("mod -refresh")
	print(">>> full + 3 spares -> hacks %d, spares %d (none used)" % [HackingMods.current_mods[key].duration, Inventory.get_amount(m)])
	HackingMods.current_mods[key].duration = 2
	os.universal_commands("mod -refresh")
	print(">>> worn (2) + 3 spares -> hacks %d, spares %d" % [HackingMods.current_mods[key].duration, Inventory.get_amount(m)])
	Inventory.remove_resource(m, Inventory.get_amount(m))
	HackingMods.current_mods = keep_mods
	get_tree().quit()
