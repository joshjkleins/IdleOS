extends HBoxContainer

func update(name: String, amount: int):
	$ItemName.text = name
	$amount.text = "x" + str(amount)
