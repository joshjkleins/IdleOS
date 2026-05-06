class_name CacheDecrypting
extends RefCounted

const DUMP_SIZE: int = 5 #ROWS IN THE DUMP
const HEX_CHARACTERS_SIZE: int = 13 #number of ?? in body

var pad_between_cols = "    "
var hex_body: String = ""

var dump_info = {}

var current_row: int = 0
var current_index: int = 0

#order
# in build dump also build what the real arrays will be
# first get loot from cache, roll how many items and quantity of each will drop
# once that is determined - determine which rows they will appear on (maybe bring dump down to just 5 lines?)
# this way the background can be set when building the original array, will also need to set in |..| array
# determine if each iteration is an item pull, or not, and update colors acordingly
# when an item is revealed, add it to bottom and add it to player inventory. Consume cache at start.

# var example dump_info = {
# 	"left": ["0x0000", "0x0010"],
# 	"codes": {
# 		0: [{"hex": "F8", "char": "D"}, {"hex": "14", "char": "A"}, {"hex": "A4", "char": "T"}, {"hex": "14", "char": "A"}]
# 	}
# }

func reset():
	current_row = 0
	current_index = 0

#when it is confirmed player has a cache, this function builds a 'dump' which is 3 arrays filled with the placeholder characters for the module (0x0000, ?? ??, |...|)
func build_dump(cache: CacheData):
	dump_info = {}
	var loot = get_potential_items(cache)
	
	var id_array = []
	for i in range(DUMP_SIZE): #how many rows total (roughly 5 ish)
		var hex_start = 10 * i
		var formatted_str: String = "0x%04d" % hex_start
		id_array.append(formatted_str)
	dump_info["left"] = id_array
	
	dump_info["codes"] = {}
	for i in range(DUMP_SIZE):
		var codes_array = get_random_hexes(HEX_CHARACTERS_SIZE)
		dump_info["codes"][i] = codes_array


#builds entire hex dump based on a combination of placeholder data and real data
func render_dump() -> String:
	hex_body = ""
	for i in range(DUMP_SIZE):
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

#calling this updates the current index (column) and row, iteration through the entire dump
func update_dump() -> bool:
	current_index += 1

	if current_index > dump_info["codes"][current_row].size():
		current_index = 1
		current_row += 1

		if current_row >= dump_info["codes"].size():
			return false

	return true

func get_potential_items(cache: CacheData) -> Dictionary:
	var loot = {}
	for item in cache.entries:
		if randf() <= item.drop_chance:
			var quant = randi_range(item.min_quantity, item.max_quantity)
			loot[item.item] = quant
	##DO RARE ITEMS NEXT
	#not current conditions if loot is empty
	return loot

func string_to_hex(s: String) -> String:
	var bytes = s.to_utf8_buffer()
	return " ".join(bytes.map(func(b): return "%02X" % b))


func get_random_hexes(num: int) -> Array:
	var result: Array = []
	
	#10% chance of blank row
	if randf() < 0.1:
		for i in range(num):
			var byte_value = randi_range(32, 126)
			while byte_value == 91 or byte_value == 93:
				byte_value = randi_range(32, 126)
			var hex_value = char(byte_value)
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
		
