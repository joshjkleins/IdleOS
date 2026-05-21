extends Node
#game info
#Idle game
#Skills (as seens in traditional idle games) = Modules

#important design rules for this game
#every process should do one of the following, and clearly
#Generate a resource
#Convert a resource
#Buffs other processes (short term or permenant)
#unlock new systems

#random ideas
#defrag disk: long process, everything is slow during it, but once done a perm speed bonus to everything

#Defining "Process"
#Pick one: Generate, Convert, Buff, Unlock

enum InventoryFilter { ALL, CACHES, VALUABLES, RESOURCES }
var inventory := {}

func _ready():
	#for i in Items.ITEM_MAP:
		#add_resource(Items.ITEM_MAP[i], 10)
	#pass
	#add_resource(Items.DATA, 25)
	#add_resource(Items.LOGS, 200)
	#add_resource(Items.ENCRYPTED_PASSWORDS, 21)
	#add_resource(Items.ENCRYPTED_PINS, 25)
	#add_resource(Items.LOGS, 2)
	#add_resource(Items.ENCRYPTED_PASSWORDS, 4)
	#add_resource(Items.PASSWORDS, 30)
	#add_resource(Items.USERNAMES, 30)
	#add_resource(Items.STUDENT_CACHE, 100)
	#add_resource(Items.PINS, 30)
	#add_resource(Items.ACCOUNT_NUMBERS, 30)
	add_resource(Items.CREDENTIALS, 1)
	add_resource(Items.IP_ADDRESS, 1)
	add_resource(Items.SQL_INJECTOR, 100)
	add_resource(Items.PACKET_SPOOF, 100)
	#add_resource(Items.ADMIN_CACHE, 2)
	#add_resource(Items.COP_CACHE, 1)
	#add_resource(Items.BODY_CAM_FOOTAGE_DELETION_LOGS, 2)
	

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
	for resource in inventory.keys():
		if inventory[resource] > 0 and _matches_filter(resource, filter):
			if resource.name.length() > max_name_length:
				max_name_length = resource.name.length()

	var name_width = max_name_length + 4

	output += pad_text("Items", name_width)
	output += pad_text("Amount", amount_width)
	output += "Description\n"
	output += pad_text("--------", name_width)
	output += pad_text("------", amount_width)
	output += "-----------\n"

	for resource in inventory.keys():
		if _matches_filter(resource, filter):
			var amount: int = inventory[resource]
			if amount > 0:
				has_items = true
				output += pad_text(resource.name, name_width)
				output += pad_text(amount, amount_width)
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
