extends Node

signal cred_cycle_completed
signal account_cycle_completed
signal xp_gained
signal matching_level_up_signal

# When the player earns the bonus
var bonus_expires_at: int
var vm_token = Items.VM_MATCHING_TOKEN
@onready var MAX_VMS = 7
@onready var VM_UPTIME = 30.0
var CURRENT_VMS = 0

var terminal_scene = preload("res://scenes/cred_matching_terminal.tscn")

#GENERAL MODULE DATA
var SKILL = {
	"name": "Matching",
	"level": 1,
	"experience": 0,
	"color": Color("#EAB308"),
	"level up signal": matching_level_up_signal,
	"efficiency description": "Chance to make multiple resources.",
	"command": "cd matching",
	"sfx": "matching_item_received"
}

## Tiers follow the hacking locations: School > Lawfirm > Hospital > Bank > Police > Government.
## Each match pairs that tier's identifier (Parsing) with its cracked item (Cracking).
## Pacing follows Mining: each tier matches 1.5x slower, tuned for +50% matching speed per tier from upgrades.
var CREDENTIAL = {
	"name": "Credential",
	"tier name": "TIER I | CREDENTIAL",
	"level": 1,
	"experience": 0,
	"experience per level": 67, # xp per match
	"command": "match -cred",
	"efficiency": 0.0,
	"efficiency rate": 0.002,
	"unlocked": true,
	"unlock level": 1,
	"base speed min": 0.2, # seconds per terminal message (24 per match)
	"base speed max": 1.2,
	"overclock speed min": 0.1,
	"overclock speed max": 0.6,
	"overheat speed": 1.75,
	"heat": 2.4,
	"overclock heat": 2.7,
	"overheat heat": 0.3,
	"vm token chance": 0.01, # per match; scales with match length so tokens/hour stay level
	"requirements": {
		Items.USERNAMES: 1,
		Items.PASSWORDS: 1
	},
	"resource gained": Items.CREDENTIALS,
	"resource amount gained": 1,
	"match theme": "credential", # terminal tags/messages, see cred_matching_terminal.gd THEMES
	"description": "Matches usernames to cracked passwords, creating credentials.",
	"efficiency description": "Chance to assemble extra.",
	"signal": cred_cycle_completed
}

var CERTIFICATE = {
	"name": "Certificate",
	"tier name": "TIER II | CERTIFICATE",
	"level": 1,
	"experience": 0,
	"experience per level": 155, # xp per match
	"command": "match -cert",
	"efficiency": 0.0,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock level": 15,
	"base speed min": 0.3, # seconds per terminal message (24 per match)
	"base speed max": 1.8,
	"overclock speed min": 0.15,
	"overclock speed max": 0.9,
	"overheat speed": 2.625,
	"heat": 3.6,
	"overclock heat": 4.05,
	"overheat heat": 0.45,
	"vm token chance": 0.015, # per match; scales with match length so tokens/hour stay level
	"requirements": {
		Items.CASE_NUMBER: 1,
		Items.DIGITAL_SIGNATURE: 1
	},
	"resource gained": Items.SIGNED_CERTIFICATE,
	"resource amount gained": 1,
	"match theme": "certificate", # terminal tags/messages, see cred_matching_terminal.gd THEMES
	"description": "Binds a digital signature to a case number, forging a signed certificate.",
	"efficiency description": "Chance to assemble extra.",
	"signal": cred_cycle_completed
}

var BADGE = {
	"name": "Badge",
	"tier name": "TIER III | BADGE",
	"level": 1,
	"experience": 0,
	"experience per level": 300, # xp per match
	"command": "match -badge",
	"efficiency": 0.0,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock level": 30,
	"base speed min": 0.45, # seconds per terminal message (24 per match)
	"base speed max": 2.7,
	"overclock speed min": 0.225,
	"overclock speed max": 1.35,
	"overheat speed": 3.938,
	"heat": 5.4,
	"overclock heat": 6.08,
	"overheat heat": 0.67,
	"vm token chance": 0.0225, # per match; scales with match length so tokens/hour stay level
	"requirements": {
		Items.STAFF_IDS: 1,
		Items.BADGE_HASH: 1
	},
	"resource gained": Items.ACCESS_BADGE,
	"resource amount gained": 1,
	"match theme": "badge", # terminal tags/messages, see cred_matching_terminal.gd THEMES
	"description": "Pairs a staff ID with its cracked badge hash, provisioning an access badge.",
	"efficiency description": "Chance to assemble extra.",
	"signal": cred_cycle_completed
}

var ACCOUNT = {
	"name": "Account",
	"tier name": "TIER IV | ACCOUNT",
	"level": 1,
	"experience": 0,
	"experience per level": 530, # xp per match
	"command": "match -account",
	"efficiency": 0.0,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock level": 45,
	"base speed min": 0.675, # seconds per terminal message (24 per match)
	"base speed max": 4.05,
	"overclock speed min": 0.338,
	"overclock speed max": 2.025,
	"overheat speed": 5.906,
	"heat": 8.1,
	"overclock heat": 9.11,
	"overheat heat": 1.01,
	"vm token chance": 0.0338, # per match; scales with match length so tokens/hour stay level
	"requirements": {
		Items.ACCOUNT_NUMBERS: 1,
		Items.PINS: 1
	},
	"resource gained": Items.ACCOUNT_ACCESS_TOKENS,
	"resource amount gained": 1,
	"match theme": "account", # terminal tags/messages, see cred_matching_terminal.gd THEMES
	"description": "Pairs an account number with its cracked PIN, minting account access tokens.",
	"efficiency description": "Chance to assemble extra.",
	"signal": cred_cycle_completed
}

var OFFICER = {
	"name": "Officer",
	"tier name": "TIER V | OFFICER",
	"level": 1,
	"experience": 0,
	"experience per level": 885, # xp per match
	"command": "match -officer",
	"efficiency": 0.0,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock level": 60,
	"base speed min": 1.012, # seconds per terminal message (24 per match)
	"base speed max": 6.075,
	"overclock speed min": 0.506,
	"overclock speed max": 3.038,
	"overheat speed": 8.859,
	"heat": 12.15,
	"overclock heat": 13.67,
	"overheat heat": 1.52,
	"vm token chance": 0.0506, # per match; scales with match length so tokens/hour stay level
	"requirements": {
		Items.BADGE_NUMBER: 1,
		Items.PRIVATE_KEYS: 1
	},
	"resource gained": Items.OFFICER_AUTH_KEYS,
	"resource amount gained": 1,
	"match theme": "officer", # terminal tags/messages, see cred_matching_terminal.gd THEMES
	"description": "Binds a private key to an officer badge number, creating officer auth keys.",
	"efficiency description": "Chance to assemble extra.",
	"signal": cred_cycle_completed
}

var CLEARANCE = {
	"name": "Clearance",
	"tier name": "TIER VI | CLEARANCE",
	"level": 1,
	"experience": 0,
	"experience per level": 1410, # xp per match
	"command": "match -clearance",
	"efficiency": 0.0,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock level": 75,
	"base speed min": 1.519, # seconds per terminal message (24 per match)
	"base speed max": 9.112,
	"overclock speed min": 0.759,
	"overclock speed max": 4.556,
	"overheat speed": 13.289,
	"heat": 18.22,
	"overclock heat": 20.5,
	"overheat heat": 2.28,
	"vm token chance": 0.0759, # per match; scales with match length so tokens/hour stay level
	"requirements": {
		Items.CLEARANCE_ID: 1,
		Items.BIO_TEMPLATE: 1
	},
	"resource gained": Items.SECURITY_CLEARANCE,
	"resource amount gained": 1,
	"match theme": "clearance", # terminal tags/messages, see cred_matching_terminal.gd THEMES
	"description": "Binds a biometric template to a clearance ID, granting security clearance.",
	"efficiency description": "Chance to assemble extra.",
	"signal": cred_cycle_completed
}

var minor_processes = [
	CREDENTIAL,
	CERTIFICATE,
	BADGE,
	ACCOUNT,
	OFFICER,
	CLEARANCE,
]

func signal_exp(_amount: int):
	xp_gained.emit()
	SaveManager.mark_dirty()

#var process_upgrades = {
	#"speed": { "id": 1, "name": "Speed", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	#"efficiency": { "id": 2, "name": "Efficiency", "level": 0, "amount": 0.0, "increase per level": 0.15 },
	#"experience": { "id": 3, "name": "Experience", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	#"offline": { "id": 4, "name": "Offline progression", "level": 0, "amount": 0, "increase per level": 60 },
	#"vm windows": { "id": 5, "name": "VM Windows", "level": 0, "amount": 1, "increase per level": 1 },
	#"vm duration": { "id": 6, "name": "VM Duration", "level": 0, "amount": 30.0, "increase per level": 30.0 },
#}
#
#func get_upgrade_cost(upgrade_stat: String) -> int:
	#return process_upgrades[upgrade_stat]["level"] * 800 + 100
#
#func upgraded(upgrade_stat: Dictionary):
	#upgrade_stat["level"] += 1
	#upgrade_stat["amount"] += upgrade_stat["increase per level"]
	#
	#if upgrade_stat["name"].to_lower() == "vm windows":
		#MAX_VMS += upgrade_stat["increase per level"]
	#if upgrade_stat["name"].to_lower() == "vm duration":
		#VM_UPTIME += upgrade_stat["increase per level"]

func has_requirements(minor_process) -> bool:
	for item in minor_process["requirements"]:
		if Inventory.get_amount(item) <= 0:
			return false
	return true

func missing_requirements_text(minor_process) -> String:
	var return_text = "Missing:"
	for item in minor_process["requirements"]:
		if Inventory.get_amount(item) <= 0:
			return_text += " " + item.name
	
	return return_text

func create_vm_window(minor_process, repeat) -> VMWindow:
	var setup = func(t):
		t.set_type(minor_process, true)
		t.start()
	return VMManager.open(self, minor_process, terminal_scene.instantiate(), setup, repeat)


func save_data() -> Dictionary:
	return {
		"processes": Exp.processes_save_data(self),
		"bonus_expires_at": bonus_expires_at,
		"skill_level": SKILL["level"],
		"skill_experience": SKILL["experience"],
		"credential_level": CREDENTIAL["level"],
		"credential_experience": CREDENTIAL["experience"],
		"credential_efficiency": CREDENTIAL["efficiency"]
	}

func load_data(data: Dictionary) -> void:
	bonus_expires_at = int(data.get("bonus_expires_at", bonus_expires_at))
	SKILL["level"] = int(data.get("skill_level", SKILL["level"]))
	SKILL["experience"] = int(data.get("skill_experience", SKILL["experience"]))
	CREDENTIAL["level"] = int(data.get("credential_level", CREDENTIAL["level"]))
	CREDENTIAL["experience"] = int(data.get("credential_experience", CREDENTIAL["experience"]))
	CREDENTIAL["efficiency"] = float(data.get("credential_efficiency", CREDENTIAL["efficiency"]))
	Exp.processes_load_data(self, data.get("processes", {})) # all processes (legacy keys above cover old saves)

const RANDOM_USERNAMES := [
	"byteRunner77",
	"neonTiger",
	"silentProxy",
	"darkKernel",
	"pixelRaider",
	"ghostCipher",
	"ironSpectre",
	"lunarSyntax",
	"zeroDayFox",
	"voidCrawler",
	"turboHydra",
	"omegaPulse",
	"echoVector",
	"rapidDelta",
	"nightAssembler",
	"hexCrawler",
	"frostByte",
	"alphaCircuit",
	"gammaNode",
	"dataMantis",
	"vortexDrive",
	"silentCrate",
	"quantumPixel",
	"binaryLancer",
	"crimsonPacket",
	"shadowSocket",
	"omegaClaw",
	"nightSignal",
	"ravenUpload",
	"staticHunter",
	"deltaMachine",
	"hyperBreach",
	"nanoRunner",
	"vaporKernel",
	"electricNomad",
	"stormCache",
	"glitchNova",
	"radarGhost",
	"iceProtocol",
	"pixelNomad",
	"lunarSignal",
	"vectorShadow",
	"solarRogue",
	"rapidSocket",
	"bytePirate",
	"frozenRoot",
	"turboHex",
	"crashOverride",
	"steelCrawler",
	"silentOverflow",
	"toxicMatrix",
	"omegaTrace",
	"voidHunter",
	"quantumEcho",
	"cyberAnchor",
	"blackoutNode",
	"phantomByte",
	"novaSignal",
	"darkPacket",
	"hexRaider",
	"pixelDrifter",
	"cyberNova",
	"binaryFang",
	"terminalGhost",
	"echoCrawler",
	"nightPulse",
	"lunarNode",
	"staticCipher",
	"rapidHex",
	"stormRunner",
	"hyperThread",
	"crimsonRoot",
	"shadowOverride",
	"voidPacket",
	"alphaMantis",
	"vaporSignal",
	"gammaGhost",
	"electricFox",
	"zeroSpectre",
	"silentThread",
	"turboTrace",
	"pixelPulse",
	"quantumSocket",
	"binaryDrifter",
	"novaKernel",
	"omegaRoot",
	"stormHex",
	"darkSyntax",
	"ravenCipher",
	"nightSocket",
	"frostSignal",
	"vectorHydra",
	"phantomProxy",
	"cyberMantis",
	"dataNomad",
	"rapidCrawler",
	"blackoutPulse",
	"shadowKernel",
	"electricPacket",
	"silentRogue",
	"voidTrace",
	"omegaByte",
	"hyperGhost",
	"vaporFox",
	"crimsonHex",
	"novaDrive",
	"ghostThread",
	"staticRaider",
	"binaryPulse",
	"echoSocket",
	"frozenCipher",
	"nightKernel",
	"pixelHunter",
	"stormProxy",
	"darkRoot",
	"quantumTrace",
	"vectorSignal",
	"alphaPacket",
	"cyberDrive",
	"silentMantis",
	"lunarHex",
	"rapidGhost",
	"turboCipher",
	"vaporNode",
	"shadowFox",
	"zeroRunner",
	"blackoutCrawler",
	"novaByte",
	"ghostSocket",
	"frostOverride",
	"binaryTrace",
	"nightRaider",
	"electricSignal",
	"echoHydra",
	"stormDrifter",
	"pixelKernel",
	"crimsonProxy",
	"staticThread",
	"voidCipher",
	"hyperPulse",
	"alphaFox",
	"quantumRunner",
	"cyberSocket",
	"shadowSignal",
	"vaporHex",
	"novaMantis",
	"darkPacket77",
	"silentNova",
	"lunarCipher",
	"frozenDrive",
	"rapidByte",
	"turboGhost",
	"stormSocket",
	"binaryNomad",
	"omegaCrawler",
	"nightTrace",
	"pixelOverride",
	"vectorRaider",
	"electricKernel",
	"echoPacket",
	"cyberRoot",
	"blackoutFox",
	"crimsonSignal",
	"voidHydra",
	"ghostProxy",
	"alphaTrace",
	"staticNomad",
	"hyperByte",
	"shadowPulse",
	"frostSocket",
	"novaHex",
	"binaryHunter",
	"rapidKernel",
	"silentPacket",
	"vaporThread",
	"darkCrawler",
	"turboRunner",
	"nightCipher",
	"pixelFox",
	"vectorDrive",
	"echoGhost",
	"stormOverride",
	"quantumKernel",
	"cyberRaider",
	"zeroSignal",
	"shadowTrace",
	"alphaSocket",
	"ghostByte",
	"binaryHydra",
	"staticRunner",
	"omegaSignal",
	"novaThread",
	"rapidPulse",
	"silentFox",
	"lunarRoot",
	"frostKernel",
	"hyperNomad",
	"darkSocket",
	"stormByte",
	"pixelCipher",
	"cyberGhost",
	"vectorPacket",
	"voidSignal",
	"turboRoot",
	"electricTrace",
	"echoRunner",
	"binarySocket",
	"novaProxy",
	"shadowKernelX",
	"nightHydra",
	"rapidSignal",
	"silentTrace",
	"frostPulse",
	"vaporRaider",
	"ghostNomad",
	"crimsonSocket",
	"omegaThread",
	"pixelByte",
	"stormCrawler",
	"darkProxy",
	"quantumSignal",
	"alphaGhost",
	"hyperRoot",
	"binaryCipher",
	"vectorPulse",
	"cyberThread",
	"zeroKernel",
	"electricSocket",
	"silentHydra",
	"novaSignalX",
	"voidRunner",
	"pixelTrace",
	"nightProxy",
	"frostNomad",
	"shadowByte",
	"echoSignal",
	"stormGhost",
	"rapidThread",
	"turboPacket",
	"cyberCipher",
	"binaryRoot",
	"omegaRunner",
	"vectorKernel",
	"lunarTrace",
	"ghostSignal",
	"hyperSocket",
	"darkHydra",
	"silentKernel",
	"novaPacket",
	"pixelRunner",
	"frozenSignal",
	"alphaOverride",
	"cyberPulse",
	"shadowNomad",
	"rapidSocketX",
	"stormKernelX",
	"voidGhost",
	"electricByte"
]
