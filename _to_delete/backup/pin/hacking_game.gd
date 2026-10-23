extends VBoxContainer
## The auto-battle hacking fight, built in code in the same card style as the headers:
##   [ target header: name · place · state chips (overclock / overheat / firewall down / intel) · status ]
##   [ YOU: anonymity, bandwidth ]            [ TARGET: integrity, firewall ]
##   [ SQL Injector ] [ Packet Spoof ] [ Countermeasures ]   cycle bar, stats, MOD/INTEL lines, state
##   [ COMBAT LOG ]  tagged lines: ATK DEF CTR FW MOD INTEL HEAT SYS
##   [ YIELD ]
## Colors: gold = boosted by a hacking mod, teal = weakened by Decoding intel, amber = overclock,
## red-orange = overheat.
## Firewall break: when SQL Injectors take the firewall to 0, the target's countermeasures run at
## FW_BREAK_SLOW speed for FW_BREAK_TIME seconds, then the firewall reboots to full in FW_REFILL_TIME.
## Used elsewhere: setup(), prepare(), start_hack(), end(), _grant_rewards(), is_hacking, FIREWALL_AMOUNT.

const C_BG = HeaderCard.C_BG
const C_BORDER = HeaderCard.C_BORDER
const C_DIM = HeaderCard.C_DIM
const C_TEXT = HeaderCard.C_TEXT
const C_YOU = Color("#22C55E")
const C_BAND = Color("#3b82f6")
const C_INTEG = Color("#e5484d")
const C_FW = Color("#e8902a")
const C_SQL = Color("#22C55E")
const C_SPOOF = Color("#60a5fa")
const C_CTR = Color("#e5484d")
const C_MOD = Color("#e0c068")
const C_INTEL = Color("#14B8A6")
const C_CRIT = Color("#ffc24a")
const C_OC = Color("#f59e0b")
const C_HEAT = Color("#ff5a3c")
const C_WIN = Color("#4ec994")
const C_EXP = Color("#c084fc") # one-time items / EXPLOIT charge

const FW_BREAK_SLOW := 0.5   # enemy countermeasure speed multiplier while the firewall is down
const FW_BREAK_TIME := 10.0  # seconds the firewall stays down
const FW_REFILL_TIME := 1.0  # seconds to reboot back to full
const LOG_MAX_LINES := 200
const OVERCLOCK_BW_MULT := 2.0  # overclock doubles bandwidth regen
const OVERHEAT_BW_MULT := 0.5   # overheat halves it

@onready var bandwidth_timer = $BandwidthTimer
@onready var safe_exit_timer = $SafeExitTimer

# old color names kept for callers
var c_green: Color = C_WIN
var c_yellow: Color = C_OC
var c_blue: Color = C_SPOOF
var c_red: Color = C_INTEG
var c_white: Color = C_TEXT

#region ui nodes (built in _build_ui)
var header_card: Dictionary
var target_name_label: Label
var sub_label: Label
var status_label_box: PanelContainer
var status_label: Label
var chip_overclock: PanelContainer
var chip_overheat: PanelContainer
var chip_firewall: PanelContainer
var chip_intel: PanelContainer
var you_card: Dictionary
var target_card: Dictionary
var anon_row: Dictionary
var band_row: Dictionary
var integ_row: Dictionary
var fw_row: Dictionary
var anon_bar: ProgressBar
var band_bar: ProgressBar
var integ_bar: ProgressBar
var firewall_bar: ProgressBar
var sql_card: Dictionary
var spoof_card: Dictionary
var ctr_card: Dictionary
var attack_bar: ProgressBar
var defense_bar: ProgressBar
var counter_bar: ProgressBar
var log_rtl: RichTextLabel
var yield_label: Label
var yield_hint: Label
var _banner_node: Control
var _log_empty := true
#endregion

var is_hacking: bool = false
var player_is_alive: bool = true
var attacking: bool = false
var ATTACK_SPEED: float = 10.0
var ATTACK_BASE: int = 0
var ATTACK_AMOUNT: int = 0
var FIREWALL_DAMAGE: int = 0
var ATTACK_BW_COST = 0
var ATTACK_HEAT: float = 0.3
const BASE_ATTACK_HEAT := 0.3
const ATTACK_HEAT_PER_DAMAGE := 0.1
var DEFEND_PCT: float = 0.05 # Packet Spoof heal as a fraction of max anonymity
## Capstones
const SECOND_WIND_RESTORE := 0.25 # Second Wind (T1 capstone): max anonymity restored after each win in a multi-hack run
const EVASION_CHANCE := 0.1       # countermeasure dodged
const RECYCLER_CHANCE := 0.5      # SQL Injector not consumed
const SIPHON_PCT := 0.005         # max anonymity restored per SQL hit
const DEAD_MANS_RESTORE := 0.25   # once per session: survive a trace at 1, then restore this much
const EXPLOIT_KIT_CHANCE := 0.5   # one-time item not consumed
var dead_mans_used := false
var defending: bool = false
var DEFEND_SPEED: float = 5.0
var DEFEND_AMOUNT: int = 0
var DEFEND_BW_COST: int = 0
var DEFEND_HEAT: float = 0.5
var COUNTER_SPEED: float = 12.0
var COUNTER_AMOUNT: int = 2
var COUNTER_HEAT: float = 0
var EXP_AMOUNT: int = 0
var BANDWIDTH_RECOVERY_RATE: float = 0.0
var MAX_BANDWIDTH: int = 0

var OVERCLOCK_VALUE: float = 1.0 # bandwidth regen multiplier (overclock / overheat)
var OVERHEAT_VALUE: float = 1.0
var NEXT_HEAT_APPLICATION: int = 0

var INTEGRITY_AMOUNT: int = 0
var FIREWALL_AMOUNT: int = 0
var target_reward
var target_reward_amount
var target_name

var reward_amount: int = 0
var requirements
var current_target: Dictionary = {} # the Stats target being hacked (intel is looked up per hack)

var offensive_item
var defensive_item
var COMBAT_QUEUE = []

var stop_hacking: bool = false
var caches_gained: int = 0

# Number of hacks remaining. -1 means recursive/unlimited.
var hacks_remaining: int = 1
var hack_total: int = 1
var hack_index: int = 0

# If true, the hack starts in overclock mode.
var start_overclock: bool = false

# firewall break
var firewall_down := false
var fw_down_left := 0.0
var fw_start_value := 0.0   # what the firewall reboots to (after intel / mods)
var fw_base := 0            # target's firewall before intel
var integ_base := 0
var _fw_tween: Tween

var fight_time := 0.0
var hack_time := 0.0          # this hack only (Silent Entry)
var decoys_left := 0          # Decoy Traffic misses left this hack
var active_intel: Dictionary = {} # this attempt's intel {pct, hacks_left, integrity/firewall/counter/counter speed: [before, after]}
var _state := ""                  # "", "overclock", "overheat"
var _panel_tick := 0.0
var _revealed := false            # target stats are shown once access is granted

# one-time item effects (Exploits); cleared at the start of each hack attempt
var stun_left := 0.0          # countermeasures paused
var poison_left := 0.0        # Slow Drip ticking
var throttle_left := 0.0      # SQL bandwidth cost halved
var spoof_boost_left := 0.0   # Packet Spoof x2
var bw_freeze_left := 0.0     # bandwidth held at max, actions free
var crits_left := 0           # guaranteed crits
var _breach_hit := false
var breach_crit := false
var stop_after_win := false
var fw_fresh := false        # Handshake Exploit: the next hit is the first against this firewall
var _hack_sql := 0           # SQL Injectors / Packet Spoofs used this hack (Stats.record_usage on a win)
var _hack_spoof := 0   # 'kill -s': finish the current hack, then end the run      # the first SQL hit after the firewall goes down is a guaranteed crit
var ghost_left := 0           # countermeasures that miss
var _exploit_lock := 0.0      # Exploits.LOCKOUT between uses
var _poison_tick := 0.0
var _bw_cap_warned := false
var _exp_ready := false
var exp_row: Dictionary
var _effect_chips := {}
var _bw_warned := {}              # action -> true: the bandwidth wait is logged once per hack
var _atk_waiting := false
var _def_waiting := false

func _ready():
	_build_ui()
	Signals.end_hacking_safely_signal.connect(kill_hack_safely)
	Signals.end_hacking_signal.connect(kill_hack)
	Signals.manual_packet_spoof_signal.connect(manual_defense)

#region combat loop
func _process(delta):
	if !is_hacking:
		return
	fight_time += delta
	_update_state()
	# overclock / overheat only touch bandwidth regen (and enemy speed on overheat);
	# damage and attack speed come from mods and upgrades only
	var cold_boot = HackingMods.has_mod(HackingMods.MOD_TYPE.COLD_BOOT) # equippable: no overclock heat, overheat doesn't speed the enemy
	if Stats.overclocked:
		OVERCLOCK_VALUE = OVERCLOCK_BW_MULT
		OVERHEAT_VALUE = 1.0
		NEXT_HEAT_APPLICATION = 0 if cold_boot else 2
	elif Stats.overheated:
		OVERCLOCK_VALUE = OVERHEAT_BW_MULT
		OVERHEAT_VALUE = 1.0 if cold_boot else 2.0  # 2x speed for enemy
	else:
		OVERCLOCK_VALUE = 1.0
		OVERHEAT_VALUE = 1.0

	_exploit_lock = max(0.0, _exploit_lock - delta)
	_tick_effects(delta)
	if !is_hacking:
		return

	# bandwidth regenerates continuously (float); Overdraft holds it at max
	if bw_freeze_left > 0.0:
		Hacking.current_bandwidth = float(MAX_BANDWIDTH)
	else:
		Hacking.current_bandwidth = min(float(MAX_BANDWIDTH), Hacking.current_bandwidth + _bw_rate() * delta)
	band_bar.value = Hacking.current_bandwidth

	hack_time += delta
	var mod_atk_spd = 1.0 + _mod(HackingMods.MOD_TYPE.ATTACK_SPEED) + _mod(HackingMods.MOD_TYPE.SQL_BOOST)
	if attacking:
		attack_bar.value += ATTACK_SPEED * delta * mod_atk_spd
	if defending:
		defense_bar.value += DEFEND_SPEED * delta * (1.0 + _mod(HackingMods.MOD_TYPE.SPOOF_SPEED))
	# Silent Entry: the first seconds of each hack go unnoticed
	if Stats.current_anon > 0 and stun_left <= 0.0 and hack_time >= _mod(HackingMods.MOD_TYPE.STEALTH_START):
		counter_bar.value += _counter_rate() * delta

	if firewall_down:
		fw_down_left -= delta
		if fw_down_left <= 0.0:
			_restore_firewall()

	# a full bar fires as soon as there is bandwidth for it; Packet Spoof gets first claim
	_def_waiting = false
	if defense_bar.value >= defense_bar.max_value and defending:
		if has_bandwidth(_spoof_cost()):
			defense()
		else:
			_def_waiting = true
			_warn_bandwidth("Packet Spoof", _spoof_cost())
	_atk_waiting = false
	if attack_bar.value >= attack_bar.max_value and attacking and !_def_waiting:
		if has_bandwidth(_sql_cost()):
			attack()
		else:
			_atk_waiting = true
			_warn_bandwidth("SQL Injector", _sql_cost())
	if !is_hacking:
		return

	if counter_bar.value >= counter_bar.max_value:
		counter_bar.value = 0.0
		counter()
	if !is_hacking:
		return

	_panel_tick -= delta
	if _panel_tick <= 0.0:
		_panel_tick = 0.2
		_try_auto_exploit()
		_refresh_panels()

## countermeasure bar fill per second (overheat, firewall break, slow mod, intel all apply)
func _counter_rate() -> float:
	# firewall down: -50% (Shatter Protocol: a further -25%); Latency Injector: -20%
	var fw_slow = max(0.05, FW_BREAK_SLOW - _mod(HackingMods.MOD_TYPE.FW_BREAK_SLOW)) if firewall_down else 1.0
	return COUNTER_SPEED * OVERHEAT_VALUE * fw_slow / (1.0 + _mod(HackingMods.MOD_TYPE.COUNTER_SLOW)) * (1.0 - _mod(HackingMods.MOD_TYPE.COUNTER_SLOW_PCT))

## Packet Spoof bandwidth (Ghost Packet: free)
func _spoof_cost() -> float:
	return 0.0 if HackingMods.has_mod(HackingMods.MOD_TYPE.SPOOF_FREE) else float(DEFEND_BW_COST)

func has_bandwidth(cost: float) -> bool:
	return bw_freeze_left > 0.0 or Hacking.current_bandwidth >= cost

## SQL Injector bandwidth per attack: item + equipped mods (by tier), halved by Throttle Patch.
## Capped at max bandwidth so an attack can always eventually fire.
func _sql_cost() -> float:
	var c = float(ATTACK_BW_COST + HackingMods.get_bandwidth_cost())
	if throttle_left > 0.0:
		c *= float(Exploits.DEFS.throttle_patch.mult)
	if c > MAX_BANDWIDTH and MAX_BANDWIDTH > 0:
		if !_bw_cap_warned and is_hacking:
			_bw_cap_warned = true
			_log("BW", C_INTEG, "SQL Injector + mods cost %s bandwidth but your max is %d - capped at max (upgrade max bandwidth)" % [_fmt(c), MAX_BANDWIDTH])
		c = float(MAX_BANDWIDTH)
	return c

func _spend_bandwidth(cost: float) -> void:
	if bw_freeze_left > 0.0:
		return
	Hacking.current_bandwidth = max(0.0, Hacking.current_bandwidth - cost)

## bandwidth regenerated per second: base + upgrade + mod, x2 overclocked, x0.5 overheated
func _bw_rate() -> float:
	var per_tick = BANDWIDTH_RECOVERY_RATE + _mod(HackingMods.MOD_TYPE.BAND_RATE)
	var burst = _mod(HackingMods.MOD_TYPE.BW_PCT_REGEN) * MAX_BANDWIDTH # Burst Buffer: % of max bandwidth per second
	return (per_tick / max(0.01, Hacking.bandwidth_recovery_speed) + burst) * OVERCLOCK_VALUE

## logged once per action per hack; after that the card's state line shows the wait
func _warn_bandwidth(action: String, cost: float) -> void:
	if _bw_warned.has(action):
		return
	_bw_warned[action] = true
	_log("BW", C_BAND, "%s waiting for bandwidth (needs %s, have %.1f) - bandwidth regen limits your action rate" % [action, _fmt(cost), Hacking.current_bandwidth])
#endregion

#region setup
func setup(target: Dictionary, loadout: Dictionary = {}, hack_count: int = 1, overclock: bool = false):
	current_target = target
	caches_gained = 0
	stop_hacking = false
	hacks_remaining = hack_count
	hack_total = hack_count
	hack_index = 0
	fight_time = 0.0
	_state = ""
	_bw_cap_warned = false
	_clear_effects()
	Exploits.reset_charge() # charge belongs to one hack session
	active_intel = {}
	firewall_down = false
	breach_crit = false
	stop_after_win = false
	_revealed = false

	start_overclock = overclock
	Stats.overclocked = start_overclock

	offensive_item = loadout.offensive
	defensive_item = loadout.defensive
	var dmg_upgrade = Upgrades.get_package_info("hacking.damage")
	ATTACK_BASE = offensive_item.damage + dmg_upgrade.current
	ATTACK_AMOUNT = ATTACK_BASE + int(_mod(HackingMods.MOD_TYPE.DAMAGE))
	var firewall_upgrade = Upgrades.get_package_info("hacking.firewall")
	FIREWALL_DAMAGE = offensive_item.firewall_damage + firewall_upgrade.current
	ATTACK_SPEED = offensive_item.speed
	ATTACK_BW_COST = offensive_item.bandwidth_cost

	var bandwidth_upgrade = Upgrades.get_package_info("hacking.bandwidth_recovery")
	BANDWIDTH_RECOVERY_RATE = Hacking.bandwidth_recovery_rate + bandwidth_upgrade.current
	var max_b_upgrade = Upgrades.get_package_info("hacking.max_bandwidth")
	MAX_BANDWIDTH = Hacking.max_bandwidth + max_b_upgrade.current

	COUNTER_SPEED = target["counter speed"]
	COMBAT_QUEUE.clear()
	# Healing: a Packet Spoof restores a % of max anonymity (its "heal" 5 = 5%) + the Healing track
	DEFEND_PCT = float(defensive_item.heal) / 100.0 + Upgrades.cur("hacking.healing")
	DEFEND_AMOUNT = int(ceil(Stats.max_anon * DEFEND_PCT))
	# Damage track: each install also adds attack heat (balances System cooling)
	ATTACK_HEAT = BASE_ATTACK_HEAT + ATTACK_HEAT_PER_DAMAGE * int(Upgrades.get_package_info("hacking.damage").get("installed", 0))
	dead_mans_used = false
	DEFEND_SPEED = defensive_item.speed
	DEFEND_BW_COST = defensive_item.bandwidth_cost

	Stats.current_anon = Stats.max_anon
	anon_bar.max_value = Stats.max_anon
	anon_bar.value = Stats.current_anon
	Hacking.current_bandwidth = float(MAX_BANDWIDTH) # reset bandwidth when starting to hack
	band_bar.max_value = MAX_BANDWIDTH
	band_bar.value = Hacking.current_bandwidth
	integ_bar.max_value = target.integrity
	integ_bar.value = 0
	firewall_bar.max_value = max(1, target.firewall)
	firewall_bar.value = 0
	requirements = target.requirements

	COUNTER_AMOUNT = target["counter"]
	COUNTER_HEAT = target["heat"]
	EXP_AMOUNT = target["exp"]
	INTEGRITY_AMOUNT = target["integrity"]
	target_reward = target["loot"]
	target_reward_amount = target.get("loot quantity", 1)
	target_name = target["name"]
	FIREWALL_AMOUNT = target["firewall"]

	target_name_label.text = target_name
	target_card.title.text = target_name.to_upper()
	ctr_card.count.text = ""
	sql_card.title.text = offensive_item.name.to_upper()
	spoof_card.title.text = defensive_item.name.to_upper()
	for c in [chip_overclock, chip_overheat, chip_firewall, chip_intel]:
		c.visible = false
	_update_sub_label()
	update_status_label_badge("finding target", C_OC)

	attack_bar.value = 0
	defense_bar.value = 0
	counter_bar.value = 0
	reward_amount = 0
	update_bottom_row()
	log_rtl.clear()
	_log_empty = true
	_refresh_labels()
	_refresh_panels()

	if Inventory.get_amount(defensive_item) > 0 and is_anon_below_healing_threshold():
		defending = true
	if Inventory.get_amount(offensive_item) > 0:
		attacking = true

func _update_sub_label() -> void:
	var p = Stats.target_place(current_target)
	var parts = []
	if !p.is_empty():
		parts.append(str(p.location).capitalize() + (" · hard mode" if p.hard else ""))
	if hack_total == -1:
		parts.append("hack %d (repeating)" % max(1, hack_index))
	elif hack_total > 1:
		parts.append("hack %d/%d" % [max(1, hack_index), hack_total])
	sub_label.text = "  ·  ".join(parts)
#endregion

#region actions
func attack():
	var M = HackingMods.MOD_TYPE
	var crit = 1.0
	var forced_crit = false
	_breach_hit = false
	if crits_left > 0:
		crits_left -= 1
		crit = 2.0
		forced_crit = true
	elif breach_crit:
		breach_crit = false
		crit = 2.0
		forced_crit = true
		_breach_hit = true
	elif randf() <= _get_total_efficiency() * (_mod(M.CRIT_CHANCE_MULT) if HackingMods.has_mod(M.CRIT_CHANCE_MULT) else 1.0):
		crit = 2.0
	if crit > 1.0 and HackingMods.has_mod(M.CRIT_DAMAGE_MULT):
		crit *= _mod(M.CRIT_DAMAGE_MULT) # Critical Overflow: 10 -> 20 -> 40
	var bw_cost = _sql_cost()
	var raw_dmg = int(round(ATTACK_AMOUNT * (1.0 + _mod(M.DAMAGE_PCT)) * crit))
	var fw_before = firewall_bar.value if !firewall_down else 0.0
	var blocked = min(fw_before, raw_dmg) # only the part the firewall actually absorbed
	var actual_dmg = max(raw_dmg - fw_before, 0)

	var fw_hit = 0
	var opener = 0.0
	if fw_before > 0 and fw_fresh and _mod(M.FW_OPENER) > 0:
		opener = _mod(M.FW_OPENER) # Handshake Exploit: first hit on a new firewall
	if fw_before > 0:
		fw_fresh = false
		var fw_dmg = FIREWALL_DAMAGE + _mod(M.FIREWALL_DAMAGE) + _mod(M.FW_PCT_HIT) * fw_base + opener # Packet Shredder: % of max firewall
		fw_hit = int(min(fw_before, fw_dmg))
		firewall_bar.value -= fw_dmg

	_spend_bandwidth(bw_cost)
	band_bar.value = Hacking.current_bandwidth
	integ_bar.value -= actual_dmg
	Exploits.add_charge("crit" if crit > 1 else "attack")
	add_heat(ATTACK_HEAT)
	var recycled = Upgrades.has("hacking.recycler") and randf() < RECYCLER_CHANCE
	if !recycled:
		Inventory.remove_resource(offensive_item, 1)
		_hack_sql += 1
	var siphoned = 0
	if Upgrades.has("hacking.siphon"):
		var before_anon = Stats.current_anon
		Stats.current_anon = min(Stats.max_anon, Stats.current_anon + ceil(Stats.max_anon * SIPHON_PCT))
		siphoned = int(Stats.current_anon - before_anon)
		anon_bar.value = Stats.current_anon
	Signals.update_hacking_header()

	# log: what hit what, and why it was bigger
	var line = "SQL Injector -> %s  %s" % [target_name, _c("-%d integrity" % actual_dmg, C_INTEG)]
	if crit > 1:
		line = _c("CRIT x%d " % int(crit), C_CRIT) + line
		if forced_crit and !_breach_hit:
			line += "  " + _c("(Zero-Day, %d left)" % crits_left, C_EXP)
		elif _breach_hit:
			line += "  " + _c("(firewall breach)", C_FW)
	if blocked > 0:
		line += "  " + _c("firewall absorbed %d" % blocked, C_FW)
	if fw_hit > 0:
		line += "  " + _c("firewall -%d" % fw_hit, C_FW)
	var tags = []
	if _mod(M.DAMAGE) > 0:
		tags.append("+%d dmg" % int(_mod(M.DAMAGE)))
	if _mod(M.FIREWALL_DAMAGE) > 0 and fw_hit > 0:
		tags.append("+%d firewall dmg" % int(_mod(M.FIREWALL_DAMAGE)))
	if opener > 0:
		tags.append("handshake +%d firewall dmg" % int(opener))
	if crit > 1 and _mod(M.EFFICIENCY) > 0:
		tags.append("+%d%% crit" % roundi(_mod(M.EFFICIENCY) * 100))
	if !tags.is_empty():
		line += "  " + _c("(MOD " + ", ".join(tags) + ")", C_MOD)
	if recycled:
		line += "  " + _c("(recycled)", C_EXP)
	if _mod(M.COUNTER_RESET) > 0 and counter_bar.value > 0.0 and randf() < _mod(M.COUNTER_RESET):
		counter_bar.value = 0.0 # Countermeasure Reset mod (payloads)
		line += "  " + _c("(MOD countermeasures reset)", C_MOD)
		_float(ctr_card.panel, "RESET", C_MOD, 14)
	if siphoned > 0:
		line += "  " + _c("+%d anonymity (siphon)" % siphoned, C_YOU)
	line += "  " + _c("bw -%s" % _fmt(bw_cost) if bw_freeze_left <= 0.0 else "bw frozen", C_DIM)
	_log("ATK", C_SQL, line)

	# impact
	if crit > 1:
		_float(integ_bar, "CRIT -%d" % actual_dmg, C_CRIT, 20)
		_shake(target_card.panel, 5.0)
		_flash(integ_bar, Color(2.0, 1.8, 1.2), 0.35)
	elif actual_dmg > 0:
		_float(integ_bar, "-%d" % actual_dmg, C_INTEG, 15)
		_flash(integ_bar, Color(1.9, 1.9, 1.9), 0.25)
	if blocked > 0:
		_float(firewall_bar, "blocked %d" % blocked, C_FW, 11, 18.0)
		_flash(firewall_bar, Color(1.8, 1.6, 1.4), 0.25)
	_flash(sql_card.panel, Color(1.25, 1.4, 1.25), 0.2)

	attacking = Inventory.get_amount(offensive_item) > 0
	if !attacking:
		_log("SYS", C_INTEG, "out of SQL Injectors - use 'kill' to abort")
		Signals.update_hack_console("\n\n[color=#e24b4a]OUT OF SQL INJECTORS - ABORT HACKING WITH 'KILL'[/color]\n")
	attack_bar.value = 0.0
	if integ_bar.value <= 0.0:
		win()
		return
	if fw_before > 0 and firewall_bar.value <= 0.0 and !firewall_down:
		_break_firewall(true)
	_refresh_panels()

func defense():
	# Restore mods add percentage points of max anonymity (+5 = +5%)
	var mod_restore = int(ceil(Stats.max_anon * _mod(HackingMods.MOD_TYPE.RESTORE) / 100.0))
	var amount = int(ceil(Stats.max_anon * DEFEND_PCT)) + mod_restore
	if HackingMods.has_mod(HackingMods.MOD_TYPE.SPOOF_HEAL_MULT):
		amount = int(amount * _mod(HackingMods.MOD_TYPE.SPOOF_HEAL_MULT)) # Proxy Chain
	var boosted = spoof_boost_left > 0.0
	if boosted:
		amount = int(amount * float(Exploits.DEFS.booster_shot.mult))
	var before = Stats.current_anon
	Stats.current_anon = min(Stats.max_anon, Stats.current_anon + amount)
	var healed = int(Stats.current_anon - before)
	add_heat(DEFEND_HEAT)
	_spend_bandwidth(_spoof_cost())
	band_bar.value = Hacking.current_bandwidth
	anon_bar.value = Stats.current_anon
	Exploits.add_charge("spoof")
	Inventory.remove_resource(defensive_item, 1)
	_hack_spoof += 1
	Signals.update_hacking_header()

	var line = "Packet Spoof -> you  %s  (%d/%d)" % [_c("+%d anonymity" % healed, C_YOU), Stats.current_anon, Stats.max_anon]
	if mod_restore > 0:
		line += "  " + _c("(MOD +%d restore)" % mod_restore, C_MOD)
	if boosted:
		line += "  " + _c("(Booster Shot x2)", C_EXP)
	if healed < amount:
		line += "  " + _c("%d over max" % (amount - healed), C_DIM)
	line += "  " + _c("bw -%d" % DEFEND_BW_COST, C_DIM)
	_log("DEF", C_SPOOF, line)
	_float(anon_bar, "+%d" % healed, C_MOD if mod_restore > 0 else C_YOU, 15)
	_flash(anon_bar, Color(1.6, 2.0, 1.6), 0.3)
	_flash(spoof_card.panel, Color(1.25, 1.35, 1.6), 0.2)

	if Inventory.get_amount(defensive_item) > 0 and is_anon_below_healing_threshold():
		defending = true
	else:
		defending = false
		if Inventory.get_amount(defensive_item) > 0:
			_log("DEF", C_DIM, "Packet Spoof on standby (anonymity above %d%%)" % roundi(Stats.healing_threshold_auto_start * 100))
		else:
			_log("DEF", C_INTEG, "out of Packet Spoofs")
	defense_bar.value = 0.0
	_refresh_panels()

func counter():
	var M = HackingMods.MOD_TYPE
	if ghost_left > 0:
		ghost_left -= 1
		_log("CTR", C_CTR, "%s countermeasures -> you  %s  %s" % [target_name, _c("MISSED", C_EXP), _c("(Ghost Mode, %d left)" % ghost_left, C_EXP)])
		_float(anon_bar, "MISS", C_EXP, 15)
		return
	if decoys_left > 0:
		decoys_left -= 1
		_log("CTR", C_CTR, "%s countermeasures -> you  %s  %s" % [target_name, _c("MISSED", C_EXP), _c("(Decoy Traffic, %d left)" % decoys_left, C_MOD)])
		_float(anon_bar, "DECOY", C_MOD, 15)
		return
	if Upgrades.has("hacking.evasion") and randf() < EVASION_CHANCE:
		_log("CTR", C_CTR, "%s countermeasures -> you  %s  %s" % [target_name, _c("EVADED", C_EXP), _c("(Evasion)", C_DIM)])
		_float(anon_bar, "EVADED", C_EXP, 15)
		return
	var reduce = int(_mod(M.DAMAGE_REDUCTION))
	var dmg = max(1, COUNTER_AMOUNT - reduce) # min 1 damage
	Stats.current_anon = max(0.0, Stats.current_anon - dmg)
	var switched = false
	if Stats.current_anon <= 0.0 and Upgrades.has("hacking.dead_mans_switch") and !dead_mans_used:
		dead_mans_used = true
		switched = true
		Stats.current_anon = 1.0 + ceil(Stats.max_anon * DEAD_MANS_RESTORE)
	add_heat(COUNTER_HEAT)
	anon_bar.value = Stats.current_anon
	Exploits.add_charge("hit_taken")
	var reflected = int(round(dmg * _mod(M.COUNTER_REFLECT))) # Mirror
	if reflected > 0 and Stats.current_anon > 0.0:
		integ_bar.value -= reflected
		_log("MOD", C_MOD, "Mirror reflects %d damage to %s" % [reflected, target_name])
		if integ_bar.value <= 0.0:
			win()
			return

	var line = "%s countermeasures -> you  %s  (%d/%d)" % [target_name, _c("-%d anonymity" % dmg, C_INTEG), Stats.current_anon, Stats.max_anon]
	if reduce > 0:
		line += "  " + _c("(MOD -%d dmg)" % reduce, C_MOD)
	if !active_intel.is_empty():
		line += "  " + _c("(INTEL -%d%% dmg)" % _ipct("counter"), C_INTEL)
	if firewall_down:
		line += "  " + _c("(slowed: firewall down)", C_FW)
	_log("CTR", C_CTR, line)
	if switched:
		_log("DEF", C_EXP, "DEAD MAN'S SWITCH: trace blocked at 1 anonymity, restored to %d/%d (once per session)" % [Stats.current_anon, Stats.max_anon])
		_banner("DEAD MAN'S SWITCH", "trace blocked  ·  +25% anonymity", C_EXP, 0.9)
		anon_bar.value = Stats.current_anon
	_float(anon_bar, "-%d" % dmg, C_INTEG, 15)
	_flash(anon_bar, Color(2.0, 1.2, 1.2), 0.3)
	_flash(ctr_card.panel, Color(1.6, 1.15, 1.15), 0.2)
	_shake(you_card.panel, 3.0 if dmg < Stats.max_anon * 0.1 else 6.0)

	if Stats.current_anon <= 0.0:
		lose()
		return
	if is_anon_below_healing_threshold():
		_engage_spoof("anonymity below %d%%" % roundi(Stats.healing_threshold_auto_start * 100))

func _engage_spoof(reason: String) -> void:
	if defending or Inventory.get_amount(defensive_item) <= 0:
		return
	defending = true
	_log("DEF", C_SPOOF, "Packet Spoof engaged - " + reason)
	_flash(spoof_card.panel, Color(1.3, 1.45, 1.9), 0.4)

func manual_defense():
	if is_hacking and Inventory.get_amount(defensive_item) > 0 and !defending:
		_engage_spoof("manual spoof")
#endregion

#region firewall break
## seconds the target's firewall stays down after a break (per target, "firewall reboot")
func _fw_down_time() -> float:
	return float(current_target.get("firewall reboot", FW_BREAK_TIME))

func _break_firewall(earned: bool = true) -> void:
	if earned:
		Exploits.add_charge("firewall")
		_float(exp_row.bar, "+%d charge" % int(Exploits.CHARGE_GAIN.firewall), C_EXP, 12, 18.0)
	firewall_down = true
	breach_crit = true
	fw_down_left = _fw_down_time()
	if _fw_tween and _fw_tween.is_valid():
		_fw_tween.kill()
	firewall_bar.value = 0
	_log("FW", C_FW, "%s firewall DESTROYED - countermeasures slowed %d%% for %ds" % [target_name, roundi((1.0 - max(0.05, FW_BREAK_SLOW - _mod(HackingMods.MOD_TYPE.FW_BREAK_SLOW))) * 100), int(_fw_down_time())])
	var cascade = int(round(integ_base * _mod(HackingMods.MOD_TYPE.FW_BREAK_INTEGRITY))) # Cascade
	if cascade > 0:
		integ_bar.value -= cascade
		_log("MOD", C_MOD, "Cascade: firewall collapse deals %d integrity" % cascade)
		if integ_bar.value <= 0.0:
			win()
			return
	_banner("FIREWALL DOWN", "enemy countermeasures -%d%% for %ds" % [roundi((1.0 - max(0.05, FW_BREAK_SLOW - _mod(HackingMods.MOD_TYPE.FW_BREAK_SLOW))) * 100), int(_fw_down_time())], C_FW, 0.9)
	_shake(target_card.panel, 7.0, 0.35)
	_flash(target_card.panel, Color(1.9, 1.5, 1.0), 0.5)
	_refresh_labels()
	_refresh_panels()

func _restore_firewall() -> void:
	firewall_down = false
	if HackingMods.has_mod(HackingMods.MOD_TYPE.FW_NO_REBOOT): # Firmware Brick: stays at 0 for the rest of the hack
		firewall_bar.value = 0
		_log("FW", C_FW, "firewall bricked - it won't reboot this hack (countermeasures back to full speed)")
		_refresh_panels()
		return
	_log("FW", C_FW, "firewall rebooting to %d - countermeasures back to full speed" % int(fw_start_value))
	fw_fresh = true # a new firewall: Handshake Exploit hits it again
	_fw_tween = create_tween()
	_fw_tween.tween_property(firewall_bar, "value", fw_start_value, FW_REFILL_TIME).set_ease(Tween.EASE_OUT)
	_flash(firewall_bar, Color(1.8, 1.6, 1.3), FW_REFILL_TIME)
	_refresh_labels()
	_refresh_panels()
#endregion

#region heat / state
## Heat plan: hacking heat grows with the location's tier like process heat and cooling do
const HEAT_BY_TIER := [1.0, 1.46, 2.08, 3.0, 7.0, 10.0]
func _heat_mult() -> float:
	var p = Stats.target_place(current_target)
	var t = Stats.hacking_targets.keys().find(p.location) + 1 if !p.is_empty() else 1
	return Stats.tier_heat(HEAT_BY_TIER, t)

func add_heat(amount: float):
	var hm = _heat_mult()
	if Stats.overheated:
		Stats.update_tempature(0.3 * hm)
		return
	if NEXT_HEAT_APPLICATION > 0:
		amount += NEXT_HEAT_APPLICATION
		NEXT_HEAT_APPLICATION = 0
	Stats.update_tempature(amount * hm)
	if Stats.overheated:
		var messages = "[color=#e24b4a]SYSTEM OVERHEATED - BANDWIDTH REGEN SLOWED[/color]\n"
		messages += "[color=#e24b4a]ENEMY COUNTERMEASURES INCREASED SIGNIFICANTLY[/color]\n"
		Signals.update_hack_console(messages)
		_update_state()

## logs + chips + effects when overclock / overheat starts or ends
func _update_state() -> void:
	var s = "overheat" if Stats.overheated else ("overclock" if Stats.overclocked else "")
	if s == _state:
		return
	var was = _state
	_state = s
	chip_overclock.visible = s == "overclock"
	chip_overheat.visible = s == "overheat"
	if s == "overclock":
		_log("SYS", C_OC, "OVERCLOCK active - bandwidth regen x%s (extra heat per action)" % _fmt(OVERCLOCK_BW_MULT))
		_flash(chip_overclock, Color(2, 2, 2), 0.5)
	elif s == "overheat":
		_log("HEAT", C_HEAT, "SYSTEM OVERHEATED - bandwidth regen x%s, countermeasures x2 until below 80°C" % _fmt(OVERHEAT_BW_MULT))
		_banner("OVERHEATED", "bandwidth regen x%s  ·  enemy speed x2" % _fmt(OVERHEAT_BW_MULT), C_HEAT, 1.2)
		_flash(self, Color(1.6, 0.75, 0.65), 0.8)
		_shake(header_card.panel, 6.0, 0.4)
	elif was == "overheat":
		_log("SYS", C_WIN, "system cooled below 80°C - bandwidth regen and enemy speed back to normal")
	elif was == "overclock":
		_log("SYS", C_DIM, "overclock ended")
	_refresh_panels()
#endregion

#region win / lose
func lose():
	bandwidth_timer.stop()
	is_hacking = false
	attacking = false
	defending = false
	firewall_down = false
	_log("LOSE", C_INTEG, "anonymity lost - you were traced, hack aborted")
	_banner("TRACED", "anonymity lost  ·  hack aborted", C_INTEG, 1.2)
	_flash(self, Color(1.7, 0.7, 0.7), 0.8)
	_shake(you_card.panel, 9.0, 0.45)
	update_status_label_badge("traced", C_INTEG)
	var messages = "[color=#e24b4a]ANONYMITY LOST - ABORTING HACK[/color]\n"
	if caches_gained > 0:
		messages += "[color=#e24b4a]Items lost[/color]\n"
		messages += "[color=#e24b4a]" + target_reward.name + " x" + str(caches_gained) + "[/color]"
	caches_gained = 0
	remove_mod_duration()
	Signals.update_hack_console(messages)
	await get_tree().create_timer(1.5).timeout
	Signals.hacking_ended()

func win():
	is_hacking = false
	attacking = false
	defending = false
	firewall_down = false
	if _fw_tween and _fw_tween.is_valid():
		_fw_tween.kill()
	firewall_bar.value = 0
	Tutorial.complete_event(Tutorial.TutorialEvent.HACK_STUDENT)
	if hack_total >= 2 and hack_index >= 2:
		Tutorial.complete_event(Tutorial.TutorialEvent.HACK_STUDENT_TWICE) # a run of 2+, second win

	caches_gained += target_reward_amount
	reward_amount += target_reward_amount
	Stats.record_win(current_target)
	Stats.record_usage(current_target, _hack_sql, _hack_spoof)
	remove_mod_duration()
	update_bottom_row()
	Exp.add_xp(Hacking, null, EXP_AMOUNT)
	Signals.update_hacking_header()

	if hacks_remaining > 0:
		hacks_remaining -= 1
	var more = (hacks_remaining == -1 or hacks_remaining > 0) and !stop_after_win
	_log("WIN", C_WIN, "%s breached  %s  %s" % [target_name, _c("+%d %s" % [target_reward_amount, target_reward.name], C_WIN), _c("+%d xp" % EXP_AMOUNT, C_DIM)])
	var sub = "+%d %s" % [target_reward_amount, target_reward.name]
	if hack_total > 1:
		sub += "  ·  hack %d of %d done" % [hack_index, hack_total]
	elif hack_total == -1:
		sub += "  ·  %d breached this run" % hack_index
	_banner("BREACHED", sub, C_WIN, 1.0)
	_flash(target_card.panel, Color(1.3, 1.9, 1.4), 0.7)
	_flash(yield_label, Color(2, 2, 2), 0.6)
	update_status_label_badge("breached", C_WIN)

	if more:
		# anonymity carries over between the fights of a run; Second Wind gives some back after each win
		if Upgrades.has("hacking.second_wind") and Stats.current_anon < Stats.max_anon:
			var before = Stats.current_anon
			Stats.current_anon = min(Stats.max_anon, Stats.current_anon + ceil(Stats.max_anon * SECOND_WIND_RESTORE))
			anon_bar.value = Stats.current_anon
			_log("SYS", C_SPOOF, "Second Wind: %s  (%d/%d)" % [_c("+%d anonymity" % int(Stats.current_anon - before), C_YOU), Stats.current_anon, Stats.max_anon])
		_log_rule()
		reset()
	else:
		_finish_hack()

## Ends the session after the last win: bank the rewards and signal that hacking has ended.
func _finish_hack():
	bandwidth_timer.stop()
	is_hacking = false
	attacking = false
	defending = false
	stop_hacking = true
	Signals.update_hack_console("\n\n[color=#4ec994]SUCCESSFULLY HACKED " + target_name + "[/color]")
	Signals.update_hack_console("[color=#4ec994]Gained " + target_reward.name + " x" + str(caches_gained) + "[/color]" + ("  [color=#888888](run ended early with 'kill -s')[/color]" if stop_after_win else "") + "\n\n")
	_grant_rewards()
	_log("SYS", C_SPOOF, "hack complete, disconnecting")
	await get_tree().create_timer(1.0).timeout
	Signals.hacking_ended()

func _notification(what: int) -> void:
	# closing the window mid-session: keep targets already beaten (saved by SaveManager's close handler)
	if what == NOTIFICATION_WM_CLOSE_REQUEST and caches_gained > 0:
		_grant_rewards()
		SaveManager.save_game()

func _grant_rewards():
	if caches_gained > 0:
		Inventory.add_resource(target_reward, caches_gained)
		caches_gained = 0

func reset():
	attack_bar.value = 0
	defense_bar.value = 0
	counter_bar.value = 0
	COMBAT_QUEUE.clear()
	_revealed = false
	_refresh_labels()
	await prepare()

func start_hack():
	is_hacking = true
	fw_fresh = true
	_hack_sql = 0
	_hack_spoof = 0
	hack_time = 0.0
	decoys_left = int(_mod(HackingMods.MOD_TYPE.IGNORE_COUNTERS))
	if HackingMods.has_mod(HackingMods.MOD_TYPE.EXPLOIT_FULL): # Zero Hour
		Exploits.charge = Exploits.CHARGE_MAX
	if _mod(HackingMods.MOD_TYPE.STEALTH_START) > 0:
		_log("MOD", C_MOD, "Silent Entry: unnoticed for %ds" % int(_mod(HackingMods.MOD_TYPE.STEALTH_START)))
	if Inventory.get_amount(offensive_item) > 0:
		attacking = true
	if Inventory.get_amount(defensive_item) > 0 and is_anon_below_healing_threshold():
		_engage_spoof("anonymity below %d%%" % roundi(Stats.healing_threshold_auto_start * 100))
	_update_state()

func kill_hack():
	var kept = caches_gained
	if kept > 0:
		Signals.update_hack_console("\n\n[color=#e0c068]HACK KILLED[/color]\n[color=#4ec994]Walked away with " + target_reward.name + " x" + str(kept) + "[/color]\n\n")
	else:
		Signals.update_hack_console("\n\n[color=#e0c068]HACK KILLED[/color]  [color=#888888](nothing breached this run)[/color]\n\n")
	end()
	remove_mod_duration()
	_grant_rewards()
	Signals.hacking_ended()

## 'kill -s': this hack plays out; a win banks it and ends the run instead of starting the next one
## (a loss still loses the run's caches, like any trace).
func kill_hack_safely():
	if stop_after_win:
		return
	stop_after_win = true
	_log("SYS", C_OC, "finishing this hack, then disconnecting  " + _c("('kill' stops now)", C_DIM))
	Signals.update_hack_console("[color=#e0c068]Finishing the current hack, then ending the run. 'kill' stops now.[/color]")
	update_status_label_badge("last hack", C_OC)

func end():
	_clear_effects()
	bandwidth_timer.stop()
	attacking = false
	defending = false
	is_hacking = false
	stop_hacking = true
	firewall_down = false
	reward_amount = 0
#endregion

#region prepare (access, intel, mods)
func _remove_required_resources():
	Inventory.remove_resource(requirements.item, requirements.amount)
	SaveManager.save_game() # spent payloads are saved right away: quitting mid-hack can't undo them
	_log("PAY", Compiling.SKILL.color, "%s x%d spent to gain access" % [requirements.item.name, requirements.amount])

func _has_requirements() -> bool:
	return Inventory.get_amount(requirements.item) >= requirements.amount

func prepare():
	if !_has_requirements():
		Stats.overclocked = false
		_log("SYS", C_INTEG, "unable to reach target - missing " + requirements.item.name)
		update_status_label_badge("no payload", C_INTEG)
		Signals.update_hack_console("[color=#ef9f27]Missing required resources to hack " + target_name + ", aborting.[/color]\n")
		if caches_gained > 0:
			Signals.update_hack_console("\n\n[color=#4ec994]SUCCESSFULLY HACKED " + target_name + "[/color]")
			Signals.update_hack_console("[color=#4ec994]Gained " + target_reward.name + " x" + str(caches_gained) + "[/color]\n\n")
		_grant_rewards() # bank the hacks already won (they used to be dropped here)
		await get_tree().create_timer(1.5).timeout
		Stats.overclocked = false
		Signals.hacking_ended()
		return

	hack_index += 1
	_update_sub_label()
	_clear_effects()
	_bw_warned = {}
	_revealed = false
	firewall_down = false
	chip_firewall.visible = false
	chip_intel.visible = false
	active_intel = {}
	ATTACK_AMOUNT = ATTACK_BASE + int(_mod(HackingMods.MOD_TYPE.DAMAGE)) # mods can expire between hacks
	update_status_label_badge("finding target", C_OC)
	_refresh_labels()
	_refresh_panels()

	_log("SYS", C_DIM, "locating " + target_name + "...")
	await get_tree().create_timer(1.0).timeout
	_log("SYS", C_TEXT, "target found")
	await get_tree().create_timer(0.3).timeout
	update_status_label_badge("gaining access", C_SPOOF)
	await get_tree().create_timer(0.6).timeout
	if stop_hacking:
		return
	update_bottom_row()
	_remove_required_resources()
	var intel = _apply_intel()
	Signals.update_hacking_header()
	await get_tree().create_timer(0.3).timeout
	_log("SYS", C_WIN, "access granted")

	# reveal the target at its real (pre-intel) stats
	_revealed = true
	integ_bar.max_value = integ_base
	firewall_bar.max_value = max(1, fw_base)
	integ_bar.value = 0
	firewall_bar.value = 0
	var tw = create_tween().set_parallel()
	tw.tween_property(integ_bar, "value", integ_base, 0.8)
	tw.tween_property(firewall_bar, "value", fw_base, 0.8)
	await tw.finished
	if stop_hacking:
		return

	# intel visibly doing its work
	if !intel.is_empty():
		await _show_intel(intel)
	# firewall reduction mod
	var fw_red = int(_mod(HackingMods.MOD_TYPE.FIREWALL_REDUCTION))
	var fw_now = FIREWALL_AMOUNT
	if fw_red > 0 and fw_now > 0:
		var after = max(0, fw_now - fw_red)
		_log("MOD", C_MOD, "%s: firewall %d -> %d" % [HackingMods.get_mod_name(HackingMods.MOD_TYPE.FIREWALL_REDUCTION), fw_now, after])
		_float(firewall_bar, "-%d MOD" % (fw_now - after), C_MOD, 15)
		_flash(firewall_bar, Color(2.0, 1.8, 1.0), 0.6)
		var t2 = create_tween()
		t2.tween_property(firewall_bar, "value", after, 0.5)
		await t2.finished
		fw_now = after
	fw_start_value = fw_now
	firewall_bar.value = fw_now
	_announce_mods()
	await get_tree().create_timer(0.3).timeout
	if stop_hacking:
		return
	_log("SYS", C_TEXT, "starting hack")
	update_status_label_badge("hacking", C_WIN)
	_refresh_labels()
	_refresh_panels()
	start_hack()

## Decoding intel: weakens this attempt's target stat and uses up one hack of intel.
## Returns {} or {stat, amount, hacks_left, before, after}.
func _apply_intel() -> Dictionary:
	# start from the target's real stats every attempt (intel only lasts its hacks)
	FIREWALL_AMOUNT = current_target.get("firewall", FIREWALL_AMOUNT)
	INTEGRITY_AMOUNT = current_target.get("integrity", INTEGRITY_AMOUNT)
	COUNTER_AMOUNT = current_target.get("counter", COUNTER_AMOUNT)
	COUNTER_SPEED = current_target.get("counter speed", COUNTER_SPEED)
	fw_base = FIREWALL_AMOUNT
	integ_base = INTEGRITY_AMOUNT
	var i = Decoding.use_intel(current_target)
	active_intel = i
	if i.is_empty():
		return {}
	# each stat has its own intel share (Decoding.intel_pcts: 2% steps up to 10%)
	var p: Dictionary = i.pcts
	i["integrity"] = [INTEGRITY_AMOUNT, max(1, int(round(INTEGRITY_AMOUNT * (1.0 - p.integrity))))]
	i["firewall"] = [FIREWALL_AMOUNT, max(0, int(round(FIREWALL_AMOUNT * (1.0 - p.firewall))))]
	i["counter"] = [COUNTER_AMOUNT, max(0, int(round(COUNTER_AMOUNT * (1.0 - p.counter))))]
	i["counter speed"] = [COUNTER_SPEED, max(0.1, COUNTER_SPEED * (1.0 - p["counter speed"]))]
	INTEGRITY_AMOUNT = i.integrity[1]
	FIREWALL_AMOUNT = i.firewall[1]
	COUNTER_AMOUNT = i.counter[1]
	COUNTER_SPEED = i["counter speed"][1]
	return i

## this attempt's intel on <stat>, in whole percent (0 without intel)
func _ipct(stat: String) -> int:
	return roundi(float(active_intel.get("pcts", {}).get(stat, 0.0)) * 100)

func _show_intel(i: Dictionary) -> void:
	var left = int(i.hacks_left)
	var label = chip_intel.get_meta("label")
	var pct = _ipct("integrity")
	label.text = "INTEL"
	chip_intel.visible = true
	_flash(chip_intel, Color(2, 2, 2), 0.6)
	_log("INTEL", C_INTEL, "Decoding intel weakens %s: integrity %s -> %s, firewall %s -> %s, counter %s -> %s dmg, counters %d%% slower  %s" % [target_name,
		_fmt(i.integrity[0]), _fmt(i.integrity[1]), _fmt(i.firewall[0]), _fmt(i.firewall[1]), _fmt(i.counter[0]), _fmt(i.counter[1]), _ipct("counter speed"),
		_c("(%d hack%s of intel left)" % [left, "" if left == 1 else "s"], C_DIM)])
	# drain both bars like a hit: max stays the real stat, current drops to the intel value
	var tw = create_tween().set_parallel()
	tw.tween_property(firewall_bar, "value", float(i.firewall[1]), 0.6)
	tw.tween_property(integ_bar, "value", float(i.integrity[1]), 0.6)
	var fw_cut = int(i.firewall[0]) - int(i.firewall[1])
	var in_cut = int(i.integrity[0]) - int(i.integrity[1])
	_float(firewall_bar, ("-%d INTEL" % fw_cut) if fw_cut > 0 else "INTEL", C_INTEL, 16)
	_flash(firewall_bar, Color(1.2, 2.0, 1.9), 0.7)
	if in_cut > 0:
		_float(integ_bar, "-%d INTEL" % in_cut, C_INTEL, 16)
		_flash(integ_bar, Color(1.2, 2.0, 1.9), 0.7)
	_refresh_panels()
	await tw.finished

## one log line + a gold flash on the panel each active mod boosts
func _announce_mods() -> void:
	for t in HackingMods.current_mods:
		if t == HackingMods.MOD_TYPE.FIREWALL_REDUCTION:
			continue
		var d = int(HackingMods.current_mods[t].get("duration", 0))
		var vt = HackingMods.get_mod_value_text(t, _mod(t))
		_log("MOD", C_MOD, "%s %s active  %s" % [HackingMods.get_mod_name(t), vt, _c("(%d hack%s left)" % [d, "" if d == 1 else "s"], C_DIM)])
		var card = _mod_card(t)
		if card:
			_flash(card, Color(1.7, 1.5, 0.9), 0.7)
			_float(card, "MOD " + vt, C_MOD, 12, 16.0)

func _mod_card(t) -> Control:
	var M = HackingMods.MOD_TYPE
	match t:
		M.DAMAGE, M.DAMAGE_PCT, M.EFFICIENCY, M.FIREWALL_DAMAGE, M.ATTACK_SPEED, M.SQL_BOOST, M.FW_OPENER:
			return sql_card.panel
		M.RESTORE:
			return spoof_card.panel
		M.BAND_RATE:
			return you_card.panel
		M.DAMAGE_REDUCTION, M.COUNTER_SLOW, M.COUNTER_RESET:
			return ctr_card.panel
		M.FIREWALL_REDUCTION:
			return target_card.panel
	return null
#endregion

#region panel text
func _refresh_labels() -> void:
	_on_anon_bar_value_changed(anon_bar.value)
	_on_band_bar_value_changed(band_bar.value)
	_on_integ_bar_value_changed(integ_bar.value)
	_on_firewall_bar_value_changed(firewall_bar.value)

func _on_anon_bar_value_changed(value):
	anon_row.value.text = "%d/%d" % [value, Stats.max_anon]

func _on_band_bar_value_changed(value):
	band_row.value.text = "%d/%d" % [value, band_bar.max_value]

func _on_integ_bar_value_changed(value):
	integ_row.value.text = ("%d/%d" % [value, integ_bar.max_value]) if _revealed else "--/--"

func _on_firewall_bar_value_changed(value):
	if !_revealed:
		fw_row.value.text = "--/--"
	elif firewall_down:
		fw_row.value.text = "DOWN"
	else:
		fw_row.value.text = "%d/%d" % [value, fw_base]

func _refresh_panels() -> void:
	if offensive_item == null or sql_card.is_empty():
		return
	var M = HackingMods.MOD_TYPE

	# SQL Injector
	sql_card.count.text = "x" + _short(Inventory.get_amount(offensive_item))
	sql_card.stats.text = "   ".join([
		_stat("DMG", str(int(round(ATTACK_AMOUNT * (1.0 + _mod(M.DAMAGE_PCT))))), C_MOD if (_mod(M.DAMAGE) > 0 or _mod(M.DAMAGE_PCT) > 0) else C_TEXT),
		_stat("FW", str(FIREWALL_DAMAGE + int(_mod(M.FIREWALL_DAMAGE))), C_MOD if _mod(M.FIREWALL_DAMAGE) > 0 else C_TEXT),
		_stat("CRIT", "%d%%" % roundi(_get_total_efficiency() * 100.0), C_MOD if _mod(M.EFFICIENCY) > 0 else C_TEXT),
		_stat("BW", "0" if bw_freeze_left > 0.0 else _fmt(_sql_cost()), C_EXP if (throttle_left > 0.0 or bw_freeze_left > 0.0) else (C_MOD if HackingMods.get_bandwidth_cost() > 0 else C_TEXT)),
		_stat("EVERY", _secs(100.0 / max(0.001, ATTACK_SPEED * (1.0 + _mod(M.ATTACK_SPEED) + _mod(M.SQL_BOOST)))), C_MOD if (_mod(M.ATTACK_SPEED) > 0 or _mod(M.SQL_BOOST) > 0) else C_TEXT)])
	var sql_mods = _mods_text([M.DAMAGE, M.DAMAGE_PCT, M.FIREWALL_DAMAGE, M.ATTACK_SPEED, M.SQL_BOOST, M.EFFICIENCY, M.FW_OPENER])
	if HackingMods.get_bandwidth_cost() > 0:
		sql_mods += ("\n" if sql_mods != "" else "") + _c("MOD bandwidth +%d per attack" % HackingMods.get_bandwidth_cost(), C_MOD) + _c("  · %d mod%s equipped" % [HackingMods.current_mods.size(), "" if HackingMods.current_mods.size() == 1 else "s"], C_DIM)
	_set_rtl(sql_card.mods, sql_mods)
	if Inventory.get_amount(offensive_item) <= 0:
		_set_state(sql_card, "out of SQL Injectors - 'kill' to abort", C_INTEG)
	elif _atk_waiting:
		_set_state(sql_card, "waiting for bandwidth (%s)" % _fmt(ATTACK_BW_COST), C_BAND)
	elif !is_hacking:
		_set_state(sql_card, "idle", C_DIM)
	else:
		_set_state(sql_card, "attacking", C_SQL)

	# Packet Spoof
	spoof_card.count.text = "x" + _short(Inventory.get_amount(defensive_item))
	spoof_card.stats.text = "   ".join([
		_stat("RESTORE", str(int((DEFEND_AMOUNT + int(ceil(Stats.max_anon * _mod(M.RESTORE) / 100.0))) * (float(Exploits.DEFS.booster_shot.mult) if spoof_boost_left > 0.0 else 1.0))), C_EXP if spoof_boost_left > 0.0 else (C_MOD if _mod(M.RESTORE) > 0 else C_TEXT)),
		_stat("BW", str(DEFEND_BW_COST), C_TEXT),
		_stat("EVERY", _secs(100.0 / max(0.001, DEFEND_SPEED)), C_TEXT)])
	_set_rtl(spoof_card.mods, _mods_text([M.RESTORE]))
	var th = roundi(Stats.healing_threshold_auto_start * 100)
	if Inventory.get_amount(defensive_item) <= 0:
		_set_state(spoof_card, "none left", C_INTEG)
	elif _def_waiting:
		_set_state(spoof_card, "waiting for bandwidth (%s)" % _fmt(DEFEND_BW_COST), C_BAND)
	elif defending:
		_set_state(spoof_card, "ACTIVE - restoring anonymity", C_SPOOF)
	else:
		_set_state(spoof_card, "standby - auto below %d%% anonymity ('spoof')" % th, C_DIM)

	# Countermeasures
	var reduce = int(_mod(M.DAMAGE_REDUCTION))
	var dmg_col = C_MOD if reduce > 0 else (C_INTEL if !active_intel.is_empty() else C_TEXT)
	var spd_col = C_TEXT
	if firewall_down:
		spd_col = C_FW
	elif Stats.overheated:
		spd_col = C_HEAT
	elif _mod(M.COUNTER_SLOW) > 0:
		spd_col = C_MOD
	elif !active_intel.is_empty():
		spd_col = C_INTEL
	var rate = _counter_rate() if is_hacking else COUNTER_SPEED / (1.0 + _mod(M.COUNTER_SLOW))
	ctr_card.stats.text = "   ".join([
		_stat("DMG", str(max(1, COUNTER_AMOUNT - reduce)) if _revealed else "--", dmg_col),
		_stat("EVERY", _secs(100.0 / max(0.001, rate)) if _revealed else "--", spd_col)])
	var ctr_mods = _mods_text([M.DAMAGE_REDUCTION, M.COUNTER_SLOW, M.COUNTER_RESET])
	if !active_intel.is_empty():
		ctr_mods += ("\n" if ctr_mods != "" else "") + _c("INTEL -%d%% dmg, -%d%% speed" % [_ipct("counter"), _ipct("counter speed")], C_INTEL)
	_set_rtl(ctr_card.mods, ctr_mods)
	if stun_left > 0.0:
		_set_state(ctr_card, "STUNNED %.1fs" % stun_left, C_EXP)
	elif firewall_down:
		_set_state(ctr_card, "SLOWED -%d%% (firewall down) %.1fs" % [roundi((1.0 - FW_BREAK_SLOW) * 100), fw_down_left], C_FW)
	elif !is_hacking:
		_set_state(ctr_card, "idle", C_DIM)
	elif Stats.overheated:
		_set_state(ctr_card, "x2 speed - you are overheated", C_HEAT)
	else:
		_set_state(ctr_card, "tracing you", C_CTR)

	# you / target tags
	var band_mod = _mod(M.BAND_RATE)
	var regen = "+%s/s" % _fmt_bw(_bw_rate() if is_hacking else (BANDWIDTH_RECOVERY_RATE + band_mod) / max(0.01, Hacking.bandwidth_recovery_speed))
	var band_tags = []
	if band_mod > 0:
		band_tags.append(_c("MOD +%s" % _fmt(band_mod), C_MOD))
	if is_hacking and Stats.overclocked:
		band_tags.append(_c("OVERCLOCK x%s" % _fmt(OVERCLOCK_BW_MULT), C_OC))
	elif is_hacking and Stats.overheated:
		band_tags.append(_c("OVERHEAT x%s" % _fmt(OVERHEAT_BW_MULT), C_HEAT))
	var regen_col = C_DIM
	if is_hacking and Stats.overclocked:
		regen_col = C_OC
	elif is_hacking and Stats.overheated:
		regen_col = C_HEAT
	elif band_mod > 0:
		regen_col = C_MOD
	band_tags.append(_c("regen " + regen, regen_col))
	_set_tag(band_row, "  ".join(band_tags))
	_set_tag(anon_row, _c("spoofing", C_SPOOF) if defending else _c("auto-spoof below %d%%" % th, C_DIM))
	_set_tag(integ_row, _c("INTEL -%d%%" % _ipct("integrity"), C_INTEL) if _ipct("integrity") > 0 else "")
	var fw_tags = []
	if firewall_down:
		fw_tags.append(_c("DOWN - reboot in %.1fs" % fw_down_left, C_FW))
	else:
		if _ipct("firewall") > 0:
			fw_tags.append(_c("INTEL -%d%%" % _ipct("firewall"), C_INTEL))
		if _mod(M.FIREWALL_REDUCTION) > 0:
			fw_tags.append(_c("MOD -%d" % int(_mod(M.FIREWALL_REDUCTION)), C_MOD))
	_set_tag(fw_row, "  ".join(fw_tags))
	_refresh_exploit_ui()
	chip_firewall.visible = firewall_down
	if firewall_down:
		chip_firewall.get_meta("label").text = "FIREWALL DOWN %ds" % ceili(fw_down_left)

func update_bottom_row():
	if reward_amount > 0:
		yield_label.text = target_reward.name + " x" + str(reward_amount)
		yield_hint.text = "lost if anonymity hits 0"
	else:
		yield_label.text = "nothing yet"
		yield_hint.text = "breach the target to bank its reward"

func _on_safe_exit_timer_timeout():
	end()
	_grant_rewards()
	Signals.hacking_ended()

func update_status_label_badge(text: String, color: Color):
	var sb: StyleBoxFlat = status_label_box.get_theme_stylebox("panel").duplicate()
	sb.bg_color = Color(color, 0.18)
	sb.border_color = color
	status_label_box.add_theme_stylebox_override("panel", sb)
	status_label.text = text
	status_label.add_theme_color_override("font_color", color)

## bandwidth now regenerates continuously in _process (kept for the scene's timer connection)
func _on_bandwidth_timer_timeout():
	pass

func is_anon_below_healing_threshold() -> bool:
	return Stats.current_anon * 100 <= Stats.max_anon * int(Stats.healing_threshold_auto_start * 100)

func _get_total_efficiency() -> float:
	var base = Hacking.SKILL.efficiency
	var mod_eff = _mod(HackingMods.MOD_TYPE.EFFICIENCY)
	return snapped(base + mod_eff, 0.01)

func remove_mod_duration():
	HackingMods.remove_duration()

func _mod(t) -> float:
	return float(HackingMods.get_mod_value(t)) if HackingMods.has_mod(t) else 0.0

func _mods_text(types: Array) -> String:
	var lines = []
	for t in types:
		if HackingMods.has_mod(t):
			var d = int(HackingMods.current_mods[t].get("duration", 0))
			lines.append(_c("MOD %s %s" % [HackingMods.get_mod_name(t), HackingMods.get_mod_value_text(t, _mod(t))], C_MOD)
				+ _c("  · %d hack%s · +%d SQL bw" % [d, "" if d == 1 else "s", HackingMods.get_mod_bandwidth_cost(t)], C_DIM))
	return "\n".join(lines)

## 1 decimal for bandwidth rates (1.5/s), whole numbers stay whole
static func _fmt_bw(v: float) -> String:
	return _fmt(snapped(v, 0.1))
#endregion

#region one-time items (Exploits)
## Uses <item> now. Returns "" on success or the reason it can't be used.
func use_exploit(item: ItemData, auto: bool = false) -> String:
	if !is_hacking or !_revealed:
		return "One-time items can only be used during a hack."
	if Inventory.get_amount(item) <= 0:
		return "You don't have any %s." % item.name
	if _exploit_lock > 0.0:
		return "Wait %.1fs before using another item." % _exploit_lock
	if !Exploits.can_afford(item):
		return "Not enough charge: %s needs %d, you have %d." % [item.name, int(Exploits.cost(item)), int(Exploits.charge)]
	var why = _exploit_blocked(item.exploit_id)
	if why != "":
		return why
	var d = Exploits.get_def(item)
	Exploits.set_charge(Exploits.charge - Exploits.cost(item))
	var kit_saved = Upgrades.has("hacking.exploit_kit") and randf() < EXPLOIT_KIT_CHANCE
	if !kit_saved:
		Inventory.remove_resource(item, 1)
	Signals.update_hacking_header()
	_exploit_lock = Exploits.LOCKOUT
	var result = _apply_exploit(item.exploit_id, d)
	_log("RUN", C_EXP, "%s%s: %s  %s%s" % ["auto " if auto else "", item.name, result,
		_c("(-%d charge · %d left)" % [int(Exploits.cost(item)), Inventory.get_amount(item)], C_DIM),
		("  " + _c("(Exploit Kit: not consumed)", C_EXP)) if kit_saved else ""])
	_banner(item.name.to_upper(), d.effect, C_EXP, 0.8)
	_flash(exp_row.bar, Color(2, 1.6, 2.2), 0.5)
	_refresh_panels()
	if integ_bar.value <= 0.0 and is_hacking:
		win()
	return ""

## "" if it would do something right now, otherwise why not (nothing is spent)
func _exploit_blocked(id: String) -> String:
	match id:
		"proxy_hop":
			if Stats.current_anon >= Stats.max_anon:
				return "Anonymity is already full."
		"redaction":
			if firewall_down or firewall_bar.value <= 0.0:
				return "The firewall is already down."
		"lag_spike":
			if counter_bar.value <= 0.0:
				return "The countermeasure bar is already empty."
	return ""

func _apply_exploit(id: String, d: Dictionary) -> String:
	match id:
		"proxy_hop":
			var heal = int(ceil(Stats.max_anon * float(d.amount)))
			var before = Stats.current_anon
			Stats.current_anon = min(Stats.max_anon, Stats.current_anon + heal)
			anon_bar.value = Stats.current_anon
			var got = int(Stats.current_anon - before)
			_float(anon_bar, "+%d" % got, C_EXP, 16)
			_flash(anon_bar, Color(1.8, 1.5, 2.0), 0.4)
			return "+%d anonymity (%d/%d)" % [got, Stats.current_anon, Stats.max_anon]
		"lag_spike":
			var was = counter_bar.value
			counter_bar.value = 0.0
			_float(counter_bar, "RESET", C_EXP, 14)
			return "countermeasure bar reset (was %d%%)" % int(was)
		"cease_desist":
			stun_left = max(stun_left, float(d.time))
			_float(counter_bar, "STUNNED", C_EXP, 14)
			return "countermeasures stopped for %ss" % _fmt(d.time)
		"throttle_patch":
			throttle_left = float(d.time)
			return "SQL Injector bandwidth %s -> %s for %ss" % [_fmt(ATTACK_BW_COST + HackingMods.get_bandwidth_cost()), _fmt(_sql_cost()), _fmt(d.time)]
		"slow_drip":
			poison_left = float(d.time)
			_poison_tick = 0.0
			return "-%s integrity/s and -%s firewall/s for %ss" % [_fmt(d.integrity), _fmt(d.firewall), _fmt(d.time)]
		"booster_shot":
			spoof_boost_left = float(d.time)
			_engage_spoof("Booster Shot")
			return "Packet Spoof x%s for %ss" % [_fmt(d.mult), _fmt(d.time)]
		"overdraft":
			bw_freeze_left = float(d.time)
			Hacking.current_bandwidth = float(MAX_BANDWIDTH)
			band_bar.value = Hacking.current_bandwidth
			_flash(band_bar, Color(1.8, 1.6, 2.2), 0.5)
			return "bandwidth full and frozen for %ss" % _fmt(d.time)
		"margin_call":
			var dmg = int(ceil(integ_bar.max_value * float(d.amount)))
			integ_bar.value -= dmg
			_float(integ_bar, "-%d" % dmg, C_EXP, 22)
			_shake(target_card.panel, 8.0, 0.35)
			_flash(integ_bar, Color(2, 1.6, 2.2), 0.5)
			return "-%d integrity (ignores firewall)" % dmg
		"zero_day":
			crits_left += int(d.count)
			return "next %d SQL Injector hits are critical" % crits_left
		"ghost_mode":
			ghost_left += int(d.count)
			return "next %d countermeasures miss" % ghost_left
		"redaction":
			_float(firewall_bar, "REDACTED", C_EXP, 14)
			_break_firewall(false)
			return "firewall destroyed"
		"blackout":
			stun_left = max(stun_left, float(d.time))
			counter_bar.value = 0.0
			_float(counter_bar, "BLACKOUT", C_EXP, 14)
			return "countermeasures stunned %ss and reset" % _fmt(d.time)
	return ""

func _tick_effects(delta: float) -> void:
	if stun_left > 0.0:
		stun_left -= delta
		if stun_left <= 0.0:
			_log("RUN", C_DIM, "countermeasures back online")
	if poison_left > 0.0:
		var d = Exploits.DEFS.slow_drip
		poison_left -= delta
		integ_bar.value -= float(d.integrity) * delta
		if !firewall_down and firewall_bar.value > 0.0 and !(_fw_tween and _fw_tween.is_running()):
			firewall_bar.value -= float(d.firewall) * delta
			if firewall_bar.value <= 0.0:
				_break_firewall(true)
		_poison_tick += delta
		if _poison_tick >= 1.0:
			_poison_tick -= 1.0
			_float(integ_bar, "-%s" % _fmt(d.integrity), C_EXP, 12, 16.0)
		if poison_left <= 0.0:
			_log("RUN", C_DIM, "Slow Drip ended")
		if integ_bar.value <= 0.0:
			win()
			return
	if throttle_left > 0.0:
		throttle_left -= delta
		if throttle_left <= 0.0:
			_log("RUN", C_DIM, "Throttle Patch ended - SQL Injector costs %s bandwidth again" % _fmt(_sql_cost()))
	if spoof_boost_left > 0.0:
		spoof_boost_left -= delta
		if spoof_boost_left <= 0.0:
			_log("RUN", C_DIM, "Booster Shot ended")
	if bw_freeze_left > 0.0:
		bw_freeze_left -= delta
		if bw_freeze_left <= 0.0:
			_log("RUN", C_DIM, "Overdraft ended - bandwidth regenerates normally")

func _clear_effects() -> void:
	stun_left = 0.0
	poison_left = 0.0
	throttle_left = 0.0
	spoof_boost_left = 0.0
	bw_freeze_left = 0.0
	crits_left = 0
	ghost_left = 0
	_exploit_lock = 0.0

## 'run auto <item>': fire it when it's affordable and would actually help
func _try_auto_exploit() -> void:
	if Exploits.auto_id == "" or !is_hacking or !_revealed or _exploit_lock > 0.0:
		return
	var item = Exploits.get_item(Exploits.auto_id)
	if item == null or Inventory.get_amount(item) <= 0 or !Exploits.can_afford(item):
		return
	if _auto_wants(item.exploit_id) and _exploit_blocked(item.exploit_id) == "":
		use_exploit(item, true)

func _auto_wants(id: String) -> bool:
	match id:
		"proxy_hop":
			return Stats.current_anon <= Stats.max_anon * 0.5
		"lag_spike", "cease_desist", "blackout":
			return counter_bar.value >= 60.0 and stun_left <= 0.0
		"ghost_mode":
			return counter_bar.value >= 60.0 and ghost_left == 0
		"throttle_patch":
			return _atk_waiting and throttle_left <= 0.0
		"overdraft":
			return (_atk_waiting or _def_waiting) and bw_freeze_left <= 0.0
		"booster_shot":
			return defending and spoof_boost_left <= 0.0
		"slow_drip":
			return poison_left <= 0.0
		"zero_day":
			return crits_left == 0
		"redaction":
			return !firewall_down and firewall_bar.value > 0.0
	return true

## EXPLOIT bar, its tag, and one header chip per active effect
func _refresh_exploit_ui() -> void:
	if exp_row.is_empty():
		return
	exp_row.bar.value = Exploits.charge
	exp_row.value.text = "%d/%d" % [int(Exploits.charge), int(Exploits.CHARGE_MAX)]
	var cheapest = Exploits.cheapest_owned_cost()
	var ready = cheapest >= 0.0 and Exploits.charge >= cheapest
	var tag = ""
	if Exploits.auto_id != "":
		tag = _c("auto: " + Exploits.get_item(Exploits.auto_id).name, C_EXP)
	elif cheapest < 0.0:
		tag = _c("no one-time items", C_DIM)
	elif ready:
		tag = _c("READY - 'run'", C_EXP)
	else:
		tag = _c("next item at %d" % int(cheapest), C_DIM)
	_set_tag(exp_row, tag)
	if ready and !_exp_ready and is_hacking:
		_flash(exp_row.bar, Color(2.2, 1.7, 2.4), 0.6)
		_float(exp_row.bar, "READY", C_EXP, 11, 14.0)
	_exp_ready = ready
	_effect_chip("stun", "STUNNED %ds" % ceili(stun_left), stun_left > 0.0)
	_effect_chip("poison", "SLOW DRIP %ds" % ceili(poison_left), poison_left > 0.0)
	_effect_chip("throttle", "THROTTLE %ds" % ceili(throttle_left), throttle_left > 0.0)
	_effect_chip("boost", "SPOOF x2 %ds" % ceili(spoof_boost_left), spoof_boost_left > 0.0)
	_effect_chip("freeze", "BW FROZEN %ds" % ceili(bw_freeze_left), bw_freeze_left > 0.0)
	_effect_chip("crit", "CRIT x%d" % crits_left, crits_left > 0)
	_effect_chip("ghost", "GHOST x%d" % ghost_left, ghost_left > 0)

func _effect_chip(key: String, text: String, on: bool) -> void:
	if !_effect_chips.has(key):
		if !on:
			return
		var c = _chip(header_card.head, text, C_EXP)
		header_card.head.move_child(c, status_label_box.get_index())
		_effect_chips[key] = c
	var chip: PanelContainer = _effect_chips[key]
	if on and !chip.visible:
		_flash(chip, Color(2, 2, 2), 0.4)
	chip.visible = on
	chip.get_meta("label").text = text
#endregion

#region log
func _log(tag: String, color: Color, text: String) -> void:
	if log_rtl == null:
		return
	if log_rtl.get_paragraph_count() > LOG_MAX_LINES:
		log_rtl.remove_paragraph(0)
	var line = "%s  %s %s" % [_c("%6.1f" % fight_time, C_DIM.darkened(0.25)), _c("%-5s" % tag, color), text]
	log_rtl.append_text(line if _log_empty else "\n" + line)
	_log_empty = false

func _log_rule() -> void:
	if log_rtl and !_log_empty:
		log_rtl.append_text("\n" + _c("-".repeat(60), C_BORDER.lightened(0.2)))

## kept for older callers
func _update_info_panel(message: String, color: Color):
	_log("SYS", color, message)
#endregion

#region effects
## rising number over a control ("-12", "+5", "CRIT -24")
func _float(anchor: Control, text: String, color: Color, size: int = 14, rise: float = 26.0) -> void:
	if anchor == null or !anchor.is_visible_in_tree():
		return
	var l := _label(text, size, color)
	l.top_level = true
	l.z_index = 20
	l.add_theme_color_override("font_outline_color", C_BG)
	l.add_theme_constant_override("outline_size", 5)
	add_child(l)
	var ms = l.get_combined_minimum_size()
	var y = -ms.y * 0.6 if !(anchor is PanelContainer) else anchor.size.y * 0.55 - ms.y * 0.5 # cards: pop inside the card
	var start = anchor.global_position + Vector2(anchor.size.x * randf_range(0.35, 0.8) - ms.x * 0.5, y)
	l.global_position = start
	l.pivot_offset = ms * 0.5
	l.scale = Vector2(1.3, 1.3)
	var tw = l.create_tween().set_parallel()
	tw.tween_property(l, "scale", Vector2.ONE, 0.15)
	tw.tween_property(l, "global_position:y", start.y - rise, 0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(l, "modulate:a", 0.0, 0.4).set_delay(0.55)
	tw.chain().tween_callback(l.queue_free)

## brief over-bright tint that fades back (modulate > 1 brightens)
func _flash(node: CanvasItem, color: Color, time: float = 0.3) -> void:
	if node == null:
		return
	if node.has_meta("flash_tw"):
		var old = node.get_meta("flash_tw")
		if old is Tween and old.is_valid():
			old.kill()
	node.modulate = color
	var tw = node.create_tween()
	tw.tween_property(node, "modulate", Color.WHITE, time).set_ease(Tween.EASE_OUT)
	node.set_meta("flash_tw", tw)

func _shake(node: Control, strength: float = 4.0, time: float = 0.25) -> void:
	if node == null or node.has_meta("shaking"):
		return
	node.set_meta("shaking", true)
	var base = node.position
	var tw = node.create_tween()
	tw.tween_method(_shake_step.bind(node, base, strength), 0.0, 1.0, time)
	tw.tween_callback(_shake_end.bind(node, base))

func _shake_step(t: float, node: Control, base: Vector2, strength: float) -> void:
	node.position = base + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * (1.0 - t)

func _shake_end(node: Control, base: Vector2) -> void:
	node.position = base
	node.remove_meta("shaking")
	var p = node.get_parent()
	if p is Container:
		p.queue_sort()

## big centered call-out for the moments that matter (breach, firewall down, overheat, traced)
func _banner(title: String, sub: String, color: Color, hold: float = 1.0) -> void:
	if !is_visible_in_tree():
		return
	if is_instance_valid(_banner_node):
		_banner_node.queue_free()
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(C_BG, 0.95)
	sb.border_color = color
	sb.set_border_width_all(2)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 10
	sb.content_margin_bottom = 12
	p.add_theme_stylebox_override("panel", sb)
	p.top_level = true
	p.z_index = 30
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	p.add_child(box)
	var t := _label(title, 26, color)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	if sub != "":
		var s := _label(sub, 12, C_TEXT)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(s)
	add_child(p)
	_banner_node = p
	var sz = p.get_combined_minimum_size()
	p.size = sz
	var r = get_global_rect()
	p.global_position = r.position + Vector2((r.size.x - sz.x) * 0.5, r.size.y * 0.30 - sz.y * 0.5)
	p.pivot_offset = sz * 0.5
	p.scale = Vector2(1.4, 1.4)
	p.modulate.a = 0.0
	var tw = p.create_tween()
	tw.set_parallel()
	tw.tween_property(p, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(p, "modulate:a", 1.0, 0.1)
	tw.chain().tween_interval(hold)
	tw.chain().tween_property(p, "modulate:a", 0.0, 0.35)
	tw.chain().tween_callback(p.queue_free)
#endregion

#region ui build
func _build_ui() -> void:
	add_theme_constant_override("separation", 8)

	# header: target name, place, state chips, status pill
	header_card = _card(self, "", C_YOU)
	target_name_label = header_card.title
	target_name_label.add_theme_font_size_override("font_size", 20)
	target_name_label.add_theme_color_override("font_color", C_TEXT)
	sub_label = _label("", 12, C_DIM)
	sub_label.size_flags_vertical = Control.SIZE_SHRINK_END
	header_card.head.add_child(sub_label)
	header_card.head.move_child(sub_label, 1)
	header_card.head.add_theme_constant_override("separation", 10)
	chip_intel = _chip(header_card.head, "INTEL", C_INTEL)
	chip_firewall = _chip(header_card.head, "FIREWALL DOWN", C_FW)
	chip_overclock = _chip(header_card.head, "OVERCLOCK x2 BW", C_OC)
	chip_overheat = _chip(header_card.head, "OVERHEATED", C_HEAT)
	status_label_box = _chip(header_card.head, "", C_OC)
	status_label_box.visible = true
	status_label = status_label_box.get_meta("label")
	status_label.add_theme_font_size_override("font_size", 12)

	# you vs target
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 8)
	add_child(stats)
	you_card = _card(stats, "YOU", C_YOU)
	target_card = _card(stats, "TARGET", C_INTEG)
	anon_row = _stat_row(you_card.body, "ANONYMITY", C_YOU, 14)
	band_row = _stat_row(you_card.body, "BANDWIDTH", C_BAND, 10)
	exp_row = _stat_row(you_card.body, "EXPLOIT", C_EXP, 6)
	exp_row.bar.max_value = Exploits.CHARGE_MAX
	Exploits.charge_changed.connect(_refresh_exploit_ui)
	integ_row = _stat_row(target_card.body, "INTEGRITY", C_INTEG, 14)
	fw_row = _stat_row(target_card.body, "FIREWALL", C_FW, 10)
	anon_bar = anon_row.bar
	band_bar = band_row.bar
	integ_bar = integ_row.bar
	firewall_bar = fw_row.bar
	anon_bar.value_changed.connect(_on_anon_bar_value_changed)
	band_bar.value_changed.connect(_on_band_bar_value_changed)
	integ_bar.value_changed.connect(_on_integ_bar_value_changed)
	firewall_bar.value_changed.connect(_on_firewall_bar_value_changed)

	# actions
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 8)
	add_child(acts)
	sql_card = _action_card(acts, "SQL INJECTOR", C_SQL)
	spoof_card = _action_card(acts, "PACKET SPOOF", C_SPOOF)
	ctr_card = _action_card(acts, "COUNTERMEASURES", C_CTR)
	attack_bar = sql_card.bar
	defense_bar = spoof_card.bar
	counter_bar = ctr_card.bar

	# combat log
	var log_card = _card(self, "COMBAT LOG", C_DIM)
	log_card.panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_card.body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var legend = _rtl(11)
	legend.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	legend.text = "[right]%s  %s  %s  %s  %s  %s  %s[/right]" % [_c("ATK", C_SQL), _c("DEF", C_SPOOF), _c("CTR", C_CTR), _c("FW", C_FW), _c("MOD", C_MOD), _c("INTEL", C_INTEL), _c("RUN", C_EXP)]
	log_card.head.add_child(legend)
	log_rtl = RichTextLabel.new()
	log_rtl.bbcode_enabled = true
	log_rtl.scroll_following = true
	log_rtl.selection_enabled = false
	log_rtl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_rtl.add_theme_font_size_override("normal_font_size", 12)
	log_rtl.add_theme_constant_override("line_separation", 3)
	log_card.body.add_child(log_rtl)

	# yield
	var y = _card(self, "YIELD", C_WIN)
	yield_label = _label("", 13, C_TEXT)
	y.head.add_child(yield_label)
	y.head.move_child(yield_label, 1)
	y.head.add_theme_constant_override("separation", 12)
	yield_hint = _label("", 11, C_DIM)
	y.head.add_child(yield_hint)

func _card(parent: Control, title: String, accent: Color) -> Dictionary:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_BG
	sb.border_color = C_BORDER
	sb.set_border_width_all(1)
	sb.border_width_top = 2
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", sb)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.set_meta("accent", accent)
	p.draw.connect(func(): p.draw_rect(Rect2(0, 0, p.size.x, 2), p.get_meta("accent")))
	parent.add_child(p)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 5)
	p.add_child(body)
	var head := HBoxContainer.new()
	body.add_child(head)
	var t := _label(title, 12, accent)
	head.add_child(t)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	return {"panel": p, "body": body, "head": head, "title": t}

func _action_card(parent: Control, title: String, accent: Color) -> Dictionary:
	var c = _card(parent, title, accent)
	c.panel.size_flags_stretch_ratio = 1.0
	c.panel.custom_minimum_size.x = 150
	var count = _label("", 13, C_TEXT)
	c.head.add_child(count)
	c["count"] = count
	c["bar"] = _bar(c.body, accent, 10)
	var st = _rtl(12)
	c.body.add_child(st)
	c["stats"] = st
	var md = _rtl(11)
	md.visible = false
	c.body.add_child(md)
	c["mods"] = md
	var state = _label("", 11, C_DIM)
	state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	c.body.add_child(state)
	c["state"] = state
	return c

func _stat_row(parent: Control, name: String, color: Color, height: float) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var n := _label(name, 11, C_DIM)
	n.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(n)
	var tag := _rtl(11)
	tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(tag)
	var v := _label("--", 15, C_TEXT)
	row.add_child(v)
	var bar := _bar(parent, color, height)
	return {"name": n, "tag": tag, "value": v, "bar": bar}

func _bar(parent: Control, color: Color, height: float) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.step = 0.001
	b.max_value = 100
	b.custom_minimum_size.y = height
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.06)
	var fg := StyleBoxFlat.new()
	fg.bg_color = color
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	parent.add_child(b)
	return b

func _chip(parent: Control, text: String, color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color, 0.16)
	sb.border_color = color
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 7
	sb.content_margin_right = 7
	sb.content_margin_top = 1
	sb.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", sb)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var l := _label(text, 11, color)
	p.add_child(l)
	p.set_meta("label", l)
	p.visible = false
	parent.add_child(p)
	return p

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _rtl(size: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_font_size_override("normal_font_size", size)
	return r

func _set_rtl(r: RichTextLabel, text: String) -> void:
	r.text = text
	r.visible = text != ""

func _set_tag(row: Dictionary, bb: String) -> void:
	row.tag.text = "[right]" + bb + "[/right]" if bb != "" else ""

func _set_state(card: Dictionary, text: String, color: Color) -> void:
	card.state.text = text
	card.state.add_theme_color_override("font_color", color)

func _stat(name: String, value: String, color: Color) -> String:
	return _c(name, C_DIM) + " " + _c(value, color)

static func _c(text: String, color: Color) -> String:
	return "[color=#%s]%s[/color]" % [color.to_html(false), text]

static func _secs(s: float) -> String:
	return ("%.1fs" % s) if s < 100 else ("%ds" % int(s))

static func _fmt(v) -> String:
	var f = float(v)
	return str(int(round(f))) if is_equal_approx(f, round(f)) else "%.1f" % f

static func _short(n: int) -> String:
	if n >= 1000000:
		return "%.1fm" % (n / 1000000.0)
	if n >= 10000:
		return "%.1fk" % (n / 1000.0)
	return str(n)
#endregion
