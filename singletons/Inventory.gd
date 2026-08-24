extends Node

enum InventoryFilter { ALL, CACHES, VALUABLES, RESOURCES }
var inventory := {}

func _ready():
	add_resource(Items.PARENTS_CREDIT_CARD, 4)
	add_resource(Items.SCHOOL_PAYLOAD, 5)
	return
	for i in Items.ITEM_MAP:
		add_resource(Items.ITEM_MAP[i], 500)

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
	
	Signals.item_added(resource, amount)

func remove_resource(resource: ItemData, amount: int) -> bool:
	if not inventory.has(resource):
		return false
	if inventory[resource] < amount:
		return false
	
	inventory[resource] -= amount
	
	if inventory[resource] <= 0:
		inventory.erase(resource)
	
	return true

func _matches_filter(resource, filter: InventoryFilter) -> bool:
	match filter:
		InventoryFilter.CACHES:
			return resource.name.contains("cache")
		InventoryFilter.VALUABLES:
			return resource.valuable
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
	
	var mu_text = item.ItemColor.keys()[item.color_type].capitalize()
	var c = Palette.get_color(item.color_type)
	var hex = c.to_html(false)
	
	var main_use = "Main use: [color=#%s]%s[/color]" % [hex, mu_text]

	var text = "\n"
	text += item_name + "\n"
	text += amount + "\n"
	text += description + "\n"
	text += obtained_from + "\n"
	text += main_use + "\n\n"

	
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

	return text

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

	return output

func pad_text(value, width: int) -> String:
	var text := str(value)
	if text.length() >= width:
		return text.substr(0, width)
	return text + " ".repeat(width - text.length())

func get_cache() -> CacheData:
	for i in inventory:
		if i.name.contains("cache"):
			return i
	return null #should never hit this

func has_cache() -> bool:
	for i in inventory:
		if i.name.contains("cache"):
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
