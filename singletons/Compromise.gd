extends Node
## Compromise (2026-10-28, replaces hard mode): six of a location's targets back to back in one run.
## Anonymity, heat, bandwidth, Exploit charge and overclock carry over between fights (like a repeat hack).
## Costs PAYLOAD_PER_TIER x tier of the location's payload, paid once at the start. Hacking XP is banked and
## paid on the last breach, with one random driver of that tier the player doesn't own yet. Being traced,
## 'kill' or quitting forfeits everything. Wins don't count as normal breaches. Unlocks when the tier's
## upload goals are complete. 'recon <location>' shows the lineup, 'compromise -<location>' starts it.

const PAYLOAD_PER_TIER := 20
const RULES := [
	"Six targets, fought back to back in this order. Each one uses its own intel.",
	"Anonymity, heat, bandwidth and Exploit charge carry over from one fight to the next.",
	"No rewards until the final breach: Hacking XP is banked, and the prize is a random %s driver you don't have yet.",
	"Getting traced, 'kill' or quitting ends the run and the payloads are lost. Start again from the first target.",
	"Each fight uses 1 hack of your equipped Hacking Mods.",
]
const RECOMMEND := "Stockpile of SQL Injectors, Packet Spoofs, exploits, Intel, and equipped Hacking Mods are highly recommended"

## location key -> [[target index, [traits], {stat overrides}]]. The traits replace the target's own.
## Overrides (optional) change only this compromise fight, never the normal target: any target key works,
## e.g. {"integrity": 300, "counter": 7, "counter speed": 25.0, "firewall": 20, "firewall reboot": 8.0, "heat": 1.0}.
## Values are the target's BASE stats, before traits (same as in stats.gd), so traits still multiply them.
const LINEUPS := {
	"School": [ # (on the cards, after traits)
		[0, ["swarm"], {"integrity": 100, "firewall": 13, "counter": 15, "counter speed": 33.4}],  # Student: 3 dmg every 1.0s
		[0, ["fortress"], {"integrity": 178.6, "firewall": 21.88, "counter": 14}],  # Student: 125 int, 35 fw, 14 dmg
		[1, ["heavy"], {"integrity": 300, "firewall": 15, "counter": 9, "counter speed": 16.67, "firewall reboot": 12.0}],  # Administrator: 45 dmg every 20s
		[2, ["fortress"], {"integrity": 214.3, "firewall": 28.13, "counter": 10, "firewall reboot": 14.0}],  # Vice Principal: 150 int, 45 fw, reboot 7s
		[3, ["heavy", "throttle"], {"counter": 10, "counter speed": 18.52, "firewall reboot": 12.0}],  # Principal: 50 dmg every 18s
		[4, ["swarm", "heater"], {"counter": 20, "firewall reboot": 15.0}],  # Superintendent: 4 dmg
	],
	"Lawfirm": [ # 2026-10-29: first pass, no overrides yet (tune from the recon cards)
		[0, ["throttle"], {"integrity": 240}],  # Legal Assistant
		[0, ["heavy"], {"integrity": 240}],     # Legal Assistant
		[1, ["siphon"], {"counter speed": 23.26}],  # Paralegal: every 4.3s
		[2, ["fortress"], {}],            # Associate Attorney
		[3, ["regenerator", "swarm"], {}],  # Lawyer
		[4, ["escalator", "throttle"], {"integrity": 520, "counter": 25, "firewall": 33}], # 2026-10-30: integrity 600 -> 520, counter 30 -> 25 # Partner (Heater swapped for Throttle: overheat made it unbeatable)
	],
	"Hospital": [ # 2026-10-30: second pass, +10% counter / counter speed, ~+15% integrity, 1s less reboot (shown); tested at 468 max anonymity
		[0, ["packet_loss"], {"integrity": 980, "counter": 44, "counter speed": 17.6, "firewall reboot": 9.0}],  # Receptionist
		[0, ["heavy"], {"integrity": 810, "counter": 32, "counter speed": 17.6, "firewall reboot": 9.0}],        # Receptionist
		[1, ["throttle"], {"integrity": 760, "counter": 41, "counter speed": 24.2, "firewall reboot": 7.0}],     # Orderly
		[2, ["fortress"], {"firewall": 38, "integrity": 390, "counter": 39, "counter speed": 19.8}], # Nurse (reboot kept at 4s: 3s with +10% stats won ~0/4 with the right build)
		[3, ["regenerator", "heater"], {"integrity": 440, "counter": 29, "counter speed": 22.0, "firewall reboot": 5.0}], # Doctor
		[4, ["adaptive", "escalator"], {"integrity": 1100, "counter": 37, "counter speed": 17.6, "firewall": 48}], # Chief of Medicine (reboot kept at 3.5s: +10% alone drops the right build to ~50%)
	],
}

## location key from 'school' / '-school' / 'School' ("" when unknown)
func location_key(text: String) -> String:
	var t = text.strip_edges().to_lower().trim_prefix("-").replace("-", " ")
	for loc in Stats.hacking_targets:
		if str(Stats.hacking_targets[loc].name).to_lower() == t or str(loc).to_lower() == t:
			return loc
	return ""

func tier_of(loc: String) -> int:
	return Stats.hacking_targets.keys().find(loc) + 1

func has_lineup(loc: String) -> bool:
	return LINEUPS.has(loc)

func is_unlocked(loc: String) -> bool:
	return has_lineup(loc) and tier_of(loc) in Uploads.completed_tiers

func payload(loc: String) -> ItemData:
	return Stats.hacking_targets[loc].targets[0].requirements.item

func cost(loc: String) -> int:
	return PAYLOAD_PER_TIER * tier_of(loc)

## The fights: copies of the location's targets with the lineup's traits. "_base" points at the real target
## (Stats.target_key / target_place follow it, so intel, heat tier and the location still work).
func lineup(loc: String) -> Array:
	var out = []
	var targets: Array = Stats.hacking_targets[loc].targets
	for k in LINEUPS.get(loc, []).size():
		var e = LINEUPS[loc][k]
		var base: Dictionary = targets[e[0]]
		var t = base.duplicate()
		t["traits"] = e[1].duplicate()
		if e.size() > 2:
			for k2 in e[2]: # this fight's own stats (the normal target is untouched)
				t[k2] = e[2][k2]
		t["unlocked"] = true
		t["_base"] = base
		t["_step"] = k + 1
		t["_steps"] = LINEUPS[loc].size()
		out.append(t)
	return out

#region drivers
## a driver's tier: its place among its skill's drivers (1st = School ... 5th = Police Station)
func driver_tier(id: String) -> int:
	var sk = Drivers.DEFS[id].skill
	var n = 0
	for d in Drivers.DEFS:
		if Drivers.DEFS[d].skill == sk:
			n += 1
			if d == id:
				return n
	return 0

func tier_drivers(tier: int) -> Array:
	return Drivers.DEFS.keys().filter(func(d): return driver_tier(d) == tier)

func drivers_left(tier: int) -> Array:
	return tier_drivers(tier).filter(func(d): return !Drivers.is_owned(d))

## grants a random driver of <tier> the player doesn't own; "" when none are left
func roll_driver(tier: int) -> String:
	var left = drivers_left(tier)
	if left.is_empty():
		return ""
	var id = left.pick_random()
	Drivers.grant(id)
	return id
#endregion

## why a compromise can't start right now ("" = it can)
func start_problem(loc: String) -> String:
	if loc == "" or !has_lineup(loc):
		return "No compromise there. Locations with one: %s." % ", ".join(LINEUPS.keys().map(func(l): return Stats.hacking_targets[l].name.to_lower()))
	var name = Stats.hacking_targets[loc].name
	if !is_unlocked(loc):
		return "%s compromise is locked: complete the %s upload goals first." % [name, name]
	if drivers_left(tier_of(loc)).is_empty():
		return "You have all %d %s drivers. Rewards for repeat compromises are coming later." % [tier_drivers(tier_of(loc)).size(), name]
	if Inventory.get_amount(payload(loc)) < cost(loc):
		return "A %s compromise costs %d %s (you have %d)." % [name, cost(loc), payload(loc).name, Inventory.get_amount(payload(loc))]
	if Inventory.get_amount(Items.SQL_INJECTOR) <= 0:
		return "Missing SQL Injectors."
	return ""
