extends Node
## Easy-mode targets per location + hacking upgrade totals per tier (combat pass input).
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 5: await get_tree().process_frame
	var out := ["loc\ti\tname\tintegrity\tfirewall\tcounter\tcounter speed\theat\texp\treq\tintel stat\tloot\tkeys"]
	for loc in Stats.hacking_targets:
		var L = Stats.hacking_targets[loc]
		var i = 0
		for t in L.targets:
			i += 1
			var req = t.requirements
			out.append("\t".join([loc, str(i), t.name, str(t.integrity), str(t.firewall), str(t.counter), str(t["counter speed"]), str(t.heat), str(t.exp),
				"%s x%d" % [req.item.name, req.amount], str(t.get("intel stat", "")), t.loot.name if t.loot else "", ",".join(t.keys())]))
	out.append("")
	for id in Upgrades.packages:
		if id.begins_with("hacking."):
			var p = Upgrades.packages[id]
			var tots = []
			for tt in range(1, 7):
				tots.append(str(snappedf(p.levels.filter(func(l): return int(l.tier) <= tt).reduce(func(a, l): return a + float(l.get("value", 0)), 0.0), 0.001)))
			out.append("UPG\t%s\t%s\t%s\t%s" % [id, p.type, " ".join(tots), str(p.get("effect", ""))])
	var f = FileAccess.open(OS.get_environment("HOME") + "/mnt/idle-os-prototype/_to_delete/combatdump.tsv", FileAccess.WRITE)
	f.store_string("\n".join(out)); f.close()
	print(">>> ok")
	get_tree().quit()
