extends Node
## Fresh-save tutorial run under demo rules (time-scaled). PART=1: mining..matching, PART=2: phishing..compiling.
var os
var game_t := 0.0
var log_lines: Array = []
func _ready() -> void:
	_run.call_deferred()
func _process(delta: float) -> void:
	game_t += delta
	Stats.system_tempature = min(Stats.system_tempature, 70.0) # keep heat out of the timing (cooling is idle-time)
func _cmd(c: String) -> void:
	os._on_input_line_text_submitted(c)
	for i in 10: await get_tree().process_frame
func _done(e) -> bool:
	return Tutorial.completed_events.has(e)
func _until(e, limit_min: float = 60.0) -> bool:
	var start = game_t
	while !_done(e):
		await get_tree().process_frame
		if game_t - start > limit_min * 60.0:
			return false
	return true
func _section(name: String, start: float) -> void:
	print(">>> %-34s %5.1f game-min  | tutorial %d/38 | logs %d ip %d enc %d user %d pw %d cred %d sql %d spoof %d payload %d" % [name, (game_t - start) / 60.0, Tutorial.completed_events.size(), Inventory.get_amount(Items.LOGS), Inventory.get_amount(Items.IP_ADDRESS), Inventory.get_amount(Items.ENCRYPTED_PASSWORDS), Inventory.get_amount(Items.USERNAMES), Inventory.get_amount(Items.PASSWORDS), Inventory.get_amount(Items.CREDENTIALS), Inventory.get_amount(Items.SQL_INJECTOR), Inventory.get_amount(Items.PACKET_SPOOF), Inventory.get_amount(Items.SCHOOL_PAYLOAD)])
func _stop() -> void:
	await _cmd("kill -s")
	var t = game_t
	while os.process_running and game_t - t < 120.0:
		await get_tree().process_frame
	if os.process_running:
		await _cmd("stop")
func _package_upload(item: String) -> void:
	await _cmd("cd ../decoding")
	await _cmd("decode -package=%s 1" % item)
	var t = game_t
	while os.process_running and game_t - t < 120.0:
		await get_tree().process_frame
	await _cmd("upload -" + item)
	await _cmd("cd ..")
func _run() -> void:
	Engine.max_fps = 0
	os = load("res://scenes/idle_os_2.tscn").instantiate()
	add_child(os)
	for i in 30: await get_tree().process_frame
	if Tutorial.show_intro: os._finish_boot()
	for i in 30: await get_tree().process_frame
	Engine.time_scale = float(OS.get_environment("TS")) if OS.get_environment("TS") != "" else 30.0
	var E = Tutorial.TutorialEvent
	var part = OS.get_environment("PART")
	var t0 = game_t
	if part == "1":
		await _cmd("-h"); await _cmd("cd mining"); await _cmd("mine -logs")
		await _cmd("info"); await _cmd("info mining"); await _cmd("focus"); await _cmd("sticky"); await _cmd("ls"); await _cmd("ls logs")
		print("    mining ok: ", await _until(E.MINE_20_LOGS))
		await _cmd("unsticky"); await _stop()
		_section("Mining (35 logs)", t0); t0 = game_t
		await _cmd("upload"); await _cmd("cd ../decoding"); await _cmd("decode -package=logs 5")
		var t = game_t
		while os.process_running and game_t - t < 120.0: await get_tree().process_frame
		await _cmd("upload -logs"); await _cmd("cd ..")
		_section("Upload intro (5 logs)", t0); t0 = game_t
		await _cmd("cd parsing"); await _cmd("parse -footprint=logs")
		for e in [E.PARSE_20_LOGS, E.OBTAIN_3_ENCRYPTED_PASSWORDS, E.OBTAIN_3_USERNAMES, E.OBTAIN_3_IP_ADDRESSES]:
			var ok = await _until(e, 40.0)
			if !ok: print("    STUCK on ", E.keys()[e])
		await _stop(); await _cmd("cd ..")
		await _package_upload("ip address")
		_section("Parsing (30 logs) + upload IP", t0); t0 = game_t
		await _cmd("cd cracking"); await _cmd("crack -password")
		print("    crack ok: ", await _until(E.CRACK_3_PASSWORDS, 40.0))
		await _stop(); await _cmd("cd ..")
		await _package_upload("passwords")
		_section("Cracking (6) + upload password", t0); t0 = game_t
		await _cmd("cd matching"); await _cmd("match -cred")
		print("    match ok: ", await _until(E.MATCH_3_CREDENTIALS, 40.0))
		await _stop(); await _cmd("cd ..")
		await _package_upload("credentials")
		_section("Matching (5) + upload credential", t0); t0 = game_t
		print("    uploads: logs %d/%d ip %d pw %d cred %d | current task: %s" % [Uploads.get_uploaded(Items.LOGS), Uploads.get_staged(Items.LOGS), Uploads.get_uploaded(Items.IP_ADDRESS), Uploads.get_uploaded(Items.PASSWORDS), Uploads.get_uploaded(Items.CREDENTIALS), Tutorial.get_current_task().left(60)])
		SaveManager.save_game()
	else:
		await _cmd("info phishing spear"); await _cmd("track sql injectors"); await _cmd("cd phishing"); await _cmd("phish -spear")
		print("    sql ok: ", await _until(E.PHISH_15_SQL_INJECTORS, 40.0), " spoof ok: ", await _until(E.PHISH_1_PACKET_SPOOFS, 40.0))
		await _cmd("untrack sql injectors"); await _stop(); await _cmd("cd ..")
		_section("Phishing (10 SQL + 1 spoof)", t0); t0 = game_t
		await _cmd("cd compiling"); await _cmd("compile -school")
		print("    compile ok: ", await _until(E.COMPILE_3_SCHOOL_PAYLOADS, 40.0))
		await _stop(); await _cmd("cd ..")
		await _package_upload("school payload")
		_section("Compiling (4) + upload payload", t0); t0 = game_t
		print("    current task: ", Tutorial.get_current_task().left(70))
		SaveManager.save_game()
	get_tree().quit()
