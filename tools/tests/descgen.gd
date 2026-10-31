extends Node
## Proposes item descriptions from the live data (recipes, cache pools, variants). Writes path\told\tnew.
func _ready() -> void:
	_run.call_deferred()
func _a(word: String) -> String:
	return ("an " if word.left(1).to_lower() in ["a", "e", "i", "o", "u"] else "a ") + word
func _consumer(item: ItemData) -> Array:
	for skill in [Cracking, Matching, Compiling]:
		for p in skill.minor_processes:
			if p.get("requirements") is Dictionary and p.get("resource gained") is ItemData and p.requirements.has(item):
				return [skill, p]
	return []
func _other(p: Dictionary, item: ItemData) -> ItemData:
	for k in p.requirements:
		if k != item:
			return k
	return null
func _run() -> void:
	for i in 5: await get_tree().process_frame
	var rt = RichTextLabel.new(); rt.bbcode_enabled = true; add_child(rt)
	var rare_from := {}
	for it in Items.ITEM_MAP.values():
		if it is CacheData and it.get_variant() == CacheData.CacheVariant.BASE:
			for e in it.rare_pool:
				if e.item:
					rare_from.get_or_add(e.item, []).append(it)
	var out := []
	for it in Items.ITEM_MAP.values():
		var t = Inventory.item_tier(it)
		var ty = Inventory.item_type(it)
		if t == 0 and ty not in ["combat", "token"]:
			continue
		var loc = Exploits.tier_name(t) if t > 0 else ""
		var d := ""
		match ty:
			"cache":
				match it.get_variant():
					CacheData.CacheVariant.BASE:
						var role = it.name.substr(0, it.name.to_lower().rfind(" cache"))
						d = "Received from hacking %s %s. Decode it for resources and a chance at a rare item, or Parse it into a variant." % [_a(loc), role]
					CacheData.CacheVariant.FOOTPRINT:
						d = "Cache variant. Decodes for double the basic resources, but never a rare item."
					CacheData.CacheVariant.CORRUPTION:
						d = "Cache variant. +%d%% chance on every drop (rare included), but each find has a %d%% chance to corrupt the rest of the cache." % [roundi(CacheData.CORRUPTION_DROP_BONUS * 100), roundi(CacheData.CORRUPTION_CHANCE * 100)]
					CacheData.CacheVariant.NETWORK:
						d = "Cache variant. Always drops VM caches: 1 to its tier + %d." % CacheData.NETWORK_VM_CACHE_EXTRA
					CacheData.CacheVariant.EXTRACTION:
						d = "Cache variant. When its rare item drops, you get %d instead of 1." % (1 + CacheData.EXTRACTION_EXTRA_RARE)
			"rare":
				var roles = rare_from.get(it, []).map(func(c): return c.name.substr(0, c.name.to_lower().rfind(" cache")))
				rt.text = Inventory.used_in_text(it)
				var access = "Target access" in rt.get_parsed_text()
				d = "Rare find from %s %s caches." % [loc, "/".join(roles)]
				if access:
					d += " Used to compile access to the next target."
				elif "Upload goal" in rt.get_parsed_text():
					d += " Needed for the %s upload goal." % loc
			"payload":
				d = "A compiled payload, used to hack %s targets." % loc
			"combat":
				var src = "Caught with 'phish -spear' or found by parsing with Corruption. Upgrade it with 'apt'."
				d = ("Basic attack used in every hack. " if it == Items.SQL_INJECTOR else "Restores anonymity during a hack. ") + src
			"token":
				d = it.description if it.description.ends_with("('ssh').") else it.description.trim_suffix(".") + " ('ssh')."
			"resource":
				var src = Inventory.producer(it)
				var con: Array = _consumer(it)
				var from := ""
				if src.get("skill") == Mining:
					var finds = it.contained_items.map(func(c): return c.name)
					d = "Obtained from Mining. Parse it for %s, or use it as Phishing bait." % (", ".join(finds.slice(0, finds.size() - 1)) + " and " + finds[-1])
				else:
					if src.get("skill") == Parsing:
						from = "Obtained by Parsing %s." % src.inputs[0][0].name
					elif src.get("skill") == Cracking:
						from = "Cracked from %s." % src.inputs[0][0].name
					elif src.get("skill") == Matching:
						from = "Matched from %s and %s." % src.inputs.map(func(x): return x[0].name)
					if con.is_empty():
						d = from
					elif con[0] == Cracking:
						d = "%s Crack it for %s." % [from, con[1]["resource gained"].name]
					elif con[0] == Matching:
						d = "%s Match it with %s to make %s." % [from, _other(con[1], it).name, con[1]["resource gained"].name]
					else:
						d = "%s Used with %s to compile %s." % [from, _other(con[1], it).name, con[1]["resource gained"].name]
		if d != "" and d != it.description:
			out.append("\t".join([it.resource_path, it.description, d]))
	var f = FileAccess.open(OS.get_environment("HOME") + "/mnt/idle-os-prototype/_to_delete/descgen.tsv", FileAccess.WRITE)
	f.store_string("\n".join(out)); f.close()
	print(">>> %d changes" % out.size())
	get_tree().quit()
