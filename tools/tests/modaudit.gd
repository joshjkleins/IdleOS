extends Node
## Every in-game item's hacking mod stats (compile -mod) + directly equippable mods + exploits, by tier/type.
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 5: await get_tree().process_frame
	var out := []
	for it in Items.ITEM_MAP.values():
		var t = Inventory.item_tier(it)
		var ty = Inventory.item_type(it)
		if t == 0 and ty not in ["combat", "token", "exploit", "mod"]:
			continue
		var mt = HackingMods.MOD_TYPE.keys()[it.hacking_mod_type] if it.hacking_mod_type < HackingMods.MOD_TYPE.size() else str(it.hacking_mod_type)
		out.append("\t".join([str(t), ty, it.name, mt, str(it.hacking_mod_value), str(it.hacking_mod_duration), str(it.hacking_mod_consumed), str(it.hacking_mod_item), it.exploit_id]))
	var f = FileAccess.open(OS.get_environment("HOME") + "/mnt/idle-os-prototype/_to_delete/modaudit.tsv", FileAccess.WRITE)
	f.store_string("\n".join(out)); f.close()
	print(">>> %d" % out.size())
	get_tree().quit()
