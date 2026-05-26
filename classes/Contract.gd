# contract.gd
class_name Contract
extends RefCounted

var major_skill: Node
var minor_skill: Dictionary
var cost: int
var goal_amount: int
var goal_item: ItemData
var goal_source: Dictionary
var progress: int
var reward: Dictionary
var description: String
var active: bool

func connect_progress():
	minor_skill.signal.connect(update_progress)

#updates to below: also add ItemData param so i can make sure the item
#coming through is the correct one (this would apply in parsing when player
#can get multiple items)
func update_progress(amount):
	if active:
		progress += amount

		if progress >= goal_amount:
			minor_skill.signal.disconnect(update_progress)
			active = false
			contract_fullfilled()
		else:
			update_progress_status()

#trigger some visual that this contract is done connected to frontend
func contract_fullfilled():
	print("contract has been fullfilled, complete for rewards")

#this function should only be called when player manually completes finished contracts
func contract_finished():
	print("Contract fullfilled, adding reward")
	Exp.add_xp(major_skill, minor_skill, reward["exp_amount"])
	Inventory.add_resource(reward["item"], reward["amount"])
	Signals.contract_finished_signal.emit(self)

#this needs to be connected to a frontend node
func update_progress_status():
	print("Connect and update some visual here")
