extends HBoxContainer

func update(n_name: String, amount: int):
	$ItemName.text = n_name
	$amount.text = "x" + str(amount)
