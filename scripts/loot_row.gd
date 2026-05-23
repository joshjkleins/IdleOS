extends HBoxContainer

func update_info(loot, rare: bool = false):
	$HBoxContainer/ItemName.text = loot.item.name
	$HBoxContainer/ItemChance.text = str(int(loot.drop_chance * 100)) + "%"
	
	if rare:
		$HBoxContainer/ItemName.add_theme_color_override("font_color", Color.DARK_ORCHID)
		$ItemQuantity.text = str(loot["min_quantity"])
	else:
		$ItemQuantity.text = str(loot["min_quantity"]) + "-" + str(loot["max_quantity"])
			
