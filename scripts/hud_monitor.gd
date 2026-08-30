extends PanelContainer

@onready var labels_container = $MarginContainer/LabelsContainer

var tracked_items: Array[ItemData] = []

const MONITOR_SIZE = 4

func _ready():
	Signals.item_added_signal.connect(update_monitored_items_hud)
	Signals.item_removed_signal.connect(update_monitored_items_hud)
	add_to_group("tracked_items_panel")

func update_monitored_items_hud(item: ItemData, _amount: int = 0):
	if !tracked_items.has(item):
		return
	
	var index = tracked_items.find(item)
	
	if index >= 0:
		var labels = labels_container.get_children()
		labels[index].text = item.name + "=" + str(Inventory.get_amount(item))
	SaveManager.mark_dirty()

func add_monitored_item(item: ItemData) -> String:
	if tracked_items.size() >= MONITOR_SIZE:
		return wrap_text_in_color(
			"Can only track " + str(MONITOR_SIZE) + " items at one time.",
			TextColor.ERROR
		)
	
	if tracked_items.has(item):
		return wrap_text_in_color(
			item.name + " is already being tracked.",
			TextColor.WARNING
		)
	
	tracked_items.append(item)
	if item == Items.SQL_INJECTOR:
		Tutorial.complete_event(Tutorial.TutorialEvent.TRACK_SQL)
	refresh_items()
	
	SaveManager.mark_dirty()
	return wrap_text_in_color(
		"Tracking " + item.name,
		TextColor.SUCCESS
	)


func add_monitored_items(item_names: Array[String]) -> String:
	var messages: Array[String] = []
	var slots_remaining = MONITOR_SIZE - tracked_items.size()
	
	for item_name in item_names:
		item_name = item_name.strip_edges()
		
		if item_name.is_empty():
			continue
		
		var item = Inventory.get_item_by_name(item_name)
		
		if item == null:
			messages.append(
				wrap_text_in_color(
					"Item not found: " + item_name,
					TextColor.ERROR
				)
			)
			continue
		
		if tracked_items.has(item):
			messages.append(
				wrap_text_in_color(
					item.name + " is already being tracked.",
					TextColor.WARNING
				)
			)
			continue
		
		# No more room
		if slots_remaining <= 0:
			messages.append(
				wrap_text_in_color(
					"Tracking limit reached. " + item.name + " was not added.",
					TextColor.ERROR
				)
			)
			continue
		
		tracked_items.append(item)

		slots_remaining -= 1
		
		messages.append(
			wrap_text_in_color(
				"Tracking " + item.name,
				TextColor.SUCCESS
			)
		)
		if item == Items.SQL_INJECTOR:
			Tutorial.complete_event(Tutorial.TutorialEvent.TRACK_SQL)
	refresh_items()
	
	SaveManager.mark_dirty()
	return "\n".join(messages)


func remove_monitored_items(item_names: Array[String]) -> String:
	var messages: Array[String] = []
	
	for item_name in item_names:
		item_name = item_name.strip_edges()
		
		if item_name.is_empty():
			continue
		
		var item = Inventory.get_item_by_name(item_name)
		
		if item == null:
			messages.append(
				wrap_text_in_color(
					"Item not found: " + item_name,
					TextColor.ERROR
				)
			)
			continue
		
		if !tracked_items.has(item):
			messages.append(
				wrap_text_in_color(
					item.name + " not currently being tracked.",
					TextColor.WARNING
				)
			)
			continue
		
		tracked_items.erase(item)
		if item == Items.SQL_INJECTOR:
			Tutorial.complete_event(Tutorial.TutorialEvent.UNTRACK_ITEMS)
		
		messages.append(
			wrap_text_in_color(
				item.name + " no longer being tracked.",
				TextColor.SUCCESS
			)
		)
	
	refresh_items()
	
	SaveManager.mark_dirty()
	return "\n".join(messages)

func remove_all() -> String:
	if tracked_items.is_empty():
		return wrap_text_in_color("No items currently being tracked.", TextColor.WARNING)
	
	var amount_removed = tracked_items.size()
	tracked_items.clear()
	
	refresh_items()
	
	SaveManager.mark_dirty()
	return wrap_text_in_color("Stopped tracking " + str(amount_removed) + " item" + ("s" if amount_removed != 1 else "") + ".", TextColor.SUCCESS)

func refresh_items():
	var labels = labels_container.get_children()
	
	for i in range(MONITOR_SIZE):
		if i < tracked_items.size():
			var item = tracked_items[i]
			labels[i].text = item.name + "=" + str(Inventory.get_amount(item))
			labels[i].visible = true
		else:
			labels[i].visible = false

enum TextColor { SUCCESS, WARNING, ERROR }

func wrap_text_in_color(text: String, color: TextColor) -> String:
	var color_hex: String
	
	match color:
		TextColor.SUCCESS:
			color_hex = "#6fa86f"
		TextColor.WARNING:
			color_hex = "#d4a85a"
		TextColor.ERROR:
			color_hex = "#c96b6b"
	
	return "[color=%s]%s[/color]" % [color_hex, text]

func save_data() -> Dictionary:
	var ids := []
	for item in tracked_items:
		ids.append(item.id)
	return {
		"tracked_item_ids": ids
	}

func load_data(data: Dictionary) -> void:
	tracked_items.clear()
	var ids: Array = data.get("tracked_item_ids", [])
	for id in ids:
		var item: ItemData = Items.ITEM_MAP.get(int(id))
		if item == null:
			push_warning("Unknown item id in tracked_items save: %s" % id)
			continue
		tracked_items.append(item)
	refresh_items()
