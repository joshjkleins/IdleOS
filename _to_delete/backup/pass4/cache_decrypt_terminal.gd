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
var target_cache: ItemData = null # Cache / Skim / Deep: only this cache (null = any). Salvage: the item.
var target_arg = null # Intel: the target dictionary
var current_cache: CacheData = null

## p_type picks what gets decoded ("decode kind"): cache, skim, deep (caches), salvage (an item),
## intel (a hacking target). <arg> is the cache / item / target the command named (or null).

func set_cache_type(p_type: Dictionary, window: bool = false, arg = null):
	setup_process(Decoding, p_type, window)
	if arg is ItemData:
		target_cache = arg
	else:
		target_arg = arg

var drop_rates: RichTextLabel # current cache's drop table (Cache / Skim / Deep)

func heat_tier_mult() -> float:
	var it = current_cache if current_cache else target_cache
	var t = Inventory.item_tier(it) if it else Upgrades.working_tier("Decoding")
	return Stats.tier_heat(Decoding.HEAT_BY_TIER, t if t > 0 else Upgrades.working_tier("Decoding"))

func _ready():
	cache_decrypt.item_found.connect(update_items_gained)
	drop_rates = RichTextLabel.new()
	drop_rates.bbcode_enabled = true
	drop_rates.fit_content = true
	drop_rates.scroll_active = false
	drop_rates.add_theme_font_size_override("normal_font_size", 11)
	drop_rates.visible = false
	caches_display_container.get_parent().add_child(drop_rates)
	caches_display_container.get_parent().move_child(drop_rates, caches_display_container.get_index() + 1)

## One line: "DROPS  Logs 5-10 (100%) · ... · RARE Parents credit card x1 (19.8%)" for the current process.
## Two lines under the cache: DROPS (basics, VM cache, tokens) and RARE (rare items, one-time items,
## rare tracker). Name, amount, chance.
func _show_drop_rates(cache: CacheData) -> void:
	var basics = []
	var rares = []
	for r in Decoding.get_drop_table(cache, process_data, Decoding.FORENSICS_EXPLOIT_MULT if _mod() == "forensics" else 1.0):
		var qty = str(r.min) if r.min == r.max else "%d-%d" % [r.min, r.max]
		var pct = ("%.1f%%" % (r.chance * 100.0)).replace(".0%", "%")
		if r.rare:
			rares.append("[color=#e0c068]%s[/color] x%s [color=#7d6a3a]%s[/color]" % [r.name, qty, pct])
		else:
			basics.append("[color=#c8d0d8]%s[/color] %s [color=#5c6b7a]%s[/color]" % [r.name, qty, pct])
	if process_data == Decoding.SKIM:
		basics.append("[color=#5c6b7a]%.1f%% chance for +50%% basics[/color]" % (Decoding.get_efficiency(Decoding.SKIM) * 100.0))
	var tb = Decoding.tracker_bonus(cache) if Decoding.get_rare_chance(process_data) > 0.0 else 0.0
	if tb > 0.0:
		rares.append("[color=#7d6a3a]rare tracker +%.2f%% (%d dry)[/color]" % [tb * 100.0, int(Decoding.rare_tracker.get(Decoding.cache_family(cache), 0))])
	var sep = "   [color=#3a444e]|[/color]   "
	var t = "[color=#5c6b7a]DROPS[/color]  " + sep.join(basics)
	if !rares.is_empty():
		t += "\n[color=#7d6a3a]RARE[/color]   " + sep.join(rares)
	drop_rates.text = t
	drop_rates.visible = true

func _kind() -> String:
	return process_data.get("decode kind", "cache")


## Modifiers work on the cache processes and Salvage, not on Intel
func modifier_block_reason() -> String:
	if _kind() == "intel":
		return "Decoding modifiers work on Cache, Skim, Deep Scan and Salvage, not on %s." % process_data.name
	return ""

func _mod() -> String:
	return str(modifier.get("command", ""))

func start_decrypting():
	begin_run()
	clear_labels()
	items_from_session = {}
	match _kind():
		"salvage":
			await _run_salvage()
		"intel":
			await _run_intel()
		_:
			await _run_caches()
	if running:
		finish_safely() # out of things to decode

## Reveals the current dump one byte per speed step. Returns the worst mode seen (decides heat).
var _cycle_seconds := 0.0 # real seconds this pass took (VM tokens roll on time)
var _cycle_steps := 0

## Reveals one byte per step time. Time is banked per frame, so steps shorter than a frame (high Speed)
## reveal several bytes in that frame instead of being capped at one byte per frame.
func _reveal_dump() -> Mode:
	var cycle_mode := Mode.NORMAL
	var times_to_update = cache_decrypt.HEX_CHARACTERS_SIZE * cache_decrypt.row_count()
	_cycle_seconds = 0.0
	_cycle_steps = 0
	var banked := 0.0
	for i in range(times_to_update):
		if !running or cache_decrypt.corrupted:
			break
		var mode := get_mode()
		cycle_mode = worst_mode(cycle_mode, mode)
		var t := get_step_time(mode)
		while banked < t and running:
			await get_tree().process_frame
			banked += get_process_delta_time()
		if !running:
			break
		banked -= t
		cache_decrypt.update_dump()
		hex_display.text = cache_decrypt.render_dump()
		_cycle_seconds += t
		_cycle_steps += 1
	return cycle_mode

## VM token chance for the pass just finished, rolled on time spent (speed, Compression and overclock don't
## change tokens per hour): "vm token chance" is for a base-speed pass, scaled by how long this one took.
## Token Vault and Forensics double it.
func _token_chance() -> float:
	var base = float(process_data["base speed"]) * max(1, _cycle_steps)
	var chance = (float(process_data.get("vm token chance", 0.01)) + Exp.vm_token_level_bonus(skill)) * (_cycle_seconds / max(0.001, base))
	if Upgrades.has("decoding.token_vault"):
		chance *= 2.0
	if has_modifier("forensics"):
		chance *= 2.0
	return chance

## After every finished cache / salvage / intel pass.
func _cycle_done(cycle_mode: Mode) -> void:
	apply_heat(cycle_mode)
	process_data.signal.emit(1)
	record_cycle(1)
	Exp.add_xp(Decoding, process_data, process_data["experience per level"] * (2 if has_modifier("survey") else 1))
	Signals.update_hud(Decoding)
	if randf() <= _token_chance():
		Inventory.add_resource(Items.VM_DECODING_TOKEN, 1)

#region caches (Cache / Skim / Deep Scan)
func _run_caches() -> void:
	var token_cost: int = process_data.get("token cost", 0)
	while _has_requirements() and running:
		if stop_requested:
			return
		if token_cost > 0 and Inventory.get_amount(Items.VM_DECODING_TOKEN) < token_cost:
			cache_name.text = "Out of VM Decoding tokens (%d per cache)" % token_cost
			return
		cache_decrypt.reset()

		if target_cache != null and Inventory.get_amount(target_cache) > 0:
			current_cache = target_cache
		else:
			current_cache = Inventory.get_cache()
		cache_name.text = current_cache.name + " x" + str(Inventory.get_amount(current_cache))
		cache_name.remove_theme_color_override("font_color")
		Inventory.remove_resource(current_cache, 1)
		if token_cost > 0:
			Inventory.remove_resource(Items.VM_DECODING_TOKEN, token_cost)
		_show_drop_rates(current_cache)
		cache_decrypt.build_dump(current_cache, process_data, _mod())
		hex_display.text = cache_decrypt.render_dump()

		var cycle_mode := await _reveal_dump()
		if !running:
			apply_heat(cycle_mode) # one heat tick per cache (also when killed mid-cache)
			return

		if cache_decrypt.corrupted:
			_show_corruption()
			await get_tree().create_timer(1.0).timeout
			if !running:
				return

		Tutorial.track_event(Tutorial.TutorialEvent.DECODE_1_STUDENT_CACHE, 1)
		if has_modifier("index"):
			var t = Decoding.target_for_cache(current_cache)
			if !t.is_empty():
				Decoding.add_intel_point(t)
				update_items_gained_label("Intel (%s)" % t.name, 1)
		_cycle_done(cycle_mode)

func _has_requirements() -> bool:
	if target_cache != null:
		return Inventory.get_amount(target_cache) > 0
	return Inventory.has_cache()
#endregion

#region intel
func _run_intel() -> void:
	var target: Dictionary = target_arg if target_arg is Dictionary else {}
	if target.is_empty():
		return
	while running:
		if stop_requested:
			return
		if Decoding.is_intel_maxed(target):
			cache_name.text = "Intel on %s maxed: %s" % [target.name, Decoding.intel_text(target)]
			return
		cache_decrypt.reset()
		cache_name.text = "Intel: %s  ·  %s" % [target.name, Decoding.intel_text(target)]
		var rows = []
		var finds = 0
		for i in Decoding.INTEL_LINES:
			if randf() < Decoding.get_efficiency(process_data):
				rows.append({"text": "INTEL FOUND"})
				finds += 1
			else:
				rows.append(null)
		cache_decrypt.build_rows(rows)
		hex_display.text = cache_decrypt.render_dump()
		var cycle_mode := await _reveal_dump()
		if !running:
			apply_heat(cycle_mode)
			return
		for i in finds:
			Decoding.add_intel_point(target)
		if finds > 0:
			update_items_gained_label("Intel finds", finds)
		cache_name.text = "Intel: %s  ·  %s" % [target.name, Decoding.intel_text(target)]
		_cycle_done(cycle_mode)

## Session tally row without adding anything to the inventory.

func update_items_gained_label(label_name: String, amount: int) -> void:
	items_from_session[label_name] = items_from_session.get(label_name, 0) + amount
	clear_labels()
	for i in items_from_session.keys():
		var new_label = item_label.instantiate()
		new_label.update(i, items_from_session[i])
		labels_container.add_child(new_label)
#endregion


#region salvage
func _run_salvage() -> void:
	while running and target_cache and Inventory.get_amount(target_cache) >= Decoding.SALVAGE_COST:
		if stop_requested:
			return
		cache_decrypt.reset()
		Inventory.remove_resource(target_cache, Decoding.SALVAGE_COST)
		cache_name.text = "Salvaging %s x%d  (%d left)  ·  %.0f%% per line to find tokens  ·  %.1f%% to double a find" % [target_cache.name, Decoding.SALVAGE_COST, Inventory.get_amount(target_cache), Decoding.get_salvage_line_chance(target_cache) * 100.0, Decoding.get_efficiency(Decoding.SALVAGE) * 100.0]
		cache_decrypt.build_rows(Decoding.roll_salvage(target_cache, _mod()))
		hex_display.text = cache_decrypt.render_dump()
		var cycle_mode := await _reveal_dump()
		if !running:
			apply_heat(cycle_mode)
			return
		_cycle_done(cycle_mode)
	if running and target_cache:
		cache_name.text = "Not enough %s to salvage (%d needed)" % [target_cache.name, Decoding.SALVAGE_COST]
#endregion

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
