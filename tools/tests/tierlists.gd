extends Node
## 2026-11-03: 'exploits' and 'mod -tier' list only unlocked tiers (School + Lawfirm here), greyed rows for unowned
func _ready() -> void:
	_run.call_deferred()
func _strip(s: String) -> String:
	var r = RegEx.new(); r.compile("\\[(/?color[^\\]]*|/?bgcolor[^\\]]*)\\]"); return r.sub(s, "", true)
func _run() -> void:
	Stats.unlock_location("Lawfirm")
	var mods = Inventory.get_hacking_mods_items()
	var one = Phishing.tier_mod_pool(1)[0].item
	Inventory.add_resource(one, 2)
	var ex = Exploits.get_items().filter(func(i): return int(i.tier) == 1)[0]
	Inventory.add_resource(ex, 1)
	print(">>> EXPLOITS\n", _strip(ContextCommands.exploits_text()).split("WHERE TO FIND")[0])
	print(">>> MOD -TIER\n", _strip(ContextCommands._mod_items_text(false)))
	get_tree().quit()
