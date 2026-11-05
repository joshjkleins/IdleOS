extends Node
## 2026-11-05: offline Spear with bait that runs out partway (25 Encrypted passwords, 1 h)
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	var bait = Items.ENCRYPTED_PASSWORDS if "ENCRYPTED_PASSWORDS" in Items else Upgrades.get_item("Encrypted passwords")
	for amt in [25, 120, 0]:
		Inventory.remove_resource(bait, Inventory.get_amount(bait))
		Inventory.add_resource(bait, amt)
		var sql0 = Inventory.get_amount(Items.SQL_INJECTOR)
		var snap = {"bait": bait.id, "target": "", "mod_tier": 0}
		Offline.report = {"gains": [], "lost": {}, "drivers": [], "uploaded": [], "staged": [], "notes": [], "trap": -1.0}
		var ran = Offline._run(Phishing, Phishing.SPEAR, snap, 3600.0)
		print(">>> start bait %d: ran %.0fs of 3600, bait left %d, SQL gained %d, lines %d" % [amt, ran, Inventory.get_amount(bait), Inventory.get_amount(Items.SQL_INJECTOR) - sql0, Phishing.max_lines + int(Upgrades.cur("phishing.lines"))])
	get_tree().quit()
