extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 30: await get_tree().process_frame
	Inventory.add_resource(Items.LOGS, 2000)
	print("2000 logs: ", HintEngine.upload_hint())
	Inventory.add_resource(Items.LOGS, 5000)
	print("7000 logs: ", HintEngine.upload_hint())
	var rare = Uploads.get_tier_rares(1)[0]
	Inventory.add_resource(rare, 3)
	print("+3 %s: " % rare.name, HintEngine.upload_hint(), " reserve ", HintEngine.reserved().get(rare, 0))
	Inventory.add_resource(rare, 10)
	print("+13: ", HintEngine.upload_hint())
	get_tree().quit()
