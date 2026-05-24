extends PanelContainer

var target

func update_info(info):
	target = info
	$MarginContainer/VBoxContainer/RowOne/TargetName.text = info.name
	$MarginContainer/VBoxContainer/RowOne/PanelContainer/MarginContainer/Difficulty.text = info.difficulty
	$MarginContainer/VBoxContainer/RowTwo/MarginContainer/HBoxContainer/Command.text = info.command
	$MarginContainer/VBoxContainer/GridContainer/IntegrityBox/MarginContainer/VBoxContainer/IntegrityAmount.text = str(info.integrity)
	$MarginContainer/VBoxContainer/GridContainer/FirewallBox/MarginContainer/VBoxContainer/FirewallAmount.text = str(info.firewall)
	$MarginContainer/VBoxContainer/GridContainer/CounterattackBox/MarginContainer/VBoxContainer/CounterAmount.text = str(info.counter)
	$MarginContainer/VBoxContainer/GridContainer/AttackSpeedBox/MarginContainer/VBoxContainer/SpeedAmount.text = str(info["counter speed"])
	$MarginContainer/VBoxContainer/HBoxContainer/Reward.text = info.loot.name

	if $MarginContainer/VBoxContainer/LootContainer.get_children().size() > 0:
		for n in $MarginContainer/VBoxContainer/LootContainer.get_children():
			n.queue_free()
	
	var loot_row = load("res://scenes/loot_row.tscn")
	for loot in info.loot.entries:
		var new_row = loot_row.instantiate()
		new_row.update_info(loot)
		$MarginContainer/VBoxContainer/LootContainer.add_child(new_row)
	for loot in info.loot.rare_pool:
		var new_row = loot_row.instantiate()
		new_row.update_info(loot, true)
		$MarginContainer/VBoxContainer/LootContainer.add_child(new_row)
	

func flash_green():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color("#3dff95"), 0.15)
	await tween.finished
	
	var tween2 = create_tween()
	tween2.tween_property(self, "modulate", Color.WHITE, 0.15)
	await tween2.finished

func flash_red():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color("#ff5a3d"), 0.15)
	await tween.finished
	
	var tween2 = create_tween()
	tween2.tween_property(self, "modulate", Color.WHITE, 0.15)
	await tween2.finished
