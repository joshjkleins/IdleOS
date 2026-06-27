extends Node

var viewing_item = null
var viewing_skill = null

var val_col_size_id = 5
var val_col_size_name = 30
var val_col_size_amount = 10
var val_col_size_value = 10

var available_offensive_items = {
	1: {
		"id": 1,
		"item": Items.SQL_INJECTOR,
		"available": true
	},
	2: {
		"id": 2,
		"item": Items.DDOS,
		"available": false
	}
}

var available_defensive_items = {
	1: {
		"id": 1,
		"item": Items.PACKET_SPOOF,
		"available": true
	}
}

var available_utility_items = {
	1: {
		"id": 1,
		"item": Items.PACKET_SPOOF,
		"available": true
	}
}

func marketplace_welcome() -> String:
	return Ascii.marketplace +  """
============================================================

DATA:        """ + str(Inventory.get_amount(Items.DATA)) + """

------------------------------------------------------------
[1] CONTRACT BOARD
	Active exploit and intrusion requests

[2] SELL VALUABLES
	Sell valuables found in caches for large amounts of data

[3] BLACK MARKET
	Exploits, scripts, hardware, anonymizers

[4] NETWORK EXCHANGE
	Buy/sell bandwidth and compute cycles


[exit] EXIT
------------------------------------------------------------
"""

func contracts() -> String:
	var head = """
================================================================
CONTRACTS
================================================================\n"""
	var contract_text = ""
	for i in range(ContractsManager.available_contracts.size()):
		var contract = ContractsManager.available_contracts[i]
		
		var cost = ""
		if contract.available:
			cost = "COST: " + str(contract.cost) + " DATA"
		else:
			cost = "[color=green]PURCHASED[/color]"
		var first_line = "[" + str(i + 1) + "] " + contract.major_skill.SKILL.name + " / " + contract.minor_skill.name
		contract_text += _pad_text(first_line, 40) + cost + "\n"
		contract_text += "    " + _pad_text(contract.description, 40) + "REWARD: +" + str(contract.reward_exp) + " exp, +" + str(contract.reward_item_amount) + " " + contract.reward_item.name + "\n\n"
	
	var foot = "------------------------------------------------------------\n"
	foot += "[back] BACK\n"
	return head + contract_text + foot

func purchase_contract(num: int) -> Dictionary:
	if num <= 0 or num > ContractsManager.available_contracts.size():
		return { "message": "Not valid number", "purchased": false }
	
	var target_contract = ContractsManager.available_contracts[num - 1]
	
	if !target_contract.available:
		return { "message": "Contract has already been purchased.", "purchased": false }
		
	#is player contract inventory full
	if !ContractsManager.can_add_contract():
		return { "message": "Only 3 contracts can be active at once.", "purchased": false }
	
	if target_contract.cost > Inventory.get_amount(Items.DATA):
		return { "message": "Not enough data.", "purchased": false }
	
	Inventory.remove_resource(Items.DATA, target_contract.cost)
	return { "message": ContractsManager.add_active_contract(target_contract), "purchased": true }

func refresh_contracts():
	if Inventory.get_amount(Items.REFRESH_TOKEN) <= 0:
		return { "message": "No refresh tokens.", "successful": false }
	
	Inventory.remove_resource(Items.REFRESH_TOKEN, 1)
	ContractsManager.refresh_token_used()
	return { "message": "Getting new contracts.", "successful": true }

func maretplace_valuables_main() -> String:
	var vals = Inventory.get_all_valuables()
	if vals.is_empty():
		return "No valuables found in inventory."
	var title = """
================================================================
ASSET INVENTORY
================================================================\n\n"""
	var header = _pad_text("ID", val_col_size_id) + _pad_text("ITEM", val_col_size_name) + _pad_text("QTY", val_col_size_amount) + _pad_text("VALUE", val_col_size_value) + "\n"
	var sep = "-".repeat(val_col_size_id + val_col_size_name + val_col_size_amount + val_col_size_value) + "\n"
	var val_text = ""
	for v in vals:
		var id = _pad_text(str(v.id), val_col_size_id)
		var v_name = _pad_text(v.name, val_col_size_name)
		var amount = _pad_text(str(Inventory.get_amount(v)), val_col_size_amount)
		var value = _pad_text(str(v.value), val_col_size_value)
		val_text +=  id + v_name + amount + value + "\n"
	
	var options = """
[ID]         VIEW VALUABLE TO SELL
[sell -a]    SELL ALL
[back]       RETURN TO MAIN MARKETPLACE
"""
	return title + header + sep + val_text + "\n" + sep + options + "\n"

func sell_all_valuables() -> String:
	if !Inventory.has_valuables():
		return "No valuables to sell"
	
	var total_sale_data = 0
	var vals = Inventory.get_all_valuables()
	for v in vals:
		total_sale_data += v.value * Inventory.get_amount(v)
		Inventory.remove_resource(v, Inventory.get_amount(v))
	Inventory.add_resource(Items.DATA, total_sale_data)
	return "all valuables sold for " + str(total_sale_data)

func view_valuable_item(id: int) -> String:
	var item = null
	for i in Inventory.inventory:
		if i.id == id:
			item = i
	
	if item == null:
		return "No item found with that ID"
	viewing_item = item
	return """
================================================================
SELECTED VALUABLE : """ + item.name + """
================================================================

Quantity : """ + str(Inventory.get_amount(item)) + """
Value    : """ + str(item.value) + """ / unit
Total    : """ + str(item.value * Inventory.get_amount(item)) + """ data

================================================================

[number]   SELL SPECIFIC AMOUNT
[all]      SELL ALL
[back]     BACK

"""

func handle_valuable_details_sell_all() -> String:
	if viewing_item == null:
		return "No item selected, you should never see this message, oops!"
	if Inventory.get_amount(viewing_item) <= 0:
		return "Item selected but you have 0 of that item. You should never see this message, oops!"
	
	
	var amount = Inventory.get_amount(viewing_item)
	var items_worth = viewing_item.value * amount
	
	Inventory.remove_resource(viewing_item, amount)
	Inventory.add_resource(Items.DATA, amount)
	var item_name = viewing_item.name
	viewing_item = null
	
	return "Sold " + item_name + " x" + str(amount) + " for " + str(items_worth) + " data"

func handle_valuable_details_sell(amount: int) -> String:
	if viewing_item == null:
		return "No item selected, you should never see this message, oops!"
	if Inventory.get_amount(viewing_item) <= 0:
		return "Item selected but you have 0 of that item. You should never see this message, oops!"
	if amount <= 0:
		return "Must enter number larger than 0"
	if amount > Inventory.get_amount(viewing_item):
		return "Not enough " + viewing_item.name
	
	var items_worth = viewing_item.value * amount
	
	Inventory.remove_resource(viewing_item, amount)
	Inventory.add_resource(Items.DATA, amount)
	var item_name = viewing_item.name
	
	viewing_item = null
	
	return "Sold " + item_name + " x" + str(amount) + " for " + str(items_worth) + " data"

func upgrades_main():
	viewing_skill = null
	return """
================================================================================
OS UPGRADES
================================================================================
[1] MINING
[2] PARSING
[3] CRACKING
[4] MATCHING
[5] HACKING
[6] DECODING
[7] PHISHING
[8] DEFRAGGING

--------------------------------------------------------------------------------

[back] BACK
"""

func upgrades_details(skill: Node) -> String:
	var header = """
================================================================================
""" + skill.SKILL.name + """ upgrades
================================================================================
"""
	var body = ""
	if skill == Defragging:
		var id = 0
		for ms in skill.minor_processes:
			var cost = "[color=GREEN]INSTALLED[/color]\n" if ms.unlocked else str(ms["unlock cost"]) + " DATA\n" 
			body += _pad_text("[" + str(id) + "]", 5) + _pad_text(ms.name, 30) + "COST: " + cost
			id += 1
	else:
		for up in skill.process_upgrades.keys():
			var p = skill.process_upgrades[up]
			var key = _pad_text("[" + str(p.id) + "]", 5)
			var cost = "COST: " + str(skill.get_upgrade_cost(up)) + " DATA\n"
			var upgrade_text = ""
			var title = ""
			if p.name == "Offline progression": #offline progression
				title = _pad_text(p.name, 30)
				upgrade_text = "     " + minutes_to_hours_text(p["amount"]) + " -> " +  minutes_to_hours_text(p["amount"] + p["increase per level"]) + "\n\n"
			elif p.name == "Max lines":
				title = _pad_text(p.name + " increase", 30) 
				upgrade_text = "     " + str(p["amount"]) + " -> " +  str(p["amount"] + p["increase per level"]) + "\n\n"
			elif p.name.to_lower() == "vm windows":
				title = _pad_text(p.name, 30)
				upgrade_text = "     " + str(p["amount"]) + " -> " + str(p["amount"] + p["increase per level"]) + "\n\n"
			elif p.name.to_lower() == "vm duration":
				title = _pad_text(p.name, 30)
				upgrade_text = "     " + str(p["amount"]) + " -> " + str(p["amount"] + p["increase per level"]) + "\n\n"
			elif p.name.to_lower() == "efficiency":
				title = _pad_text(p.name + " bonus", 30) 
				upgrade_text = "     " + percent_format(p["amount"] + 1.0) + " -> " + percent_format(p["amount"] + 1.0 + p["increase per level"]) + "\n\n"
			else: #speed / efficiency
				title = _pad_text(p.name + " bonus", 30) 
				upgrade_text = "     " + percent_format(p["amount"]) + " -> " + percent_format(p["amount"] + p["increase per level"]) + "\n\n"
			body += key + title + cost + upgrade_text 
	var footer = """

--------------------------------------------------------------------------------

[back] BACK
"""
	viewing_skill = skill
	return header + body + footer
#var process_upgrades = {
	#"speed": { "id": 1, "name": "Speed", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	#"efficiency": { "id": 2, "name": "Efficiency", "level": 0, "amount": 0.0, "increase per level": 0.15 },
	#"experience": { "id": 3, "name": "Experience", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	#"offline": { "id": 4, "name": "Offline progression", "level": 0, "amount": 0, "increase per level": 60 },
	#"vm windows": { "id": 5, "name": "VM Windows", "level": 0, "amount": 1, "increase per level": 1 },
	#"vm duration": { "id": 6, "name": "VM Duration", "level": 0, "amount": 30.0, "increase per level": 30.0 },
#}
func purchase_upgrade(num: int) -> Dictionary:
	if viewing_skill == Defragging:
		if num < 0 or num > 6:
			return { "message": "Not valid number", "purchased": false }
		
		var minor_skill_upgrade = Defragging.minor_processes[num]
		var cost = minor_skill_upgrade["unlock cost"]
		
		if minor_skill_upgrade == null or cost <= 0:
			return { "message": "Not valid number", "purchased": false }
		
		if minor_skill_upgrade["unlocked"]:
			return { "message": "Already unlocked", "purchased": false }
		
		if cost > Inventory.get_amount(Items.DATA):
			return { "message": "Not enough data.", "purchased": false }
		
		Inventory.remove_resource(Items.DATA, cost)
		minor_skill_upgrade.unlocked = true
		return { "message": "Upgrade purchased", "purchased": true }
		
	else:
		var valid_num = false
		for pu in viewing_skill.process_upgrades.keys():
			if num == viewing_skill.process_upgrades[pu]['id']:
				valid_num = true
		if !valid_num:
			return { "message": "Not valid number", "purchased": false }
		
		var upgrade = null
		var cost = 0
		for upgrade_type in viewing_skill.process_upgrades.keys():
			if viewing_skill.process_upgrades[upgrade_type]["id"] == num:
				upgrade = viewing_skill.process_upgrades[upgrade_type]
				cost = viewing_skill.get_upgrade_cost(upgrade_type)
		if upgrade == null or cost <= 0:
			return { "message": "Not valid number", "purchased": false }
		
		if cost > Inventory.get_amount(Items.DATA):
			return { "message": "Not enough data.", "purchased": false }
		
		Inventory.remove_resource(Items.DATA, cost)
		viewing_skill.upgraded(upgrade)
		return { "message": "Upgrade purchased", "purchased": true }


func percent_format(value: float) -> String:
	var percent = (value - 1.0) * 100.0
	return "%d%%" % round(percent)

func minutes_to_hours_text(minutes: int) -> String:
	var hours = minutes / 60
	return "%d hour%s" % [hours, "" if hours == 1 else "s"]

func black_market_main() -> String:
	return """
================================================================================
BLACK MARKET - CATEGORIES
================================================================================

[1] OFFENSIVE
	Items needed to bring down hacking targets integrity

[2] DEFENSIVE
	Items used to increase your own defensives as to remain anonymous

[3] UTILITY
	Items that provide helpful benefits during hacking attemps

--------------------------------------------------------------------------------

[back] BACK
"""


func black_market_items(type: String) -> String:
	var stock = null
	var title = ""
	match type:
		"offensive":
			stock = available_offensive_items
			title = 'OFFENSIVE'
		"defensive":
			stock = available_defensive_items
			title = 'DEFENSIVE'
		"utility":
			stock = available_utility_items
			title = 'UTILITY'
			
	if stock == null:
		return "Nothing found...oops."
	var return_string = ""
	
	return_string += """
--------------------------------------------------------------------------------
""" + title + """ HACKING
--------------------------------------------------------------------------------
\n"""
	var col_one_size = 6
	var col_two_size = 25
	var col_stats = 12
	for i in stock.keys():
		var item = stock[i]
		if item.available:
			var id = _pad_text("[" + str(item.id) + "]", col_one_size)
			var i_name = _pad_text(item.item.name, col_two_size)
			var cost = str(item.item.data_cost) + " DATA\n"
			var desc = " ".repeat(col_one_size) + item.item.description + "\n"
			
			var col_one = ""
			var col_two = ""
			var col_three = ""
			var col_four = ""
			match type:
				"offensive":
					col_one = _pad_text("INT: " + str(item.item.damage), col_stats)
					col_two = _pad_text("FW: " + str(item.item.firewall_damage), col_stats)
					col_three = _pad_text("BW: " + str(item.item.bandwidth_cost), col_stats)
					col_four = _pad_text("SPD: " + str(item.item.speed_name), col_stats)
				"defensive":
					col_one = _pad_text("ANON: " + str(item.item.heal), col_stats)
					col_three = _pad_text("BW: " + str(item.item.bandwidth_cost), col_stats)
					col_four = _pad_text("SPD: " + str(item.item.speed_name), col_stats)
				"utility":
					col_one = _pad_text("ANON: " + str(item.item.heal), col_stats)
					col_three = _pad_text("BW: " + str(item.item.bandwidth_cost), col_stats)
					col_four = _pad_text("SPD: " + str(item.item.speed_name), col_stats)
					
			
			var row_one = id + i_name + cost
			var row_two = desc
			var row_three = " ".repeat(col_one_size) + col_one + col_two + col_three + col_four + "\n\n"
			return_string += row_one + row_two + row_three
	
	return_string += """

--------------------------------------------------------------------------------

[back] BACK
"""
	return return_string

func black_market_item_details(item_num: int, type: String) -> String:
	var stock = null
	match type:
		"offensive":
			stock = available_offensive_items
		"defensive":
			stock = available_defensive_items
		"utility":
			stock = available_utility_items
	if stock == null:
		return "Nothing in stock, oops."
			
	if !stock.has(item_num) or stock[item_num]["available"] == false:
		return "Invalid ID"
	
	viewing_item = stock[item_num].item
	
	var stats = ""
	match type:
		"offensive":
			stats = """
Integrity Damage    """ + _pad_text(str(viewing_item.damage), 10) + """ Bring a targets integrity to 0 successfully hack them
Firewall Damage     """ + _pad_text(str(viewing_item.firewall_damage), 10) + """ Targets firewall will take damage before their integrity is damaged
Bandwidth Cost      """ + _pad_text(str(viewing_item.bandwidth_cost), 10) + """ Item use consumes bandwidth. Bandwidth constantly regenerates.
Attack Speed        """ + _pad_text(viewing_item.speed_name, 10) 
		"defensive":
			stats = """
Anonymity Heal      """ + _pad_text(str(viewing_item.heal), 10) + """ Having your anonymity brought to 0 will expose you and fail the hack attempt.
Bandwidth Cost      """ + _pad_text(str(viewing_item.bandwidth_cost), 10) + """ Item use consumes bandwidth. Bandwidth constantly regenerates.
Attack Speed        """ + _pad_text(viewing_item.speed_name, 10)
		"utility":
			stats = """
Anonymity Heal      """ + _pad_text(str(viewing_item.heal), 10) + """ Having your anonymity brought to 0 will expose you and fail the hack attempt.
Bandwidth Cost      """ + _pad_text(str(viewing_item.bandwidth_cost), 10) + """ Item use consumes bandwidth. Bandwidth constantly regenerates.
Attack Speed        """ + _pad_text(viewing_item.speed_name, 10)
	
	return """
------------------------------------------------------------
SELECTED: """ + viewing_item.name + """ 
------------------------------------------------------------

COST PER ITEM:
""" + str(viewing_item.data_cost) + """ DATA

DESCRIPTION:
""" + viewing_item.description + """

STATISTICS:""" + stats + """

------------------------------------------------------------
PURCHASE OPTIONS:
buy a=[amount] : BUY x AMOUNT            [color=#888888]example purchase of 10: a=10[/color]
buy d=[amount] : SPEND x AMOUNT OF DATA  [color=#888888]example purchase of 100 data worth: d=500[/color]

[back] BACK
"""

func handle_black_market_buy_command(text: String) -> String:
	if viewing_item == null:
		return "No item, oops."
	text = text.strip_edges().to_lower()
	var split = text.split(" ")
	
	if split.size() < 2:
		return "Invalid buy command"
	
	var command = split[1]
	
	# Buy specific amount
	if command.begins_with("a="):
		var amount_text = command.trim_prefix("a=")
		
		if !amount_text.is_valid_int():
			return "Invalid amount"
		
		var amount = int(amount_text)
		
		if amount <= 0:
			return "Amount must be greater than 0"
		
		var total_cost = viewing_item.data_cost * amount
		
		if Inventory.get_amount(Items.DATA) < total_cost:
			return "Not enough data"
		
		Inventory.remove_resource(Items.DATA, total_cost)
		Inventory.add_resource(viewing_item, amount)
		
		var item_name = viewing_item.name
		viewing_item = null
		return "Purchased " + item_name + " x" + str(amount) + " for " + str(total_cost) + " data"
	
	
	# Spend dollar amount worth
	elif command.begins_with("d="):
		var spend_text = command.trim_prefix("d=")
		
		if !spend_text.is_valid_int():
			return "Invalid amount"
		
		var spend_amount = int(spend_text)
		
		if spend_amount <= 0:
			return "Amount must be greater than 0"
		
		if Inventory.get_amount(Items.DATA) < spend_amount:
			return "Not enough money"
		
		var amount_to_buy = floori(spend_amount / viewing_item.data_cost)
		
		if amount_to_buy <= 0:
			return "Amount too low to purchase item"
		
		var total_cost = amount_to_buy * viewing_item.data_cost
		
		Inventory.remove_resource(Items.DATA, total_cost)
		Inventory.add_resource(viewing_item, amount_to_buy)
		
		var item_name = viewing_item.name
		viewing_item = null
		return "Purchased " + item_name + " x" + str(amount_to_buy) + " for " + str(total_cost) + " data"
	
	else:
		return "Unknown buy command"

func _pad_text(text: String, width: int) -> String:
	if text.length() >= width:
		return text
	
	return text + " ".repeat(width - text.length())
