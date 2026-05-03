extends Node
#game info
#Idle game
#Skills (as seens in traditional idle games) = Modules

#important design rules for this game
#every process should do one of the following, and clearly
#Generate a resource
#Convert a resource
#Buffs other processes (short term or permenant)
#unlock new systems

#random ideas
#defrag disk: long process, everything is slow during it, but once done a perm speed bonus to everything

#Defining "Process"
#Pick one: Generate, Convert, Buff, Unlock

enum InventoryFilter { ALL, CACHES, VALUABLES, RESOURCES }
var inventory := {}

func _ready():
	for i in Items.ITEM_MAP:
		add_resource(Items.ITEM_MAP[i], 1)
	pass
	#add_resource(Items.DATA, 200)
	#add_resource(Items.LOGS, 2)
	#add_resource(Items.ENCRYPTED_PASSWORDS, 4)
	#add_resource(Items.PASSWORDS, 10)
	#add_resource(Items.USERNAMES, 10)
	#add_resource(Items.CREDENTIALS, 100)
	#add_resource(Items.IP_ADDRESS, 100)
	#add_resource(Items.ADMIN_CACHE, 2)
	#add_resource(Items.COP_CACHE, 1)
	#add_resource(Items.BODY_CAM_FOOTAGE_DELETION_LOGS, 2)
	

func get_amount(resource: ItemData) -> int:
	if inventory.has(resource):
		return inventory[resource]
	return 0

func add_resource(resource: ItemData, amount):
	if inventory.has(resource):
		inventory[resource] += amount
	else:
		inventory[resource] = amount

func remove_resource(resource: ItemData, amount: int) -> bool:
	if not inventory.has(resource):
		return false
	if inventory[resource] < amount:
		return false
	
	inventory[resource] -= amount
	
	if inventory[resource] <= 0:
		inventory.erase(resource)
	
	return true

func _matches_filter(resource, filter: InventoryFilter) -> bool:
	match filter:
		InventoryFilter.CACHES:
			return resource.name.contains("cache")
		InventoryFilter.VALUABLES:
			return resource.valuable
		InventoryFilter.RESOURCES:
			return !resource.valuable and !resource.name.contains("cache")
		_:
			return true

func list_inventory(filter: InventoryFilter = InventoryFilter.ALL) -> String:
	var amount_width = 15
	var output = ""
	var has_items := false

	var max_name_length = 0
	for resource in inventory.keys():
		if inventory[resource] > 0 and _matches_filter(resource, filter):
			if resource.name.length() > max_name_length:
				max_name_length = resource.name.length()

	var name_width = max_name_length + 4

	output += pad_text("Items", name_width)
	output += pad_text("Amount", amount_width)
	output += "Description\n"
	output += pad_text("--------", name_width)
	output += pad_text("------", amount_width)
	output += "-----------\n"

	for resource in inventory.keys():
		if _matches_filter(resource, filter):
			var amount: int = inventory[resource]
			if amount > 0:
				has_items = true
				output += pad_text(resource.name, name_width)
				output += pad_text(amount, amount_width)
				output += resource.description + "\n"

	if not has_items:
		return "You have no items."
	return output

func pad_text(value, width: int) -> String:
	var text := str(value)
	if text.length() >= width:
		return text.substr(0, width)
	return text + " ".repeat(width - text.length())

# Resources:
# Data  - main currency resource
# Encrypted passwords - must use password unscramble module to have usable passwords (weak, medium, strong, impossible)
# Logs - Purchased from dark web - must run process on logs to randomly get scrambled passwords and usernames, rarely IP addresses (Basic, intermediate, advanced)
# Usernames - Used in tandem with unscrambled passwords for credentials
# Ip Address - Needed to find hack targets. Will be consumed after hacking attempt. (Common, Uncommon, Rare)
# Credentials - Refine usernames and passwords to match, credentials are used with IP addresses for beginning a hack
# Cache - obtained from successful hacks. Run process to break down what is in this (data, pw, logs, username, creds, ip address, logs)

# Random Items: Valuables only to be sold for data ie Report cards (School), Criminal records (Police), P/L sheet (business) etc

#Processes:
# Data gathering - generates data with a simple progress bar
# Password unscrambling - uses scrambled passwords and generates usable passwords
# Log decrypting - Consumes logs into a random resource of similar quality (passwords, usernames, ip address, credentials)
# (Authentication Module)Credential matching - consumes passwords + usernames to create a credential
# Hacking - "combat" mechanic - consumes IP address and credentials, generates Cache
# Cache decrypting - Consumes cache for random items (data, logs, usernames, ip address, credentials, random items)
# Black market / marketplace - buy & sell <- black market should be given to player through tutorial. Will show how to install a modules.

# Upgrades:
# Effeciency - Used instead of levels in traditional idle games. Level 1-99. Increases speed of process. Possible chance of free additional resources.
# Access token (level 1): Used to show what's available in dark web, upgrading the token gives access to better items

# Marketplace:
# Logs
# Modules

#Hacking:
# Should be a versus : player vs target
# using a credential wears down targets 'health'

# Run hacking module
# Search for target using IP addresses
# Choose from list of targets, consume credentials to get in
# Start hacking mini game(s)
# Once finished, gain Cache.


#Game Implementation
# Step 1 - get core loop done from getting data, to finishing a hack and opening a cache/selling valuables
# Finish all modules: Password unscramble, credential matching, cache decrypting, dark web (only accessible after hacking lvl high enough)
# Hacking mini game
# decrypt cache
# allow selling of stuff to marketplace


# Step 2 
# add save/load system
# add settings
# add offline progression

# Step 3
# add module upgrades/installations
# add prestige/restart functionality

# Step 4 
# Playtesters / feedback
# Work on steam page 
