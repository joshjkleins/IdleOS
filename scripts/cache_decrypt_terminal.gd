extends PanelContainer

@onready var cache_name = $MarginContainer/VBoxContainer/CacheName
@onready var labels_container = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/LabelsContainer
@onready var hex_display = $MarginContainer/VBoxContainer/HexDisplay

@onready var cache_decrypt = CacheDecrypting.new()

var items_from_session = {} #reference for labels
var running: bool = false
var can_apply_heat: bool = true
var safe_stop: bool = false

var item_label = preload("res://scenes/cache_item_label.tscn")

func _ready():
	Signals.item_found_in_cache_signal.connect(update_items_gained)

func start_decrypting():
	clear_labels()
	items_from_session = {}
	running = true
	safe_stop = false
	while Inventory.has_cache() and running:
		if safe_stop:
			Signals.end_cache_decrypting_safely()
			break
		cache_decrypt.reset()
		can_apply_heat = true
		if !Inventory.has_cache():
			print("No cache")
			return
			
		var current_cache = Inventory.get_cache()
		cache_name.text = current_cache.name + " x" + str(Inventory.get_amount(current_cache))
		Inventory.remove_resource(current_cache, 1)
		#build body
		cache_decrypt.build_dump(current_cache)
		
		hex_display.text = cache_decrypt.render_dump()
		
		var times_to_update = cache_decrypt.HEX_CHARACTERS_SIZE * cache_decrypt.DUMP_SIZE
		
		var overclocked_this_cache = Stats.overclocked
		for i in range(times_to_update):
			if !running:
				apply_heat(overclocked_this_cache)
				break
			cache_decrypt.update_dump()
			hex_display.text = cache_decrypt.render_dump()
			var speed
			var heat
			if Stats.overclocked:
				speed = Stats.player_stats["Cache Decrypting"]["overclock speed"]
				overclocked_this_cache = true
			elif Stats.overheated:
				speed = Stats.player_stats["Cache Decrypting"]["overheat speed"]
			else:
				speed = Stats.player_stats["Cache Decrypting"]["base speed"]
			await get_tree().create_timer(speed).timeout
		if !running:
			apply_heat(overclocked_this_cache)
			break
		
		#finished with a single cache
		apply_heat(overclocked_this_cache)
		Stats.add_xp(Stats.player_stats["Cache Decrypting"])
		
		Signals.update_hud(Stats.player_stats["Cache Decrypting"])
		#Signals.update_module_header("Cache Decrypting")

func apply_heat(overclocked_this_cache):
	if can_apply_heat:
		can_apply_heat = false
		var heat
		if overclocked_this_cache:
			heat = Stats.player_stats["Cache Decrypting"]["overclock heat"]
		elif Stats.overheated:
			heat = Stats.player_stats["Cache Decrypting"]["overheat heat"]
		else:
			heat = Stats.player_stats["Cache Decrypting"]["heat"]
		Stats.update_tempature(heat)

func clear_labels():
	for n in labels_container.get_children():
		n.queue_free()

func update_items_gained(item, amount):
	if items_from_session.has(item.name):
		items_from_session[item.name] += amount
	else:
		items_from_session[item.name] = amount
	
	#rebuild
	clear_labels()
	
	for i in items_from_session.keys():
		var new_label = item_label.instantiate()
		new_label.update(i, items_from_session[i])
		labels_container.add_child(new_label)
	
	Inventory.add_resource(item, amount)

func stop():
	safe_stop = false
	running = false

func stop_safely():
	safe_stop = true
