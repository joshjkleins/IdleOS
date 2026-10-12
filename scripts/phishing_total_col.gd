extends VBoxContainer

var item: ItemData

func update_labels(the_item: ItemData):
	if the_item == item:
		$TotalLabelAmount.text = str(Inventory.get_amount(item))

func set_item(the_item: ItemData):
	item = the_item
	$TotalLabelTitle.text = item.name.to_upper()
	$TotalLabelAmount.text = str(Inventory.get_amount(item))
	
	Signals.phishing_item_caught_item_signal.connect(update_labels)
