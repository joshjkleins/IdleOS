extends HBoxContainer

func update(description: String, value: String, duration: int):
	$ModifierLabel.text = description + " " + value
	$ModifierLabel2.text = str(duration) + " hacks"
