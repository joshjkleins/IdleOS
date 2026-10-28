extends Node

signal cred_cycle_completed
signal account_cycle_completed
signal xp_gained
signal matching_level_up_signal

# When the player earns the bonus
var bonus_expires_at: int
var vm_token = Items.VM_MATCHING_TOKEN
@onready var MAX_VMS = 7
@onready var VM_UPTIME = 60.0
var CURRENT_VMS = 0

## Modifier commands unlocked by Matching capstones (see Mining.MODIFIERS for how they work).
const MODIFIERS = [
	{"command": "prebuild", "name": "Prebuild", "package": "matching.prebuild", "speed": 0.5, "heat": 1.5,
		"effect": "-50% speed, heat x1.5. Each match has a 5% chance to also produce the tier's payload."},
	{"command": "correlate", "name": "Correlate", "package": "matching.correlate", "speed": 0.6, "heat": 2.0,
		"effect": "-40% speed, heat x2. Efficiency x2 and VM token chance x2."},
	{"command": "survey", "name": "Survey", "package": "matching.survey", "speed": 1.0, "heat": 1.0,
		"effect": "Half output, +100% Matching XP."},
]
const PREBUILD_CHANCE := 0.05
## Hot Cache: +1% speed per consecutive match, up to the installed cap
const HOT_CACHE_STEP := 0.01
## Cold Storage: overclock and the modifiers add no extra heat
const COOL_PACKAGE := "matching.cold_storage"

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
	"experience per level": 47, # xp per match
	"command": "match -cred",
	"efficiency": 0.0,
	"efficiency rate": 0.002,
	"unlocked": true,
	"unlock tier": 1, # 2026-10-26: opens with this tier's location (1 = from the start)
	"efficiency level": 1, # efficiency grows from this skill level (its old unlock level)
	"base speed min": 0.1407, # seconds per terminal message (24 per match)
	"base speed max": 0.844,
	"overclock speed min": 0.0703,
	"overclock speed max": 0.422,
	"overheat speed": 1.2308,
	"heat": 1.5072,
	"overclock heat": 1.6955,
	"overheat heat": 0.1884,
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
	"experience per level": 163, # xp per match
	"command": "match -cert",
	"efficiency": 0.0,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock tier": 2, # 2026-10-26: opens with this tier's location (1 = from the start)
	"efficiency level": 15, # efficiency grows from this skill level (its old unlock level)
	"base speed min": 0.3158, # seconds per terminal message (24 per match)
	"base speed max": 1.8951,
	"overclock speed min": 0.1579,
	"overclock speed max": 0.9475,
	"overheat speed": 2.7637,
	"heat": 4.107,
	"overclock heat": 4.6204,
	"overheat heat": 0.5134,
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
	"experience per level": 464, # xp per match
	"command": "match -badge",
	"efficiency": 0.0,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock tier": 3, # 2026-10-26: opens with this tier's location (1 = from the start)
	"efficiency level": 30, # efficiency grows from this skill level (its old unlock level)
	"base speed min": 0.6963, # seconds per terminal message (24 per match)
	"base speed max": 4.1777,
	"overclock speed min": 0.3481,
	"overclock speed max": 2.0889,
	"overheat speed": 6.0933,
	"heat": 11.501,
	"overclock heat": 12.9493,
	"overheat heat": 1.4269,
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
	"experience per level": 1191, # xp per match
	"command": "match -account",
	"efficiency": 0.0,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock tier": 4, # 2026-10-26: opens with this tier's location (1 = from the start)
	"efficiency level": 45, # efficiency grows from this skill level (its old unlock level)
	"base speed min": 1.5164, # seconds per terminal message (24 per match)
	"base speed max": 9.0986,
	"overclock speed min": 0.7593,
	"overclock speed max": 4.5493,
	"overheat speed": 13.2683,
	"heat": 30.5282,
	"overclock heat": 34.3348,
	"overheat heat": 3.8066,
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
	"experience per level": 2888, # xp per match
	"command": "match -officer",
	"efficiency": 0.0,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock tier": 5, # 2026-10-26: opens with this tier's location (1 = from the start)
	"efficiency level": 60, # efficiency grows from this skill level (its old unlock level)
	"base speed min": 3.3022, # seconds per terminal message (24 per match)
	"base speed max": 19.8228,
	"overclock speed min": 1.6511,
	"overclock speed max": 9.913,
	"overheat speed": 28.9071,
	"heat": 126.1453,
	"overclock heat": 141.9265,
	"overheat heat": 15.7813,
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
	"experience per level": 6773, # xp per match
	"command": "match -clearance",
	"efficiency": 0.0,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock tier": 6, # 2026-10-26: opens with this tier's location (1 = from the start)
	"efficiency level": 75, # efficiency grows from this skill level (its old unlock level)
	"base speed min": 7.2963, # seconds per terminal message (24 per match)
	"base speed max": 43.7681,
	"overclock speed min": 3.6457,
	"overclock speed max": 21.884,
	"overheat speed": 63.8316,
	"heat": 315.5657,
	"overclock heat": 355.055,
	"overheat heat": 39.4892,
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
	# (legacy "<process>_efficiency" is ignored: efficiency is rebuilt from level in Exp.processes_load_data)
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
