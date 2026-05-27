extends Node

var current_contracts: Array[Contract]
var MAX_CONTRACTS: int = 3

func _ready():
	Signals.contract_finished_signal.connect(remove_contract)
	#add_active_contract(create_contract())

func create_contract():
	var contract = Contract.new()

	contract.major_skill = Mining
	contract.minor_skill = Mining.DATA
	contract.cost = 500
	contract.goal_amount = randi_range(10, 15)
	contract.goal_source = Mining.DATA
	contract.goal_item = Items.DATA
	contract.progress = 0
	contract.reward_exp = randi_range(1000, 10000)
	contract.reward_item = Items.LOGS
	contract.reward_item_amount = randi_range(10, 50)
	contract.description = "Mine " + str(contract.goal_amount) + " data"
	contract.active = true
	contract.connect_progress()
	
	add_active_contract(contract)
	#return contract

func remove_contract(contract):
	if current_contracts.has(contract):
		current_contracts.erase(contract)

#show info in terminal
func show_contracts():
	if current_contracts.is_empty():
		return "No active contracts"

	var lines: Array[String] = []

	lines.append("[b]=== ACTIVE CONTRACTS ===[/b]")
	lines.append("")

	for i in current_contracts.size():
		var contract = current_contracts[i]

		var progress_percent = int(
			(float(contract.progress) / contract.goal_amount) * 100.0
		)

		progress_percent = clamp(progress_percent, 0, 100)

		lines.append("[color=yellow]#%s[/color] %s" % [
			i + 1,
			contract.description
		])

		lines.append("  Progress: %s / %s (%s%%)" % [
			contract.progress,
			contract.goal_amount,
			progress_percent
		])

		lines.append("  Cost: $%s" % [
			str(contract.cost)
		])

		lines.append("  Reward:")

		lines.append("    EXP: %s (%s)" % [
			contract.reward_exp,
			contract.major_skill.SKILL.name
		])

		lines.append("    Item: %s x%s" % [
			contract.reward_item.name,
			contract.reward_item_amount
		])

		lines.append("")

	return "\n".join(lines)

func add_active_contract(contract: Contract):
	if current_contracts.size() < MAX_CONTRACTS:
		current_contracts.append(contract)
		Signals.contract_added(contract)
	else:
		print("Too many contracts")

func complete_contracts() -> String:
	if current_contracts.is_empty():
		return "No active contracts"
	
	var contracts_to_remove = []
	for contract in current_contracts:
		if contract.complete:
			contracts_to_remove.append(contract)
	if contracts_to_remove.is_empty():
		return "No contracts fulfilled"
	
	var return_string = ""
	for contract in contracts_to_remove:
		return_string += contract.major_skill.SKILL.name + " contract completed.\n"
		return_string += "---------------------\n"
		return_string += "+" + str(contract.reward_exp) + ", +" + str(contract.reward_item_amount) + " " + contract.reward_item.name + "\n\n"
		contract.contract_finished()
		current_contracts.erase(contract)
		
	return return_string
