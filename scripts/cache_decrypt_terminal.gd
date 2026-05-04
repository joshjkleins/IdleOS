extends Control


#func add_line_success(text: String):
	#add_line("[color=#4ec994]" + text + "[/color]")  # green
#
#func add_line_error(text: String):
	#add_line("[color=#e24b4a]" + text + "[/color]")  # red
#
#func add_line_warning(text: String):
	#add_line("[color=#ef9f27]" + text + "[/color]")  # amber
#
#func add_line_system(text: String):
	#add_line("[color=#888888]" + text + "[/color]")  # muted gray
#
#func add_line_highlight(text: String):
	#add_line("[color=#7f77dd]" + text + "[/color]")  # purple
@onready var cache_name = $PanelContainer/MarginContainer/VBoxContainer/CacheName
@onready var cache_decrypt = CacheDecrypting.new()
@onready var hex_display = $PanelContainer/MarginContainer/VBoxContainer/Control/HexDisplay

const TIME_PER_INDEX = 0.08

func _ready():
	start_decrypting()

func start_decrypting():
	if !Inventory.has_cache():
		print("No cache")
		return
		
	var current_cache = Inventory.get_cache()
	cache_name.text = current_cache.name
	#build body
	cache_decrypt.build_dump(current_cache)
	
	hex_display.text = cache_decrypt.render_dump()
	
	var times_to_update = cache_decrypt.hd_rows[0].size() * cache_decrypt.hd_rows.size()
	for i in range(times_to_update):
		cache_decrypt.update_dump()
		hex_display.text = cache_decrypt.render_dump()
		await get_tree().create_timer(TIME_PER_INDEX).timeout
		
	print("Done decrypting")
