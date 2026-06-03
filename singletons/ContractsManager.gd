extends Node

var current_contracts: Array[Contract]
var MAX_CONTRACTS: int = 3

var available_contracts = []
var contract_reward_pool = [
	Items.LOGS,
	Items.IP_ADDRESS,
	Items.CREDENTIALS,
	Items.PASSWORDS,
	Items.ENCRYPTED_PASSWORDS,
	Items.SQL_INJECTOR,
	Items.PACKET_SPOOF,
	Items.USERNAMES,
]

func _ready():
	Signals.contract_finished_signal.connect(remove_contract)
	available_contracts = create_available_contracts(5)

func create_available_contracts(amount: int) -> Array[Contract]:
	var contracts: Array[Contract]
	var contract_types = [create_mining_contract, create_parsing_contract, create_cracking_contract, create_matching_contract, create_decoding_contract, create_phishing_contract]
	for i in range(amount):
		var contract = contract_types.pick_random().call()
		contracts.append(contract)
	
	return contracts

func refresh_token_used():
	available_contracts.clear()
	available_contracts = create_available_contracts(50)

func create_mining_contract() -> Contract:
	var contract = Contract.new()
	contract.major_skill = Mining
	var skills_unlocked = []
	for skill in Mining.minor_processes:
		if skill.unlocked:
			skills_unlocked.append(skill)
	contract.minor_skill = skills_unlocked.pick_random()
	var lvl = Mining.SKILL.level
	contract.cost = int(lvl * randi_range(10, 15))
	contract.goal_amount = int(lvl * randi_range(10, 25))
	contract.goal_item = contract.minor_skill["resource gained"]
	contract.progress = 0
	contract.reward_exp = int(lvl * randi_range(40, 65))
	contract.reward_item = contract_reward_pool.pick_random()
	contract.reward_item_amount = int(lvl * randi_range(3, 8))
	contract.description = "Mine " + str(contract.goal_amount) + " " + contract.goal_item.name
	contract.active = false
	contract.available = true
	return contract

func create_parsing_contract() -> Contract:
	var contract = Contract.new()
	contract.major_skill = Parsing
	var skills_unlocked = []
	for skill in Parsing.minor_processes:
		if skill.unlocked:
			skills_unlocked.append(skill)
	contract.minor_skill = skills_unlocked.pick_random()
	var lvl = Parsing.SKILL.level
	contract.cost = int(lvl * randi_range(10, 15))
	contract.goal_amount = int(lvl * randi_range(10, 25))
	contract.goal_item = Items.LOGS
	contract.progress = 0
	contract.reward_exp = int(lvl * randi_range(40, 65))
	contract.reward_item = contract_reward_pool.pick_random()
	contract.reward_item_amount = int(lvl * randi_range(3, 8))
	contract.description = contract.minor_skill.name + " parse " + str(contract.goal_amount) + " " + contract.goal_item.name
	contract.active = false
	contract.available = true
	return contract

func create_cracking_contract() -> Contract:
	var contract = Contract.new()
	contract.major_skill = Cracking
	var skills_unlocked = []
	for skill in Cracking.minor_processes:
		if skill.unlocked:
			skills_unlocked.append(skill)
	contract.minor_skill = skills_unlocked.pick_random()
	var lvl = Cracking.SKILL.level
	contract.cost = int(lvl * randi_range(10, 15))
	contract.goal_amount = int(lvl * randi_range(10, 25))
	contract.goal_item = contract.minor_skill["resource gained"]
	contract.progress = 0
	contract.reward_exp = int(lvl * randi_range(40, 65))
	contract.reward_item = contract_reward_pool.pick_random()
	contract.reward_item_amount = int(lvl * randi_range(3, 8))
	contract.description = "Crack " + str(contract.goal_amount) + " " + contract.goal_item.name
	contract.active = false
	contract.available = true
	return contract

func create_matching_contract() -> Contract:
	var contract = Contract.new()
	contract.major_skill = Matching
	var skills_unlocked = []
	for skill in Matching.minor_processes:
		if skill.unlocked:
			skills_unlocked.append(skill)
	contract.minor_skill = skills_unlocked.pick_random()
	var lvl = Matching.SKILL.level
	contract.cost = int(lvl * randi_range(10, 15))
	contract.goal_amount = int(lvl * randi_range(10, 25))
	contract.goal_item = contract.minor_skill["resource gained"]
	contract.progress = 0
	contract.reward_exp = int(lvl * randi_range(40, 65))
	contract.reward_item = contract_reward_pool.pick_random()
	contract.reward_item_amount = int(lvl * randi_range(3, 8))
	contract.description = "Match " + str(contract.goal_amount) + " " + contract.goal_item.name
	contract.active = false
	contract.available = true
	return contract

func create_decoding_contract() -> Contract:
	var contract = Contract.new()
	contract.major_skill = Decoding
	var skills_unlocked = []
	for skill in Decoding.minor_processes:
		if skill.unlocked:
			skills_unlocked.append(skill)
	contract.minor_skill = skills_unlocked.pick_random()
	var lvl = Decoding.SKILL.level
	contract.cost = int(lvl * randi_range(10, 15))
	contract.goal_amount = int(lvl * randi_range(10, 25))
	#contract.goal_item = contract.minor_skill["resource gained"]
	contract.progress = 0
	contract.reward_exp = int(lvl * randi_range(40, 65))
	contract.reward_item = contract_reward_pool.pick_random()
	contract.reward_item_amount = int(lvl * randi_range(3, 8))
	contract.description = "Decode " + str(contract.goal_amount) + " caches"
	contract.active = false
	contract.available = true
	return contract

func create_phishing_contract() -> Contract:
	var contract = Contract.new()
	contract.major_skill = Phishing
	var skills_unlocked = []
	for skill in Phishing.minor_processes:
		if skill.unlocked:
			skills_unlocked.append(skill)
	contract.minor_skill = skills_unlocked.pick_random()
	var lvl = Phishing.SKILL.level
	contract.cost = int(lvl * randi_range(10, 15))
	contract.goal_amount = int(lvl * randi_range(10, 25))
	#contract.goal_item = contract.minor_skill["resource gained"]
	contract.progress = 0
	contract.reward_exp = int(lvl * randi_range(200, 400))
	contract.reward_item = contract_reward_pool.pick_random()
	contract.reward_item_amount = int(lvl * randi_range(5, 22))
	contract.description = contract.minor_skill.name + " phish " + str(contract.goal_amount) + " times"
	contract.active = false
	contract.available = true
	return contract

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
	if current_contracts.size() >= MAX_CONTRACTS:
		return "You own too many contracts, but this should have been checked earlier...oops"
	
	contract.active = true
	contract.available = false
	contract.connect_progress()
	current_contracts.append(contract)
	Signals.contract_added(contract)
	return "Contract purchased for " + str(contract.cost) + " Data"

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
		return_string += "+" + str(contract.reward_exp) + " exp, +" + str(contract.reward_item_amount) + " " + contract.reward_item.name + "\n\n"
		contract.contract_finished()
		current_contracts.erase(contract)
		
	return return_string

func can_add_contract() -> bool:
	if current_contracts.size() >= MAX_CONTRACTS:
		return false
	return true
