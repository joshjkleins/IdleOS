extends Node

enum ItemType {
	RESOURCE,
	MODULE
}

var items = {
	0: {
		"id": 0,
		"name": "Logs",
		"cost": 10,
		"description": "Decrypt logs to gain random resources (data, passwords, usernames, credentials)",
		"type": ItemType.RESOURCE,
		"available": true
	},
	1: {
		"id": 1,
		"name": "Log Parsing",
		"cost": 10,
		"description": "Module used to parse through logs for a chance to gain random resources.",
		"type": ItemType.MODULE,
		"available": true
	},
	2: {
		"id": 2,
		"name": "Password Cracking",
		"cost": 50,
		"description": "Module used to transform a scrambled password to a valid password used to create credentials.",
		"type": ItemType.MODULE,
		"available": true
	}
}

func purchase_item(id: int, amount: int) -> String:
	# Validate item
	if not items.has(id):
		return "Item ID not found."
	
	# Validate amount
	if amount <= 0:
		return "Invalid purchase amount."
	
	var item = items[id]
	
	# Check availability
	if not item.get("available", false):
		return item["name"] + " is not available."
	
	var player_money = Inventory.get_amount("data")
	var cost_per_item = item["cost"]
	var total_cost = cost_per_item * amount
	
	# Check funds
	if player_money < total_cost:
		return "Not enough Data. Need " + str(total_cost) + ", you have " + str(player_money) + "."
	
	# Deduct cost
	if not Inventory.remove_resource("data", total_cost):
		return "Transaction failed."
	
	# Grant rewards
	grant_item_reward(item, amount)
	
	return "Purchased x" + str(amount) + " " + item["name"] + " for " + str(total_cost) + " Data."


func grant_item_reward(item: Dictionary, amount: int) -> void:
	match item["id"]:
		0:
			Inventory.add_resource("logs", amount)
		1:
			Stats.unlock_module("Log Parsing")
			items[1].available = false
		2:
			Stats.unlock_module("Password Unscramble")
			items[2].available = false
		_:
			print("No reward logic for item id:", item["id"])


func list_available_items() -> String:
	var id_width = 4
	var name_width = 25
	var cost_width = 8
	
	var output = Ascii.resources + "\n"
	
	# Header
	output += pad_text("ID", id_width)
	output += pad_text("Name", name_width)
	output += pad_text("Cost", cost_width)
	output += "Description\n"
	
	# Divider
	output += pad_text("----", id_width)
	output += pad_text("-------------------------", name_width)
	output += pad_text("--------", cost_width)
	output += "-----------------------------\n"
	
	# Resources
	for item_id in items.keys():
		var item = items[item_id]
		if item.available and item.type == ItemType.RESOURCE:
		
			output += pad_text(item["id"], id_width)
			output += pad_text(item["name"], name_width)
			output += pad_text(item["cost"], cost_width)
			output += item["description"] + "\n"
	
	output += Ascii.modules + "\n\n"
		# Header
	output += pad_text("ID", id_width)
	output += pad_text("Name", name_width)
	output += pad_text("Cost", cost_width)
	output += "Description\n"
	
	# Divider
	output += pad_text("----", id_width)
	output += pad_text("-------------------------", name_width)
	output += pad_text("--------", cost_width)
	output += "-----------------------------\n"
	# Modules
	for item_id in items.keys():
		var item = items[item_id]
		if item.available and item.type == ItemType.MODULE:
		
			output += pad_text(item["id"], id_width)
			output += pad_text(item["name"], name_width)
			output += pad_text(item["cost"], cost_width)
			output += item["description"] + "\n"
	
	
	return output

func pad_text(value, width: int) -> String:
	var text := str(value)
	if text.length() >= width:
		return text.substr(0, width)
	return text + " ".repeat(width - text.length())
