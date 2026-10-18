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
	for c in ["cd phishing", "info phishing", "phish -smish target=nobody", "phish -spear target=student", "phish -smish target=student bait=logs"]:
		await _cmd(c)
	await _wait(3.0)
	for c in ["stop", "phish -trap bait=logs"]:
		await _cmd(c)
	Engine.time_scale = 40.0
	await _wait(90.0)
	Engine.time_scale = 1.0
	for c in ["trap", "phish -trap", "cd ..", "trap collect", "trap", "phish -whale"]:
		await _cmd(c)
	await _wait(2.0)
	await _wait(2.0)
	var rx = RegEx.new(); rx.compile("\\[[^\\]]*\\]")
	for l in out:
		var t = rx.sub(str(l), "", true).strip_edges()
		if t != "":
			print("| ", t.left(150))
	print(">>> done")
	get_tree().quit()
