class_name CacheDecrypting
extends RefCounted

signal item_found(item, amount)

const DUMP_SIZE: int = 5 #ROWS IN THE DUMP
const HEX_CHARACTERS_SIZE: int = 20 #number of ?? in body

var pad_between_cols = "    "
var hex_body: String = ""

var dump_info = {}

var current_row: int = 0
var current_index: int = 0

var corrupted: bool = false # Corruption variant: set when a find corrupts the cache
var items_found: int = 0
var items_total: int = 0

func reset():
	current_row = 0
	current_index = 0
	corrupted = false
	items_found = 0
	items_total = 0

func row_count() -> int:
	return dump_info["codes"].size()

#when it is confirmed player has a cache, this function builds a 'dump' which is 3 arrays filled with the placeholder characters for the module (0x0000, ?? ??, |...|)
func build_dump(cache: CacheData):
	dump_info = {}
	var loot: Array = get_potential_items(cache) # [{item, amount, rare}]
	items_total = loot.size()

	var all_codes: Array = []
	var rare_codes: Array = []
	for drop in loot:
		var codes_array = get_item_hexes(drop.item, drop.amount)
		# Corruption: the rare row is decoded last, so a corruption can lose it
		if drop.rare and cache.get_variant() == CacheData.CacheVariant.CORRUPTION:
			rare_codes.append(codes_array)
		else:
			all_codes.append(codes_array)
	while all_codes.size() + rare_codes.size() < DUMP_SIZE:
		all_codes.append(get_random_hexes(HEX_CHARACTERS_SIZE))
	all_codes.shuffle()
	all_codes.append_array(rare_codes)

	# one address per row; the dump grows past DUMP_SIZE when a cache has more drops
	var id_array = []
	for i in range(all_codes.size()):
		id_array.append("0x%04d" % (10 * i))
	dump_info["left"] = id_array

	dump_info["codes"] = {}
	for i in range(all_codes.size()):
		dump_info["codes"][i] = all_codes[i]

#builds entire hex dump based on a combination of placeholder data and real data
func render_dump() -> String:
	hex_body = ""
	for i in range(row_count()):
		if i > current_row:
			break
		
		#ID
		hex_body += dump_info["left"][i] + pad_between_cols

		#HEX COLS
		var row = ""
		var words = "|"
		for j in range(dump_info["codes"][i].size()):
			if current_index > j or current_row > i:
				if current_index == (j + 1) and current_row == i:
					row += "[bgcolor=#4ec994]" + dump_info["codes"][i][j]["hex"] + "[/bgcolor]"
					words += dump_info["codes"][i][j]["char"]
					if dump_info["codes"][i][j].has("item"):
						#Signals.item_found_in_cache(dump_info["codes"][i][j]["item"], dump_info["codes"][i][j]["amount"])
						item_found.emit(dump_info["codes"][i][j]["item"], dump_info["codes"][i][j]["amount"])
				else:
					row += dump_info["codes"][i][j]["hex"]
					words += dump_info["codes"][i][j]["char"]
			else:
				row += "??"
				words += "."
			row += " "
		row.strip_edges()

		hex_body += row + pad_between_cols
		words += "|"
		hex_body += words + "\n"
	
	return hex_body

#calling this updates the current index (column) and row, iterating through the entire dump
func update_dump() -> bool:
	current_index += 1

	if current_index > dump_info["codes"][current_row].size():
		current_index = 1
		current_row += 1

		if current_row >= dump_info["codes"].size():
			return false

	return true

## Returns [{item, amount, rare}] (rare last). Variant rules live in CacheData.roll_loot().
func get_potential_items(cache: CacheData) -> Array:
	# tutorial: the very first Student cache drops everything, including the rare item
	if not Decoding.first_cache_decoded and cache == Items.STUDENT_CACHE:
		var loot = []
		for entry in cache.entries:
			loot.append({"item": entry.item, "amount": randi_range(entry.min_quantity, entry.max_quantity), "rare": false})
		loot.append({"item": cache.rare_pool.pick_random().item, "amount": 1, "rare": true})
		Decoding.first_cache_decoded = true
		SaveManager.mark_dirty()
		return loot
	return Decoding.roll_loot(cache)

func get_item_hexes(item, amount) -> Array:
	var result: Array = []
	#get item name
	var n
	if item["shortened_name"] == "":
		n = item.name
	else:
		n = item["shortened_name"]
	#get item name length
	var n_length = n.length()
	#determine if > or < HEX_Char_size
	var item_hex_array: Array = []
	
	for i in range(n_length):
		var n_char = n[i]
		var is_final = (i == n_length - 1)
		
		var hex_value = "%02X" % n_char.unicode_at(0)

		
		if is_final:
			item_hex_array.append({
				"hex": "[color=#dd9426]" + hex_value + "[/color]",
				"char": "[color=#dd9426]" + n_char + "[/color]",
				"item": item,
				"amount": amount
			})
		else:
			item_hex_array.append({
				"hex": "[color=#dd9426]" + hex_value + "[/color]",
				"char": "[color=#dd9426]" + n_char + "[/color]"
			})
		
		
		var max_starting_point = HEX_CHARACTERS_SIZE - item_hex_array.size()
		var start = randi_range(0, max_starting_point)
		var random_hex_array = get_random_hexes(HEX_CHARACTERS_SIZE - item_hex_array.size(), false)
		
		if start == 0:
			result = item_hex_array + random_hex_array
		else:
			var beginning_array = random_hex_array.slice(0, start)
			var end_array = random_hex_array.slice(start)
			result = beginning_array + item_hex_array + end_array
	
	return result

func get_random_hexes(num: int, blank_lines: bool = true) -> Array:
	var result: Array = []
	
	#10% chance of blank row
	if randf() < 0.1 and blank_lines:
		for i in range(num):
			result.append({
				"hex": "00",
				"char": "."
			})
	else:
		for i in range(num):
			var byte_value = randi_range(32, 126)
			while byte_value == 91 or byte_value == 93:
				byte_value = randi_range(32, 126)
			var hex_value = char(byte_value)
			result.append({
				"hex": "%02X" % byte_value,
				"char": hex_value
			})

	return result
