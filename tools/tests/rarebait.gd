extends Node
var os
func _ready() -> void:
	_run.call_deferred()
func _strip(s: String) -> String:
	var r = RegEx.new(); r.compile("\\[[^\\]]*\\]"); return r.sub(s, "", true)
func _run() -> void:
	for i in 30: await get_tree().process_frame
	var cc = Items.PARENTS_CREDIT_CARD
	Inventory.add_resource(cc, 5)
	print("before goal: is_rare_bait=%s  parse: %s" % [Phishing.is_rare_bait(cc), Phishing.parse_bait("phish -mod bait=parents credit card").error])
	print(_strip(Inventory.list_specific_item(cc)).split("USED IN")[1].left(500))
	Uploads.uploaded[cc] = Uploads.get_goal_amount(cc, 1)
	var pb = Phishing.parse_bait("phish -mod bait=parents credit card")
	print("after goal: is_rare_bait=%s bait=%s err='%s' cost=%d  spear: '%s'" % [Phishing.is_rare_bait(cc), pb.bait.name if pb.bait else "-", pb.error, Phishing.bait_cost(cc), Phishing.parse_bait("phish -spear bait=parents credit card").error])
	print(_strip(Inventory.list_specific_item(cc)).split("USED IN")[1].left(400))
	print("drop rows student cache: ", Decoding.get_drop_table(Items.STUDENT_CACHE).filter(func(r): return r.get("exploit", false)).map(func(r): return "%s %.0f%%" % [r.name, r.chance * 100]))
	var got = {}
	for k in 400:
		for ex in Exploits.roll_drops(Items.STUDENT_CACHE, Decoding.CACHE):
			got[ex.name] = got.get(ex.name, 0) + 1
	print("400 student caches: ", got)
	get_tree().quit()
