extends Node
func _ready() -> void:
	SaveManager.load_game()
	_run.call_deferred()
func _run() -> void:
	await get_tree().process_frame
	print(">>> launch eff: logs=%s password=%s spear=%s cred=%s" % [Mining.LOGS.efficiency, Cracking.PASSWORD.efficiency, Phishing.SPEAR.efficiency, Matching.CREDENTIAL.efficiency])
	SaveManager.save_game()
	get_tree().quit()
