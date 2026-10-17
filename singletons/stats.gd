extends Node

signal gained_xp_signal

const MAX_LEVEL = 99 # keep in sync with Exp.MAX_LEVEL (legacy helpers below; Exp owns leveling)

var MAX_TEMP = 100.0
var MIN_TEMP = 30.0
var system_tempature = 30.0
var cooling_amount = -0.1 #reduces temp by 1
var cooling_frequency = 1.0 #in seconds
var overheated = false
var overclocked = false
var CURRENT_ALL_VMS: int = 0
var MAX_ALL_VMS: int = 0
var HEAT_REDUCTION: float = 0.0
var OVERHEAT_FAN: bool = false

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
				"exp": 100,
				"integrity": 100,
				"firewall": 10,
				"counter": 5,
				"counter speed": 16.0,
				"loot": Items.STUDENT_CACHE
			},
			{
				"name": "Administrator",
				"difficulty": "Easy",
				"unlocked": true,
				"command": "hack administrator",
				"requirements": {"item": Items.SCHOOL_PAYLOAD, "amount": 2},
				"heat": 0.9,
				"exp": 1200,
				"integrity": 120,
				"firewall": 13,
				"counter": 7,
				"counter speed": 16.0,
				"loot": Items.ADMIN_CACHE
			},
			{
				"name": "Vice Principal",
				"difficulty": "Medium",
				"unlocked": true,
				"command": "hack vice-principal",
				"requirements": { "item": Items.SCHOOL_PAYLOAD, "amount": 3 },
				"heat": 1.0,
				"exp": 1800,
				"integrity": 140,
				"firewall": 15,
				"counter": 9,
				"counter speed": 16.0,
				"loot": Items.VICE_PRINCIPAL_CACHE
			},
			{
				"name": "Principal",
				"difficulty": "Medium",
				"unlocked": true,
				"command": "hack principal",
				"requirements": {"item": Items.SCHOOL_PAYLOAD, "amount": 4},
				"heat": 1.3,
				"exp": 2400,
				"integrity": 160,
				"firewall": 20,
				"counter": 6,
				"counter speed": 30.0,
				"loot": Items.PRINCIPAL_CACHE
			},
			{
				"name": "Superintendent",
				"difficulty": "Hard",
				"unlocked": true,
				"command": "hack superintendent",
				"requirements": {"item": Items.SCHOOL_PAYLOAD, "amount": 5},
				"heat": 2.0,
				"exp": 3000,
				"integrity": 200,
				"firewall": 30,
				"counter": 12,
				"counter speed": 20.0,
				"loot": Items.SUPERINTENDENT_CACHE
			}
		],
		"hard mode targets": [
			{ #generally hard - requires 2 mods to beat (hopefully) and manually spoof and overclock management
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
				"heat": 0.7,
				"exp": 200,
				"integrity": 200,
				"firewall": 20,
				"counter": 10,
				"counter speed": 16.0,
				"loot": Items.LEGAL_ASSISTANT_CACHE
			},
			{ # PLACEHOLDER stats (School x2.0, tier 2) - balance later
				"name": "Paralegal",
				"difficulty": "Easy",
				"unlocked": true,
				"command": "hack paralegal",
				"requirements": {"item": Items.LAWFIRM_PAYLOAD, "amount": 2},
				"heat": 1.1,
				"exp": 2400,
				"integrity": 240,
				"firewall": 26,
				"counter": 14,
				"counter speed": 16.0,
				"loot": Items.PARALEGAL_CACHE
			},
			{ # PLACEHOLDER stats (School x2.0, tier 2) - balance later
				"name": "Associate Attorney",
				"difficulty": "Medium",
				"unlocked": true,
				"command": "hack associate-attorney",
				"requirements": {"item": Items.LAWFIRM_PAYLOAD, "amount": 3},
				"heat": 1.2,
				"exp": 3600,
				"integrity": 280,
				"firewall": 30,
				"counter": 18,
				"counter speed": 16.0,
				"loot": Items.ASSOCIATE_ATTORNEY_CACHE
			},
			{ # PLACEHOLDER stats (School x2.0, tier 2) - balance later
				"name": "Lawyer",
				"difficulty": "Medium",
				"unlocked": true,
				"command": "hack lawyer",
				"requirements": {"item": Items.LAWFIRM_PAYLOAD, "amount": 4},
				"heat": 1.5,
				"exp": 4800,
				"integrity": 320,
				"firewall": 40,
				"counter": 12,
				"counter speed": 30.0,
				"loot": Items.LAWYER_CACHE
			},
			{ # PLACEHOLDER stats (School x2.0, tier 2) - balance later
				"name": "Partner",
				"difficulty": "Hard",
				"unlocked": true,
				"command": "hack partner",
				"requirements": {"item": Items.LAWFIRM_PAYLOAD, "amount": 5},
				"heat": 2.2,
				"exp": 6000,
				"integrity": 400,
				"firewall": 60,
				"counter": 24,
				"counter speed": 20.0,
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
				"heat": 0.9,
				"exp": 350,
				"integrity": 350,
				"firewall": 35,
				"counter": 18,
				"counter speed": 16.0,
				"loot": Items.RECEPTIONIST_CACHE
			},
			{ # PLACEHOLDER stats (School x3.5, tier 3) - balance later
				"name": "Orderly",
				"difficulty": "Easy",
				"unlocked": true,
				"command": "hack orderly",
				"requirements": {"item": Items.HOSPITAL_PAYLOAD, "amount": 2},
				"heat": 1.3,
				"exp": 4200,
				"integrity": 420,
				"firewall": 45,
				"counter": 24,
				"counter speed": 16.0,
				"loot": Items.ORDERLY_CACHE
			},
			{ # PLACEHOLDER stats (School x3.5, tier 3) - balance later
				"name": "Nurse",
				"difficulty": "Medium",
				"unlocked": true,
				"command": "hack nurse",
				"requirements": {"item": Items.HOSPITAL_PAYLOAD, "amount": 3},
				"heat": 1.4,
				"exp": 6300,
				"integrity": 490,
				"firewall": 52,
				"counter": 32,
				"counter speed": 16.0,
				"loot": Items.NURSE_CACHE
			},
			{ # PLACEHOLDER stats (School x3.5, tier 3) - balance later
				"name": "Doctor",
				"difficulty": "Medium",
				"unlocked": true,
				"command": "hack doctor",
				"requirements": {"item": Items.HOSPITAL_PAYLOAD, "amount": 4},
				"heat": 1.7,
				"exp": 8400,
				"integrity": 560,
				"firewall": 70,
				"counter": 21,
				"counter speed": 30.0,
				"loot": Items.DOCTOR_CACHE
			},
			{ # PLACEHOLDER stats (School x3.5, tier 3) - balance later
				"name": "Chief of Medicine",
				"difficulty": "Hard",
				"unlocked": true,
				"command": "hack chief-medicine",
				"requirements": {"item": Items.HOSPITAL_PAYLOAD, "amount": 5},
				"heat": 2.4,
				"exp": 10500,
				"integrity": 700,
				"firewall": 105,
				"counter": 42,
				"counter speed": 20.0,
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
				"heat": 1.1,
				"exp": 550,
				"integrity": 550,
				"firewall": 55,
				"counter": 28,
				"counter speed": 16.0,
				"loot": Items.TELLER_CACHE
			},
			{ # PLACEHOLDER stats (School x5.5, tier 4) - balance later
				"name": "Loan Officer",
				"difficulty": "Easy",
				"unlocked": true,
				"command": "hack loan-officer",
				"requirements": {"item": Items.BANK_PAYLOAD, "amount": 2},
				"heat": 1.5,
				"exp": 6600,
				"integrity": 660,
				"firewall": 71,
				"counter": 38,
				"counter speed": 16.0,
				"loot": Items.LOAN_OFFICER_CACHE
			},
			{ # PLACEHOLDER stats (School x5.5, tier 4) - balance later
				"name": "Branch Manager",
				"difficulty": "Medium",
				"unlocked": true,
				"command": "hack branch-manager",
				"requirements": {"item": Items.BANK_PAYLOAD, "amount": 3},
				"heat": 1.6,
				"exp": 9900,
				"integrity": 770,
				"firewall": 82,
				"counter": 50,
				"counter speed": 16.0,
				"loot": Items.BRANCH_MANAGER_CACHE
			},
			{ # PLACEHOLDER stats (School x5.5, tier 4) - balance later
				"name": "Security",
				"difficulty": "Medium",
				"unlocked": true,
				"command": "hack security",
				"requirements": {"item": Items.BANK_PAYLOAD, "amount": 4},
				"heat": 1.9,
				"exp": 13200,
				"integrity": 880,
				"firewall": 110,
				"counter": 33,
				"counter speed": 30.0,
				"loot": Items.SECURITY_CACHE
			},
			{ # PLACEHOLDER stats (School x5.5, tier 4) - balance later
				"name": "Chief Financial Officer",
				"difficulty": "Hard",
				"unlocked": true,
				"command": "hack cfo",
				"requirements": {"item": Items.BANK_PAYLOAD, "amount": 5},
				"heat": 2.6,
				"exp": 16500,
				"integrity": 1100,
				"firewall": 165,
				"counter": 66,
				"counter speed": 20.0,
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
				"heat": 1.3,
				"exp": 800,
				"integrity": 800,
				"firewall": 80,
				"counter": 40,
				"counter speed": 16.0,
				"loot": Items.SECRETARY_CACHE
			},
			{ # PLACEHOLDER stats (School x8.0, tier 5) - balance later
				"name": "Cop",
				"difficulty": "Easy",
				"unlocked": true,
				"command": "hack cop",
				"requirements": {"item": Items.POLICE_PAYLOAD, "amount": 2},
				"heat": 1.7,
				"exp": 9600,
				"integrity": 960,
				"firewall": 104,
				"counter": 56,
				"counter speed": 16.0,
				"loot": Items.COP_CACHE
			},
			{ # PLACEHOLDER stats (School x8.0, tier 5) - balance later
				"name": "Detective",
				"difficulty": "Medium",
				"unlocked": true,
				"command": "hack detective",
				"requirements": {"item": Items.POLICE_PAYLOAD, "amount": 3},
				"heat": 1.8,
				"exp": 14400,
				"integrity": 1120,
				"firewall": 120,
				"counter": 72,
				"counter speed": 16.0,
				"loot": Items.DETECTIVE_CACHE
			},
			{ # PLACEHOLDER stats (School x8.0, tier 5) - balance later
				"name": "Sergeant",
				"difficulty": "Medium",
				"unlocked": true,
				"command": "hack sergeant",
				"requirements": {"item": Items.POLICE_PAYLOAD, "amount": 4},
				"heat": 2.1,
				"exp": 19200,
				"integrity": 1280,
				"firewall": 160,
				"counter": 48,
				"counter speed": 30.0,
				"loot": Items.SERGEANT_CACHE
			},
			{ # PLACEHOLDER stats (School x8.0, tier 5) - balance later
				"name": "Captain",
				"difficulty": "Hard",
				"unlocked": true,
				"command": "hack captain",
				"requirements": {"item": Items.POLICE_PAYLOAD, "amount": 5},
				"heat": 2.8,
				"exp": 24000,
				"integrity": 1600,
				"firewall": 240,
				"counter": 96,
				"counter speed": 20.0,
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
				"heat": 1.5,
				"exp": 1200,
				"integrity": 1200,
				"firewall": 120,
				"counter": 60,
				"counter speed": 16.0,
				"loot": Items.CLERK_CACHE
			},
			{ # PLACEHOLDER stats (School x12.0, tier 6) - balance later
				"name": "Analyst",
				"difficulty": "Easy",
				"unlocked": true,
				"command": "hack analyst",
				"requirements": {"item": Items.GOVERNMENT_PAYLOAD, "amount": 2},
				"heat": 1.9,
				"exp": 14400,
				"integrity": 1440,
				"firewall": 156,
				"counter": 84,
				"counter speed": 16.0,
				"loot": Items.ANALYST_CACHE
			},
			{ # PLACEHOLDER stats (School x12.0, tier 6) - balance later
				"name": "Ambassador",
				"difficulty": "Medium",
				"unlocked": true,
				"command": "hack ambassador",
				"requirements": {"item": Items.GOVERNMENT_PAYLOAD, "amount": 3},
				"heat": 2.0,
				"exp": 21600,
				"integrity": 1680,
				"firewall": 180,
				"counter": 108,
				"counter speed": 16.0,
				"loot": Items.AMBASSADOR_CACHE
			},
			{ # PLACEHOLDER stats (School x12.0, tier 6) - balance later
				"name": "Vice President",
				"difficulty": "Medium",
				"unlocked": true,
				"command": "hack vice-president",
				"requirements": {"item": Items.GOVERNMENT_PAYLOAD, "amount": 4},
				"heat": 2.3,
				"exp": 28800,
				"integrity": 1920,
				"firewall": 240,
				"counter": 72,
				"counter speed": 30.0,
				"loot": Items.VICE_PRESIDENT_CACHE
			},
			{ # PLACEHOLDER stats (School x12.0, tier 6) - balance later
				"name": "President",
				"difficulty": "Hard",
				"unlocked": true,
				"command": "hack president",
				"requirements": {"item": Items.GOVERNMENT_PAYLOAD, "amount": 5},
				"heat": 3.0,
				"exp": 36000,
				"integrity": 2400,
				"firewall": 360,
				"counter": 144,
				"counter speed": 20.0,
				"loot": Items.PRESIDENT_CACHE
			}
		],
		"art": preload("res://art/university-ascii.png")
	}
}

func _ready():
	cooling_amount = Upgrades.get_package_info("system.cooling_amount").current
	MAX_ALL_VMS =  Upgrades.get_package_info("system.vm_windows").current
	HEAT_REDUCTION =  Upgrades.get_package_info("system.heat_reduction").current
	OVERHEAT_FAN =  Upgrades.get_package_info("system.overheat_fan").current
	set_max_anon()

##############################
######## DEFRAG BONUS ########
##############################
func grant_bonus(skill: Dictionary): #Mining, Parsing etc
	var now = Time.get_unix_time_from_system()
	skill.skill.bonus_expires_at = now + (skill["bonus time"] * 60)

func has_bonus(skill: Node) -> bool:
	return Time.get_unix_time_from_system() < skill.bonus_expires_at

func get_bonus_time_remaining(bonus_expires_at) -> int:
	return max(0, bonus_expires_at - Time.get_unix_time_from_system())

func get_bonus_time_text(skill: Node) -> String:
	var remaining = get_bonus_time_remaining(skill.bonus_expires_at)

	var minutes = remaining / 60
	var seconds = remaining % 60

	return "%02d:%02d" % [minutes, seconds]
##############################
###### END DEFRAG BONUS ######
##############################

func update_tempature(amount: float):
	if amount >= 0.0:
		amount -= HEAT_REDUCTION
		if amount <= 0.0:
			amount = 0.0
	system_tempature += amount
	if system_tempature >= MAX_TEMP:
		system_tempature = MAX_TEMP
	elif system_tempature <= MIN_TEMP:
		system_tempature = MIN_TEMP
	
	
	#OVERHEAT PARAMETERS
	if system_tempature <= 80: #if overheated, stops overheat mode when reaching below 40
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

func set_max_anon():
	max_anon = Upgrades.get_package_info("hacking.max_anonymity").current

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
	
	return {
		"system_tempature": system_tempature,
		"overheated": overheated,
		"hacking_locations": locations
	}

func load_data(data: Dictionary) -> void:
	system_tempature = float(data.get("system_tempature", system_tempature))
	overheated = bool(data.get("overheated", overheated))
	
	var locations: Dictionary = data.get("hacking_locations", {})
	for location_key in locations:
		if not hacking_targets.has(location_key):
			continue
		var location: Dictionary = hacking_targets[location_key]
		var saved: Dictionary = locations[location_key]
		# OR with the default: everything is open while progression is redesigned, so old demo saves
		# (which stored "unlocked": false) can't re-lock locations. Revisit when unlock progression lands.
		location["unlocked"] = location["unlocked"] or bool(saved.get("unlocked", false))
		location["hard mode unlocked"] = location["hard mode unlocked"] or bool(saved.get("hard mode unlocked", false))
	
	Signals.system_temp_updated(system_tempature)
