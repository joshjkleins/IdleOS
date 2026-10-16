extends BaseTerminal
## Decoding terminal: consumes one cache at a time and reveals its hex dump one byte per speed step.
## Each item row pays out when its last byte is revealed. Loot + variant rules come from CacheData;
## Corruption caches can corrupt after any find, losing the rest of that cache.

@onready var labels_container = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/LabelsContainer
@onready var hex_display = $MarginContainer/VBoxContainer/HexDisplay
@onready var cache_name = $MarginContainer/VBoxContainer/CachesDisplayContainer/CacheName
@onready var caches_display_container = $MarginContainer/VBoxContainer/CachesDisplayContainer

@onready var cache_decrypt = CacheDecrypting.new()

const C_CORRUPT = "#e24b4a"

var items_from_session = {} #reference for labels
var item_label = preload("res://scenes/cache_item_label.tscn")
var target_cache: ItemData = null
var current_cache: CacheData = null

func set_cache_type(p_type: Dictionary, window: bool = false, cache: ItemData = null):
	setup_process(Decoding, p_type, window)
	target_cache = cache

func _ready():
	cache_decrypt.item_found.connect(update_items_gained)

func start_decrypting():
	begin_run()
	clear_labels()
	items_from_session = {}
	while _has_requirements() and running:
		if stop_requested:
			finish_safely()
			return
		cache_decrypt.reset()

		if target_cache != null and Inventory.get_amount(target_cache) > 0:
			current_cache = target_cache
		else:
			current_cache = Inventory.get_cache()
		cache_name.text = current_cache.name + " x" + str(Inventory.get_amount(current_cache))
		cache_name.remove_theme_color_override("font_color")
		Inventory.remove_resource(current_cache, 1)
		cache_decrypt.build_dump(current_cache)
		hex_display.text = cache_decrypt.render_dump()

		var cycle_mode := Mode.NORMAL
		var times_to_update = cache_decrypt.HEX_CHARACTERS_SIZE * cache_decrypt.row_count()
		for i in range(times_to_update):
			if !running or cache_decrypt.corrupted:
				break
			cache_decrypt.update_dump()
			hex_display.text = cache_decrypt.render_dump()
			var mode := get_mode()
			cycle_mode = worst_mode(cycle_mode, mode)
			await get_tree().create_timer(get_step_time(mode)).timeout

		apply_heat(cycle_mode) # one heat tick per cache (also when killed mid-cache)
		if !running:
			return

		if cache_decrypt.corrupted:
			_show_corruption()
			await get_tree().create_timer(1.0).timeout
			if !running:
				return

		process_data.signal.emit(1)
		record_cycle(1)
		Tutorial.track_event(Tutorial.TutorialEvent.DECODE_1_STUDENT_CACHE, 1)
		Exp.add_xp(Decoding, process_data, process_data["experience per level"])
		Signals.update_hud(Decoding)
		if randf() <= 0.01:
			Inventory.add_resource(Items.VM_DECODING_TOKEN, 1)

	if running:
		finish_safely() # out of caches

func _has_requirements() -> bool:
	if target_cache != null:
		return Inventory.get_amount(target_cache) > 0
	return Inventory.has_cache()

func _show_corruption() -> void:
	hex_display.text += "[color=%s]>> DATA CORRUPTED :: cache integrity lost, remaining sectors unrecoverable[/color]" % C_CORRUPT
	cache_name.text = current_cache.name + "  [CORRUPTED]"
	cache_name.add_theme_color_override("font_color", Color(C_CORRUPT))

func clear_labels():
	for n in labels_container.get_children():
		n.queue_free()

func update_items_gained(item, amount):
	if items_from_session.has(item.name):
		items_from_session[item.name] += amount
	else:
		items_from_session[item.name] = amount
	clear_labels()
	for i in items_from_session.keys():
		var new_label = item_label.instantiate()
		new_label.update(i, items_from_session[i])
		labels_container.add_child(new_label)
	Inventory.add_resource(item, amount)

	# Corruption variant: each find (except the last) can corrupt the rest of the cache
	cache_decrypt.items_found += 1
	if current_cache and current_cache.get_variant() == CacheData.CacheVariant.CORRUPTION:
		if cache_decrypt.items_found < cache_decrypt.items_total and randf() < CacheData.CORRUPTION_CHANCE:
			cache_decrypt.corrupted = true
