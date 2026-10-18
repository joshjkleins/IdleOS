extends Node
var os
var seen := 0
var out: Array = []
func _ready() -> void:
	_run.call_deferred()
func _poll() -> void:
	if os.lines.size() < seen:
		seen = 0
	while seen < os.lines.size():
		out.append(os.lines[seen]); seen += 1
func _wait(sec: float) -> void:
	var t = 0.0
	while t < sec:
		await get_tree().process_frame
		_poll()
		t += get_process_delta_time()
func _cmd(c: String) -> void:
	out.append("##CMD " + c)
	os._on_input_line_text_submitted(c)
	await _wait(1.5)
func _run() -> void:
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	await _wait(3.0)
	os.accepting_player_inputs = true
	Inventory.add_resource(Items.USERNAMES, 50)
	Inventory.add_resource(Items.PASSWORDS, 50)
	Inventory.add_resource(Items.CREDENTIALS, 5000)
	Inventory.add_resource(Items.SQL_INJECTOR, 5000)
	for c in ["apt install phishing.efficiency", "y"]:
		await _cmd(c)
	await _wait(8.0)
	for c in ["cd phishing", "phish -trap"]:
		await _cmd(c)
	for id in ["phishing.chum", "phishing.lure"]:
		var p = Upgrades.packages[id]; p.installed = 1; Upgrades._recompute(p)
	for c in ["chum", "stop", "phish -spear", "chum", "lure", "chum -kill", "stop"]:
		await _cmd(c)
	await _wait(2.0)
	var rx = RegEx.new(); rx.compile("\\[[^\\]]*\\]")
	for l in out:
		var t = rx.sub(str(l), "", true).strip_edges()
		if t != "":
			print("| ", t.left(150))
	print(">>> done")
	get_tree().quit()
