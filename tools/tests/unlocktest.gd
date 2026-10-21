extends Node
## 'unlock <target>' (Hacking) pays the access recipe; compile -access is gone.
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	for i in 10: await get_tree().process_frame
	var adm = Stats.find_target_by_name("administrator")
	print("hint: ", Stats.get_unlock_hint(adm), " recipe: ", Stats.get_access_recipe(adm))
	print(Stats.buy_access(adm))
	var r = Stats.get_access_recipe(adm)
	Inventory.add_resource(r.rare, r.rare_amount)
	Inventory.add_resource(r.payload, r.payload_amount + 1)
	print(Stats.buy_access(adm))
	print("unlocked=", adm.unlocked, " left payload=", Inventory.get_amount(r.payload), " rare=", Inventory.get_amount(r.rare))
	print(Stats.buy_access(adm))
	print(Stats.buy_access(Stats.find_target_by_name("student")))
	print("compiling procs: ", Compiling.minor_processes.map(func(p): return p.name))
	var hs = load("res://scenes/hacking.tscn")
	print("hacking scene loads: ", hs != null)
	var bad = []
	for id in Upgrades.packages:
		for l in Upgrades.packages[id].levels:
			for c in l.get("costs", []):
				if c.item != "VM tokens (any skill)" and Inventory.get_item_by_name(c.item) == null and !(c.item in bad):
					bad.append(c.item)
	print("unresolved cost items: ", bad)
	get_tree().quit()
