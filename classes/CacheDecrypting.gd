class_name CacheDecrypting
extends RefCounted

#TODO
# update colors on reveal letters/codes
# make it a random index of which it gets revealed (maybe if 12 data then 12 lines are revealed 1 data each)
# maybe make random lettters and words for non-item lines

const DUMP_SIZE: int = 20
const MAX_ASCII_LEN: int = 13

var pad_between_cols = "    "
var hex_body: String = ""

var hd_id = []
var hd_rows = []       # current display state (starts as all ??)
var hd_code = []       # current display state (starts as all ...)
var hd_rows_final = [] # pre-baked resolved version
var hd_code_final = [] # pre-baked resolved version

var current_row: int = 0
var current_index: int = 0
var finished: bool = false

func shorten_label(name: String) -> String:
	if name.length() <= MAX_ASCII_LEN:
		return name
	var parts = name.split("_") if "_" in name else name.split(" ")
	if parts.size() > 1:
		var joined = ""
		for p in parts:
			joined += p.substr(0, 4) + "_"
		return joined.rstrip("_").substr(0, MAX_ASCII_LEN)
	return name.substr(0, MAX_ASCII_LEN - 2) + ".."

func build_dump(cache: CacheData):
	var all_entries: Array = []
	for entry in cache.entries:
		all_entries.append(entry)
	for entry in cache.rare_pool:
		all_entries.append(entry)

	# pre-bake final resolved rows for each item
	var item_finals = {}
	for idx in range(all_entries.size()):
		var entry = all_entries[idx]
		var label = shorten_label(entry.item.name)
		var bytes = label.to_utf8_buffer()
		var max_offset = 13 - bytes.size()
		var col_offset = randi_range(0, max(0, max_offset))

		# build the final resolved hex row
		var final_row = []
		for col in range(13):
			var byte_index = col - col_offset
			if byte_index >= 0 and byte_index < bytes.size():
				final_row.append("%02X" % bytes[byte_index])
			else:
				final_row.append("%02X" % ((idx * 13 + col) % 256))

		# build the final resolved code row
		var final_code = []
		final_code.append("|")
		for col in range(13):
			var byte_index = col - col_offset
			var ascii_pos = col * 2
			var c1 = "."
			var c2 = "."
			if byte_index >= 0 and byte_index < label.length():
				if byte_index * 2 < label.length():
					c1 = label.substr(byte_index * 2, 1)
				if byte_index * 2 + 1 < label.length():
					c2 = label.substr(byte_index * 2 + 1, 1)
			final_code.append(c1)
			final_code.append(c2)
		final_code.append("|")

		item_finals[idx] = { "row": final_row, "code": final_code }

	# now build all display rows
	for i in range(DUMP_SIZE):
		hd_id.append("0x%04d" % (10 * i))

		# unresolved starting state
		var c_row = []
		for j in range(13):
			c_row.append("??")
		hd_rows.append(c_row)

		var code_row = ["|"]
		for k in range(24):
			code_row.append(".")
		code_row.append("|")
		hd_code.append(code_row)

		# resolved final state (item row or fake hex)
		if item_finals.has(i):
			hd_rows_final.append(item_finals[i]["row"])
			hd_code_final.append(item_finals[i]["code"])
		else:
			var fake_row = []
			for col in range(13):
				fake_row.append("%02X" % ((i * 13 + col) % 256))
			hd_rows_final.append(fake_row)
			var fake_code = ["|"]
			for k in range(24):
				fake_code.append(".")
			fake_code.append("|")
			hd_code_final.append(fake_code)

func update_dump() -> bool:
	# resolve current cell from pre-baked final
	hd_rows[current_row][current_index] = hd_rows_final[current_row][current_index]
	
	# resolve the two ascii chars this hex col maps to
	var ascii_pos = 1 + (current_index * 2)
	if ascii_pos <= 24:
		hd_code[current_row][ascii_pos] = hd_code_final[current_row][ascii_pos]
	if ascii_pos + 1 <= 24:
		hd_code[current_row][ascii_pos + 1] = hd_code_final[current_row][ascii_pos + 1]

	current_index += 1
	if current_index >= 13:
		current_index = 0
		current_row += 1
		if current_row >= DUMP_SIZE:
			finished = true
			return false

	# highlight next cell
	hd_rows[current_row][current_index] = "[bgcolor=#1a2a1a]%s[/bgcolor]" % hd_rows_final[current_row][current_index]
	return true

func render_dump() -> String:
	hex_body = ""
	#build all rows
	for i in range(DUMP_SIZE):
		if i > current_row:
			break
		hex_body += hd_id[i] + pad_between_cols + " ".join(hd_rows[i]) + pad_between_cols + "".join(hd_code[i]) + "\n"
		
	return hex_body
