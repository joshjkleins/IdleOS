extends HBoxContainer
## One phishing line. How it runs depends on the process "style" (see Phishing.gd):
##   lines: cast -> wait -> bite roll -> download -> catch, recast
##   whale: the terminal's only line; every line is on it (more lines = shorter reel); catch is a bundle
##   smish: the terminal's only line; sends a blast, replies trickle in as intel points
##   trap:  the terminal's only line; sets the trap, then the terminal finishes
## The terminal (PhishingTerminal) supplies mode / timing / heat / bite chance / bait / tokens.

signal line_ended_signal
signal caught_something

var type
var terminal # PhishingTerminal
var pb_fill_tween: Tween
var pb_drain_tween: Tween
var active: bool = false
var safe_stop: bool = false
var _download_mode = 0  # BaseTerminal.Mode the catch downloaded in (decides catch heat)
var _attempt_seconds := 0.0 # time this attempt took (VM tokens roll on time)

func setup():
	active = true
	$Method.text = type.name
	$Status.text = "sending phishing attempt"
	$ProgressBar.value = 0.0
	$ProgressBar.max_value = 5.0
	$ProgressBar/TimeRemaining.text = "00:00:00"
	$ProgressBar/TimeRemaining.visible = false

func begin(p_type, p_terminal = null):
	type = p_type
	if p_terminal:
		terminal = p_terminal
	setup()
	_attempt_seconds = 0.0
	match type.get("style", "lines"):
		"whale":
			_run_whale()
		"smish":
			_run_smish()
		"trap":
			_run_trap()
		_:
			_run_line()

#region shared steps
## Fill the bar over the cast time; returns the mode it was cast in, or -1 if stopped.
func _cast(status: String) -> int:
	$Status.text = status
	var cast_mode = terminal.get_mode()
	var cast_time: float = terminal.step_seconds(cast_mode, "cast time", "overclock cast time", "overheat cast time")
	_attempt_seconds += cast_time
	$ProgressBar.max_value = 5.0
	$ProgressBar.value = 0.0
	pb_fill_tween = create_tween()
	pb_fill_tween.tween_property($ProgressBar, "value", $ProgressBar.max_value, cast_time)
	await pb_fill_tween.finished
	if !active:
		return -1
	terminal.apply_heat(cast_mode)
	return cast_mode

func _wait(status: String, seconds: float) -> bool:
	$Status.text = status
	_attempt_seconds += seconds
	await get_tree().create_timer(seconds).timeout
	return active

## Drain the bar over <time> (download / reel); false if stopped.
func _drain(status: String, time: float) -> bool:
	$ProgressBar/TimeRemaining.visible = true
	$Status.text = status
	_attempt_seconds += time
	$ProgressBar.max_value = time
	$ProgressBar.value = time
	pb_drain_tween = create_tween()
	pb_drain_tween.tween_property($ProgressBar, "value", 0, time)
	await pb_drain_tween.finished
	$ProgressBar/TimeRemaining.visible = false
	return active

func _add(item: ItemData, amount: int) -> void:
	if item == null or amount <= 0:
		return
	Inventory.add_resource(item, amount)
	if item == Items.SQL_INJECTOR:
		Tutorial.track_event(Tutorial.TutorialEvent.PHISH_15_SQL_INJECTORS, amount)
	if item == Items.PACKET_SPOOF:
		Tutorial.track_event(Tutorial.TutorialEvent.PHISH_1_PACKET_SPOOFS, amount)
	Signals.phishing_item_caught_item(item)

## After an attempt (caught or not): token roll, short pause, then recast unless stopping.
func _end_attempt(pause: float) -> void:
	terminal.roll_tokens(_attempt_seconds + pause)
	if !safe_stop:
		await get_tree().create_timer(pause).timeout
	if !active:
		return
	if safe_stop:
		stop()
	if active:
		begin(type)

func roll_item_reward(resource_list: Array) -> Dictionary:
	var total_weight = 0
	for entry in resource_list:
		total_weight += entry["weight"]
	if total_weight <= 0:
		return {}
	var roll = randi_range(1, total_weight)
	var cumulative = 0
	for entry in resource_list:
		cumulative += entry["weight"]
		if roll <= cumulative:
			return {"item": entry["item"], "amount": randi_range(entry["min"], entry["max"])}
	return {}
#endregion

#region lines (Spear, Mod)
func _run_line() -> void:
	var baited: bool = terminal.take_bait()
	if await _cast("sending phishing attempt" + (" (baited)" if baited else "")) < 0:
		return
	if !await _wait("waiting for response   ", terminal.wait_seconds(terminal.get_mode())):
		return
	if randf() < terminal.get_bite_chance(baited):
		_download_mode = terminal.get_mode()
		var time = terminal.step_seconds(_download_mode, "download time", "overclocked download time", "overheated download time", true)
		if !await _drain("attempt successful, downloading information", time):
			return
		var reward = roll_item_reward(terminal.reward_list())
		var amount = terminal.catch_amount(reward.amount, baited) if !reward.is_empty() else 0
		if amount <= 0:
			$Status.text = "nothing worth keeping"
		else:
			$Status.text = "+%d %s" % [amount, reward.item.name]
			_add(reward.item, amount)
		var lured = terminal.roll_lure()
		if lured:
			_add(lured, 1)
			$Status.text += "  [color=#e3b341]+1 %s (lure)[/color]" % lured.name
		terminal.apply_heat(_download_mode)
		type.signal.emit(1)
		Exp.add_xp(Phishing, type, terminal.catch_xp(type["experience per level"]))
		Signals.update_hud(Phishing)
		caught_something.emit(type)
		_end_attempt(1.0)
	else:
		$Status.text = "attempt failed"
		_end_attempt(1.5)
#endregion

#region whale
func _run_whale() -> void:
	var lines: int = terminal.line_count()
	var baited: bool = terminal.take_bait()
	if await _cast("casting %d lines at a whale%s" % [lines, " (baited)" if baited else ""]) < 0:
		return
	if !await _wait("circling the target...", terminal.wait_seconds(terminal.get_mode())):
		return
	if randf() < terminal.get_bite_chance(baited):
		_download_mode = terminal.get_mode()
		var total = terminal.step_seconds(_download_mode, "download time", "overclocked download time", "overheated download time", true)
		if !await _drain("WHALE ON: reeling in with %d lines" % lines, total / max(1, lines)):
			return
		var count = terminal.catch_amount(randi_range(type["bundle min"], type["bundle max"]), baited)
		var tally := {}
		for i in count:
			var r = roll_item_reward(type["resource gained"])
			if !r.is_empty():
				tally[r.item] = tally.get(r.item, 0) + r.amount
		var parts = []
		for item in tally:
			_add(item, tally[item])
			parts.append("+%d %s" % [tally[item], item.name])
		if randf() < type.get("exploit chance", 0.0):
			var ex = Phishing.roll_exploit_item()
			if ex:
				_add(ex, 1)
				parts.append("[color=#e3b341]+1 %s[/color]" % ex.name)
		var lured = terminal.roll_lure()
		if lured:
			_add(lured, 1)
			parts.append("[color=#e3b341]+1 %s (lure)[/color]" % lured.name)
		$Status.text = "landed: " + ", ".join(parts)
		terminal.apply_heat(_download_mode)
		type.signal.emit(count)
		Exp.add_xp(Phishing, type, terminal.catch_xp(type["experience per level"] * (2 if baited else 1)))
		Signals.update_hud(Phishing)
		caught_something.emit(type)
		_end_attempt(2.0)
	else:
		$Status.text = "the whale slipped away"
		_end_attempt(2.0)
#endregion

#region smish
func _run_smish() -> void:
	var texts: int = int(type["texts per line"]) * terminal.line_count()
	var baited: bool = terminal.take_bait()
	if await _cast("sending %d texts%s" % [texts, " (baited)" if baited else ""]) < 0:
		return
	var mode = terminal.get_mode()
	var window: float = terminal.step_seconds(mode, "wait time max", "overclock wait time", "overheat wait time", true)
	var chance = terminal.get_bite_chance(baited)
	var replies: Array = []
	for i in texts:
		if randf() < chance:
			replies.append(randf() * window)
	replies.sort()
	var got := 0
	var last_target := ""
	$ProgressBar/TimeRemaining.visible = true
	$ProgressBar.max_value = window
	$ProgressBar.value = window
	pb_drain_tween = create_tween()
	pb_drain_tween.tween_property($ProgressBar, "value", 0, window)
	$Status.text = "%d texts out, waiting for replies" % texts
	var t := 0.0
	for at in replies:
		await get_tree().create_timer(max(0.01, at - t)).timeout
		t = at
		if !active:
			return
		got += 1
		var mult = terminal.catch_amount(1, baited) # bait / Chum x2, Survey may make it 0
		var target = Phishing.smish_target(terminal.smish_target)
		if mult <= 0:
			last_target = target.name if !target.is_empty() else ""
		elif target.is_empty():
			_add(Items.SQL_INJECTOR, mult) # every target maxed
			last_target = ""
		else:
			for i in mult:
				Decoding.add_intel_point(target)
			last_target = target.name
		type.signal.emit(1)
		var lured = terminal.roll_lure()
		if lured:
			_add(lured, 1)
		Exp.add_xp(Phishing, type, terminal.catch_xp(type["experience per level"] * (2 if baited else 1)))
		Signals.update_hud(Phishing)
		caught_something.emit(type)
		$Status.text = "%d/%d replied · +%d intel on %s" % [got, texts, mult, last_target] if last_target != "" else "%d/%d replied · targets maxed: +%d SQL Injector" % [got, texts, mult]
	await get_tree().create_timer(max(0.01, window - t)).timeout
	if !active:
		return
	_attempt_seconds += window
	$ProgressBar/TimeRemaining.visible = false
	terminal.apply_heat(mode)
	$Status.text = "blast done: %d of %d replied" % [got, texts]
	_end_attempt(2.0)
#endregion

#region trap
func _run_trap() -> void:
	var bait: ItemData = terminal.bait if terminal.take_bait() else null
	if await _cast("planting watering-hole trap" + (" (baited)" if bait else "")) < 0:
		return
	Phishing.set_trap(bait)
	$Status.text = "trap set: fills in %s" % Phishing.format_minutes(Phishing.trap_seconds_total())
	stop()
#endregion

func kill_tweens():
	for tw in [pb_fill_tween, pb_drain_tween]:
		if tw and tw.is_valid() and tw.is_running():
			tw.kill()

func stop():
	if !active:
		return
	active = false
	kill_tweens()
	process_done()

func stop_safely():
	safe_stop = true

func process_done():
	line_ended_signal.emit()

func _on_progress_bar_value_changed(value):
	$ProgressBar/TimeRemaining.text = str(value).pad_decimals(2)
