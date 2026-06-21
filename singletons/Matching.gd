extends Node

signal cred_cycle_completed
signal account_cycle_completed
signal xp_gained
signal matching_level_up_signal

# When the player earns the bonus
var bonus_expires_at: int
var vm_token = Items.VM_MATCHING_TOKEN
@onready var MAX_VMS = process_upgrades["vm windows"]["amount"]
@onready var VM_UPTIME = process_upgrades["vm duration"]["amount"]
var CURRENT_VMS = 0

var terminal_scene = preload("res://scenes/cred_matching_terminal.tscn")
var vm_window = preload("res://scenes/vm_window.tscn")

#GENERAL MODULE DATA
var SKILL = {
	"name": "Matching",
	"level": 1,
	"experience": 0,
	"color": Color("#D4537E"),
	"level up signal": matching_level_up_signal,
	"efficiency description": "Chance to make multiple resources.",
}

var CREDENTIAL = {
	"name": "Credential",
	"tier name": "TIER I | CREDENTIAL",
	"level": 1,
	"experience": 0,
	"experience per level": 900,
	"command": "data-mining",
	"efficiency": 0.0,
	"efficiency rate": 0.002,
	"unlocked": true,
	"unlock level": 1,
	"base speed min": 0.2,
	"base speed max": 1.2,
	"overclock speed min": 0.1,
	"overclock speed max": 0.2,
	"overheat speed": 3.0,
	"heat": 1,
	"overclock heat": 1,
	"overheat heat": 1,
	"requirements": [Items.USERNAMES, Items.PASSWORDS],
	"resource gained": Items.CREDENTIALS,
	"resource amount gained": 1,
	"description": "Creates credentials using passwords & usernames.",
	"efficiency description": "Chance to not consume a username or password.",
	"signal": cred_cycle_completed
}

var ACCOUNT = {
	"name": "Account",
	"tier name": "TIER I | ACCOUNT",
	"level": 1,
	"experience": 0,
	"experience per level": 900,
	"command": "data-mining",
	"efficiency": 0.0,
	"efficiency rate": 0.002,
	"unlocked": false,
	"unlock level": 25,
	"base speed min": 0.3,
	"base speed max": 1.3,
	"overclock speed min": 0.2,
	"overclock speed max": 0.4,
	"overheat speed": 3.0,
	"heat": 1,
	"overclock heat": 1,
	"overheat heat": 1,
	"requirements": [Items.PINS, Items.ACCOUNT_NUMBERS],
	"resource gained": Items.ACCOUNT_ACCESS_TOKENS,
	"resource amount gained": 1,
	"description": "Creates account access token using PINs & Account numbers.",
	"efficiency description": "Chance to not consume a PIN or Account number.",
	"signal": account_cycle_completed
}

var minor_processes = [
	CREDENTIAL,
	ACCOUNT
]

func signal_exp(_amount: int):
	xp_gained.emit()

var process_upgrades = {
	"speed": { "id": 1, "name": "Speed", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	"efficiency": { "id": 2, "name": "Efficiency", "level": 0, "amount": 0.0, "increase per level": 0.15 },
	"experience": { "id": 3, "name": "Experience", "level": 0, "amount": 1.0, "increase per level": 0.05 },
	"offline": { "id": 4, "name": "Offline progression", "level": 0, "amount": 0, "increase per level": 60 },
	"vm windows": { "id": 5, "name": "VM Windows", "level": 0, "amount": 1, "increase per level": 1 },
	"vm duration": { "id": 6, "name": "VM Duration", "level": 0, "amount": 30.0, "increase per level": 30.0 },
}

func get_upgrade_cost(upgrade_stat: String) -> int:
	return process_upgrades[upgrade_stat]["level"] * 800 + 100

func upgraded(upgrade_stat: Dictionary):
	upgrade_stat["level"] += 1
	upgrade_stat["amount"] += upgrade_stat["increase per level"]
	
	if upgrade_stat["name"].to_lower() == "vm windows":
		MAX_VMS += upgrade_stat["increase per level"]
	if upgrade_stat["name"].to_lower() == "vm duration":
		VM_UPTIME += upgrade_stat["increase per level"]

func has_requirements(minor_process) -> bool:
	for item in minor_process["requirements"]:
		if Inventory.get_amount(item) > 0:
			return true
	return false

func missing_requirements_text(minor_process) -> String:
	var return_text = "Missing:"
	for item in minor_process["requirements"]:
		if Inventory.get_amount(item) <= 0:
			return_text += " " + item.name
	
	return return_text

func create_vm_window(minor_process, repeat) -> Window:
	var content_instance = terminal_scene.instantiate()
	var new_window = vm_window.instantiate()
	new_window.title = SKILL.name + " | " + minor_process.name + " | Tokens used: " + str(1)
	new_window.wrap_controls = true
	new_window.repeat = repeat
	
	new_window.set_repeat(repeat)
	new_window.set_time(VM_UPTIME)
	new_window.set_token(vm_token)
	new_window.set_processes(Matching, minor_process)
	
	new_window.add_child(content_instance)
	
	new_window.size = content_instance.size
	new_window.min_size = content_instance.size
	
	new_window.close_requested.connect(func(): 
		CURRENT_VMS -= 1
		new_window.queue_free()
	)
	new_window.about_to_popup.connect(func(): 
		content_instance.set_type(minor_process, true)
		content_instance.start()
	)
	CURRENT_VMS += 1
	return new_window


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
