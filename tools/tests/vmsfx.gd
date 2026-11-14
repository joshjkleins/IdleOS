extends Node
## 2026-11-14: the vm_shutdown sfx loads and plays when a VM is released
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 10: await get_tree().process_frame
	print(">>> stream loaded: %s" % (Audiomanager._sfx_streams.get("vm_shutdown") != null))
	var before = Audiomanager._last_played.get("vm_shutdown", -1)
	Audiomanager.play_sfx("vm_shutdown")
	print(">>> played: %s" % (Audiomanager._last_played.get("vm_shutdown", -1) != before))
	get_tree().quit()
