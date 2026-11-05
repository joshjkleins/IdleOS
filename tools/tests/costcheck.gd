extends Node
## 2026-11-05: every upgrade cost item resolves to an ItemData
func _ready() -> void:
	var bad = []
	var n = 0
	for id in Upgrades.packages:
		for l in Upgrades.packages[id].levels:
			for c in l.costs:
				n += 1
				if !str(c.item).begins_with("@") and Upgrades.get_item(c.item) == null:
					bad.append("%s T%d %s" % [id, l.tier, c.item])
	print(">>> costs %d  unresolved %s" % [n, bad])
	get_tree().quit()
