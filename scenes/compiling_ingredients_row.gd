extends VBoxContainer

var item

func set_labels(req: Dictionary):
	item = req.item
	$HBoxContainer/ItemNameCost.text = req.item.name + " x" + str(req.amount)
	$HBoxContainer/ItemInventoryAmount.text = str(Inventory.get_amount(req.item))

func update_amount():
	$HBoxContainer/ItemInventoryAmount.text = str(Inventory.get_amount(item))
