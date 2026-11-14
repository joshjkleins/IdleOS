extends Node
## 2026-11-14: Decoy Traffic misses are used before Smoke Screen's
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	var g = load("res://scenes/hacking_game.tscn").instantiate()
	add_child(g)
	for i in 5: await get_tree().process_frame
	g.decoys_left = 2
	g.ghost_left = 3
	var seq = []
	for i in 4:
		var d = g.decoys_left; var s = g.ghost_left
		g.counter()
		seq.append("decoy" if g.decoys_left < d else ("smoke" if g.ghost_left < s else "hit"))
	print(">>> 4 countermeasures with 2 decoys + 3 smoke: %s  (left: decoy %d, smoke %d)" % [seq, g.decoys_left, g.ghost_left])
	get_tree().quit()
