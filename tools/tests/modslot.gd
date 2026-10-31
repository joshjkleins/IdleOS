extends Node
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 5: await get_tree().process_frame
	for n in ["sql_booster", "hardened_shell", "backdoor", "leech", "critical_overflow", "decoy_traffic", "packet_shredder"]:
		var it = load("res://items/hacking_mods/%s.tres" % n)
		if it: Inventory.add_resource(it, 2)
	var re = RegEx.new(); re.compile("\\[(color|/color)[^\\]]*\\]")
	var t = re.sub(ContextCommands.get_mod_command(false), "", true)
	var on = false
	for l in t.split("\n"):
		if "MOD ITEMS" in l: on = true
		if on and l.strip_edges() != "": print(">>> ", l.substr(0, 110))
	get_tree().quit()
