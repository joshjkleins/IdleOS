extends Node
## Tab completion: CommandRegistry.complete on partial commands (main terminal + hacking console).
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 10: await get_tree().process_frame
	Inventory.add_resource(Items.LOGS, 10); Inventory.add_resource(Items.ENCRYPTED_PASSWORDS, 3); Inventory.add_resource(Items.STUDENT_CACHE, 2)
	for t in ["cd mi", "cd ../pa", "pa", "parse -f", "parse -footprint=", "parse -footprint=enc", "up", "upload ", "upload sch", "mine", "mine -", "info compiling sc", "apt install mining.sp", "decode -cache=s", "ls admin", "ls vice p", "phish -spear bait=", "ssh pars", "ssh parsing footprint=l", "zz", "", "track lo", "compile -mod=l"]:
		var r = CommandRegistry.complete(t)
		print("'%s' -> '%s'  %s" % [t, r.text, CommandRegistry.options_text(r.options, 12) if !r.options.is_empty() else ""])
	for t in ["vi", "view school", "hack st", "unl", "unlock a"]:
		var r = CommandRegistry.complete(t, true)
		print("[hack] '%s' -> '%s'  %s" % [t, r.text, CommandRegistry.options_text(r.options, 12) if !r.options.is_empty() else ""])
	get_tree().quit()
