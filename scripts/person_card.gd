extends PanelContainer

var target

func update_info(info):
	target = info
	$MarginContainer/VBoxContainer/RowOne/TargetName.text = info.name
	$MarginContainer/VBoxContainer/RowOne/DifficultyContainer/MarginContainer/Difficulty.text = info.difficulty
	var sb = $"MarginContainer/VBoxContainer/RowOne/DifficultyContainer".get_theme_stylebox("panel").duplicate()
	sb.bg_color = _get_difficulty_color(info.difficulty)
	$MarginContainer/VBoxContainer/RowOne/DifficultyContainer.add_theme_stylebox_override("panel", sb)
	$MarginContainer/VBoxContainer/RowTwo/MarginContainer/HBoxContainer/Command.text = info.command
	$MarginContainer/VBoxContainer/GridContainer/IntegrityBox/MarginContainer/VBoxContainer/IntegrityAmount.text = str(info.integrity)
	$MarginContainer/VBoxContainer/GridContainer/FirewallBox/MarginContainer/VBoxContainer/FirewallAmount.text = str(info.firewall)
	$MarginContainer/VBoxContainer/GridContainer/CounterattackBox/MarginContainer/VBoxContainer/CounterAmount.text = str(info.counter)
	$MarginContainer/VBoxContainer/GridContainer/AttackSpeedBox/MarginContainer/VBoxContainer/SpeedAmount.text = str(info["counter speed"])
	$MarginContainer/VBoxContainer/HBoxContainer/Reward.text = info.loot.name
	
	if $MarginContainer/VBoxContainer/RequirementsRow.get_children().size() > 0:
		for node in $MarginContainer/VBoxContainer/RequirementsRow.get_children():
			node.queue_free()
	
	for item in info.requirements:
		var hbc = HBoxContainer.new()
		
		var nln = Label.new()
		nln.text = item.item["name"]
		nln.add_theme_font_size_override("font_size", 12)
		
		var nla = Label.new()
		nla.text = "x" + str(item["amount"])
		nla.add_theme_font_size_override("font_size", 12)
		nla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nla.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		
		hbc.add_child(nln)
		hbc.add_child(nla)
		$MarginContainer/VBoxContainer/RequirementsRow.add_child(hbc)
	
	if $MarginContainer/VBoxContainer/LootContainer.get_children().size() > 0:
		for n in $MarginContainer/VBoxContainer/LootContainer.get_children():
			n.queue_free()
	
	#var loot_row = load("res://scenes/loot_row.tscn")
	#for loot in info.loot.entries:
		#var new_row = loot_row.instantiate()
		#new_row.update_info(loot)
		#$MarginContainer/VBoxContainer/LootContainer.add_child(new_row)
	#for loot in info.loot.rare_pool:
		#var new_row = loot_row.instantiate()
		#new_row.update_info(loot, true)
		#$MarginContainer/VBoxContainer/LootContainer.add_child(new_row)
	

func _get_difficulty_color(difficulty: String) -> Color:
	match difficulty.to_lower():
		"easy":
			return Color("#3d8a3d")
		"medium":
			return Color("#b89324")
		"hard":
			return Color("#ee0e00")
		_:
			return Color("#3d8a3d")

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
