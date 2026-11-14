extends Node
func _ready() -> void:
	var seen = {}
	for it in Items.ITEM_MAP.values():
		if it.hacking_mod_item:
			var k = "%s/%s" % [it.hacking_mod_type, it.tier]
			seen[k] = seen.get(k, []) + [it.name]
	var dup = 0
	for k in seen:
		if seen[k].size() > 1:
			dup += 1
			print(">>> dup ", k, seen[k])
	print(">>> mod items %d  type/tier keys %d  dups %d" % [seen.values().reduce(func(a, b): return a + b.size(), 0), seen.size(), dup])
	get_tree().quit()
