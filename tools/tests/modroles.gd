extends Node
## Each tier's items by mod role (Mining item, parsed -> Cracking / Matching / Compiling, cracked, matched,
## payload, rares in cache order, base caches in target order). Writes _to_delete/modroles.tsv (tier, role, path).
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 5: await get_tree().process_frame
	var out := []
	var pays = Compiling.get_payload_processes()
	var locs = Stats.hacking_targets.keys()
	for t in range(1, 7):
		var mp = Mining.minor_processes[t - 1]
		var mined: ItemData = mp["resource gained"]
		out.append([t, "mining", mined.resource_path])
		var pay = pays[t - 1]
		var matched: ItemData = null
		var compile_in: ItemData = null
		for r in pay.requirements:
			if r in mined.contained_items: compile_in = r
			else: matched = r
		out.append([t, "parsed_compile", compile_in.resource_path])
		out.append([t, "matched", matched.resource_path])
		out.append([t, "payload", pay["resource gained"].resource_path])
		for m in Matching.minor_processes:
			if m["resource gained"] is ItemData and m["resource gained"] == matched:
				for r in m.requirements:
					if r in mined.contained_items:
						out.append([t, "parsed_match", r.resource_path])
					else:
						out.append([t, "cracked", r.resource_path])
						for c in Cracking.minor_processes:
							if c["resource gained"] is ItemData and c["resource gained"] == r:
								out.append([t, "encrypted", c.requirements.keys()[0].resource_path])
		var k = 0
		for tg in Stats.hacking_targets[locs[t - 1]].targets:
			k += 1
			out.append([t, "cache%d" % k, tg.loot.resource_path])
			for e in tg.loot.rare_pool:
				if e.item: out.append([t, "rare%d" % k, e.item.resource_path])
	var f = FileAccess.open(OS.get_environment("HOME") + "/mnt/idle-os-prototype/_to_delete/modroles.tsv", FileAccess.WRITE)
	f.store_string("\n".join(out.map(func(r): return "\t".join(r.map(func(x): return str(x))))))
	f.close()
	print(">>> %d" % out.size())
	get_tree().quit()
