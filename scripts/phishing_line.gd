extends HBoxContainer

signal line_ended_signal

var type
var pb_fill_tween: Tween
var pb_drain_tween: Tween
var active: bool = false
var safe_stop: bool = false
var did_overclock: bool = false

func setup():
	active = true
	$Method.text = type.name
	$Status.text = "sending phishing attempt"
	$ProgressBar.value = 0.0
	$ProgressBar.max_value = 5.0
	$ProgressBar/TimeRemaining.text = "00:00:00"
	$ProgressBar/TimeRemaining.visible = false

func begin(p_type):
	type = p_type
	setup()
	pb_fill_tween = create_tween()
	pb_fill_tween.tween_property($ProgressBar, "value", $ProgressBar.max_value, 2.0)
	await pb_fill_tween.finished
	if !active:
		return
	
	add_heat()
	
	var defrag_bonus = Defragging.PHISHING["bonus efficiency"] if Stats.has_bonus(Phishing) else 0.0
	var eff_text = str((type["efficiency"] + Phishing.process_upgrades["efficiency"]["amount"] + defrag_bonus) * 100).pad_decimals(1) 
	$Status.text = "waiting for response   " + "[color=#888888]" + eff_text + "% chance of success[/color]"
	await get_tree().create_timer(randf_range(type["wait time min"], type["wait time max"])).timeout
	if !active:
		return
	var eff = type["efficiency"] + Phishing.process_upgrades["efficiency"]["amount"] + defrag_bonus
	if randf() <= eff: #success
		$ProgressBar/TimeRemaining.visible = true
		$Status.text = "attempt successful, downloading information"
		
		pb_drain_tween = create_tween()
		var time
		if Stats.overheated:
			did_overclock = false
			time = type["overheated download time"]
		elif Stats.overclocked:
			did_overclock = true
			time = type["overclocked download time"]
		else:
			did_overclock = false
			time = type["download time"]
			
		$ProgressBar.max_value = time
		$ProgressBar.value = time
		pb_drain_tween.tween_property($ProgressBar, "value", 0, time)
		await pb_drain_tween.finished
		if !active:
			return
		finished(true)
	else: #failure
		finished(false)

func finished(caught: bool):
	if caught:
		var item = type["resource gained"].pick_random()
		$Status.text = "+1 " + item.name
		add_heat()
		Inventory.add_resource(item, 1)
		type.signal.emit(1)
		Exp.add_xp(Phishing, type, type["experience per level"]  * Phishing.process_upgrades["experience"]["amount"])
		Signals.update_hud(Phishing)
		
		if !safe_stop:
			await get_tree().create_timer(1.0).timeout
		if !active:
			return
	else:
		$Status.text = "attempt failed"
		await get_tree().create_timer(1.5).timeout
		if !active:
			return
	if safe_stop:
		stop()
	if active:
		begin(type)

func add_heat():
	if Stats.overheated:
		Stats.update_tempature(type["overheat heat"])
	elif did_overclock:
		Stats.update_tempature(type["overclock heat"])
	else:
		Stats.update_tempature(type["heat"])

func kill_tweens():
	if pb_fill_tween:
		if pb_fill_tween.is_valid():
			if pb_fill_tween.is_running():
				pb_fill_tween.kill()
	if pb_drain_tween:
		if pb_drain_tween.is_valid():
			if pb_drain_tween.is_running():
				pb_drain_tween.kill()

func stop():
	active = false
	kill_tweens()
	process_done()

func stop_safely():
	safe_stop = true

func process_done():
	line_ended_signal.emit()
	print("Done")

func _on_progress_bar_value_changed(value):
	$ProgressBar/TimeRemaining.text = str(value).pad_decimals(2)
