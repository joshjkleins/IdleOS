extends Node

var val_col_size_id = 5
var val_col_size_name = 30
var val_col_size_amount = 10
var val_col_size_value = 10

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

[5] EXIT
------------------------------------------------------------
"""

func maretplace_valuables_main() -> String:
	var title = """
================================================================
ASSET INVENTORY
================================================================\n\n"""
	var vals = Inventory.get_all_valuables()
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

func _pad_text(text: String, width: int) -> String:
	if text.length() >= width:
		return text
	
	return text + " ".repeat(width - text.length())


func view_valuable_item(id: int) -> String:
	var item = null
	for i in Inventory.inventory:
		if i.id == id:
			item = i
	
	if item == null:
		return "No item found with that ID"
	
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
	
