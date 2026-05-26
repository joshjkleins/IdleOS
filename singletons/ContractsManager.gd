extends Node

var current_contracts: Array[Contract]

func _ready():
	Signals.contract_finished_signal.connect(remove_contract)

func create_contract():
	var contract = Contract.new()

	contract.major_skill = Mining
	contract.minor_skill = Mining.DATA
	contract.cost = 500
	contract.goal_amount = 25
	contract.goal_source = Mining.DATA
	contract.goal_item = Items.DATA
	contract.progress = 0
	contract.reward = {
		"exp": Mining.DATA,
		"exp_amount": 5000,
		"item": Items.LOGS,
		"amount": 55
	}
	contract.description = "Mine 200 data"
	contract.active = true
	contract.connect_progress()
	current_contracts.append(contract)

func remove_contract(contract):
	if current_contracts.has(contract):
		current_contracts.erase(contract)

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

		if contract.reward.has("exp"):
			lines.append("    EXP: %s (%s)" % [
				contract.reward.exp_amount,
				contract.reward.exp.name
			])

		if contract.reward.has("item"):
			lines.append("    Item: %s x%s" % [
				contract.reward.item.name,
				contract.reward.amount
			])

		lines.append("")

	return "\n".join(lines)
