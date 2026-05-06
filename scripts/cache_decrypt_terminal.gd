extends Control

@onready var cache_name = $MarginContainer/VBoxContainer/CacheName
@onready var hex_display = $MarginContainer/VBoxContainer/Control/HexDisplay
@onready var labels_container = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/LabelsContainer

@onready var cache_decrypt = CacheDecrypting.new()

var items_from_session = {} #reference for labels

var item_label = preload("res://scenes/cache_item_label.tscn")

const TIME_PER_INDEX = 0.05

func _ready():
	Signals.item_found_in_cache_signal.connect(update_items_gained)

func start_decrypting():
	clear_labels()
	items_from_session = {}
	while Inventory.has_cache():
		
		cache_decrypt.reset()
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
		for i in range(times_to_update):
			cache_decrypt.update_dump()
			hex_display.text = cache_decrypt.render_dump()
			await get_tree().create_timer(TIME_PER_INDEX).timeout

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
