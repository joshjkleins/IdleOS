extends Node
func _ready() -> void:
	_run.call_deferred()
func _d(j) -> String:
	var o = {}
	for k in j.get("out", {}): o[k.name] = snappedf(float(j.out[k]), 0.001)
	var i = {}
	for k in j.get("inp", {}): i[k.name] = snappedf(float(j.inp[k]), 0.001)
	return "sec %.2f in %s out %s xp %s" % [float(j.get("seconds", 0)), i, o, str(j.get("xp", 0))]
func _run() -> void:
	for i in 30: await get_tree().process_frame
	print("mine logs: ", _d(Offline._job(Mining, Mining.minor_processes[0], {})))
	Inventory.add_resource(Items.LOGS, 100)
	print("parse footprint logs: ", _d(Offline._job(Parsing, Parsing.FOOTPRINT, {"items": [Items.ItemType.LOGS]})))
	Inventory.add_resource(Items.ENCRYPTED_PASSWORDS, 100); Inventory.add_resource(Items.USERNAMES, 100); Inventory.add_resource(Items.PASSWORDS, 100); Inventory.add_resource(Items.CREDENTIALS, 100); Inventory.add_resource(Items.IP_ADDRESS, 100)
	print("crack pw: ", _d(Offline._job(Cracking, Cracking.PASSWORD, {})))
	print("match cred: ", _d(Offline._job(Matching, Matching.minor_processes[0], {})))
	print("phish spear: ", _d(Offline._job(Phishing, Phishing.SPEAR, {})))
	print("compile school: ", _d(Offline._job(Compiling, Compiling.SCHOOL, {})))
	Inventory.add_resource(Items.LOGS, 100)
	Inventory.add_resource(Items.STUDENT_CACHE, 1)
	print("decode cache: ", _d(Offline._job(Decoding, Decoding.CACHE, {"item": Items.ItemType.STUDENT_CACHE})))
	print("vm uptime per token: ", VMManager.get("TOKEN_SECONDS") if "TOKEN_SECONDS" in VMManager else "?")
	print("upload secs basic/rare: ", Uploads.get_upload_seconds(Items.LOGS), " ", Uploads.get_upload_seconds(Items.PARENTS_CREDIT_CARD))
	for s in [Mining, Parsing, Cracking, Matching, Phishing, Compiling, Decoding, Hacking]:
		print(s.SKILL.name, " xp L2 %d L5 %d L10 %d" % [Exp.xp_for_level(2), Exp.xp_for_level(5), Exp.xp_for_level(10)])
		break
	var stu = Stats.hacking_targets["School"].targets[0]
	print("student: ", {"integ": stu.integrity, "fw": stu.firewall, "exp": stu.exp, "req": [stu.requirements.item.name, stu.requirements.amount]})
	get_tree().quit()
