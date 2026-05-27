# contract.gd
class_name Contract
extends RefCounted

signal progress_updated_signal
signal progress_complete_signal
signal contract_finished_signal

var major_skill: Node
var minor_skill: Dictionary
var cost: int
var goal_amount: int
var goal_item: ItemData
var goal_source: Dictionary
var progress: int
var description: String
var active: bool
var complete: bool = false
var reward_exp: int
var reward_item: ItemData
var reward_item_amount: int

func connect_progress():
	minor_skill.signal.connect(update_progress)

func update_progress(amount):
	if active:
		progress += amount
		if progress >= goal_amount:
			progress = goal_amount
			minor_skill.signal.disconnect(update_progress)
			active = false
			contract_fullfilled()
		progress_updated_signal.emit(self)

#trigger some visual that this contract is done connected to frontend
func contract_fullfilled():
	complete = true
	progress_complete_signal.emit()
	print("contract has been fullfilled, complete for rewards")

#this function should only be called when player manually completes finished contracts
func contract_finished():
	Exp.add_xp(major_skill, minor_skill, reward_exp)
	Inventory.add_resource(reward_item, reward_item_amount)
	contract_finished_signal.emit()
