extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 30: await get_tree().process_frame
	Inventory.add_resource(Items.DATABASES, 50)
	for t in ["parse -extraction=databases t", "parse -extraction=databases target=", "ssh parse -extraction=databases t"]:
		var r = CommandRegistry.complete(t)
		print(">>> '%s' -> '%s' %s" % [t, r.text, r.options])
	get_tree().quit()
