extends HBoxContainer

signal line_ended_signal
signal caught_something

var type
var pb_fill_tween: Tween
var pb_drain_tween: Tween
var active: bool = false
var safe_stop: bool = false
var did_overclock: bool = false

func setup():
	active = true
	
	var defrag_bonus = Defragging.PHISHING["bonus efficiency"] if Stats.has_bonus(Phishing) else 1.0
	var base_eff = type["efficiency"] + Phishing.process_upgrades["efficiency"]["amount"]
	var eff_text = str(base_eff * defrag_bonus * 100.0).pad_decimals(1)
	
	$Method.text = type.name #+ " [color=#888888][font_size=12](eff: " + eff_text + "%)[/font_size][/color]"
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
	
	var defrag_bonus = Defragging.PHISHING["bonus efficiency"] if Stats.has_bonus(Phishing) else 1.0
	var base_eff = type["efficiency"] + Phishing.process_upgrades["efficiency"]["amount"]
	#var eff_text = str(base_eff * defrag_bonus * 100.0).pad_decimals(1) 
	$Status.text = "waiting for response   "
	await get_tree().create_timer(randf_range(type["wait time min"], type["wait time max"])).timeout
	if !active:
		return
	var eff = base_eff * defrag_bonus
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

func roll_item_reward(resource_list: Array) -> Dictionary:

	# Sum up total weight
	var total_weight = 0
	for entry in resource_list:
		total_weight += entry["weight"]

	# Roll a random number within the total weight
	var roll = randi_range(1, total_weight)

	# Walk through entries, subtracting weight until we land on one
	var cumulative = 0
	for entry in resource_list:
		cumulative += entry["weight"]
		if roll <= cumulative:
			var amount = randi_range(entry["min"], entry["max"])
			return {
				"item": entry["item"],
				"amount": amount
			}

	# Fallback (shouldn't be hit if weights are set up correctly)
	return {}

func finished(caught: bool):
	if caught:
		########### ADD WEIGHTED PICKS HERE #############
		var reward = roll_item_reward(type["resource gained"])
		#var item = type["resource gained"].pick_random()
		
		$Status.text = "+1 " + reward.item.name
		add_heat()
		
		#make this one either or since player should only be able to 'phish' in one thing
		if randf() <= 0.01:
			Inventory.add_resource(Items.VM_PHISHING_TOKEN, 1)
		else:
			Inventory.add_resource(reward.item, 1)
			if reward.item == Items.SQL_INJECTOR:
				Tutorial.track_event(Tutorial.TutorialEvent.PHISH_15_SQL_INJECTORS, 1)
			if reward.item == Items.PACKET_SPOOF:
				Tutorial.track_event(Tutorial.TutorialEvent.PHISH_5_PACKET_SPOOFS, 1)
		type.signal.emit(1)
		Exp.add_xp(Phishing, type, type["experience per level"]  * Phishing.process_upgrades["experience"]["amount"])
		Signals.update_hud(Phishing)
		caught_something.emit(type)
		
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

func _on_progress_bar_value_changed(value):
	$ProgressBar/TimeRemaining.text = str(value).pad_decimals(2)
