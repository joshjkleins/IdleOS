extends Node
## 2026-11-14: cost of one decoded find with many different items already in the session panel
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	var t = load("res://scenes/cache_decrypt_terminal.tscn").instantiate()
	add_child(t)
	for i in 5: await get_tree().process_frame
	var items = Items.ITEM_MAP.values().slice(0, 60)
	for it in items:
		t.update_items_gained(it, 1)
	await get_tree().process_frame
	var t0 = Time.get_ticks_usec()
	for k in 200:
		t.update_items_gained(items[k % items.size()], 1)
	var per = (Time.get_ticks_usec() - t0) / 200.0
	await get_tree().process_frame
	print(">>> %d items shown: %.0f us per find  (rows in panel: %d)" % [items.size(), per, t.labels_container.get_child_count()])
	get_tree().quit()
