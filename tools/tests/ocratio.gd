extends Node
func _ready() -> void:
	for sk in [Mining, Parsing, Cracking, Matching, Phishing, Decoding, Compiling]:
		for p in sk.minor_processes:
			var sp = ""; var ht = ""
			for pair in [["base speed", "overclock speed"], ["cast time", "overclock cast time"], ["download time", "overclocked download time"]]:
				if p.has(pair[0]) and p.has(pair[1]) and float(p[pair[1]]) > 0:
					sp += "%s x%.2f " % [pair[0].split(" ")[0], float(p[pair[0]]) / float(p[pair[1]])]
			if p.has("heat") and p.has("overclock heat") and float(p.heat) > 0:
				ht = "x%.2f" % (float(p["overclock heat"]) / float(p.heat))
			print(">>> %-10s %-12s speed %-40s heat %s" % [sk.SKILL.name, p.name, sp, ht])
	get_tree().quit()
