extends HBoxContainer

func update_info(loot, rare: bool = false):
	$HBoxContainer/ItemName.text = loot.item.name
	
	if rare:
		$HBoxContainer/ItemName.add_theme_color_override("font_color", Color.DARK_ORCHID)
		$ItemQuantity.text = str(loot["min_quantity"])
		$HBoxContainer/ItemChance.text = "5%"
	else:
		$ItemQuantity.text = str(loot["min_quantity"]) + "-" + str(loot["max_quantity"])
		$HBoxContainer/ItemChance.text = str(int(loot.drop_chance * 100)) + "%"
			
