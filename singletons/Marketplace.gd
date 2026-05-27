extends Node

var viewing_item = null

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
