extends Node
func _ready():
	var bad = []
	for loc in Stats.hacking_targets:
		for t in Stats.hacking_targets[loc].targets:
			var c = t.get("loot")
			if c and Inventory.get_item_by_name(str(c.name).to_lower()) == null:
				bad.append(c.name)
	print(">>> caches 'ls' can't find by lowercase name: ", bad)
	get_tree().quit()
