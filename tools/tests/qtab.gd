extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 10: await get_tree().process_frame
	for l in Stats.hacking_targets: Stats.unlock_location(l)
	Exp.refresh_all_process_unlocks()
	Uploads.completed_tiers = [1]
	for p in Upgrades.group_packages("Mining"):
		p.installed = p.levels.size(); Upgrades._recompute(p)
	Inventory.add_resource(Items.LOGS, 10)
	Queue.steps = ["mine -logs 3", "parse -footprint=logs 2"]
	for t in ["queue -a", "queue -add pa", "queue -add parse -netw", "queue -add parse -network=lo", "queue -add parse -network=logs 10 ov", "queue -add mine -logs 10 ", "queue -add mine -logs 10 s", "queue -add mine -logs pro", "queue -r", "queue -rm ", "queue add crack -pa"]:
		var r = CommandRegistry.complete(t)
		print(">>> '%s' -> '%s' %s" % [t, r.text, r.options if !r.options.is_empty() else ""])
	get_tree().quit()
