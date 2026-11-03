extends Node
## 2026-11-03: Alert step units per skill and tier (per 10% of alert) as the game computes them
func _ready() -> void:
	for sk in Alert.SKILLS:
		var row = []
		for t in range(1, 7):
			row.append(Alert.step_units(sk, t))
		print(">>> ", sk, " ", row)
	get_tree().quit()
