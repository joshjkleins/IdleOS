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


var inventory := {
	"data": {
		"amount": 100,
		"description": "Raw encrypted data used as marketplace currency"
	},
	"encrypted passwords": {
		"amount": 50,
		"description": "Encrypted passwords that need cracking"
	},
	"passwords": {
		"amount": 20,
		"description": "Decrypted passwords used for account breaches"
	},
	"usernames": {
		"amount": 20,
		"description": "Usernames can be combined with an unscrambled password to make a credential"
	},
	"credentials": {
		"amount": 0,
		"description": "A combined username and password used to attempt hacks"
	},
	"ip address": {
		"amount": 0,
		"description": "IP address used to find hacking target"
	},
	"logs": {
		"amount": 100,
		"description": "Encrypted log files that can be processed for resources"
	}
}

func get_amount(resource: String) -> int:
	if inventory.has(resource):
		return inventory[resource]["amount"]
	return 0


func add_resource(resource: String, amount: int) -> void:
	if inventory.has(resource):
		inventory[resource]["amount"] += amount


func remove_resource(resource: String, amount: int) -> bool:
	if not inventory.has(resource):
		return false
	
	if inventory[resource]["amount"] < amount:
		return false
	
	inventory[resource]["amount"] -= amount
	return true

func list_inventory_items() -> String:
	var name_width = 25
	var amount_width = 15
	
	var output = ""
	var has_items := false
	
	output += pad_text("Resource", name_width)
	output += pad_text("Amount", amount_width)
	output += "Description\n"
	
	output += pad_text("--------", name_width)
	output += pad_text("------", amount_width)
	output += "-----------\n"
	
	for resource in inventory.keys():
		var data = inventory[resource]
		var amount = data["amount"]
		
		if amount > 0:
			has_items = true
			output += pad_text(resource.capitalize(), name_width)
			output += pad_text(amount, amount_width)
			output += data["description"] + "\n"
	
	if not has_items:
		return "You have no resources."
	
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
