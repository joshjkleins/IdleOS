extends HBoxContainer

func update(description: String, value, duration: int):
	if value is int:
		$ModifierLabel.text = description + " +" + str(value)
	elif value is float:
		$ModifierLabel.text = description + " +" + str(int(value * 100.0)) + "%"
		
	$ModifierLabel2.text = str(duration) + " hacks"
