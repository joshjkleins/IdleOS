extends Node
## Every item in Items.ITEM_MAP: tier field vs location tier, type, and description (tab separated).
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 5: await get_tree().process_frame
	var out := []
	for key in Items.ITEM_MAP:
		var it: ItemData = Items.ITEM_MAP[key]
		var src = Inventory.producer(it)
		out.append("\t".join([str(key), it.resource_path.trim_prefix("res://items/"), it.name, str(it.tier), str(Inventory.item_tier(it)),
			Inventory.item_type(it), "mod" if it.is_compilable_mod() else "", str(it.get_obtained_from_skills()), it.obtained_from_additional_hint,
			it.description.replace("\n", " / ")]))
	var f = FileAccess.open(OS.get_environment("HOME") + "/mnt/idle-os-prototype/_to_delete/itemdump.tsv", FileAccess.WRITE)
	f.store_string("\n".join(out))
	f.close()
	print(">>> %d items" % out.size())
	get_tree().quit()
