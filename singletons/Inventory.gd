extends Node

enum InventoryFilter { ALL, CACHES, VALUABLES, RESOURCES }
var inventory := {}

func _ready():
	pass
	#for i in Items.ITEM_MAP:
		#add_resource(Items.ITEM_MAP[i], 50)
	#pass
	#add_resource(Items.DATA, 2500)
	add_resource(Items.LOGS, 50)
	#add_resource(Items.ENCRYPTED_PASSWORDS, 5)
	#add_resource(Items.ENCRYPTED_PINS, 250)
	#add_resource(Items.PASSWORDS, 5)
	#add_resource(Items.USERNAMES, 5)
	#add_resource(Items.STUDENT_CACHE, 20)
	#add_resource(Items.PINS, 3)
	#add_resource(Items.ACCOUNT_NUMBERS, 3)
	#add_resource(Items.VM_MINING_TOKEN, 5)
	add_resource(Items.VM_PARSING_TOKEN, 1)
	#add_resource(Items.VM_CRACKING_TOKEN, 5)
	#add_resource(Items.VM_MATCHING_TOKEN, 10)
	#add_resource(Items.VM_PHISHING_TOKEN, 100)
	#add_resource(Items.VM_DECODING_TOKEN, 5)
	#add_resource(Items.REFRESH_TOKEN, 500)
	#add_resource(Items.IP_ADDRESS, 4)
	#add_resource(Items.CREDENTIALS, 4)
	#add_resource(Items.SQL_INJECTOR, 25)
	#add_resource(Items.PACKET_SPOOF, 6)
	#add_resource(Items.ADMIN_CACHE, 1)
	#add_resource(Items.COP_CACHE, 1)
	#add_resource(Items.BODY_CAM_FOOTAGE_DELETION_LOGS, 2)

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
#func list_inventory(filter: InventoryFilter = InventoryFilter.ALL) -> String:
	#var amount_width = 15
	#var output = ""
	#var has_items := false
#
	#var max_name_length = 0
	#for resource in inventory.keys():
		#if inventory[resource] > 0 and _matches_filter(resource, filter):
			#if resource.name.length() > max_name_length:
				#max_name_length = resource.name.length()
#
	#var name_width = max_name_length + 5
#
	#output += pad_text("Items", name_width + 1)
	#output += pad_text("Amount", amount_width)
	#output += "Description\n"
	#output += pad_text("--------", name_width + 1)
	#output += pad_text("------", amount_width)
	#output += "-----------\n"
#
	#for resource in inventory.keys():
		#if _matches_filter(resource, filter):
			#var amount: int = inventory[resource]
			#if amount > 0:
				#var c = Palette.get_color(resource.color_type)
				#var hex = c.to_html(false)
				#
				#has_items = true
				#var temp_name = pad_text(resource.name, name_width)
				#
				#output += "[color=%s]▍[/color]" % hex
				#output += temp_name
				#output += pad_text(str(amount), amount_width)
				#output += resource.description + "\n"
#
	#if not has_items:
		#return "You have no items."
	#return output

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

func get_all_valuables() -> Array:
	if !has_valuables():
		return []
	var vals = []
	for i in inventory:
		if i.valuable:
			vals.append(i)
	return vals
