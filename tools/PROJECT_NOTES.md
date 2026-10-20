# IdleOS — project notes for a fresh session

Read this first. It covers how we work, how to test, the upgrade system, and what's left.
Last updated: 2026-10-18, after the Phishing upgrade step.

## Demo branch: demo-nextfest (Steam Next Fest demo, live 2026-10-19)
- The live demo is built from `demo-nextfest`. Demo hotfixes go there (export + upload to the demo app); if the
  bug is shared, fix it on cdd too. The demo cut lives in `scripts/demo_rules.gd` (DemoRules, demo branch only):
  level cap 10, School only (Student + Student Hard), Tier 1 slots [1, 4, 6] per wired skill and [1, 2, 3] for
  System, upload goal 100 basics / 5 Parents credit cards, 2 mod slots, 'wishlist', the send-off on the School
  goal. Its call sites are marked DEMO. Don't merge demo-nextfest into cdd (it would bring the cut with it).
- **Ported to cdd on 2026-10-19** (everything shared from the demo playtest round): intro objective line;
  welcome goal statement (demo_welcome_message, without the demo lines); tutorial rework (VM step right after
  'ls logs' with a free VM Mining token, overheating on the mine-35 step, cd hints, VM tip on the parse step,
  +N packaged in UPLOADS / 'unpack', side-panel track text, new tutorial-complete text); packaging needs an
  amount until the tutorial is done; clearer package header; 'upload -a'; '-h' PROGRESS section; info table
  order + efficiency list only for unlocked processes; type_text into a given label.
- **Save version 2 + tutorial reset** (also on cdd): SaveManager.SAVE_VERSION = 2 + `loaded_version`. A save
  below 2 with tutorial progress gets a one-time WELCOME BACK note; `tutorial reset` / `tutorial -r` clears the
  checklist (steps a save can't redo are auto-checked, `upload_baseline` ignores earlier uploads);
  `_complete_skipped_new_steps` only runs for version < 2. Demo saves carry over to the full game, so keep
  reading version 2 saves the same way (bump the version only with a migration in `_migrate_if_needed`).
- The dev 'add <item>' / 'rm <item>' commands stay on cdd behind `idle_os_2.DEV_ITEM_COMMANDS` (turn off before
  release; the demo removed them).
- Tests from the demo branch are in tools/tests: tutreset, tutreset2, oldsave (+ olddemo_save.json, a save from
  the Oct 8 demo), notes_test, playtest. demotest and sendoff are demo-only (they use DemoRules / the send-off).

## Working conventions (from Josh)
- Godot 4.4 project. On the linked computer it lives at `~/OneDrive/Documents/idle-os-prototype`;
  in the device shell (`device_bash`) that's `$HOME/mnt/idle-os-prototype`.
- **Never delete.** Don't ask for delete permission on the project folder (declined before). Move
  unwanted files into `_to_delete/` instead (backups go in `_to_delete/backup/`).
- **Josh commits himself.** Don't run git commits.
- Leave `classes/` alone, except `classes/CacheDecrypting.gd`, which is in use.
- Never run `pkill -f Godot_v4` (it kills the shell).
- Testing flags stay ON while developing: `idle_os_2.DEV_ITEM_COMMANDS := true` (add/rm), `Exp.DEV_MAX_ALL := true` (all skills/processes level 99,
  unlocked) and `Upgrades.DEV_UNLOCK_ALL_TIERS := true`. Turn them off before release. `Tutorial.DEV_ALWAYS_SHOW_INTRO` (intro every launch) is OFF on cdd since 2026-10-19 (Josh).
- Josh dislikes walls of text in the terminal: collapse/hide anything not actionable.
- Big changes: brainstorm/plan with him first, then implement **one skill at a time** so he can test.

## Testing setup (device shell)
- **The device shell's home can be fresh in a new session** (Godot, `$HOME/new` and the old test scripts
  were gone on 2026-10-18). Rebuild: download
  `https://github.com/godotengine/godot/releases/download/4.4.1-stable/Godot_v4.4.1-stable_linux.x86_64.zip`
  to `$HOME`, unzip with python `zipfile`, `chmod +x`; `cp -r` the project to `$HOME/new` (drop `.git`,
  `_to_delete`). Test scripts are now kept in the project at `tools/tests/` (has `.gdignore`, so Godot
  skips them): copy them to `$HOME/new` root to run. The older ones (`cmd_test`, `vm_test`, `sweep`,
  `minetest`, `parsetest`, `cracktest`, ...) were lost and are not in `tools/tests` yet.
- Godot binary: `$HOME/Godot_v4.4.1-stable_linux.x86_64`.
- Test copy of the project: `$HOME/new`. **Copy every edited file there before running tests**
  (`cp <file> $HOME/new/<file>`). Test scripts (`*.gd` + `*.tscn` pairs) live in `$HOME/new` root.
- Import/compile check (must show no SCRIPT ERROR / Parse Error):
  `timeout 150 ./Godot_v4.4.1-stable_linux.x86_64 --headless --path new --import`
- Clear the save between runs: `rm -rf ~/.local/share/IdleOS_Demo`.
- Headless test: `./Godot... --headless --path new res://<test>.tscn`.
  Renders: `xvfb-run -a ./Godot... --path new res://<test>.tscn --rendering-driver opengl3`,
  save PNGs to `_to_delete/screens/`, crop with PIL, stage with `device_stage_files`, then Read.
- Each device call is limited to ~180 s and background jobs die when the call ends: split long runs.
  Use `Engine.time_scale` to speed up timers.
- New test scene from a script: `sed 's/fshot2/<name>/' fshot2.tscn > <name>.tscn`.
- **Regressions to run after changes:** `cmd_test`, `vm_test`, intro
  (`--headless --path new --quit-after 1500`), sweeps `SWEEP=<skill> res://sweep.tscn`
  (mining, parsing, cracking, matching, phishing, decoding, compiling; ~85 s each) and
  `SWEEP=hack` (~170 s). All should print 0 SCRIPT ERROR and `>>> done`.
- `matchtest` (Matching upgrade checks; `PART=1|2|3` splits it to fit 180 s) and `cmdmatch` (drives the
  real terminal: `apt matching`, `cd matching`, `match -cred`, modifiers, `info matching`) are in `tools/tests/`.
- Useful existing tests (lost, see above): `minetest`, `parsetest`, `cracktest` (per-skill upgrade checks),
  `apttest`, `bulktest`, `bartest` (apt flows), `exptest` (one-time items), `fshot2/fshot3` (fight renders).

## Godot gotchas we hit
- Autoload order matters; use `call_deferred` / connect in `_ready` when a later autoload is needed.
- A script cycle through `class_name ItemData` (item_resource.gd -> HackingMods) breaks loading:
  HackingMods looks up Upgrades at runtime (`get_node_or_null("/root/Upgrades")`) for this reason.
- Containers reset child scale/position; use `tween_method` for per-frame transforms.
- `match` inside a lambda is a parse error; typed vars need explicit types when inferring from untyped values.
- Static functions can't read non-static members.
- Main terminal: `add_line` is queued (0.03 s/line) and every 20 lines starts a new text block and
  clears `lines`. To update a line in place use `_add_live_line()` (returns a safe index) + `set_line`.
- Glyphs ▾ ▸ █ are not in the font; use bgcolor spaces for bars. ▲ ─ │ ├ └ ═ work.

## Upgrade system (apt) — the big recent change
- Design + balance live in `tools/upgrades/idleos_upgrades.xlsx` (tabs: All Upgrades, Inputs, Summary,
  Max Anonymity, Tier Totals, Rare Demand). It is generated by `tools/upgrades/gen_upgrades.py`
  (the design source: slot definitions per group) and exported to the game with
  `python3 tools/upgrades/export_upgrades.py tools/upgrades/idleos_upgrades.xlsx data/upgrades.json`
  (run LibreOffice recalc on the xlsx first so formula costs have values).
- Model: 9 groups (System + 8 skills) x 6 tiers x 10 installs; each install +0.1 version (v0.0 -> v6.0).
  A tier opens when its location unlocks AND the previous tier's 10 installs are done. The 10th install
  of a tier is the MAJOR RELEASE (banner + changelog). Costs = 2 h of solo running at Tier 1 x1.1 per
  tier, paid in the skill's own output; capstones also cost 2 of a tier rare item.
- `singletons/Upgrades.gd` loads `data/upgrades.json` (in `_init`). API: `get_package_info(id).current`,
  `cur(id)` (track total), `has(id)` (capstone installed), `install_block_reason`, `install`,
  `plan_bulk`, `version_text(group)`, `apply_effects()`. `WIRED_GROUPS` lists groups whose effects are
  implemented (others show "coming soon" and can't install). `LEGACY_DEFAULTS` covers ids old code still
  reads (hacking.max_anonymity=100, hacking.recursive_hacking=true, hacking.overclock=true).
- apt commands (idle_os_2.gd + ContextCommands.gd): `apt`, `apt <skill>` (working tier table, finished
  tiers collapsed, later tiers hidden), `apt <package>`, `apt install <package>` (y/n + install
  sequence), `apt install <skill>` / `apt install all` (bulk, one confirmation).
- Versions show on header cards (right footer) and the SYSTEM side panel title.
- Old saves start at v0.0 (save format 2).
- **Modifier commands** (capstones): each skill defines `MODIFIERS` (command, name, package, speed,
  heat, effect) and `COOL_PACKAGE` in its singleton. `BaseTerminal.modifier` holds the active one;
  `get_step_time` divides by its speed, `get_heat` multiplies by its heat (removed by the cool capstone;
  overclock heat also drops to normal heat when cooled) and applies `<skill>.heat_sink`.
  `idle_os_2._handle_modifier_command` handles `<cmd>` / `<cmd> -kill`, one at a time incl. overclock,
  main-terminal process only. The `info <skill>` MODIFIERS box lists overclock + MODIFIERS.
- **VM tokens roll on time, not per cycle:** chance = process "vm token chance" x (this cycle's real
  seconds / base-speed cycle seconds), x2 for the token capstone, x2 for the prospect-style modifier.
- **Survey** (every skill): half output (coin flip on odd amounts), double XP.

### Done
- System: all 10 per tier + capstones (Overheat Fan, Idle Cooling, Liquid Cooling, Load Balancer,
  Watchdog, Server Rack). Defrag 10/40 min -> 25/25. Thermal Paste raises the overheat clear temp
  (80 -> 92) and the overclock limit follows it. Background Services stores the offline cap (hours) —
  not used until offline progression exists.
- Mining: speed, efficiency (+ level rate 0.08 -> 0.035), heat sink, vein detection, pipelining,
  Deep Core, modifiers sift/prospect/survey, Cool Bits.
- Parsing: speed, efficiency, rows, pattern cache, fast skip, Token Sniffer, modifiers
  plaintext/deep-read/survey, Cold Cache.
- Cracking: speed, efficiency, recovery, dictionary, rainbow tables, Keyring, modifiers
  crossref/analyze/survey, Cryo Rig.
- Matching: speed, efficiency, recovery (rolled when inputs are consumed: the pair is kept), Auto-Correlate
  (every step of a match x (1 - head start)), Hot Cache (streak per run, shown in the "confirmation
  algorithm" subtitle, resets on stop), Rolodex, modifiers prebuild/correlate/survey (title shows
  "MATCHING ENGINE · <MOD>"), Cold Storage. VM tokens now roll on time (were flat per match).
  Measured at L99: 17.2 s/match base -> 0.46 s all tracks max; tokens/hour 2.14 unchanged by speed.
- **Fixed: first-process efficiency compounding every launch** (Logs 26197%, Spear 1748%...). Skills'
  `load_data` wrote the legacy `<process>_efficiency` key before `Exp.processes_load_data` snapshotted the
  code base (the load runs in idle_os_2 `_ready`, before Exp's deferred snapshot). Legacy lines removed;
  efficiency is always rebuilt from level, so old saves heal on load. Test: `tools/tests/efftest`.
- **Phishing processes** (before its upgrades): order is Spear (T1, L1), Whaling (T2, L15), Smish (T3, L30),
  Trap (T4, L45), Mod (UTILITY, L5). Each process has a "style" (lines / whale / smish / trap) that
  `phishing_line.gd` branches on; the terminal runs 1 line for whale/smish/trap.
  - Whaling: every line on one whale, reel = 120 s / lines; bundle 10-24 (85% SQL / 15% spoof); 5% one-time
    exploit item from an unlocked tier. ~1.3x Spear's items/hour at L99.
  - Smish: blast of 8 texts per line, replies at random times over 60 s; reply chance 3% (+0.05%/lvl);
    each reply = 1 intel point (`Decoding.add_intel_point`) on `target=<target>` or a random unlocked
    target that isn't maxed; all maxed -> 1 SQL Injector. `parse_bait` now also parses `target=`.
  - Trap: 60 s setup in the terminal, then fills over 45 min of real (unix) time, also offline. State in
    `Phishing.trap` (saved). `trap` / `trap collect` work from any context (also `phish -trap collect`).
    Full haul 70 SQL + 15 spoofs; rare rolls only when full: exploit item at eff, hacking mod at eff/5.
    Early collect = proportional basics, no rares. Not allowed in a VM, excluded from contracts.
    Right panel row under PROCESS: `scripts/trap_status.gd` (code-built by system_dock).
  - Mod pool = every hacking mod item whose `tier` is unlocked (`Phishing.mod_pool()`): new mods only need
    a `.tres` with `hacking_mod_item = true` and the right `tier`.
  - Bait: 10 Mining items per cast (whale cast / smish blast / trap), doubles what that cast brings in, and
    still multiplies bite chance x1.10 (Logs) .. x1.35 (Databases). Warns if you have fewer than 10.
  - VM tokens: bonus on top of the catch. "vm token chance" per attempt at base speed (+ "vm token per" for
    info: 0.33% per cast, 5% per whale, 4% per blast, 100% on a full trap), scaled by time spent / base attempt
    and by 3 / lines for Spear/Mod, so ~2/hr regardless of speed or lines. Info now shows each process's real
    "vm token chance" for every skill (it was hardcoded "1%").
  - Trap efficiency 15% -> 25% at L99 (rate 0.0010204); bait multiplies the rare chance on top.
  - Display commands use (optional) not [optional]: `strip_bbcode` ate the brackets and broke table padding.
  - Upgrade tiers are location tiers for every skill (the sheet's 6 Phishing tiers are correct).
- **Phishing upgrades** (WIRED): PhishingTerminal helpers do the work for every style:
  `step_seconds()` (speed + modifier speed on normal/overclock, Quick Hook on reels: Spear/Mod download,
  Whaling reel, Smish reply window; overheat fixed), `wait_seconds()`, `catch_amount()` (bait x2, Chum x2,
  Survey half), `catch_xp()`, `roll_lure()`, `take_bait()` (Bait Recycling), `modifier_block_reason()`
  (no modifiers while setting a Trap; idle_os_2 checks it). Efficiency is RELATIVE:
  `Phishing.get_efficiency(p)` = level efficiency x (1 + track), +20% of its own at max (Spear 59% -> 71%,
  Trap 25% -> 30%). Bait Power adds to the bait multiplier. Speed applies to every step except Trap's fill.
  Level rate 0.005 -> 0.003 (Spear, Whaling). Capstones: overclock, tackle_box (token x2, also Trap),
  lure/chum/survey modifiers, deep_water (COOL_PACKAGE). Measured L99: Spear 400/h base, ~9,000/h all
  tracks max (3 -> 9 lines); Whaling 490/h -> ~7,700/h.
  - Sheet: Phishing wording updated in gen_upgrades.py; Inputs rate stays 330/h (measured L10 Spear 217/h
    unbaited, 445/h baited; bait burns ~6.5k Logs/h vs ~3k/h supply, so ~320/h blended).
  - gen_upgrades.py now saves next to itself (or to argv[1]). data/upgrades.json strips designer notes like
    "(existing ...)" from effects, so after regenerating only the changed group was merged into the json
    (regenerating everything would bring those notes back).
- **Intro + boot rework** (idle_os_2.gd, `#region intro + boot`): briefing in `INTRO_TEXT`, typed by
  `type_text()` frame-rate independent at `INTRO_CPS` (140/s, short pause between paragraphs); any key
  finishes typing (`_typing` / `_skip_requested`, handled first in `_input`). 'enter' runs
  `install_idle_os()`: a boot log drawn straight into the label (`_boot_print/_boot_set`, not add_line, which
  used to wipe the typed "Downloading Module" lines), header cards per module, then the right panel
  section by section (each section's own alpha kept in meta "boot_alpha": separators are 0.35), then the
  command line. Any key skips to `_finish_boot()`. ~6 s typing + ~5 s boot (was ~19 s + ~26 s).
  The demo-end outro (player_uploaded_proper_item) also uses type_text, so it's skippable too.
- **Tutorial revamp (uploads woven in):** `Tutorial.TUTORIAL_ORDER` is the order shown; the enum is only ids
  (saved as numbers), so NEW EVENTS GO AT THE END of the enum. New steps: UPLOAD_INFO ('upload'),
  PACKAGE_5_LOGS (`Uploads.stage` -> `Tutorial.on_items_packaged`), UPLOAD_LOGS / _IP_ADDRESS / _PASSWORD /
  _CREDENTIAL / _SCHOOL_PAYLOAD (done once that item is uploading or uploaded, via `Uploads.changed`).
  Counts worked backwards so uploads don't starve the next skill: mine 35, parse 30, enc pw 6, usernames 5,
  IP 5, crack 6, match 5, compile 4 (old enum names like MINE_20_LOGS kept). UNLOCK_MINING_OVERCLOCK_WITH_APT
  now = "install your first Mining upgrade" (any Mining install). Old saves: `_complete_skipped_new_steps()`
  marks new steps done when the player is already past them. `decode -package=<item> <amount>` packages
  that many then stops (`Decoding.next_package_limit` -> terminal `package_limit`). Test: tools/tests/tuttest.
- `info <skill>` MODIFIERS box: STATUS column 14 -> 18 (COMMAND 45 -> 41) so "at Matching v1.0" no longer
  runs into the command text (affected every 8+ letter skill).

- **Decoding upgrades** (WIRED, 2026-10-19): rare chance down: CACHE / DEEP "efficiency" 0.1 -> 0.04, rate
  0.001 -> 0.0004 (Cache 4% at L1 -> 7.9% at L99; Deep x2). Efficiency is RELATIVE like Phishing
  (`Decoding.get_efficiency` = level eff x (1 + track), +20% at max: Cache rare 7.9% -> 9.5%). Yield multiplies
  basics in `roll_loot` / `get_drop_table`. Rare Tracker: `Decoding.rare_tracker` (saved), one counter per cache
  family (`cache_family`: variants share "Student cache"), +cur per dry cache, reset on a rare, only counts
  while installed; shown in the drop line. Compression = Package passes faster (Josh: keep uploads the slow
  part, everything uploading at once), `cache_decrypt_terminal.get_step_time` override. Field Notes: max intel
  hacks 10 + N (`intel_max_hacks()`), first find starts with 1 + N hacks. Capstones: overclock, token_vault
  (token x2), index / forensics / survey (`Decoding.MODIFIERS`, passed to `roll_loot(cache, process, mod)` /
  `roll_salvage(item, mod)`), clean_room (COOL_PACKAGE). Modifiers refused on Package / Intel
  (`modifier_block_reason`). Index credits `target_for_cache` (easy target first, hard once easy is maxed).
  Forensics: `Exploits.roll_drop(cache, process, mult)`. VM tokens now roll on time (`_token_chance`).
  - `_reveal_dump` now banks frame time and reveals several bytes per frame when a step is shorter than a
    frame. Before, each byte waited for its own timer, so high Speed was capped by the frame rate (max Speed
    is 0.018 s/byte, about one 60 fps frame). Other skills with per-step timers may have the same cap at max Speed.
  - Measured L99 (Student caches): base 174 caches/h, ~6.8k Logs/h; all tracks max ~2,000 caches/h,
    ~120k Logs/h, heat/h x11.6 (heat is per cache). Package L99 ~1.2k items/h base, ~21k/h speed + compression.
    Rare Tracker at max (+1.5% per dry cache) lifts the real rare rate 9.5% -> 15.5% per cache (Josh to decide
    if that's too strong: +0.25% max per dry would give ~11.3%). Tests: tools/tests/decodeup (PART 1/2/3),
    decodecap.

- **Compiling upgrades + Mod / Access rework** (WIRED, 2026-10-19):
  - Burst (efficiency proc) = 100x fill speed for 1 s, no heat (kept from the old code; Josh loves the "goes crazy
    for a second" feel). Efficiency is RELATIVE (`Compiling.get_efficiency`, +20% at max: 10.8% -> 13% at L99);
    Optimize doubles it. Bursts happen on payloads, Mod hacks and Access stages. Recovery (20% flat, never the
    access rares), Linker (double payload), Mod Tuning (mod value x(1 + track) when built), Survey (half output,
    XP x2), Build Cache + Optimize token x2, Cold Build = COOL_PACKAGE. `BaseTerminal.get_fill_rate` now applies
    modifier speed. The fill loop keeps progress past 100 in `_fill` (several fills per frame, max 20), so
    speed and bursts aren't capped by the frame rate. VM tokens roll on real fill time (`_token_chance`).
  - **Mod** = one fill per hack: `compile -mod=<item>` equips the mod on the first fill (needs a slot or the same
    type equipped) and adds a hack per fill up to the item's duration (`Compiling.mod_cap`, Debug x1.5), then stops.
    Cost per fill = item cost / duration (ceil) + SQL Injectors (10 x tier per full mod, split; `mod_fill_cost`).
    ~10 s per fill at base. `HackingMods.extend_mod` (no SaveManager call in there: it made a cyclic reference
    through ItemData). At the normal cap with the Debug capstone, the terminal waits for 'debug' instead of
    spending. Shared validation: `Compiling.check_mod` (main terminal + ssh).
  - **Access** = stages, progress saved per target (`Compiling.access_progress`, key Stats.target_key):
    10 stages for a location's 2nd target, +5 per target after (`access_stages`), ~30 s each at base. Payloads are
    spread over the stages, the 5 rares are taken by the final stage (`access_stage_cost`); without them it stops
    at the final stage and says what's missing. No modifiers and no overclock on Access (`modifier_block_reason`,
    `overclock_block_reason`, `get_mode` override). Debug is refused off Mod (`modifier_refuses`, new idle_os_2 hook).
  - Measured L99 School: base ~850 payloads/h (bursts are ~half of it); all tracks max ~46k/h (input-bound in
    practice). Tests: tools/tests/compileup (PART 1 payloads, 2 Mod, 3 Access), compilecap (commands).

- **Hacking upgrades** (WIRED, 2026-10-19). LEGACY_DEFAULTS is gone: '-r' and hacking overclock are always on.
  - Max anonymity (no upgrade): `Stats.set_max_anon()` = 100 + 5 x (Hacking level - 1) + 100 x (locations unlocked
    - 1); refreshed on Hacking level up, location unlock, Stats load and apply_effects (145 at L10, 590 at L99 with
    School only, 1,090 with all six). It also sets the auto-spoof threshold (0.3 + spoof_threshold track, 90% max).
  - hacking_game.setup: Damage / Firewall / Bandwidth tracks as before (`current` = sum of the track); attack heat
    0.3 + 0.1 per Damage install; Packet Spoof heals DEFEND_PCT = item heal/100 + Healing track of max anonymity
    (5% -> 11%); RESTORE mods are % points of max anonymity (+5 = +5%, mod text shows "+5%"). Persistent Session
    multiplies `Exploits.add_charge`. Mod slots were already read by HackingMods.refresh_slots.
  - Capstones: Clean Exit (lose(): keep floor 50% of banked caches), Evasion (10% dodge in counter()), Recycler (50%
    SQL kept), Siphon (each SQL attack restores 0.5% of max anonymity, ceil), Dead Man's Switch (once per session,
    reset in setup(): survive at 1 + 25%), Exploit Kit (50% one-time item kept in use_exploit). All log a tag.
  - Measured (tools/tests/hackup SCEN=A/B/C, no mods): L10 no upgrades beats the Student 3/3 (~40 s), loses the
    Superintendent and Student (Hard) (firewall soaks the whole hit at 1 firewall dmg). L45 / 4 locations: Teller 0/2
    with no upgrades -> 2/2 with tiers 1-4; CFO 0/2 either way. L99 / all max: sustain is fine (Siphon + 11% heals +
    Evasion) but Government targets stall: their firewall refills 10 s after breaking and 13 firewall dmg can't keep
    it down, so fights hit the 10-minute test cap. Firewall pressure is the main thing for the balance pass (with mods
    in the loadout). tools/tests/hackcap checks Clean Exit / Exploit Kit / Persistent Session.

### Left (designs are in the sheet; wire one per step, add the group to WIRED_GROUPS)
- ~~Phishing~~ DONE (kept for reference): speed, efficiency (bite chance, 20% max), lines (+1/tier), bait_power (+5%),
  bait_recycling (+5% bait kept), quick_hook (-5% reel). Capstones: overclock, tackle_box, lure (mod:
  -50% speed, heat x1.5, 3% per catch to also hook a hacking mod item), chum (mod: -40% speed, catches
  doubled, token x2, heat x2), survey, deep_water. All done. Re-measure Phishing's rate
  for the sheet afterwards.
- ~~Decoding~~ DONE 2026-10-19 (see Done).
- ~~Compiling~~ DONE 2026-10-19 (see Done).
- ~~Hacking~~ DONE 2026-10-19 (see Done). All nine groups are wired.

## Other systems built recently (for context)
- Combat (`scripts/hacking_game.gd`): code-built card UI, tagged combat log, floats/flashes/banners,
  firewall break (enemy attack speed -50% for 10 s, then quick refill), bandwidth is a float that
  regenerates continuously, overclock doubles bandwidth regen, overheat halves it.
- One-time items (`singletons/Exploits.gd`, `items/exploits/`): 12 tier-locked items found in that
  tier's caches (1%, x2 Deep Scan); `run <alias>` during a hack; EXPLOIT charge from combat, resets when
  a hack session ends; `run auto <item>`.
- Hacking mods: 1 slot base, +1 per tier (max 7); each equipped mod adds SQL bandwidth cost by tier
  (`HackingMods.MOD_BW_COST_BY_TIER`, Tier 1 = +2).
- `ls -h` shows the item-type glossary.

## Offline progression (built 2026-10-19) — singletons/Offline.gd (autoload)
- Only the MAIN terminal process runs offline. VMs close on quit (no offline, no VM tokens offline), Hacking never
  runs offline or resumes (quitting mid-hack reopens on the main terminal), Trap already fills on real time, and
  `crack -vm`, Salvage and Deep Scan (VM-token processes) are online only. Defragging isn't a process.
- Save: `Offline.save_data()` = quit time + `snapshot()` of the main terminal (skill, process, the command that started
  it: idle_os_2.main_command {context, text}, captured in _on_input_line_text_submitted, + args: parse items /
  extraction target, bait / smish target, cache / package item / intel target / package limit, mod item / access target).
- Load: SaveManager calls Offline.load_data; idle_os_2._ready calls `Offline.compute()` right after load_game (before
  the boot saves again). Time away is capped by `cap_seconds()` = 1 h base + Background Services (24 h max).
- Rates are CALCULATED (Josh: measured rates would include overclock / modifiers / VMs): `_job()` builds one cycle per
  skill at normal speed with upgrades (seconds, avg outputs, inputs, xp, heat); random ones average SAMPLES=300 virtual
  cycles with the same helpers the terminals use (Parsing.roll_find, Decoding.roll_loot with the rare tracker restored,
  phishing weighted rolls...). `_run()` = cycles limited by time and inputs, moving on to the next input when one runs
  out (next cache / parse item, bait -> unbaited). Custom `apply` for Package (stages, still-needed + limit), Intel and
  Smish (intel points), Compiling Mod (hacks to cap) and Access (stages; can finish and unlock offline). Compiling
  bursts are folded into the fill time (`_compile_seconds`).
- Heat: if one cycle's heat (heat sink + flat reduction) > System cooling over the same seconds -> outputs -10%
  (OVERHEAT_PENALTY), shown as "ran hot". Temperature is reset to the minimum after.
- Uploads continue at half speed (UPLOAD_SPEED) via Uploads._upload_one, so goals can complete offline.
- Show: `idle_os_2._offline_welcome()` (after the welcome text, or after _finish_boot): "RESTORING OFFLINE SESSION",
  a connect bar, then one row per gained resource whose count climbs from 0 behind a filling bar (~2.5 s a row,
  1.2 s with many, count eases out; not skippable by design; XP gained per skill gets its own row after the resources), then used / packaged / uploaded / levels / notes / ran hot, then it
  resumes the main command. Level-ups from offline XP give their VM token as usual (Josh: keep them) and the level line
  shows it ("Mining level 5 -> 11  +6 VM mining token"). The Trap keeps filling on real time (collect stays manual):
  the download shows "trap: N% full" / "trap full: 'trap collect'".
- Upload goal complete: `ContextCommands.tier_complete_text(tier)` banner (what the next location opens: first target,
  Tier N upgrades, next goal). Online it prints on Uploads.tier_completed (connected in idle_os_2._ready after
  Offline.compute); goals finished offline print it after the download (report.tiers). Before this the full game
  unlocked the next location silently (only the demo had a send-off).
- Validated vs live (tools/tests/offtest, L99 base upgrades, per hour): Mining 1,896 live / 1,993 offline Logs,
  Parsing within ~6%, Matching 480 / 478, Spear 372 / 380, Spear baited 832 / 815, Whaling 427 / 441, Decoding caches
  6,597 / 6,709 Logs, Cracking 410 / 382, Compiling 818-960 live (bursts are rare: +-15% per hour) / 740 model.
  tools/tests/offflow = save -> 2 h later -> download + resume (STEP=1 then STEP=2, SHOT=1 for screenshots).

## Flow chart node (built 2026-10-19) — scenes/flow_chart.tscn + scripts/flow_chart.gd
- A Control drawn with _draw (boxes, arrows, labels) posted into the scrollback like a process terminal,
  via `idle_os_2.post_flow_chart(setup)` (waits for queued text to finish printing first).
- `flow` -> `show_loop()`: hand-placed game-loop chart (layout matches Josh's approved mockup). Listed in `-h`.
- `info <skill> <process>` -> `show_recipe(skill, process)`: auto layout from `Inventory.producer()`
  (now returns "skill" too). Columns = steps from raw items, inputs that skip columns go on outer rows,
  boxes show have/need (red when short). Replaced the text RECIPE tree (`Inventory.recipe_text` is now unused).
- Drawn in design px, scaled to terminal width (never above 1x), fonts floor at 11.
- Screens test: `tools/tests/flowshot`.

## Balance pass (Josh's plan, after offline progression)
- Order: resource rates per tier and process (with that tier's upgrades applied) -> combat (easy targets first) ->
  combat hard (each fight needs more focus / detail). Compiling at max (~46k payloads/h) is either reined in or
  paired with big resource sinks (Josh decides).
- Demo Student (Hard) was retuned on demo-nextfest (2026-10-19): integrity 450, firewall 30, counter 15, speed 20
  (was 500 / 80 / 20 / 50 = unbeatable with demo tools), and the VM Parsing token mod 25 -> 15 firewall reduction.
  Simulated (tools/tests/hardtune + hardsim, run on a copy of the demo branch): 13/36 mod pairs win in ~45 s - 2.5 min,
  single mods lose except VM Parsing token + full intel (~2 min). cdd still has the old Student (Hard) numbers and the
  Parsing token at 25 (decide in the pass; cdd's Student (Hard) also has 145 max anon at L10 + % heals now).
- Packet Spoof (5 heal per 12.5 s, 2 bw, first claim on bandwidth) is too weak for "spoof early" to matter: early
  spoofing delays attacks more than it heals. Needs a spoof change (bandwidth priority / cost / heal) if early spoof
  should be a skill. Firewall reboot (10 s after a break) is what stalls late fights.
- ~~Item tiers~~ DONE 2026-10-19: all 185 in-game items whose `tier` field disagreed with their location now carry it
  (`tools/tests/itemdump` checks: 0 mismatches). This switched on tier effects that were silently stuck at tier 1:
  Corruption +1%/Mining tier, bait x1.10 (Logs) .. x1.35 (Databases),
  Compiling mod SQL cost 10 x tier, Phishing mod pool gated by tier unlock. Library / Small business / University
  items (not in the 6 locations) left at tier 1. Backups: `_to_delete/backup/tiers/`.
- Network parsing retuned 2026-10-19 (Josh: VM tokens are a resource sink, ~5% max): one token per find (was
  Mining-tier tokens per find), 0.5% per line at L1 -> 2.46% at L99, efficiency upgrades count 5% (+1% at max),
  +0.3%/Mining tier above Logs (NETWORK_TIER_BONUS) -> Databases at L99 + max upgrades = 4.96%.
  Deep Read no longer doubles Network line finds (still doubles the per-cycle VM token chance).
- ~~Stale item descriptions~~ DONE 2026-10-19: 231 descriptions regenerated from live data by `tools/tests/descgen`
  (recipes, cache rare pools, variant constants): fixes e.g. "Used as upgrade ingredient" / "Sell on the marketplace" /
  blank rares, Bio Template "forms a Gateway Address". Re-run descgen after changing recipes or variant numbers
  (it writes `_to_delete/descgen.tsv`; empty = all descriptions current). Backups: `_to_delete/backup/descriptions/`.

- Rates per tier measured 2026-10-19: `tools/tests/ratetier` (Offline cycle models; every upgrade up to that tier,
  process level 1 and 99, no modifiers/overclock, before the overheat penalty) -> `tools/balance/rates_2026-10-19.tsv`.

- **Heat plan (Josh, 2026-10-20).** Targets per tier: main + your VMs on the new tier's work run ~1.3x hot on
  arrival; cool after the tier's Cooling + Heat Reduction installs; main + all VM windows cool at the tier's end
  (Load Balancer T4 halves VM heat, Server Rack T6 removes it).
  Step 1 DONE: speed upgrades no longer add heat (BaseTerminal.get_heat and Offline._hc divide by 1 + speed track;
  overclock/modifiers still add theirs, overheated mode unchanged); System Heat Reduction is now 5% per tier
  (percent of every heat tick, was flat 0.1/tier) and the Defrag heat boost is 20% (was flat 0.2); Cooling per
  tier install 0.3/0.35/0.55/0.7/1.05/1.55 -> totals 0.4/0.75/1.3/2.0/3.05/4.6 C/s (COOLING_STEP in gen_upgrades.py).
  Measure: `HEAT=1 res://ratetier.tscn` -> `_to_delete/heat.tsv` (heat/s vs cooling, arriving vs tier done).
  Step 2 DONE: Josh's skill ladder kept at every tier (all your windows on one skill's new-tier work, on arrival):
  Mining 0.9x cooling (never compounds), Parsing/Phishing 1.0x, Cracking/Decoding 1.15x, Matching 1.25x,
  Compiling 1.35x; tier base 0.1/0.146/0.208/0.3/0.7/1.0 heat/s (x skill mult x previous tier's reduction).
  `tools/balance/heat_calibrate.py` scaled the per-tier processes' heat / overclock heat / overheat heat
  (Mining, Cracking, Matching, Compiling payloads) and wrote HEAT_BY_TIER tables for shared processes:
  Parsing (item tier), Decoding (cache / item tier), Phishing (bait tier, else Upgrades.working_tier),
  Compiling Mod/Access (working tier) via BaseTerminal.heat_tier_mult() (+ Offline). Whaling heat x4.5 and
  Phishing Mod x1.5 first (they were 0.02 / 0.06 heat/s vs Spear 0.09). It multiplies what's there: re-run only
  after resetting HEAT_BY_TIER to 1.0 and re-measuring. Result (main alone, arrival -> tier done): T1 0.9-1.3x -> 0.2-0.35x;
  T2+ main alone ~0.2-0.47x on arrival (the 1.3x is with main + your VM windows), main + all VMs ~0.9x at tier end.
  Compiling Mod is hot (4x at T1 arrival) but short (one fill per hack, SQL-limited). Hacking heat (enemy
  COUNTER_HEAT, 0.3 per action) doesn't scale with the new cooling yet: combat pass.
  Later: flat cooling extras (Overheat Fan +0.3 C/s, Defrag cooling +0.5 C/s, hacking/upload heat) don't scale.
  Step 3 DONE (pace plan): every tier arrives at the same seconds per payload as Tier 1 (L1, previous tier's
  upgrades): ~57-61 s; with the tier's own upgrades ~24-27 s; at L99 10 s (T1) -> 15 s (T6).
  `tools/balance/pace_calibrate.py find|time` (+ `payload_seconds.py`, ARRIVE=1 ratetier -> rates_arrive.tsv):
  Parsing.FIND_BY_TIER (Footprint/Extraction find chance incl. Pattern Cache, by Mining item tier) and
  Parsing.TIME_BY_TIER (their line time); Mining/Cracking/Matching/Compiling per-tier processes' speed values
  scaled, with heat and XP per cycle scaled the same (heat/s, XP/h unchanged). Tier 1 Matching 30% faster
  (was the slowest step: 17 s -> 12 s per payload on arrival). Corruption/Network/caches unaffected.
  Higher tiers = longer cycles with bigger hauls (T6 arrival: Mining ~28 s/cycle, Cracking ~37 s, Matching ~32 s).
  Snapshots: tools/balance/rates_2026-10-20_{arrive,done}.tsv, heat_2026-10-20.tsv.
  Not done: Decoding / Phishing still speed up 7.6x by T6 (no per-tier base slowdown; caches and SQL aren't in
  the payload chain) - revisit with the combat/cache pass.

## Combat pass (started 2026-10-20)
- Tier gating: Mining / Cracking / Matching / Compiling payload processes need their tier (location) unlocked as well
  as the skill level (Exp.process_tier / tier_block_reason; main terminal + ssh). Hidden while
  Upgrades.DEV_UNLOCK_ALL_TIERS is on.
- Compile -mod stats for every tier: `tools/balance/mod_stats.py` (roles from tools/tests/modroles). Same mod type per
  role at every tier, higher each tier: Mining item SQL dmg 10/20/35/55/80/120; parsed->Matching firewall reduction
  15/30/53/83/120/180; parsed->Compiling firewall dmg 10..120; encrypted crit 2..12%; cracked crit 3..18%; matched
  attack speed 15..40%; payload bandwidth +2..+7/s. Rare N of a tier = the next tier's basic of its role
  (rare1 dmg, rare2 bandwidth, rare3 spoof restore 15..30%, rare4 crit (T6 Deep Cover IDs = best, 20%), rare5
  counter slow 20..45%). Caches: counter damage reduction 5-9 / 15-19 / 30-34 / 50-54 / 75-79 / 110-114 (placeholder
  starts). Hacking crit now 5% L1 -> 30% L99 (rate 0.00255, recomputed from level on load):
  30% + 20% mod = 50%, x2 Vuln Scanner = exactly 100%.
- Equippable mods (items/hacking_mods, 3 per tier, % based, 20 hacks, Phishing Mod + Corruption pools by tier):
  T1 SQL Booster (+50% attack speed, now its own SQL_BOOST type so it stacks with Matched mods), Shatter Protocol
  (firewall break slow -75%), Burst Buffer (+20% max bandwidth/s); T2 Firmware Brick (no reboot), Payload Amplifier
  (+25% dmg), Vuln Scanner (crit chance x2); T3 Critical Overflow (crit x4), Proxy Chain (spoof heal x2), Ghost Packet
  (spoofs free); T4 Decoy Traffic (first 3 counters miss), Packet Shredder (+10% max firewall per hit), Latency
  Injector (counters -20% speed); T5 Silent Entry (no counters first 10 s), IP Rotator (spoofs fill +80%), Zero Hour
  (EXPLOIT full at hack start); T6 Cascade (break deals 15% max integrity), Mirror (25% counter dmg reflected),
  Cold Boot (no overclock heat, overheat doesn't speed the enemy). New MOD_TYPEs are appended after NONE
  (HackingMods.EQUIP_INFO has their names/text). Smoke test: tools/tests/eqtest (TGT=<target index>).
- Next: Python combat simulator -> tune the 30 easy targets to Josh's ladder; intel stat per target (its specialty),
  bigger intel for targets 3-5; per-enemy firewall reboot time; hacking heat by tier; mod bandwidth cost per tier.

## Backlog (Josh's list, in order after upgrades)
1. ~~Offline progression~~ DONE 2026-10-19 (see "Offline progression").
2. ~~Game-loop chart~~ DONE 2026-10-19 (see "Flow chart node"; `flow` + recipe chart in `info <skill> <process>`).
3. ~~`ls` filters~~ DONE 2026-10-19: Inventory.gd `item_type()` (cache / exploit / mod / token / combat / payload / rare /
   resource, worked out from existing data, matches 'ls -h') and `item_tier()` (from the location the item comes from,
   not the item's tier field). `ls` is grouped by type (`list_inventory_grouped`), filters combine (`list_filtered`):
   -<type>, -<skill> (what it makes), school..government / t1..t6, name search ('ls cred'; one match shows details).
   `ls <item>` adds Type + location and USED IN (`used_in_text`: process inputs, parsing, bait, decoding, mod compile,
   hacking payloads, access rares, upload goal progress) and the mod block shows the per-hack compile cost.
   The filter list prints under plain 'ls' (not in 'ls -h'). `ls -<skill>` = what the skill MAKES and USES (`skill_uses`, two sections). `info <skill> <process>` adds a
   RECIPE tree (`Inventory.recipe_text` / `producer`): the full chain down to Mining with each step's command and what
   you have (red below one cycle); parse finds have no amount (chance-based). `ls <item>` shows "Made from" + the info
   command. Test: tools/tests/lstest. Some item descriptions are stale (Parents credit card: "Used as upgrade ingredient").
- Later: unique combat interactions (maybe a final enemy per location, likely hard mode only),
  Phishing higher tiers (Whaling/Smish/Trap placeholders).
