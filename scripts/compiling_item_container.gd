extends PanelContainer

var item

func set_labels(req: Dictionary):
	item = req.item
	$MarginContainer/VBoxContainer/ItemName.text = req.item.name + " x" + str(req.amount)
	$MarginContainer/VBoxContainer/ItemAmount.text = str(Inventory.get_amount(req.item))

func update_amount():
	$MarginContainer/VBoxContainer/ItemAmount.text = str(Inventory.get_amount(item))
