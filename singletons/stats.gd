extends Node

signal unlocks_changed # target / location unlocked, or a win recorded

signal gained_xp_signal

const MAX_LEVEL = 99 # keep in sync with Exp.MAX_LEVEL (legacy helpers below; Exp owns leveling)

var MAX_TEMP = 100.0
var MIN_TEMP = 30.0
var system_tempature = 30.0
var cooling_amount = -0.2 # base cooling per tick (Upgrades.BASE_COOLING sets it)
var cooling_frequency = 1.0 #in seconds
var overheated = false
var overclocked = false
var CURRENT_ALL_VMS: int = 0
var MAX_ALL_VMS: int = 0
var HEAT_REDUCTION: float = 0.0
var OVERHEAT_FAN: bool = false
const WATCHDOG_TEMP := 90.0

#hacking
var current_anon: int = 100
var max_anon: int = 100
var healing_threshold_auto_start: float = 0.3

var hacking_targets = {
	"School": {
		"command": "view school",
		"hard mode command": "view school -hard",
		"name": "School",
		"unlocked": true,
		"hard mode unlocked": true,
		"difficulty": "Easy",
		"required payload": Items.SCHOOL_PAYLOAD,
		"targets": [
			{
				"name": "Student",
				"difficulty": "Easy",
				"unlocked": true,
				"command": "hack student",
				"requirements": { "item": Items.SCHOOL_PAYLOAD, "amount": 1 },
				"heat": 0.5,
				"exp": 45,
				"integrity": 88,
				"firewall": 11,
				"counter": 7,
				"counter speed": 16.0,
				"firewall reboot": 10.0, # seconds the firewall stays down after a break
				"loot": Items.STUDENT_CACHE
			},
			{
				"name": "Administrator",
				"difficulty": "Easy",
				"unlocked": true,
				"command": "hack administrator",
				"requirements": {"item": Items.SCHOOL_PAYLOAD, "amount": 2},
				"heat": 0.8,
				"exp": 500,
				"integrity": 260,
				"firewall": 13,
				"counter": 5,
				"counter speed": 16.0,
				"firewall reboot": 8.0, # seconds the firewall stays down after a break
				"loot": Items.ADMIN_CACHE
			},
			{
				"name": "Vice Principal",
				"difficulty": "Medium",
				"unlocked": true,
				"command": "hack vice-principal",
				"requirements": { "item": Items.SCHOOL_PAYLOAD, "amount": 3 },
				"heat": 1.1,
				"exp": 753,
				"integrity": 301,
				"firewall": 22,
				"counter": 6,
				"counter speed": 16.0,
				"firewall reboot": 14.0, # seconds the firewall stays down after a break
				"loot": Items.VICE_PRINCIPAL_CACHE
			},
			{
				"name": "Principal",
				"difficulty": "Medium",
				"unlocked": true,
				"command": "hack principal",
				"requirements": {"item": Items.SCHOOL_PAYLOAD, "amount": 4},
				"heat": 1.4,
				"exp": 1005,
				"integrity": 348,
				"firewall": 16,
				"counter": 6,
				"counter speed": 30.0,
				"firewall reboot": 6.0, # seconds the firewall stays down after a break
				"loot": Items.PRINCIPAL_CACHE
			},
			{
				"name": "Superintendent",
				"difficulty": "Hard",
				"unlocked": true,
				"command": "hack superintendent",
				"requirements": {"item": Items.SCHOOL_PAYLOAD, "amount": 5},
				"heat": 1.7,
				"exp": 1252,
				"integrity": 445,
				"firewall": 18,
				"counter": 8,
				"counter speed": 20.0,
				"firewall reboot": 10.0, # seconds the firewall stays down after a break
				"loot": Items.SUPERINTENDENT_CACHE
			}
		],
		"hard mode targets": [
			{ #generally hard - requires 2 mods to beat (hopefully) and manually spoof and overclock management
				"special": "Tough all-rounder: expect to need 2 Hacking Mods, manual Packet Spoofs and careful overclock management.",
				"name": "Student (Hard)",
				"difficulty": "Hard",
				"unlocked": true,
				"command": "hack student",
				"requirements": { "item": Items.SCHOOL_PAYLOAD, "amount": 15 },
				"heat": 0.5,
				"exp": 4500,
				"integrity": 500,
				"firewall": 80,
				"counter": 20,
				"counter speed": 50.0,
				"loot": Items.STUDENT_CACHE,
				"loot quantity": 50,
			},
			{ #insane amount of integrity, needs speed + dmg
				"special": "Massive integrity. Bring attack speed and damage.",
				"name": "Administrator",
				"difficulty": "Hard",
				"unlocked": true,
				"command": "hack administrator",
				"requirements": {"item": Items.SCHOOL_PAYLOAD, "amount": 20},
				"heat": 0.9,
				"exp": 1200,
				"integrity": 3000,
				"firewall": 0,
				"counter": 7,
				"counter speed": 30.0,
				"loot": Items.ADMIN_CACHE,
				"loot quantity": 50,
			},
			{ #huge firewall, needs firewall reduction + damage
				"special": "Huge firewall. Bring firewall reduction and damage.",
				"name": "Vice Principal",
				"difficulty": "Hard",
				"unlocked": true,
				"command": "hack vice-principal",
				"requirements": { "item": Items.SCHOOL_PAYLOAD, "amount": 25 },
				"heat": 1.0,
				"exp": 1800,
				"integrity": 10,
				"firewall": 5000,
				"counter": 12,
				"counter speed": 15.0,
				"loot": Items.VICE_PRINCIPAL_CACHE,
				"loot quantity": 50,
			},
			{ #hits slow and hard, needs restore to win
				"special": "Hits slow but hard. You will need restores (Packet Spoofs) to outlast it.",
				"name": "Principal",
				"difficulty": "Hard",
				"unlocked": true,
				"command": "hack principal",
				"requirements": {"item": Items.SCHOOL_PAYLOAD, "amount": 30},
				"heat": 1.3,
				"exp": 2400,
				"integrity": 500,
				"firewall": 20,
				"counter": 150,
				"counter speed": 2.0,
				"loot": Items.PRINCIPAL_CACHE,
				"loot quantity": 50,
			},
			{ #hits fast and weak, damage reduction + restore
				"special": "Hits fast but weak. Damage reduction and restores win this one.",
				"name": "Superintendent",
				"difficulty": "Hard",
				"unlocked": true,
				"command": "hack superintendent",
				"requirements": {"item": Items.SCHOOL_PAYLOAD, "amount": 35},
				"heat": 2.0,
				"exp": 3000,
				"integrity": 700,
				"firewall": 55,
				"counter": 6,
				"counter speed": 100.0,
				"loot": Items.SUPERINTENDENT_CACHE,
				"loot quantity": 50,
			}
		],
		"art": preload("res://art/school-ascii.png")
	}, "Lawfirm": {
		"command": "view lawfirm",
		"hard mode command": "view lawfirm -hard",
		"name": "Lawfirm",
		"unlocked": true,
		"hard mode unlocked": false,
		"difficulty": "Easy",
		"required payload": Items.LAWFIRM_PAYLOAD,
		"hard mode targets": [], # none built yet
		"targets": [
			{ # PLACEHOLDER stats (School x2.0, tier 2) - balance later
				"name": "Legal Assistant",
				"difficulty": "Easy",
				"unlocked": true,
				"command": "hack legal-assistant",
				"requirements": {"item": Items.LAWFIRM_PAYLOAD, "amount": 1},
				"heat": 0.5,
				"exp": 109,
				"integrity": 164,
				"firewall": 25,
				"counter": 20,
				"counter speed": 16.0,
				"firewall reboot": 10.0, # seconds the firewall stays down after a break
				"loot": Items.LEGAL_ASSISTANT_CACHE
			},
			{ # PLACEHOLDER stats (School x2.0, tier 2) - balance later
				"name": "Paralegal",
				"difficulty": "Easy",
				"unlocked": true,
				"command": "hack paralegal",
				"requirements": {"item": Items.LAWFIRM_PAYLOAD, "amount": 2},
				"heat": 0.8,
				"exp": 1287,
				"integrity": 419,
				"firewall": 31,
				"counter": 18,
				"counter speed": 16.0,
				"firewall reboot": 8.0, # seconds the firewall stays down after a break
				"loot": Items.PARALEGAL_CACHE
			},
			{ # PLACEHOLDER stats (School x2.0, tier 2) - balance later
				"name": "Associate Attorney",
				"difficulty": "Medium",
				"unlocked": true,
				"command": "hack associate-attorney",
				"requirements": {"item": Items.LAWFIRM_PAYLOAD, "amount": 3},
				"heat": 1.1,
				"exp": 1931,
				"integrity": 691,
				"firewall": 74,
				"counter": 22,
				"counter speed": 16.0,
				"firewall reboot": 14.0, # seconds the firewall stays down after a break
				"loot": Items.ASSOCIATE_ATTORNEY_CACHE
			},
			{ # PLACEHOLDER stats (School x2.0, tier 2) - balance later
				"name": "Lawyer",
				"difficulty": "Medium",
				"unlocked": true,
				"command": "hack lawyer",
				"requirements": {"item": Items.LAWFIRM_PAYLOAD, "amount": 4},
				"heat": 1.4,
				"exp": 2578,
				"integrity": 826,
				"firewall": 41,
				"counter": 8,
				"counter speed": 30.0,
				"firewall reboot": 6.0, # seconds the firewall stays down after a break
				"loot": Items.LAWYER_CACHE
			},
			{ # PLACEHOLDER stats (School x2.0, tier 2) - balance later
				"name": "Partner",
				"difficulty": "Hard",
				"unlocked": true,
				"command": "hack partner",
				"requirements": {"item": Items.LAWFIRM_PAYLOAD, "amount": 5},
				"heat": 1.7,
				"exp": 3222,
				"integrity": 1113,
				"firewall": 56,
				"counter": 21,
				"counter speed": 20.0,
				"firewall reboot": 10.0, # seconds the firewall stays down after a break
				"loot": Items.PARTNER_CACHE
			}
		],
		"art": preload("res://art/lawfirm-ascii.png")
	}, "Hospital": {
		"command": "view hospital",
		"hard mode command": "view hospital -hard",
		"name": "Hospital",
		"unlocked": true,
		"hard mode unlocked": false,
		"difficulty": "Easy",
		"required payload": Items.HOSPITAL_PAYLOAD,
		"hard mode targets": [], # none built yet
		"targets": [
			{ # PLACEHOLDER stats (School x3.5, tier 3) - balance later
				"name": "Receptionist",
				"difficulty": "Easy",
				"unlocked": true,
				"command": "hack receptionist",
				"requirements": {"item": Items.HOSPITAL_PAYLOAD, "amount": 1},
				"heat": 0.5,
				"exp": 155,
				"integrity": 348,
				"firewall": 52,
				"counter": 40,
				"counter speed": 16.0,
				"firewall reboot": 10.0, # seconds the firewall stays down after a break
				"loot": Items.RECEPTIONIST_CACHE
			},
			{ # PLACEHOLDER stats (School x3.5, tier 3) - balance later
				"name": "Orderly",
				"difficulty": "Easy",
				"unlocked": true,
				"command": "hack orderly",
				"requirements": {"item": Items.HOSPITAL_PAYLOAD, "amount": 2},
				"heat": 0.8,
				"exp": 1865,
				"integrity": 834,
				"firewall": 63,
				"counter": 35,
				"counter speed": 16.0,
				"firewall reboot": 8.0, # seconds the firewall stays down after a break
				"loot": Items.ORDERLY_CACHE
			},
			{ # PLACEHOLDER stats (School x3.5, tier 3) - balance later
				"name": "Nurse",
				"difficulty": "Medium",
				"unlocked": true,
				"command": "hack nurse",
				"requirements": {"item": Items.HOSPITAL_PAYLOAD, "amount": 3},
				"heat": 1.1,
				"exp": 2798,
				"integrity": 1275,
				"firewall": 143,
				"counter": 43,
				"counter speed": 16.0,
				"firewall reboot": 14.0, # seconds the firewall stays down after a break
				"loot": Items.NURSE_CACHE
			},
			{ # PLACEHOLDER stats (School x3.5, tier 3) - balance later
				"name": "Doctor",
				"difficulty": "Medium",
				"unlocked": true,
				"command": "hack doctor",
				"requirements": {"item": Items.HOSPITAL_PAYLOAD, "amount": 4},
				"heat": 1.4,
				"exp": 3731,
				"integrity": 1890,
				"firewall": 91,
				"counter": 17,
				"counter speed": 30.0,
				"firewall reboot": 6.0, # seconds the firewall stays down after a break
				"loot": Items.DOCTOR_CACHE
			},
			{ # PLACEHOLDER stats (School x3.5, tier 3) - balance later
				"name": "Chief of Medicine",
				"difficulty": "Hard",
				"unlocked": true,
				"command": "hack chief-medicine",
				"requirements": {"item": Items.HOSPITAL_PAYLOAD, "amount": 5},
				"heat": 1.7,
				"exp": 4661,
				"integrity": 2193,
				"firewall": 106,
				"counter": 38,
				"counter speed": 20.0,
				"firewall reboot": 10.0, # seconds the firewall stays down after a break
				"loot": Items.CHIEF_OF_MEDICINE_CACHE
			}
		],
		"art": preload("res://art/hospital-ascii.png"), 
	}, "Bank": {
		"command": "view bank",
		"hard mode command": "view bank -hard",
		"name": "Bank",
		"unlocked": true,
		"hard mode unlocked": false,
		"difficulty": "Easy",
		"required payload": Items.BANK_PAYLOAD,
		"hard mode targets": [], # none built yet
		"targets": [
			{ # PLACEHOLDER stats (School x5.5, tier 4) - balance later
				"name": "Teller",
				"difficulty": "Easy",
				"unlocked": true,
				"command": "hack teller",
				"requirements": {"item": Items.BANK_PAYLOAD, "amount": 1},
				"heat": 0.5,
				"exp": 193,
				"integrity": 672,
				"firewall": 93,
				"counter": 64,
				"counter speed": 16.0,
				"firewall reboot": 10.0, # seconds the firewall stays down after a break
				"loot": Items.TELLER_CACHE
			},
			{ # PLACEHOLDER stats (School x5.5, tier 4) - balance later
				"name": "Loan Officer",
				"difficulty": "Easy",
				"unlocked": true,
				"command": "hack loan-officer",
				"requirements": {"item": Items.BANK_PAYLOAD, "amount": 2},
				"heat": 0.8,
				"exp": 2317,
				"integrity": 1475,
				"firewall": 106,
				"counter": 58,
				"counter speed": 16.0,
				"firewall reboot": 8.0, # seconds the firewall stays down after a break
				"loot": Items.LOAN_OFFICER_CACHE
			},
			{ # PLACEHOLDER stats (School x5.5, tier 4) - balance later
				"name": "Branch Manager",
				"difficulty": "Medium",
				"unlocked": true,
				"command": "hack branch-manager",
				"requirements": {"item": Items.BANK_PAYLOAD, "amount": 3},
				"heat": 1.1,
				"exp": 3475,
				"integrity": 2138,
				"firewall": 230,
				"counter": 67,
				"counter speed": 16.0,
				"firewall reboot": 14.0, # seconds the firewall stays down after a break
				"loot": Items.BRANCH_MANAGER_CACHE
			},
			{ # PLACEHOLDER stats (School x5.5, tier 4) - balance later
				"name": "Security",
				"difficulty": "Medium",
				"unlocked": true,
				"command": "hack security",
				"requirements": {"item": Items.BANK_PAYLOAD, "amount": 4},
				"heat": 1.4,
				"exp": 4634,
				"integrity": 3340,
				"firewall": 169,
				"counter": 34,
				"counter speed": 30.0,
				"firewall reboot": 6.0, # seconds the firewall stays down after a break
				"loot": Items.SECURITY_CACHE
			},
			{ # PLACEHOLDER stats (School x5.5, tier 4) - balance later
				"name": "Chief Financial Officer",
				"difficulty": "Hard",
				"unlocked": true,
				"command": "hack cfo",
				"requirements": {"item": Items.BANK_PAYLOAD, "amount": 5},
				"heat": 1.7,
				"exp": 5792,
				"integrity": 3876,
				"firewall": 188,
				"counter": 68,
				"counter speed": 20.0,
				"firewall reboot": 10.0, # seconds the firewall stays down after a break
				"loot": Items.CFO_CACHE
			}
		],
		"art": preload("res://art/library-ascii.png")
	}, "Police Station": {
		"command": "view police",
		"hard mode command": "view police -hard",
		"name": "Police Station",
		"difficulty": "Easy",
		"unlocked": true,
		"hard mode unlocked": false,
		"required payload": Items.POLICE_PAYLOAD,
		"hard mode targets": [], # none built yet
		"targets": [
			{ # PLACEHOLDER stats (School x8.0, tier 5) - balance later
				"name": "Secretary",
				"difficulty": "Easy",
				"unlocked": true,
				"command": "hack secretary",
				"requirements": {"item": Items.POLICE_PAYLOAD, "amount": 1},
				"heat": 0.5,
				"exp": 225,
				"integrity": 1163,
				"firewall": 135,
				"counter": 79,
				"counter speed": 16.0,
				"firewall reboot": 10.0, # seconds the firewall stays down after a break
				"loot": Items.SECRETARY_CACHE
			},
			{ # PLACEHOLDER stats (School x8.0, tier 5) - balance later
				"name": "Cop",
				"difficulty": "Easy",
				"unlocked": true,
				"command": "hack cop",
				"requirements": {"item": Items.POLICE_PAYLOAD, "amount": 2},
				"heat": 0.8,
				"exp": 2692,
				"integrity": 2340,
				"firewall": 155,
				"counter": 77,
				"counter speed": 16.0,
				"firewall reboot": 8.0, # seconds the firewall stays down after a break
				"loot": Items.COP_CACHE
			},
			{ # PLACEHOLDER stats (School x8.0, tier 5) - balance later
				"name": "Detective",
				"difficulty": "Medium",
				"unlocked": true,
				"command": "hack detective",
				"requirements": {"item": Items.POLICE_PAYLOAD, "amount": 3},
				"heat": 1.1,
				"exp": 4036,
				"integrity": 3246,
				"firewall": 349,
				"counter": 101,
				"counter speed": 16.0,
				"firewall reboot": 14.0, # seconds the firewall stays down after a break
				"loot": Items.DETECTIVE_CACHE
			},
			{ # PLACEHOLDER stats (School x8.0, tier 5) - balance later
				"name": "Sergeant",
				"difficulty": "Medium",
				"unlocked": true,
				"command": "hack sergeant",
				"requirements": {"item": Items.POLICE_PAYLOAD, "amount": 4},
				"heat": 1.4,
				"exp": 5383,
				"integrity": 4156,
				"firewall": 354,
				"counter": 118,
				"counter speed": 30.0,
				"firewall reboot": 6.0, # seconds the firewall stays down after a break
				"loot": Items.SERGEANT_CACHE
			},
			{ # PLACEHOLDER stats (School x8.0, tier 5) - balance later
				"name": "Captain",
				"difficulty": "Hard",
				"unlocked": true,
				"command": "hack captain",
				"requirements": {"item": Items.POLICE_PAYLOAD, "amount": 5},
				"heat": 1.7,
				"exp": 6728,
				"integrity": 5502,
				"firewall": 346,
				"counter": 162,
				"counter speed": 20.0,
				"firewall reboot": 10.0, # seconds the firewall stays down after a break
				"loot": Items.CAPTAIN_CACHE
			}
		],
		"art": preload("res://art/police-station-ascii.png")
	}, "Government": {
		"command": "view government",
		"hard mode command": "view government -hard",
		"name": "Government",
		"difficulty": "Hard",
		"unlocked": true,
		"hard mode unlocked": false,
		"required payload": Items.GOVERNMENT_PAYLOAD,
		"hard mode targets": [], # none built yet
		"targets": [
			{ # PLACEHOLDER stats (School x12.0, tier 6) - balance later
				"name": "Clerk",
				"difficulty": "Easy",
				"unlocked": true,
				"command": "hack clerk",
				"requirements": {"item": Items.GOVERNMENT_PAYLOAD, "amount": 1},
				"heat": 0.5,
				"exp": 252,
				"integrity": 1862,
				"firewall": 198,
				"counter": 106,
				"counter speed": 16.0,
				"firewall reboot": 10.0, # seconds the firewall stays down after a break
				"loot": Items.CLERK_CACHE
			},
			{ # PLACEHOLDER stats (School x12.0, tier 6) - balance later
				"name": "Analyst",
				"difficulty": "Easy",
				"unlocked": true,
				"command": "hack analyst",
				"requirements": {"item": Items.GOVERNMENT_PAYLOAD, "amount": 2},
				"heat": 0.8,
				"exp": 3013,
				"integrity": 3510,
				"firewall": 233,
				"counter": 115,
				"counter speed": 16.0,
				"firewall reboot": 8.0, # seconds the firewall stays down after a break
				"loot": Items.ANALYST_CACHE
			},
			{ # PLACEHOLDER stats (School x12.0, tier 6) - balance later
				"name": "Ambassador",
				"difficulty": "Medium",
				"unlocked": true,
				"command": "hack ambassador",
				"requirements": {"item": Items.GOVERNMENT_PAYLOAD, "amount": 3},
				"heat": 1.1,
				"exp": 4521,
				"integrity": 5200,
				"firewall": 491,
				"counter": 125,
				"counter speed": 16.0,
				"firewall reboot": 14.0, # seconds the firewall stays down after a break
				"loot": Items.AMBASSADOR_CACHE
			},
			{ # PLACEHOLDER stats (School x12.0, tier 6) - balance later
				"name": "Vice President",
				"difficulty": "Medium",
				"unlocked": true,
				"command": "hack vice-president",
				"requirements": {"item": Items.GOVERNMENT_PAYLOAD, "amount": 4},
				"heat": 1.4,
				"exp": 6027,
				"integrity": 8341,
				"firewall": 598,
				"counter": 168,
				"counter speed": 30.0,
				"firewall reboot": 6.0, # seconds the firewall stays down after a break
				"loot": Items.VICE_PRESIDENT_CACHE
			},
			{ # PLACEHOLDER stats (School x12.0, tier 6) - balance later
				"name": "President",
				"difficulty": "Hard",
				"unlocked": true,
				"command": "hack president",
				"requirements": {"item": Items.GOVERNMENT_PAYLOAD, "amount": 5},
				"heat": 1.7,
				"exp": 7534,
				"integrity": 10693,
				"firewall": 566,
				"counter": 223,
				"counter speed": 20.0,
				"firewall reboot": 10.0, # seconds the firewall stays down after a break
				"loot": Items.PRESIDENT_CACHE
			}
		],
		"art": preload("res://art/university-ascii.png")
	}
}

func _ready():
	apply_default_unlocks()
	(func(): Uploads.tier_completed.connect(_on_tier_completed)).call_deferred() # Uploads loads after Stats
	Upgrades.apply_effects() # cooling, VM windows, heat reduction, overheat fan, max anonymity
	(func(): Hacking.SKILL["level up signal"].connect(func(_a = null): set_max_anon())).call_deferred()

##############################
######## DEFRAG BONUS ########
##############################
## Defragging boosts. (Skills no longer get defrag bonuses: has_bonus(<skill>) is always false.)
## "12.5 min": how long a defrag boost lasts (System's Defrag Duration upgrade)
func boost_minutes_text() -> String:
	var m = Upgrades.get_defrag_minutes()
	return ("%d min" % int(m)) if is_equal_approx(m, round(m)) else ("%.1f min" % m)

func grant_bonus(process: Dictionary):
	process["expires_at"] = int(Time.get_unix_time_from_system()) + int(Upgrades.get_defrag_minutes() * 60)

func has_bonus(what) -> bool:
	return what is Dictionary and Defragging.is_active(what)

func get_bonus_time_remaining(bonus_expires_at) -> int:
	return max(0, bonus_expires_at - Time.get_unix_time_from_system())

func get_bonus_time_text(what) -> String:
	var expires = what.get("expires_at", 0) if what is Dictionary else 0
	var remaining = int(get_bonus_time_remaining(expires))
	return "%02d:%02d" % [remaining / 60, remaining % 60]

## Heat plan: multiplier from a skill's HEAT_BY_TIER table for tier <t> (1..6; out of range clamps)
static func tier_heat(table: Array, t: int) -> float:
	return float(table[clamp(t, 1, table.size()) - 1]) if !table.is_empty() else 1.0

const TUTORIAL_MAX_TEMP := 92.0 # overheat starts at 95
func update_tempature(amount: float):
	if amount >= 0.0:
		# System Heat Reduction and the defrag heat boost are both a percent of every heat tick
		amount = max(0.0, amount * (1.0 - HEAT_REDUCTION) * (1.0 - Defragging.get_heat_reduction()))
	system_tempature += amount
	# tutorial safety net (silent): the system can't overheat while the tutorial runs
	if amount > 0.0 and !Tutorial.is_tutorial_complete():
		system_tempature = min(system_tempature, TUTORIAL_MAX_TEMP)
	if system_tempature >= MAX_TEMP:
		system_tempature = MAX_TEMP
	elif system_tempature <= MIN_TEMP:
		system_tempature = MIN_TEMP
	
	
	#OVERHEAT PARAMETERS
	# Watchdog (System capstone): overclock switches itself off before it can cause an overheat
	if overclocked and system_tempature >= WATCHDOG_TEMP and Upgrades.has("system.watchdog"):
		overclocked = false
		Signals.system_message_signal.emit("[color=#ef9f27]Watchdog: %d°C reached, overclock switched off.[/color]" % int(WATCHDOG_TEMP))
	if system_tempature <= Upgrades.get_overheat_clear_temp(): # overheat clears here (80, Thermal Paste raises it)
		if overheated:
			Audiomanager.play_sfx("overheat_finished_sfx")
			Signals.system_cooled_below_overheat()
		overheated = false
	elif system_tempature >= 95: #if temp reaches 95 then overheat
		if !overheated:
			Audiomanager.play_sfx("overheat_sfx")
			overheated = true
			Signals.system_overheated()
		overclocked = false
		overheated = true
	
	Signals.system_temp_updated(system_tempature)
	
	if amount > 0:
		Signals.heat_added(amount)

func get_hacking_target_by_command(command):
	for target in hacking_targets:
		if hacking_targets[target].unlocked:
			for person in hacking_targets[target]["targets"]:
				if person["command"] == command:
					return person
	return {}

func get_hacking_location_by_command(command):
	for target in hacking_targets:
		if hacking_targets[target]["command"] == command or hacking_targets[target]["hard mode command"] == command:
			return hacking_targets[target]
	return {}

	#var targets: Dictionary = Stats.get_hacking_targets_by_command(text)
	#var location_name: String = Stats.get_hacking_location_name_by_command(text)

func get_hacking_targets_by_command(text: String) -> Array:
	for location in hacking_targets:
		if hacking_targets[location].unlocked:
			if hacking_targets[location]["command"] == text:
				return hacking_targets[location]["targets"]
			
			if hacking_targets[location]["hard mode command"] == text:
				return hacking_targets[location]["hard mode targets"]
	
	return []

func get_hacking_location_name_by_command(text: String) -> String:
	for location in hacking_targets:
		if text.to_lower() == hacking_targets[location].name.to_lower():
			return hacking_targets[location].name.to_lower()
	return ""

func get_xp_display(skill_data: Dictionary) -> Dictionary:
	var level = skill_data["level"]
	
	# Cap at max level
	if level >= MAX_LEVEL:
		return {
			"progress": 1.0,
			"current": 0,
			"needed": 0,
			"display": "MAX"
		}
	
	var current_level_xp = xp_for_level(level)        # XP threshold for current level
	var next_level_xp    = xp_for_level(level + 1)    # XP threshold for next level
	var xp_into_level    = skill_data["experience"] - current_level_xp
	var xp_needed        = next_level_xp - current_level_xp  # = xp_to_new_level(level)
	
	return {
		"progress": float(xp_into_level) / float(xp_needed),  # 0.0–1.0
		"current":  xp_into_level,   # shown left of slash
		"needed":   xp_needed,       # shown right of slash
		"display":  "%d/%d" % [xp_into_level, xp_needed]
	}

#returns experience needed provided level
func xp_for_level(lvl: int) -> int:
	if lvl <= 1:
		return 0
	return floor(50.0 * pow(lvl, 2.4))

#returns experience needed for next level
func xp_to_new_level(lvl: int):
	return xp_for_level(lvl + 1) - xp_for_level(lvl)

#returns current level given current total experience
func get_level_from_xp(total_xp: int):
	var lvl = 1
	while lvl < MAX_LEVEL and total_xp >= xp_for_level(lvl + 1):
		lvl += 1
	return lvl

#return between 0.0-1.0
func get_xp_progress(skill_data: Dictionary) -> float:
	var current_level_xp = xp_for_level(skill_data["level"])
	var next_level_xp = xp_for_level(skill_data["level"] + 1)
	return float(skill_data["experience"] - current_level_xp) / float(next_level_xp - current_level_xp)

func add_xp(skill_data: Dictionary, amount: int = 0):
	if skill_data["level"] >= MAX_LEVEL:
		return

	if amount > 0:
		print("Gained xp from specified amount")
		skill_data["experience"] += amount
		gained_xp_signal.emit(amount)
	else:
		skill_data["experience"] += skill_data["exp per level"]
		gained_xp_signal.emit(skill_data["exp per level"])

	var new_level = get_level_from_xp(skill_data["experience"])

	while skill_data["level"] < new_level:
		skill_data["level"] += 1
		on_level_up(skill_data)

		if skill_data["level"] >= MAX_LEVEL:
			skill_data["level"] = MAX_LEVEL
			break

func on_level_up(skill_data: Dictionary):
	#update efficiency
	skill_data["efficiency"] += skill_data["efficiency increase rate"]
	Audiomanager.play_sfx("level_up")

## Cooling applied each cooling tick, including the Defragging: System bonus (negative = cooling).
func get_cooling_amount() -> float:
	return cooling_amount - Defragging.get_bonus_cooling() * cooling_frequency

func update_cooling_amount(amount_to_add: float):
	cooling_amount += amount_to_add
	if cooling_amount >= 0.0:
		cooling_amount = 0.0
	cooling_updated()

#func update_cooling_frequency(time_to_remove: float): #negative number, making it cool faster
	#cooling_frequency += time_to_remove
	#if cooling_frequency <= 0.1:
		#cooling_frequency = 0.1
	#cooling_updated()

func cooling_updated():
	Signals.cooling_updated()

## Max anonymity (no upgrade): 100 + 5 per Hacking level above 1 + 100 per location unlocked past the first
## (145 at L10, ~590 at L99 with only School, 1,090 with all six). Also refreshes the auto-spoof threshold.
const BASE_MAX_ANON := 100
const MAX_ANON_PER_LEVEL := 5
const MAX_ANON_PER_LOCATION := 100
const BASE_SPOOF_THRESHOLD := 0.3

func set_max_anon():
	var locs = 0
	for loc in hacking_targets:
		if hacking_targets[loc].get("unlocked", false):
			locs += 1
	max_anon = BASE_MAX_ANON + MAX_ANON_PER_LEVEL * (int(Hacking.SKILL.level) - 1) + MAX_ANON_PER_LOCATION * max(0, locs - 1)
	healing_threshold_auto_start = BASE_SPOOF_THRESHOLD + Upgrades.cur("hacking.spoof_threshold")

func remove_vm_count(amount: int = 1):
	CURRENT_ALL_VMS -= amount
	if CURRENT_ALL_VMS < 0:
		CURRENT_ALL_VMS = 0

#func save_data() -> Dictionary:
	#return {
		#"system_tempature": system_tempature,
		#"overheated": overheated
	#}
#
#func load_data(data: Dictionary) -> void:
	#system_tempature = float(data.get("system_tempature", system_tempature))
	#overheated = bool(data.get("overheated", overheated))
	#Signals.system_temp_updated(system_tempature)

#region target progression
## Who can be hacked (saved as "unlocks"; the "unlocked" flags written in hacking_targets above are
## overwritten by apply_default_unlocks() at startup):
##  - each location + its FIRST target unlock when the previous tier's upload goal completes (School: from the start)
##  - every other target: 'unlock <target>' in Hacking (a few of the previous target's rare item + payloads)
##  - hard mode is always open, but each hard target unlocks after beating its normal version HARD_UNLOCK_WINS times
const DEV_UNLOCK_ALL_TARGETS := false # TESTING: open every location and target
const HARD_UNLOCK_WINS = 5
## Target access by tier (economy pass 2026-10-20): rares of the previous target, and payloads for target 2 (+ step
## per target after it). Tier 1 is short (~46 hacks), so its access is cheaper.
const ACCESS_RARE_BY_TIER = [2, 3, 4, 5, 5, 5]
const ACCESS_PAYLOAD_BASE_BY_TIER = [4, 10, 10, 10, 10, 10]
const ACCESS_PAYLOAD_STEP_BY_TIER = [10, 25, 25, 25, 25, 25]
const ACCESS_RARE_AMOUNT = 5 # (kept for old references; get_access_recipe uses the per-tier tables)

var wins := {} # target_key -> times beaten
## target_key -> {"sql": avg SQL Injectors per win, "spoof": avg Packet Spoofs per win, "n": wins counted}
## (HintEngine / the side panel's NEXT HACK row recommend from it)
var usage := {}

func record_usage(target: Dictionary, sql: int, spoof: int) -> void:
	var key = target_key(target)
	var u = usage.get(key, {"sql": 0.0, "spoof": 0.0, "n": 0})
	var n = min(int(u.n), 9) # rolling: the last ~10 wins count
	u.sql = (float(u.sql) * n + sql) / (n + 1)
	u.spoof = (float(u.spoof) * n + spoof) / (n + 1)
	u.n = int(u.n) + 1
	usage[key] = u

func get_usage(target: Dictionary) -> Dictionary:
	return usage.get(target_key(target), {})

func apply_default_unlocks() -> void:
	var first = true
	for loc in hacking_targets:
		var l = hacking_targets[loc]
		l["unlocked"] = first or DEV_UNLOCK_ALL_TARGETS
		l["hard mode unlocked"] = true
		for i in l.get("targets", []).size():
			l.targets[i]["unlocked"] = (first and i == 0) or DEV_UNLOCK_ALL_TARGETS
		for t in l.get("hard mode targets", []):
			t["unlocked"] = DEV_UNLOCK_ALL_TARGETS
		first = false

## "School/Student" or "School/Student (Hard)/hard": stable id for saves (wins, unlocks, intel).
func target_key(target: Dictionary) -> String:
	for loc in hacking_targets:
		for list in ["targets", "hard mode targets"]:
			for t in hacking_targets[loc].get(list, []):
				if is_same(t, target):
					return "%s/%s%s" % [loc, t.name, "/hard" if list == "hard mode targets" else ""]
	return str(target.get("name", "?"))

## {"location", "index", "hard"} for a target, or {}.
func target_place(target: Dictionary) -> Dictionary:
	for loc in hacking_targets:
		for list in ["targets", "hard mode targets"]:
			var arr = hacking_targets[loc].get(list, [])
			for i in arr.size():
				if is_same(arr[i], target):
					return {"location": loc, "index": i, "hard": list == "hard mode targets"}
	return {}

## The normal-mode version of a hard target (same position in the location's lists), or {}.
func get_easy_counterpart(target: Dictionary) -> Dictionary:
	var p = target_place(target)
	if p.is_empty() or !p.hard:
		return {}
	var easy = hacking_targets[p.location].get("targets", [])
	return easy[p.index] if p.index < easy.size() else {}

func get_hard_counterpart(target: Dictionary) -> Dictionary:
	var p = target_place(target)
	if p.is_empty() or p.hard:
		return {}
	var hard = hacking_targets[p.location].get("hard mode targets", [])
	return hard[p.index] if p.index < hard.size() else {}

func get_wins(target: Dictionary) -> int:
	return int(wins.get(target_key(target), 0))

## Called by the hacking game on every win.
func record_win(target: Dictionary) -> void:
	var key = target_key(target)
	wins[key] = int(wins.get(key, 0)) + 1
	var hard = get_hard_counterpart(target)
	if !hard.is_empty() and !hard.get("unlocked", false) and wins[key] >= HARD_UNLOCK_WINS:
		hard["unlocked"] = true
		Signals.update_hack_console("[color=#ee4a3a]Hard mode unlocked: %s[/color]" % hard.name)
	SaveManager.mark_dirty()
	unlocks_changed.emit()

func unlock_target(target: Dictionary) -> void:
	target["unlocked"] = true
	SaveManager.mark_dirty()
	unlocks_changed.emit()

## 'unlock <target>' in Hacking: pays the access recipe (rares of the previous target + payloads) and
## unlocks the target. Returns {ok, message}.
func buy_access(target: Dictionary) -> Dictionary:
	var out = {"ok": false, "message": ""}
	if target.is_empty():
		out.message = "Target not found."
		return out
	if target.get("unlocked", false):
		out.message = target.name + " is already unlocked."
		return out
	var p = target_place(target)
	if !hacking_targets[p.location].get("unlocked", false):
		out.message = "%s is in a locked location: %s." % [target.name, get_location_unlock_hint(p.location)]
		return out
	var r = get_access_recipe(target)
	if r.is_empty() or r.rare == null:
		out.message = "%s %s." % [target.name, get_unlock_hint(target)]
		return out
	var missing = []
	for pair in [[r.rare, int(r.rare_amount)], [r.payload, int(r.payload_amount)]]:
		if Inventory.get_amount(pair[0]) < pair[1]:
			missing.append("%s %d/%d" % [pair[0].name, Inventory.get_amount(pair[0]), pair[1]])
	if !missing.is_empty():
		out.message = "Access to %s needs %d %s + %d %s. Missing: %s" % [target.name, int(r.rare_amount), r.rare.name, int(r.payload_amount), r.payload.name, ", ".join(missing)]
		return out
	Inventory.remove_resource(r.rare, int(r.rare_amount))
	Inventory.remove_resource(r.payload, int(r.payload_amount))
	unlock_target(target)
	out.ok = true
	out.message = "ACCESS GRANTED: %s is unlocked (used %d %s + %d %s)." % [target.name, int(r.rare_amount), r.rare.name, int(r.payload_amount), r.payload.name]
	return out

## Opens a location and its first target (tier completion).
func unlock_location(location_key: String) -> void:
	if !hacking_targets.has(location_key):
		return
	var l = hacking_targets[location_key]
	l["unlocked"] = true
	if !l.get("targets", []).is_empty():
		l.targets[0]["unlocked"] = true
	set_max_anon()
	SaveManager.mark_dirty()
	unlocks_changed.emit()

func _on_tier_completed(tier: int) -> void:
	var keys = hacking_targets.keys()
	if tier < keys.size():
		unlock_location(keys[tier]) # tier is 1-based, so this is the next location

## What 'unlock <target>' (Hacking) costs: {"rare", "rare_amount", "payload", "payload_amount"}, or {} when
## the target isn't unlocked that way (first target of a tier, hard targets).
func get_access_recipe(target: Dictionary) -> Dictionary:
	var p = target_place(target)
	if p.is_empty() or p.hard or p.index == 0:
		return {}
	var l = hacking_targets[p.location]
	var ti = clamp(hacking_targets.keys().find(p.location), 0, 5)
	var prev = l.targets[p.index - 1]
	var rare = null
	if prev.get("loot") is CacheData and !prev.loot.rare_pool.is_empty():
		rare = prev.loot.rare_pool[0].item
	return {
		"rare": rare,
		"rare_amount": ACCESS_RARE_BY_TIER[ti],
		"payload": l.get("required payload"),
		"payload_amount": ACCESS_PAYLOAD_BASE_BY_TIER[ti] + ACCESS_PAYLOAD_STEP_BY_TIER[ti] * (p.index - 1),
	}

## Short "how do I unlock this" text for locked targets / locations.
func get_unlock_hint(target: Dictionary) -> String:
	var p = target_place(target)
	if p.is_empty():
		return ""
	if !hacking_targets[p.location].get("unlocked", false):
		return "unlocks with the %s location" % p.location
	if p.hard:
		var easy = get_easy_counterpart(target)
		return "beat %s %d/%d times" % [easy.name, min(get_wins(easy), HARD_UNLOCK_WINS), HARD_UNLOCK_WINS] if !easy.is_empty() else ""
	if p.index == 0:
		return "unlocks with the %s location" % p.location
	return "unlock %s" % target.name.to_lower()

func get_location_unlock_hint(location_key: String) -> String:
	var keys = hacking_targets.keys()
	var i = keys.find(location_key)
	if i <= 0:
		return ""
	return "complete the %s upload goal" % keys[i - 1]

func find_target_by_name(text: String, hard: bool = false) -> Dictionary:
	var name = text.to_lower().replace("-", " ").strip_edges()
	for loc in hacking_targets:
		for t in hacking_targets[loc].get("hard mode targets" if hard else "targets", []):
			if t.name.to_lower().replace("(hard)", "").strip_edges() == name:
				return t
	return {}
#endregion

#Call with Stats.unlock_hard_mode("School")
func unlock_hard_mode(location_key: String) -> void:
	if not hacking_targets.has(location_key):
		push_warning("Unknown hacking location: %s" % location_key)
		return
	hacking_targets[location_key]["hard mode unlocked"] = true

func save_data() -> Dictionary:
	var locations := {}
	for location_key in hacking_targets:
		locations[location_key] = {
			"unlocked": hacking_targets[location_key].get("unlocked", false),
			"hard mode unlocked": hacking_targets[location_key].get("hard mode unlocked", false)
		}
	
	var unlocked_locations := []
	var unlocked_targets := []
	for loc in hacking_targets:
		if hacking_targets[loc].get("unlocked", false):
			unlocked_locations.append(loc)
		for list in ["targets", "hard mode targets"]:
			for t in hacking_targets[loc].get(list, []):
				if t.get("unlocked", false):
					unlocked_targets.append(target_key(t))
	return {
		"system_tempature": system_tempature,
		"overheated": overheated,
		"hacking_locations": locations,
		"unlocks": {"locations": unlocked_locations, "targets": unlocked_targets},
		"wins": wins,
		"usage": usage,
	}

func load_data(data: Dictionary) -> void:
	system_tempature = float(data.get("system_tempature", system_tempature))
	overheated = bool(data.get("overheated", overheated))
	
	# target progression (saves from before it existed start fresh: School / Student only)
	apply_default_unlocks()
	var unlocks: Dictionary = data.get("unlocks", {})
	for loc in unlocks.get("locations", []):
		if hacking_targets.has(loc):
			hacking_targets[loc]["unlocked"] = true
	var keys: Array = unlocks.get("targets", [])
	for loc in hacking_targets:
		for list in ["targets", "hard mode targets"]:
			for t in hacking_targets[loc].get(list, []):
				if target_key(t) in keys:
					t["unlocked"] = true
	wins = {}
	var saved_wins: Dictionary = data.get("wins", {})
	for k in saved_wins:
		wins[k] = int(saved_wins[k])
	usage = {}
	var saved_usage: Dictionary = data.get("usage", {})
	for k in saved_usage:
		var u = saved_usage[k]
		usage[k] = {"sql": float(u.get("sql", 0)), "spoof": float(u.get("spoof", 0)), "n": int(u.get("n", 0))}
	set_max_anon()
	unlocks_changed.emit()
	
	Signals.system_temp_updated(system_tempature)
