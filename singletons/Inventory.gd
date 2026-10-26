extends Node

enum InventoryFilter { ALL, CACHES, VALUABLES, RESOURCES }
var inventory := {}

func has_item_by_id(id: int) -> bool:
	for i in inventory:
		if i.id == id:
			return true
	return false

func get_amount(resource: ItemData) -> int:
	if inventory.has(resource):
		return inventory[resource]
	return 0

func add_resource(resource: ItemData, amount):
	if inventory.has(resource):
		inventory[resource] += amount
	else:
		inventory[resource] = amount
	var sfx_to_play = Audiomanager.get_sfx_from_item(resource)
	if sfx_to_play != "":
		Audiomanager.play_sfx(sfx_to_play, 0.05)
	Signals.item_added(resource, amount)

func remove_resource(resource: ItemData, amount: int) -> bool:
	if not inventory.has(resource):
		return false
	if inventory[resource] < amount:
		return false
	
	inventory[resource] -= amount
	
	if inventory[resource] <= 0:
		inventory.erase(resource)
	
	Signals.item_removed(resource, amount)
	return true

func _matches_filter(resource, filter: InventoryFilter) -> bool:
	match filter:
		InventoryFilter.CACHES:
			return resource.name.contains("cache")
		#InventoryFilter.VALUABLES:
			#return resource.valuable
		InventoryFilter.RESOURCES:
			return !resource.valuable and !resource.name.contains("cache")
		_:
			return true

func list_specific_item(item: ItemData):
	var item_name = "Name: " + item.name
	var amount = "Current amount: " + str(get_amount(item))
	var description = "Description: " + item.description
	
	var of = []
	for i in item.obtained_from:
		var text = item.ItemColor.keys()[i].capitalize()
		var c = Palette.get_color(i)
		var hex = c.to_html(false)
		of.append("[color=#%s]%s[/color]" % [hex, text])
	
	var obtained_from = "Obtained from: " + ", ".join(of)
	if item.obtained_from_additional_hint != "":
		obtained_from += " - " + item.obtained_from_additional_hint
	
	var mu_text = item.ItemColor.keys()[item.color_type].capitalize()
	var c = Palette.get_color(item.color_type)
	var hex = c.to_html(false)
	
	var main_use = "Main use: [color=#%s]%s[/color]" % [hex, mu_text]
	
	var text = "\n"
	text += item_name + "\n"
	var tier = item_tier(item)
	text += "Type: %s%s\n" % [TYPE_TITLES[item_type(item)].capitalize(), ("  ·  " + tier_tag(tier)) if tier > 0 else ""]
	text += amount + "\n"
	text += description + "\n"
	text += obtained_from + "\n"
	text += main_use + "\n"
	var src = producer(item)
	if !src.is_empty() and !src.inputs.is_empty():
		var made = " + ".join(src.inputs.map(func(x): return x[0].name))
		var info_cmd = ""
		for skill in [Cracking, Matching, Compiling]:
			for p in skill.minor_processes:
				if p.get("resource gained") is ItemData and p["resource gained"] == item:
					info_cmd = "info %s %s" % [skill.SKILL.name.to_lower(), p.name.to_lower().replace(" ", "-")]
		text += "Made from: %s  [color=#666666](%s)%s[/color]\n" % [made, src.cmd, ("  ·  full chain: " + info_cmd) if info_cmd != "" else ""]
	text += "\n"
	text += used_in_text(item)
	
	if item.hacking_mod_duration != 0 and item.hacking_mod_item: # mod items only ('compile -mod' is retired)
		var hacking_mod_value = HackingMods.get_mod_value_text(item.hacking_mod_type, item.hacking_mod_value)
		var hacking_mod_name = HackingMods.get_mod_name(item.hacking_mod_type)
		var hacking_mod_display = "Hacking Mod\n"
		hacking_mod_display += "├─ " + hacking_mod_name + " " + hacking_mod_value + "\n"
		if item.hacking_mod_item:
			hacking_mod_display += "└─ Manage this mod with the 'mod' command · lasts %d hacks\n\n" % HackingMods.mod_duration(item)
		else:
			var cost = Compiling.mod_fill_cost(item)
			var parts = cost.keys().map(func(k): return "%s x%d" % [k.name, cost[k]])
			hacking_mod_display += "├─ Per hack: " + " + ".join(parts) + "  [color=#666666](compile -mod=%s builds it one hack at a time)[/color]\n" % item.name.to_lower()
			hacking_mod_display += "└─ Up to %d hacks  [color=#666666](%d with the Debug modifier)[/color]\n\n" % [Compiling.mod_cap(item), Compiling.mod_cap(item, true)]
		text += hacking_mod_display
	
	if item.contained_items.size() > 0:
		var names = []
		for i in item.contained_items:
			names.append(i.name)
		var all_names = ", ".join(names)
		text += "Parsing these logs can find the following items: " + all_names + "\n\n"
	
	if Exploits.is_exploit(item):
		text += Exploits.info_text(item)

	if item is CombatItem:
		match item.type:
			"Attack":
				text += "Integrity damage: " + str(item.damage) + "\n"
				text += "Firewall damage: " + str(item["firewall_damage"]) + "\n"
				text += "Bandwidth cost: " + str(item["bandwidth_cost"]) + "\n"
				text += "Attack speed: " + get_combat_item_speed_text(item) + "/s\n"
			"Heal":
				text += "Integrity restore: " + str(item.heal) + "\n"
				text += "Bandwidth cost: " + str(item["bandwidth_cost"]) + "\n"
				text += "Attack speed: " + get_combat_item_speed_text(item) + "/s\n"
	
	if item is CacheData:
		if item.get_variant() != CacheData.CacheVariant.BASE:
			text += "[color=#dd9426]" + item.get_variant_description() + "[/color]\n\n"
		text += "Potential items\n"
		var rows: Array = Decoding.get_drop_table(item)
		var name_width = 0
		for row in rows:
			name_width = max(name_width, row.name.length())
		for row in rows:
			text += _build_cache_item_row(row, name_width)
		text += "\n"

	if item.name.contains("VM"):
		text += "[color=#666666]for usage details use 'ssh -h'.[/color]\n"
	return text

## row: {name, min, max, chance, rare} from CacheData.get_drop_table()
func _build_cache_item_row(row: Dictionary, name_width: int) -> String:
	var amount_text = "x%d" % row.min if row.min == row.max else "x%d-%d" % [row.min, row.max]
	var chance_text = "%.0f%%" % (row.chance * 100)
	var line = "  %-*s   %-8s %6s" % [name_width, row.name, amount_text, chance_text]
	if row.rare:
		line += "  [color=#888888](rare)[/color]"
	return line + "\n"

func get_item_by_name(item_name: String) -> ItemData:
	var name = item_name.to_lower().strip_edges()
	
	# Remove surrounding quotes
	if name.begins_with('"') and name.ends_with('"'):
		name = name.trim_prefix('"').trim_suffix('"').strip_edges()
	if name.begins_with('\'') and name.ends_with('\''):
		name = name.trim_prefix('\'').trim_suffix('\'').strip_edges()
	# Exact match
	var item = Items.ITEM_NAME_MAP.get(name)
	if item != null:
		return item
	
	# Player typed singular, stored item might be plural
	item = Items.ITEM_NAME_MAP.get(name + "s")
	if item != null:
		return item
		
	item = Items.ITEM_NAME_MAP.get(name + "s cache")
	if item != null:
		return item
	
	item = Items.ITEM_NAME_MAP.get(name + "es")
	if item != null:
		return item
	
	item = Items.ITEM_NAME_MAP.get(name + "es cache")
	if item != null:
		return item
		
	# Player typed plural, stored item might be singular
	if name.ends_with("es"):
		item = Items.ITEM_NAME_MAP.get(name.left(-2))
		if item != null:
			return item
	
	if name.ends_with("s"):
		item = Items.ITEM_NAME_MAP.get(name.left(-1))
		if item != null:
			return item
	
	return null

func get_combat_item_speed_text(item: CombatItem) -> String:
	var sp = 1.0 / (100.0 / item.speed)
	return "%.2f" % sp

func list_inventory(filter: InventoryFilter = InventoryFilter.ALL) -> String:
	var amount_width = 15
	var output = ""
	var has_items := false

	var max_name_length = 0
	var resources := []

	for resource in inventory.keys():
		if inventory[resource] > 0 and _matches_filter(resource, filter):
			resources.append(resource)

			if resource.name.length() > max_name_length:
				max_name_length = resource.name.length()

	resources.sort_custom(func(a, b):
		if a.color_type == b.color_type:
			return a.name.nocasecmp_to(b.name) < 0
		return a.color_type < b.color_type
	)

	var name_width = max_name_length + 5

	output += pad_text("Items", name_width + 1)
	output += pad_text("Amount", amount_width)
	output += "Description\n"
	output += pad_text("--------", name_width + 1)
	output += pad_text("------", amount_width)
	output += "-----------\n"

	for resource in resources:
		var amount: int = inventory[resource]

		var c = Palette.get_color(resource.color_type)
		var hex = c.to_html(false)

		has_items = true
		var temp_name = pad_text(resource.name, name_width)

		output += "[color=%s]▍[/color]" % hex
		output += temp_name
		output += pad_text(str(amount), amount_width)
		output += resource.description + "\n"

	if not has_items:
		return "You have no items."
	
	output += "\nuse 'ls <item>' for additional item information.\n\n"
	return output

func pad_text(value, width: int) -> String:
	var text := str(value)
	if text.length() >= width:
		return text.substr(0, width)
	return text + " ".repeat(width - text.length())

func get_cache() -> CacheData:
	for i in inventory:
		if i.name.to_lower().contains("cache"):
			return i
	return null #should never hit this

func has_cache() -> bool:
	for i in inventory:
		if i.name.to_lower().contains("cache"):
			return true
	return false

func has_specific_cache(cache_name: String) -> bool:
	var item = get_item_by_name(cache_name)
	if get_amount(item) > 0:
		return true
	return false

func has_valuables() -> bool:
	for i in inventory:
		if i.valuable:
			return true
	return false

func has_intel() -> bool:
	for i in inventory:
		if i.upgrade_ingredient:
			return true
	return false

func get_all_valuables() -> Array:
	if !has_valuables():
		return []
	var vals = []
	for i in inventory:
		if i.valuable:
			vals.append(i)
	return vals

func save_data() -> Dictionary:
	var serializable := {}
	for item in inventory:
		serializable[str(item.id)] = inventory[item]
	
	return {
		"inventory": serializable
	}


func load_data(data: Dictionary) -> void:
	inventory.clear()
	var raw: Dictionary = data.get("inventory", {})
	for id_str in raw:
		var id := int(id_str)
		var item: ItemData = Items.ITEM_MAP.get(id)
		if item == null:
			push_warning("Unknown item id in save: %s" % id_str)
			continue
		inventory[item] = int(raw[id_str])


#example command: crack -vm use=mining create=parsing
func get_vm_token_by_skill_name(skill_name: String) -> ItemData:
	var skills_with_vm_tokens = [Mining, Parsing, Cracking, Matching, Phishing, Decoding, Compiling]
	for skill in skills_with_vm_tokens:
		if skill_name.to_lower() == skill.SKILL.name.to_lower():
			return skill.vm_token
	return null


func has_mod_item():
	for i in inventory:
		if i.hacking_mod_item:
			return true
	return false

func get_hacking_mods_items() -> Array:
	var hacking_items = []
	if inventory.is_empty():
		return hacking_items
	
	for i in inventory:
		if i.hacking_mod_item:
			hacking_items.append(i)
	return hacking_items

#Logs.....+5 damage.......10 hacks.......x100
func list_inventory_hacking_mods():
	if inventory.is_empty():
		return "Inventory is empty."
	
	var col_1 = 5
	var col_2 = 10
	for item in inventory:
		if item.name.length() > col_1:
			col_1 = item.name.length()
	col_1 += 5
	var return_text = "\n\n"
	return_text += pad_text("ITEM", col_1) + pad_text("HACKING MOD", 40) + pad_text("DURATION", 15) + pad_text("REQUIRED", 10) + pad_text("CURRENT AMOUNT", 20)
	return_text += "\n" + "-".repeat(120)
	for item in inventory:
		if !item.is_compilable_mod():
			continue
		var first_col = item.name + " ".repeat(col_1 - item.name.length())
		var second_col = HackingMods.get_mod_name(item.hacking_mod_type) + " " + HackingMods.get_mod_value_text(item.hacking_mod_type, item.hacking_mod_value)
		var third_col = str(int(item.hacking_mod_duration)) + " hacks"
		#var fourth_col = HackingMods.get_mod_value_text(item.hacking_mod_type, item.hacking_mod_value)
		var fifth_col = "x" + str(item.hacking_mod_consumed)
		var sixth_col = str(Inventory.get_amount(item))
		
		return_text += "\n" + pad_text(first_col, col_1) + pad_text(second_col, 40) + pad_text(third_col, 15) + pad_text(fifth_col, 10) + pad_text(sixth_col, 20)
	return return_text


#region item types, tiers and grouped 'ls' (2026-10-19)
## Item type, worked out from data the items already have (no per-item tagging). Matches the 'ls -h' glossary.
const TYPE_ORDER = ["resource", "payload", "combat", "cache", "rare", "mod", "exploit", "token"]
const TYPE_TITLES = {"resource": "RESOURCES", "payload": "PAYLOADS", "combat": "COMBAT", "cache": "CACHES",
	"rare": "RARE ITEMS", "mod": "MOD ITEMS", "exploit": "EXPLOITS", "token": "VM TOKENS"}
const TYPE_FLAGS = {"resources": "resource", "resource": "resource", "res": "resource", "payloads": "payload", "payload": "payload",
	"combat": "combat", "caches": "cache", "cache": "cache", "rares": "rare", "rare": "rare", "valuables": "rare",
	"mods": "mod", "mod": "mod", "exploits": "exploit", "exploit": "exploit", "one-time": "exploit", "onetime": "exploit",
	"tokens": "token", "token": "token", "vm": "token"}
var _rare_tiers := {}   # rare item -> tier of the cache it drops from
var _payloads := {}     # payload item -> tier

func _build_type_index() -> void:
	if !_rare_tiers.is_empty() or !_payloads.is_empty():
		return
	for it in Items.ITEM_MAP.values():
		if it is CacheData:
			var t = Exploits.cache_tier(it)
			for e in it.rare_pool:
				if e.item and (!_rare_tiers.has(e.item) or t < _rare_tiers[e.item]):
					_rare_tiers[e.item] = t
	var k = 0
	for p in Compiling.get_payload_processes():
		k += 1
		_payloads[p["resource gained"]] = k

func item_type(item: ItemData) -> String:
	_build_type_index()
	if item is CacheData:
		return "cache"
	if item.exploit_id != "":
		return "exploit"
	if item.hacking_mod_item:
		return "mod"
	if item in Decoding.vm_tokens():
		return "token"
	if item == Items.SQL_INJECTOR or item == Items.PACKET_SPOOF:
		return "combat"
	if _payloads.has(item):
		return "payload"
	if _rare_tiers.has(item):
		return "rare"
	return "resource"

## Location tier (1 School .. 6 Government), 0 = none (tokens, combat). Worked out from where the item comes from,
## not the item's own tier field (which defaults to 1 for most items).
func item_tier(item: ItemData) -> int:
	_build_type_index()
	match item_type(item):
		"cache":
			return Exploits.cache_tier(item)
		"rare":
			return int(_rare_tiers.get(item, 0))
		"payload":
			return int(_payloads.get(item, 0))
		"exploit", "mod":
			return int(item.tier)
		"resource":
			var t = Decoding.get_resource_tier(item)
			if t == 0:
				for i in range(Mining.minor_processes.size()):
					if Mining.minor_processes[i]["resource gained"] == item:
						return i + 1
			return t
	return 0

func tier_tag(tier: int) -> String:
	return Exploits.tier_name(tier) if tier > 0 else ""

## 'ls [filters]': grouped by type. Filters (any order, combined): -<type> (see TYPE_FLAGS), -<skill> (what that skill
## makes), a location (school, lawfirm, ... or t1..t6), and any other words as a name search.
## Returns {"text": String, "single": ItemData or null}: single = exactly one name match (show its details).
func list_filtered(args: String) -> Dictionary:
	var types := []
	var skills := []
	var tiers := []
	var words := []
	var skill_names = {}
	for i in ItemData.ItemColor.keys().size():
		skill_names[ItemData.ItemColor.keys()[i].to_lower()] = i
	var locs = Stats.hacking_targets.keys().map(func(k): return k.to_lower())
	for w in args.to_lower().split(" ", false):
		var bare = w.trim_prefix("-")
		if w.begins_with("-") and TYPE_FLAGS.has(bare):
			types.append(TYPE_FLAGS[bare])
		elif w.begins_with("-") and skill_names.has(bare) and bare not in ["default", "upgrade", "consumable"]:
			skills.append(skill_names[bare])
		elif bare in locs:
			tiers.append(locs.find(bare) + 1)
		elif bare.length() == 2 and bare.begins_with("t") and bare[1].is_valid_int():
			tiers.append(int(bare[1]))
		elif w.begins_with("-"):
			return {"text": "Unknown filter: %s  [color=#666666](types: %s · skills: -mining ... · locations: school, lawfirm ... or t1..t6 · 'ls -h')[/color]" % [w, ", ".join(["-caches", "-rares", "-resources", "-payloads", "-mods", "-exploits", "-tokens", "-combat"])], "single": null}
		else:
			words.append(w)
	var search = " ".join(words)
	var picked := []
	for item in inventory.keys():
		if inventory[item] <= 0:
			continue
		if !types.is_empty() and !(item_type(item) in types):
			continue
		if !tiers.is_empty() and !(item_tier(item) in tiers):
			continue
		if !skills.is_empty():
			var hit = false
			for sk in skills:
				if sk in item.obtained_from or skill_uses(sk, item):
					hit = true
			if !hit:
				continue
		if search != "" and !item.name.to_lower().contains(search):
			continue
		picked.append(item)
	# (a name search always lists, even with one hit, so 'ls vm' looks the same whatever you own; exact
	# names like 'ls vm cache' are handled before this by get_item_by_name)
	if picked.is_empty():
		return {"text": "No items match '%s'. [color=#666666]('ls' lists everything · 'ls -h' explains item types)[/color]" % args.strip_edges(), "single": null}
	if skills.size() == 1:
		return {"text": _skill_text(skills[0], picked), "single": null}
	return {"text": _grouped_text(picked, args.strip_edges() != ""), "single": null}

## Items a skill takes in (ItemColor index): what its processes consume
func skill_uses(sk: int, item: ItemData) -> bool:
	match sk:
		ItemData.ItemColor.PARSING:
			return item.parsable or item is CacheData
		ItemData.ItemColor.PHISHING:
			return Phishing.is_bait(item)
		ItemData.ItemColor.DECODING:
			return item is CacheData
		ItemData.ItemColor.HACKING:
			return item_type(item) in ["payload", "combat", "mod", "exploit"]
		ItemData.ItemColor.CRACKING, ItemData.ItemColor.MATCHING, ItemData.ItemColor.COMPILING:
			var skill = {ItemData.ItemColor.CRACKING: Cracking, ItemData.ItemColor.MATCHING: Matching, ItemData.ItemColor.COMPILING: Compiling}[sk]
			for p in skill.minor_processes:
				if p.get("requirements") is Dictionary and p.requirements.has(item):
					return true
			return sk == ItemData.ItemColor.COMPILING and item_type(item) == "rare"
	return false

## 'ls -<skill>': what the skill MAKES and what it USES, as two sections
func _skill_text(sk: int, items: Array) -> String:
	var title = ItemData.ItemColor.keys()[sk].to_upper()
	var makes = items.filter(func(i): return sk in i.obtained_from)
	var uses = items.filter(func(i): return !(sk in i.obtained_from))
	var name_w = 8
	for it in items:
		name_w = max(name_w, it.name.length())
	name_w += 3
	var out = ""
	if !makes.is_empty():
		out += _section(title + " · MAKES", makes, name_w)
	if !uses.is_empty():
		out += _section(title + " · USES", uses, name_w)
	return out + "\n[color=#666666]'ls <item>' for details · 'info %s <process>' shows a process's full recipe[/color]" % title.to_lower()

func _section(title: String, list: Array, name_w: int) -> String:
	list.sort_custom(func(a, b):
		if item_tier(a) != item_tier(b):
			return item_tier(a) < item_tier(b)
		return a.name.nocasecmp_to(b.name) < 0)
	var out = "\n[color=#e0c068]%s[/color] [color=#444444]%s[/color] [color=#888888]%d %s[/color]\n" % [title, "─".repeat(max(4, name_w + 14 - title.length())), list.size(), "kind" if list.size() == 1 else "kinds"]
	for it in list:
		out += _row(it, name_w)
	return out

func _row(it: ItemData, name_w: int) -> String:
	var hex = Palette.get_color(it.color_type).to_html(false)
	var desc: String = it.description
	if desc.length() > LS_DESC_WIDTH:
		desc = desc.left(LS_DESC_WIDTH - 1) + "…"
	return "[color=%s]▍[/color]%s%s%s[color=#888888]%s[/color]\n" % [hex, pad_text(it.name, name_w), pad_text(_ls_amount(int(inventory.get(it, 0))), 12),
		pad_text(tier_tag(item_tier(it)), 11), desc]

#region recipe tree ('info <skill> <process>')
## How an item is made: {"cmd": String, "inputs": [[item, amount], ...], "skill": skill singleton} or {} (not made by a process)
func producer(item: ItemData) -> Dictionary:
	for p in Mining.minor_processes:
		if p["resource gained"] == item:
			return {"cmd": p.command, "inputs": [], "skill": Mining}
	for skill in [Cracking, Matching, Compiling]:
		for p in skill.minor_processes:
			if p.get("resource gained") is ItemData and p["resource gained"] == item and p.get("requirements") is Dictionary:
				return {"cmd": p.command, "inputs": p.requirements.keys().map(func(k): return [k, int(p.requirements[k])]), "skill": skill}
	for p in Mining.minor_processes:
		var mined: ItemData = p["resource gained"]
		if item in mined.contained_items:
			return {"cmd": "parse -footprint=%s" % mined.name.to_lower(), "inputs": [[mined, 0]], "skill": Parsing} # 0: finds are chance-based
	if item_type(item) == "combat":
		return {"cmd": "phish -spear", "inputs": [], "skill": Phishing}
	return {}

## The full chain under <process> (whatever it makes), with how many you have of each. "" when it has no inputs.
func recipe_text(process: Dictionary) -> String:
	if !(process.get("requirements") is Dictionary) or process.requirements.is_empty():
		return ""
	var lines := []
	var root = process.get("resource gained")
	var root_name = root.name if root is ItemData else process.name
	lines.append([root_name + "  [color=#666666]<- %s[/color]" % process.command, root, 0, ""])
	var keys = process.requirements.keys()
	for i in keys.size():
		_recipe_lines(keys[i], int(process.requirements[keys[i]]), "", i == keys.size() - 1, lines, 0)
	var w = 0
	for l in lines:
		w = max(w, _plain_len(l[3] + l[0]))
	w += 3
	var out = "\n[color=#4ec9b0]RECIPE[/color] [color=#666666]· %s · what you have now[/color]\n" % root_name
	for l in lines:
		var text = l[3] + l[0]
		var have = "" if l[1] == null else _ls_amount(get_amount(l[1]))
		var short = l[1] != null and l[2] > 0 and get_amount(l[1]) < l[2]
		out += text + " ".repeat(max(1, w - _plain_len(text))) + ("[color=#e24b4a]%s[/color]" % have if short else have) + "\n"
	return out + "[color=#666666]red = fewer than one cycle needs[/color]\n"

func _recipe_lines(item: ItemData, amount: int, prefix: String, last: bool, lines: Array, depth: int) -> void:
	var src = producer(item)
	var label = (("%s x%d" % [item.name, amount]) if amount > 0 else item.name) + ("  [color=#666666]<- %s[/color]" % src.cmd if !src.is_empty() else "")
	lines.append([label, item, amount, prefix + ("└─ " if last else "├─ ")])
	if src.is_empty() or depth > 6:
		return
	var inputs: Array = src.inputs
	for i in inputs.size():
		_recipe_lines(inputs[i][0], inputs[i][1], prefix + ("   " if last else "│  "), i == inputs.size() - 1, lines, depth + 1)

static func _plain_len(t: String) -> int:
	var re = RegEx.new()
	re.compile("\\[[^\\]]*\\]")
	return re.sub(t, "", true).length()
#endregion

func list_inventory_grouped() -> String:
	var items = inventory.keys().filter(func(i): return inventory[i] > 0)
	if items.is_empty():
		return "You have no items."
	return _grouped_text(items, false)

const LS_DESC_WIDTH := 64

func _grouped_text(items: Array, filtered: bool) -> String:
	var name_w = 8
	for it in items:
		name_w = max(name_w, it.name.length())
	name_w += 3
	var groups := {}
	for it in items:
		var t = item_type(it)
		if !groups.has(t):
			groups[t] = []
		groups[t].append(it)
	var out = ""
	for t in TYPE_ORDER:
		if !groups.has(t):
			continue
		var list: Array = groups[t]
		list.sort_custom(func(a, b):
			var ta = item_tier(a)
			var tb = item_tier(b)
			if ta != tb:
				return ta < tb
			if a.color_type != b.color_type:
				return a.color_type < b.color_type
			return a.name.nocasecmp_to(b.name) < 0)
		var total = 0
		for it in list:
			total += int(inventory[it])
		out += "\n[color=#e0c068]%s[/color] [color=#444444]%s[/color] [color=#888888]%d %s[/color]\n" % [TYPE_TITLES[t], "─".repeat(max(4, name_w + 14 - TYPE_TITLES[t].length())), list.size(), "kind" if list.size() == 1 else "kinds"]
		for it in list:
			var hex = Palette.get_color(it.color_type).to_html(false)
			var desc: String = it.description
			if desc.length() > LS_DESC_WIDTH:
				desc = desc.left(LS_DESC_WIDTH - 1) + "…"
			out += "[color=%s]▍[/color]%s%s%s[color=#888888]%s[/color]\n" % [hex, pad_text(it.name, name_w), pad_text(_ls_amount(int(inventory[it])), 12),
				pad_text(tier_tag(item_tier(it)), 11), desc]
	if filtered:
		out += "\n[color=#666666]'ls <item>' for details and where it's used · 'ls' for everything[/color]"
	else:
		out += "\n" + _filters_help()
	return out

## Filter help under plain 'ls': one row per kind of filter, commands aligned in columns
func _filters_help() -> String:
	var rows = [
		["By type", ["ls -resources", "ls -payloads", "ls -combat", "ls -caches"]],
		["", ["ls -rares", "ls -mods", "ls -exploits", "ls -tokens"]],
		["By skill", ["ls -mining", "ls -parsing", "ls -cracking", "ls -matching"], "what it makes + uses"],
		["By location", ["ls school", "ls lawfirm", "ls t2"]],
		["By name", ["ls cred", "ls payload"], "any part of a name"],
		["Combine", ["ls -caches school", "ls -rares t2"]],
	]
	var out = "[color=#4ec9b0]FILTERS[/color]\n"
	for i in rows.size():
		var r = rows[i]
		var branch = "└─ " if i == rows.size() - 1 else ("├─ " if r[0] != "" else "│  ")
		var cmds = ""
		for c in r[1]:
			cmds += pad_text(c, 18)
		out += "[color=#666666]%s[/color]%s[color=#888888]%s[/color]%s\n" % [branch, pad_text(r[0], 13), cmds, ("[color=#666666]" + r[2] + "[/color]") if r.size() > 2 else ""]
	return out + "[color=#666666]'ls <item>' for details and where it's used · 'ls -h' explains the item types[/color]"

static func _ls_amount(n: int) -> String:
	var s = str(n)
	var o = ""
	while s.length() > 3:
		o = "," + s.right(3) + o
		s = s.left(s.length() - 3)
	return s + o

## 'ls <item>': the places it goes, as commands you can type
func used_in_text(item: ItemData) -> String:
	var rows := []
	var t = item_type(item)
	# process inputs (Cracking, Matching, Compiling payloads)
	for skill in [Cracking, Matching, Compiling]:
		for p in skill.minor_processes:
			if p.get("requirements") is Dictionary and p.requirements.has(item):
				rows.append(["%s %s" % [skill.SKILL.name, p.name], p.get("command", "")])
	if item.parsable and !(item is CacheData):
		rows.append(["Parsing", "parse -footprint=%s  [color=#666666](and the other parse processes)[/color]" % item.name.to_lower()])
	if Phishing.is_bait(item):
		rows.append(["Phishing bait", "phish -spear bait=%s  [color=#666666](10 per cast)[/color]" % item.name.to_lower()])
	if Uploads.is_rare(item):
		# surplus rares: Mod Phishing bait once the upload goal for them is met (1 per cast, a guaranteed mod of its tier)
		var rt = item_tier(item)
		var mods = ", ".join(HackingMods.pool_items(rt).map(func(m): return m.name))
		if Phishing.is_rare_bait(item):
			rows.append(["Mod Phishing bait", "phish -mod bait=%s  [color=#666666](1 per cast, guarantees one of: %s)[/color]" % [item.name.to_lower(), mods]])
		else:
			rows.append(["Mod Phishing bait", "[color=#666666]after the %s upload goal for it is met (%d/%d): then each cast guarantees one of: %s[/color]" % [Uploads.get_location_name(rt), Uploads.get_uploaded(item), Uploads.get_goal_amount(item, rt), mods]])
	if t == "cache":
		rows.append(["Decoding", "decode -cache=%s" % item.name.to_lower()])
		if item.get_variant() == CacheData.CacheVariant.BASE:
			rows.append(["Parsing (variants)", "parse -<variant>=%s  [color=#666666](Footprint, Network, Corruption, Extraction)[/color]" % item.name.to_lower()])
	if item.is_compilable_mod():
		rows.append(["Hacking mod", "compile -mod=%s  [color=#666666](%s %s)[/color]" % [item.name.to_lower(), HackingMods.get_mod_name(item.hacking_mod_type), HackingMods.get_mod_value_text(item.hacking_mod_type, item.hacking_mod_value)]])
	if t == "mod":
		rows.append(["Hacking mod", "mod  [color=#666666](manage your mods)[/color]"])
	if t == "exploit":
		rows.append(["During a hack", Exploits.use_cmd(item)])
	if t == "combat":
		rows.append(["Hacking", "used by every %s in a hack" % ("attack" if item == Items.SQL_INJECTOR else "spoof")])
	if t == "token":
		rows.append(["VM windows", "ssh -h"])
	# hacking requirements and access recipes
	for loc in Stats.hacking_targets:
		var l = Stats.hacking_targets[loc]
		if l.get("required payload") == item:
			rows.append(["Hacking", "hack <target> in %s  [color=#666666](payloads per hack)[/color]" % loc])
		for tg in l.get("targets", []):
			var r = Stats.get_access_recipe(tg)
			if !r.is_empty() and r.get("rare") == item:
				rows.append(["Target access", "unlock %s in Hacking  [color=#666666](%d needed)[/color]" % [tg.name.to_lower(), int(r.rare_amount)]])
	# upload goal
	if Uploads.is_goal_item(item):
		rows.append(["Upload goal", "%d/%d uploaded for %s  [color=#666666](upload %s <amount>)[/color]" % [Uploads.get_uploaded(item), Uploads.get_goal_amount(item), Uploads.get_location_name(Uploads.current_tier()), item.name.to_lower()]])
	if rows.is_empty():
		return ""
	var w = 8
	for r in rows:
		w = max(w, r[0].length())
	var out = "[color=#4ec9b0]USED IN[/color]\n"
	for i in rows.size():
		out += "%s %s  %s\n" % ["└─" if i == rows.size() - 1 else "├─", pad_text(rows[i][0], w), rows[i][1]]
	return out + "\n"
#endregion
