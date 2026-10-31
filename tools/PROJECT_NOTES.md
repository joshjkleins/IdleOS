# IdleOS — project notes for a fresh session

Read this first. It covers how we work, how to test, the upgrade system, and what's left.
Last updated: 2026-10-30 (tier 3 / Hospital wrapped). The newest state is in the last section,
"Tiers 1-3 balance (2026-10-29/30)"; older sections are history and some of their numbers are out of date.

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
    Full haul 68 SQL + 17 spoofs (80/20); only a full trap gives 1 exploit + 1 hacking mod (x2 baited), plus a bonus exploit at eff (15% -> 25% at 99).
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
- Combat simulator: `tools/balance/combat_sim.py` (Python copy of hacking_game.gd's rules incl. equippables, capstones,
  Overheat Fan / Liquid Cooling; matches live fights within ~5-10 points of anonymity left). `combat_tune.py <tier>`
  fits each target (difficulty k, integrity-vs-counter split r) so its gate scenario ends with the target anonymity:
  T1 arriving no mods ~40% left, T2 +1 mod ~35%, T3 + this tier's Damage/Firewall levels + 2 mods ~30%, T4 mid-tier
  all slots ~30%, T5 tier done all slots ~25%; fights ~60-90 s. Results -> combat_tune_T<n>.json,
  `write_targets.py` writes them into stats.gd; ladder table: combat_ladder_2026-10-20.txt.
  Live check: tools/tests/livecheck (CASES="tier,slot,S1..S5,intel;..."; turns Idle Cooling off - it never runs in a
  real hack - and drives overclock on <60 C / off >90 C).
- Target profiles (every tier): 1 balanced (intel firewall, reboot 10 s), 2 tanky (integrity, 8 s), 3 big firewall
  (firewall, 14 s), 4 fast light counters (counter speed 30, 6 s), 5 heavy hitter (counter, 10 s). New target keys
  "intel stat", "intel cap" (0.25 / 0.25 / 0.35 / 0.45 / 0.40 of the stat; Decoding.intel_cap), "firewall reboot"
  (hacking_game._fw_down_time). Shown in 'info hacking <location>'. Heat 0.5..1.7 by slot, x hacking_game
  HEAT_BY_TIER (1 / 1.46 / 2.08 / 3 / 7 / 10 by location) for every hacking heat tick incl. overclock.
- Hacking Damage / Firewall Damage tracks now grow with the tier (gen_upgrades DAMAGE_STEP / FIREWALL_STEP):
  +5/25/38/50/62/100 dmg (25 -> 300 total), +2/3/5/6/7/12 firewall dmg (3 -> 36), so mods stay ~+40% at every tier.
- Not done: hard-mode targets (old stats); the T1-T2 heavy hitters came out low-counter / high-integrity (r clamp);
  target exp untouched; mod bandwidth cost still +2 per mod at every tier.

## XP pass (2026-10-20)
- Tempo: ~250-300 hacks per tier (~4-5 h, easy mode). Rares needed per tier: targets 1-4 = 19 each (upload 10 +
  next target's access 5 + two capstones x2), target 5 = 12 (+ mods: 20 per full mod, optional).
  `tools/tests/raredemand` (data) + `tools/balance/xp_plan.py [extra rares for mods]` (hacks + XP per tier).
- Rare chance (Decoding CACHE and DEEP): 20% at L1 -> ~22% at L99 (was 4% -> 8%); with tracks + Rare Tracker
  ~20% (T1) .. ~26% (T6) -> ~4.7 .. 3.5 caches per rare.
- Target 5's cache now holds ~2 of the tier's other caches (4 entries x 1 at 50%; was 3-7 at 40% = ~8), so it's a
  bonus, not the farm (Josh: pick a target for a reason).
- Target exp rescaled (today's shape between targets) so a tier's hacks land the combat pass's arrival levels
  (1 / 15 / 30 / 45 / 60 / 75, 90 after Tier 6): School 7/79/119/159/198 .. Government 233/2793/4190/5586/6983.
  ~299 hacks (T1) .. ~222 (T6). Hard-mode exp untouched.

## Economy pass (2026-10-20) - Josh to feel it out in a full playthrough
- Tier length = ACTIVE play: T1 1-2 h, T2 2-3 h ... T6 6-7 h (idle/offline on top). Model `tools/balance/econ2.py`
  (60% of play in fights at ~70 s, VM windows half the time, one offline session at the tier's cap, cache loot as
  supply with 25% Extraction / 25% Footprint): hacks ~46 / 77 / 108 / 139 / 170 / 201 per tier.
- Upgrade costs x COST_SCALE [0.1, 0.7, 0.85, 0.75, 0.75, 1.0] (gen_upgrades.py); Hacking upgrades' cache cost
  HACK_CACHE_TOTAL [10, 15, 22, 28, 34, 40] per tier; capstone rares CAP_RARES [1, 1, 2, 2, 2, 2]. Only each
  level's "costs" were merged into data/upgrades.json.
- Uploads.gd: goals BASIC_GOALS [100, 300, 600, 1000, 1600, 2500], RARE_GOALS [3, 5, 6, 10, 15, 20]; upload time
  by the item's tier [38, 21, 15, 11, 9, 7] s (rares 60 s) so a goal takes ~70% of the tier's play, all items in
  parallel; upload heat = UPLOAD_HEAT_PER_SECOND[tier] x upload time (~3.5% of that tier's cooling per item).
- Target access (stats.gd): rares ACCESS_RARE_BY_TIER [2, 3, 4, 5, 5, 5]; payloads 4/14/24/34 at School, else
  10/35/60/85.
- Target exp rescaled again for those hacks (+ the upgrade caches): School 45/500/753/1005/1252 ..
  Government 252/3013/4521/6027/7534 -> arrival levels 1/15/30/45/60/75.
- Fit (needed / available production hours): 4.5/4.7, 9.4/11, 15.8/18.5, 23/27, 30/36, 38/47. T1 is the tight one.
- Ideas parked for after the playthrough: upload-goal item bonuses, small every-5-levels skill bonuses.

## Level bonuses (2026-10-20)
- Every 5 levels of a skill that makes VM tokens (Mining, Parsing, Cracking, Matching, Phishing, Decoding,
  Compiling; not Hacking / Defragging): +0.1% VM token chance per cycle, added to each process's base-speed chance
  (Exp.vm_token_level_bonus; L95 = +1.9%). Announced on level-up; 'info <skill>' shows a LEVEL BONUS block (now +
  next only, Exp.level_bonus_text); 'info <skill> <process>' shows the chance with the bonus. Test: tools/tests/lvlbonus.
- Upload-goal item bonuses: idea parked until after the playthrough.

## Playthrough notes pass (2026-10-20, Josh's first full playthrough)
- **Packaging removed.** `upload <item> <amount>` takes items straight from the inventory into the upload
  queue (`Uploads.queue`; `staged` = queued) and starts uploading. `upload <item>` = all the goal still needs,
  `upload -a` every goal item, `upload cancel <item>` (alias `unpack <item>`) returns queued items. During the
  tutorial an exact amount is required and `-a` is refused. Decoding's PACKAGE process, the terminal's package
  loop and Offline's package job are gone; `decode -package` prints a pointer to upload. Old saves: queued goal
  items start uploading on load. Tutorial: PACKAGE_5_LOGS = "upload logs 5" (also silently ticks the retired
  UPLOAD_LOGS step, which is no longer in TUTORIAL_ORDER; `Tutorial.steps()` / `steps_done()` count only
  TUTORIAL_ORDER). Upload goal text: QUEUED column + stacked, aligned command hints. Test: tools/tests/uptest.
- **Compression** (decoding.compression) = +10% basic resources per decoded cache per level, stacks with Yield.
- **compile -access removed.** Locked targets unlock with `unlock <target>` in the Hacking module (targets and
  locations pages; `unlock` alone lists locked targets with costs) via `Stats.buy_access`: pays
  `Stats.get_access_recipe` (rares of the previous target + payloads) in one go. `Compiling.access_progress`
  (old saves' partial stages) is dropped. Test: tools/tests/unlocktest.
- **Hacking upgrade costs** rotate through the tier's 5 target caches (gen_upgrades.py `TARGET_CACHES`: slots
  1-2 target 1 ... 9-10 target 5), totals still HACK_CACHE_TOTAL. Only Hacking costs were merged into upgrades.json.
- **Side panel AVAILABLE TO RUN** (scripts/available_section.gd, above ACCESS): the current upload tier's
  Mining > Parsing > Cracking > Matching > Compiling, lit when the inventory covers one run (Mining always),
  with runs available on the right. Collapsible (saved as sections.available). Screens: tools/tests/availshot.
- **Tutorial window** (scripts/tutorial_window.gd, class TutorialWindow, in VMLayer): docked top right next to
  the side panel, one page per step, < prev / current / next >, '_' folds, 'x' closes ('tutorial' reopens,
  'tutorial -l' prints the old checklist). Steps flash OBJECTIVE COMPLETE and jump to the next page; the terminal
  only gets a one-line notice while the window is up (full message when closed, and the tutorial-complete text
  always). Hidden in the Hacking module (its console still prints the full messages). Saved: Tutorial
  window_folded / window_closed. VM windows spawn below it. Test/screens: tools/tests/tutwin.
- Quick fixes: parsing processes unlock from level on load (Exp.processes_load_data), Student integrity -45,
  phishing 5 base lines, Spear catch 1-5 SQL / 1-3 spoofs, VM uptime 60 s, every decoded cache gives 1 of every
  VM token, info modifiers only once unlocked, ls filters tree, demo wording out of intro/tutorial-complete.

## Playthrough notes pass 2 (2026-10-20)
- Tutorial: page titles from `Tutorial.STEP_TITLES` (enum names kept old counts), PHISH_SPEAR_INFO retired from
  TUTORIAL_ORDER, UPLOAD_PARENTS_CC moved before the apt step, Parsing step says 'cd ..' then 'cd parsing'
  (Cracking does it in one), 1 VM token of the skill when the Parse / Crack / Match / Phish / Compile / Decode
  steps come up (`_grant_step_token`, saved token_steps_granted), post-complete line points at 'flow' and
  AVAILABLE TO RUN.
- **VM cache** (id 357, items/cache_data/vm_cache.tres, not parsable) replaces 1-of-every-token per cache:
  20% from every other cache (first tutorial Student cache always), decoding one = 5 lines x 50% at 1-3 of a
  random VM token (~4.8 tokens per VM cache). Decoding.VM_CACHE_* / roll_vm_cache.
- Balance: T1 basic upgrade costs x3 (gen_upgrades BASIC_TIER_MULT; only T1 costs merged), T1 basic upload goal
  300, upload 15 s (T1-T3) / rares 45 s, Spear SQL 1-2 / spoofs 1-2, Decoding Intel L5 / Skim L15, cache XP x3
  (Cache 150, Skim 75, Deep 300).
- Text: rare item descriptions point at 'unlock' in Hacking, compile -mod description rewritten.
- UI: decoding DROPS / RARE two-line label, apt bulk installs as a cascade of per-package bars, ssh accepts
  '-process' and singular/plural, vm show/hide/kill -a, AVAILABLE TO RUN < > pages unlocked tiers, hacking
  cards list CACHE LOOT (Decoding.get_drop_table).
- Bugs: header "+N xp" popup only on the skill that earned it (root view shows it on that skill's card, so VMs
  light up their own skills); a multi-hack that runs out of payloads now banks the hacks already won.
- Hacking T1 capstone Clean Exit -> **Second Wind** (hacking.second_wind): each win in a multi-hack run restores 25% of
  max anonymity (anonymity already carries over between fights; reset only in setup()). Old saves: Upgrades.RENAMED
  maps clean_exit installs to second_wind. Test: tools/tests/hackcap.

## From the demo-nextfest-2 playtest (2026-10-20)
- Base cooling 0.1 -> 0.2 C/s (Upgrades.BASE_COOLING, Stats.cooling_amount, cooling labels, gen_upgrades start, combat_sim COOLING).
- Optional flags in [brackets] like real terminals: phishing display commands, 'upload <item> [amount]' (hints merged into one line).
- **Tab auto-complete** (singletons/CommandRegistry.gd, rewritten; idle_os_2 `_tab_complete`): prefix-then-list like bash,
  start-of-string, case-insensitive. Candidates are whole commands: static list + skill processes (parse always gets
  '='), cd / info / ssh / apt per skill, owned items for ls / track / parse / decode / compile -mod / bait, upload goal
  and queued items, unlocked targets (intel, smish), VMs, unlocked modifiers. Hacking console: view / hack / unlock /
  run. Options list one word at a time (cut at '=' / ' -', and at spaces after cd / info / ssh / apt ...). '-h' line +
  tutorial tip on the Navigate Mining step. Tests: tools/tests/tabtest, tabkey.
- Skills run from any directory (demo player feedback: binaries belong on $PATH): idle_os_2 `_run_skill_from_anywhere`
  routes mine / parse / crack / match / phish / decode / compile commands to their skill's handler without changing
  directory; root also takes overclock / modifiers / kill -s for the running process; 'which <cmd>' and
  'ls /usr/local/bin' are unadvertised easter eggs for programmers (not in -h or the tutorial); 'hack' at root points to 'cd hacking'. Tutorial Crack / Match / Phish / Compile / Decode steps
  give the command and say it runs from anywhere; '-h' has a line for it. Test: tools/tests/pathtest.

## Playthrough notes pass 3 (2026-10-21, cdd)
- Drops: Phishing Mod bite 1% at L1 (was 0.1%); one-time items 5% EACH per cache (Exploits.roll_drops / drop_rows, each on
  its own line, no "(one-time item)" tag); cache rare chance 35% (Cache + Deep Scan efficiency; Deep x2 = 70%).
  First decode of every cache family with a rare chance always has its rare (Decoding.first_rare_given, saved;
  CacheDecrypting.get_potential_items), hidden on purpose: drop tables show the normal chance. Deep Scan = Cache's
  rare chance + 15% ("rare bonus"; was x2). VM cache hint no longer mentions the tutorial cache.
- Caches no longer drop SQL Injectors / Packet Spoofs (Phishing and Corruption parsing still do). Gap fill: each tier's
  3rd target cache now drops that tier's cracked item, the 4th its matched item (School: Vice principal -> Passwords,
  Principal -> School payload, since School caches had no payload). Old entries in _to_delete/backup/cache_entries.
- Mods: Encrypted passwords crit 5%, Passwords 7.5% (note: School budget embezzlement logs rare is 6%). New compile mod
  COUNTER_RESET (MOD_TYPE 28) on payloads: 5/7/9/11/13/15% per SQL attack to reset the counter bar; payloads gave
  bandwidth regen before (the rares still do).
- Intel rework: per target {lv[integrity, firewall, counter, counter speed], dur, hacks}. Each successful line: one stat
  +2% (in that order) until all four match, then +1 hack; repeat to 10% on everything (5 steps), then +1 hack per point
  up to 15 (+ Field Notes). A hack uses 1; the last one spends the intel. 34 points from nothing to maxed.
  The "intel stat" / "intel cap" target keys were removed from stats.gd (2026-10-22).
- System Thermal Paste -> VM Snapshot (system.vm_snapshot): chance a VM token isn't used when a VM starts or renews,
  5% at T1 then +3% per tier (Upgrades.spend_vm_token; silent on renewals). Overheat always clears at 80 C.
  Upgrades.RENAMED maps old thermal_paste installs.
- Fixes: 'ls <partial name>' always lists (no auto-details on a single hit), hacking console up/down history resets
  after a new command, 'defrag -<process>' runs from any directory, Whaling description + terminal header explain the
  bite / reel / bundle. Tab: bait completes Mining items only (Phishing.is_bait), 'ls' completes every item name.

## Tools updated (2026-10-22) to match the playthrough passes
- combat_sim.py: intel = one share off integrity / firewall / counter / counter speed (intel 1.0 = -10%, INTEL_MAX);
  "ctr_reset" mod (Countermeasure Reset: chance per SQL hit to empty the counter bar). Cooling already +0.1.
- combat_tune.py: no intel stat / intel cap per profile; MOD_VALUES T1 crit .075, ctr_reset per tier.
  write_targets.py no longer writes intel keys. Note combat_tune_T*.json still hold the 10-20 tuning (Student 148
  integrity; the game has 103 since the -45 playtest change): re-run combat_tune before write_targets.
- mod_stats.py: T1 crit 5% encrypted / 7.5% cracked, payload role = Countermeasure Reset (28), new "band" role for the
  target-2 rares (bandwidth regen).
- econ2.py / econ_plan.py: RARE_P +15% (35% base). Caches no longer drop SQL / spoofs: re-run tools/tests/econdump
  for loot.json before reading their SQL column.
- Tests: livecheck writes the new intel format (+ ctr_reset in MODV, T1 crit .075); decodeup PART=3 is the intel
  build-up (package scenarios removed); tuttest uses 'upload logs 5'; combatdump drops the intel stat column.
  Live vs sim (T1): Student 47% / 53% anon left, with full intel 64% / 67%, Vice Principal S3 32% / 32%.

## Cache loot order (2026-10-22)
- Targets 1-4 of every tier: the cache's guaranteed item is listed first, then the other two; drop chances 100% / 80% /
  60% (was 100 / 50 / 50 at School, 100 / 60 / 60 after; Doctor's payload was 80% with nothing at 100%). Entries
  reordered in the base cache and all four variants. Target-5 caches (other targets' caches) unchanged.
  Basics per cache go up ~20% at School, ~9% elsewhere. Backups: _to_delete/backup/cache_order.

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
- Later: unique combat interactions (maybe a final enemy per location, likely hard mode only).
- ~~Phishing higher tiers~~ settled 2026-10-20: Spear / Whaling / Smish / Trap / Mod are all built. Phishing stays
  tier-independent like Parsing and Decoding (processes unlock by Phishing level; its tier-locked upgrades, e.g.
  +1 line per tier, give the per-tier boost), so no Tier 5-6 processes are needed.

## Playthrough pass 4 (2026-10-22, cdd)
- Decoding: Salvage unlocks at L10. Rare chance is a flat 25% (`Decoding.RARE_CHANCE`); Cache / Deep Scan efficiency
  (5% +0.5%/lvl) now adds bonus basic resources (`efficiency_basic_mult`) instead of raising rare chance. Deep Scan keeps +15% rare.
  VM Cache drop 40%. Extraction variants give +1 rare (was +4). Admin cache order: usernames 100 / passwords 80 / logs 60.
- Intel applies the moment "INTEL FOUND" reveals in the dump (`CacheDecrypting.text_found`), not at cycle end.
  In a hack, intel drains integrity like the firewall (bar max stays the real stat; floats "-N INTEL"). Before this, intel
  integrity never actually reached the bar. Countermeasure box no longer says "this hack".
- Firewall break: the next SQL hit is a guaranteed crit (`breach_crit`, log tag "firewall breach"; combat_sim models it).
- One-time items: used with '<full name> -force' (e.g. 'proxy hop -force', tab completes); 'run' lists them, 'run auto <name>'
  unchanged, old 'run <alias>' still works silently. Proxy Hop restores 50% max anonymity.
- Hacking console: 'cd ~' (also 'cd', 'cd /', 'home', 'root') returns to the main terminal from locations / targets.
- SQL card: EVERY includes SQL Booster, DMG includes Payload Amplifier.
- 'mod': new EFFECT column (`HackingMods.STAT_LABEL`) so values read "bandwidth regen (of max) / s  +20%"; Latency Injector shows -20%.
  The list re-prints after 'mod -add' / 'mod -rm' (IDs shift). Mod items say "manage this mod with the 'mod' command".
- apt: a finished tier whose next tier is locked shows "up to date" with a gold 10/10 bar; 'apt <skill>' lists that tier's
  installed packages plus "Next: Tier N opens with X access".
- Background Services text: "N h offline progression" (current cap only).
- Side panel: finished uploads sort to the bottom; the running Defrag boost shows at the very top (DefragBoostSection,
  shares the collapse-button row); the header Defragging card only shows the cooldown. Defragging costs no items.
- Tools: econ2 / econ_plan / xp_plan use RARE_P 0.25, extraction x2, efficiency as a basics multiplier.
- Open: Network cache variant (still 50% x 10-20 VM tokens) vs VM Caches; XP pacing together with the minor-process-levels idea.
- Tests: tools/tests/p4test.gd (headless checks), p4shot.gd (side panel screenshot).

## Playthrough pass 5 (2026-10-22, cdd)
- PROCESS UNLOCKED banner (MAJOR RELEASE frame) when a level up unlocks a process: `Exp.unlock_queue` +
  `process_unlocked_signal`; idle_os_2 `_flush_unlocks` prints at the main terminal, holds while hacking / booting / the
  offline download and prints on return. Tier-blocked processes add "requires X access".
- Hacking: 'kill -s' finishes the current hack and ends the run (`stop_after_win`); 'kill' prints what you walked away with.
- Breach crit is one per firewall break; a firewall that starts at 0 never "breaks", so no crit loop.
- Salvage finds 5-10 VM tokens per line (was 10-20; efficiency doubles). Defrag VM text drops "(60s per token)".
- 'mod' footer mentions 'ls mod'. ssh accepts a process's flag: 'ssh phishing whale' = Whaling.
- Tests: tools/tests/p5test.gd, p5kill.gd.

## Demo backlog (from player feedback, 2026-10-23) - port to demo-nextfest-2 once done on cdd
Feedback: no music; hard to see your situation (management game without an overview); inconsistent command grammar;
no "I'm lost" helper; first hour feels like 90% waiting. Plan, in order:
1. 'hint' command (next 1-3 commands from game state)  2. status overview  3. first-hour pacing pass (+ XP / minor-process
levels)  4. music  5. command-consistency audit.
Also already done on cdd and not yet in the demo: pass 4/5 fixes (ssh flags + plural, '-force' items, kill -s, process-unlocked banner, etc.).

## hint command + NEXT HACK row (2026-10-23, cdd) - demo backlog item 1
- scripts/hint_engine.gd (HintEngine, static): 'hint' / 'next' / 'lost' print up to 3 {cmd, why}. Order: tutorial step (only
  that while the tutorial runs) · overheated · caches · ready to hack · target access · affordable upgrade (tier, then
  speed > hacking > efficiency > rest > capstones) · chain bottleneck (walks payload <- compile <- match <- crack <- parse
  <- mine; SQL short -> phish -spear; forced in when the main terminal is idle) · spare VM token -> ssh · upload surplus · goal.
- Uploads only suggest the surplus over HintEngine.reserved(): next level of every open package + locked-target access
  + 3 hacks of payload. Conservative on purpose (Josh kept uploading stock he needed).
- 2 unrecognized commands in a row -> "lost? try hint" (add_line watches for not-found text during a command).
- Stats.usage (saved): rolling avg SQL / spoofs per win per target; recommended = avg x1.25, else a no-reboot estimate x1.5.
- Side panel AVAILABLE TO RUN: hacking row (best target, payload + SQL rec, spoofs once known; short parts in red).
- Mentioned in -h, the welcome message and both tutorial-complete messages. Tests: hinttest / hintup / hintshot.

## First-session timeline (2026-10-23) - tools/balance/first_hour.py
Tutorial with reading time (160/230/350 wpm) + typing + real T1 process speeds (tools/tests/rates1.gd):
first hack at ~14-15 min, tutorial done ~15-16 min, ~5 min of pure waiting (mine 35 logs ~1.5 min, parse 30 ~1.4 min).
At 10 min the player is matching credentials; 13 commands of terminal basics before any output. Reading speed barely
moves it: the waits and step count dominate. Real players are slower (typos, confusion): steam median session 14 min
is about where the model's first hack lands. Options discussed: hack-first tutorial, smaller tutorial counts, faster T1.

## Faster fights + tutorial hack kit (2026-10-23)
- SQL Injector speed 20 -> 25, bandwidth cost 6 -> 5 (items/combat/sql_injector.tres; combat_sim SQL_SPEED / SQL_COST).
  Student fight ~50s -> ~40s (sim), live test 35-45s; every tier's fights ~15-20% faster (enemy tuning not re-run yet).
- Live test (tools/tests/fight2.gd, 8 trials with cooling): 1 hack + 'hack student=2' with 35 SQL / 3 spoofs: 8/8 won,
  SQL used 26-30 (5-9 left), anonymity after the 2-run 12-26 of 105. Sim (1000 runs): 30 SQL = 100% but 0 left at worst,
  so the starter kit is 35. NB: an overheated system in a 2-run loses it (counters x2, bandwidth x0.5).
- Tutorial.ensure_hack_kit: during the tutorial's hack steps (KIT_STEPS), before hacking the Student, tops up to 1 payload
  + 12 SQL per hack + 3 spoofs, so 'kill' experiments can't strand the player (tools/tests/kittest.gd).
- Mod for the tutorial (sim, Student, cost 5 / speed 25): none 40s / 9.2 SQL · SQL Booster alone 57s (slower: +2 mod bw
  makes the attack bandwidth-bound) · Payload Amplifier 41s / 6.7 SQL · Burst Buffer 37s · Burst + Booster 27s.
- New tier 1 equippable mod: Handshake Exploit (items/hacking_mods/handshake_exploit.tres, id 358, MOD_TYPE.FW_OPENER = 29,
  value 10, 20 hacks): the first hit against a new firewall (start of each hack, after every reboot) deals +10 firewall
  damage (hacking_game fw_fresh; combat_sim "opener"). Joins the Phishing mod / Corruption tier 1 pools automatically.
  Student: sim 40s / 9.2 SQL -> 34s / 5.7 SQL; live (fight2m.gd) 6 SQL per fight, 2-run ends ~50% anonymity (vs ~15%).
  Feels good with the breach crit: handshake nearly breaks the firewall, the 3rd hit breaks it, the 4th crits.

## Hack-first tutorial (2026-10-23) - Tutorial ORDER_VERSION 3
- 23 steps: -h · cd hacking · view school · hack student · cd root · decode -cache · ls · parse (3 IPs) · crack 3 ·
  match 3 · compile 2 · mod -add (Handshake Exploit, in the first Student cache) · hack student=2 · decode both ·
  upload · upload logs 5 · upload parents credit card 1 · phish 10 SQL · mine · mine 15 · kill · apt · utility.
- Starter kit (Tutorial.STARTER_KIT: 1 payload, 35 SQL, 3 spoofs) when '-h' completes. ensure_hack_kit covers both hack steps.
- Tutorial.STEP_COMMANDS: each step's "command to run" line (window + terminal + hint). GATED_STEPS only count when current.
- Window stays up in the Hacking module while the tutorial runs. 'cd root' (and cd ~, cd /, cd) everywhere.
- Silent overheat guard while the tutorial runs (Stats.TUTORIAL_MAX_TEMP 92; overheat at 95).
- Old saves: finished stays finished; otherwise shared steps keep state (VIEW_SCHOOL / RETURN_TO_ROOT implied by the
  next step) and they continue from the first open one, kit given if they're past '-h' without a hack.
- 'utility' command (ContextCommands.utility_commands) + -h line. Equippable mods last 5 hacks (was 20); mod finds up:
  phish -mod 1% -> 1.5%, Corruption mod weight 2 -> 3.
- tools/tests/tutbot.gd plays the whole tutorial from STEP_COMMANDS: all 23 steps pass, 10.2 min of game time.
  With reading (230 wpm): first hack ~3.1 min (was 14.4), third hack ~9.6, done ~16 min.
- Tutorial pass 2 (2026-10-23): window drags by its title bar (double-click docks it; Tutorial.window_moved / window_pos
  saved). First Student cache no longer drops a VM cache. New steps: cd parsing before the parse step, NAVIGATE_CRACKING
  (cd .. / cd cracking) before crack; $PATH moved to the match step. Multi-command steps list one command per line
  ("commands to run, in order"). Hack-twice starts with 'cd root'. 25 steps; tutbot passes all of them.
- Tutorial pass 3 (2026-10-23): 26 steps. Parse 10 logs (PARSE_20_LOGS) instead of 3 IPs; START_CRACKING (main terminal
  runs Password) then CRACK_3_PASSWORDS = crack 5 with the Cracking VM token. Tutorial._step_needs tops up what the
  current step needs when it comes up (silent). complete_event: retired steps never complete; a step finished ahead
  of time is checked off quietly (no terminal line); the line names the step. -h: no 'mine -logs, crack' row, PROGRESS =
  upload + intel, cd root row; 'intel -h' box (ContextCommands.intel_help_commands); process -h lists kill -s / stop -s.
  hint ends with the GOAL line (upload the location's goal to unlock the next one).
- ssh mirrors the process commands (2026-10-23): 'ssh mine -logs', 'ssh parse -footprint=logs', 'ssh crack -password'...
  (idle_os_2 maps the verb via SKILL_BINARIES; 'ssh mining logs' still works). ssh tables, tab, hint, tutorial, errors
  all show the new form. -h gained 'info <skill>' and a VIRTUAL MACHINES section (ssh, ssh <process command>, vm -h);
  side panel's empty VM line: "'ssh' lists your tokens". Tutorial VM step mentions 'ssh'. Test: tools/tests/sshtest.gd.
- 2026-10-23: SQL / spoof "waiting for bandwidth (N)" shows the real cost (mods included). Target cards redraw when a hack
  ends (hacking_box.hacking_to_persons) so payload requirements are current. 'pin' / 'unpin' replace sticky in all text
  (sticky / stick / unsticky / unstick still work). utility box 96 wide. hint: upgrades are one general line near the
  bottom ("upgrades available: use 'apt'"). Last tutorial step mentions 'focus'.

## compile -mod retired + bait opened up (2026-10-23)
- ItemData.is_compilable_mod() is always false; Compiling.MOD left out of minor_processes (dict kept for old saves /
  offline). Gone from tab, info, ls item rows, -h, utility, glossary, flow chart, hacking header. 'ls mods' = the mod
  items you own. Compiled mods already equipped in a save still work until their hacks run out.
- OPEN: compiling.mod_tuning (6 levels) and compiling.debug_build (T3 capstone 'debug' modifier) only affected Mod:
  they need new effects (asked Josh).
- Bait: any basic resource of any tier (Phishing.is_bait = Decoding.get_resource_tier > 0); bait power / heat by the
  resource's location tier (Phishing.bait_tier). Rares, caches, SQL / spoofs, tokens aren't bait.
- Debug Build (Compiling T3 capstone) repurposed: 'debug' modifier = -50% speed, heat x1.5, each payload 10% chance
  (Compiling.DEBUG_INTEL_CHANCE) to give 1 intel find on a random unlocked target of its location (Compiling.debug_intel).
  Main terminal / VM only, not offline. Mod Tuning still OPEN (move to System?).
- Upgrade slots (2026-10-23, gen_upgrades.py + merged into data/upgrades.json): System Background Services 1 per tier
  (offline cap 2/4/8/12/18/24 h); new System pointed Kernel Modules (+1 hack per equipped mod per tier,
  HackingMods.mod_duration); Compiling Mod Tuning -> Code Signing (+2.5%/tier chance a payload gives 1 intel find,
  Debug's 10% stacks). Every group still 10 per tier. Upgrades save format 3: format-2 saves halve Background Services
  installs (rounded up); mod_tuning installs carry to code_signing (RENAMED). Test: tools/tests/upgtest.gd.

## Mods + one-time items pass (2026-10-23)
- 30 equippable mods, 5 per tier (HackingMods.pool_items; RETIRED_MOD_ITEMS: Shatter Protocol, Ghost Packet still work
  if owned). New items 359-371: Backdoor, Reset Loop (COUNTER_RESET), Hardened Shell, Fresh Start, Opening Spoof,
  Hot Streak, Double Tap, Bleed, Breach Momentum, Leech, Jitter, Failsafe, Data Hoarder (MOD_TYPE 30-41).
  SQL Booster has no mod bandwidth cost.
- 30 one-time items, 5 per tier (new ids 372-389), Exploits.DEFS costs 15-20 (T1) .. 40-50 (T6).
  Ghost Mode = no hits for 8s; Firewall Drain 3% of max/s; Freeze holds the firewall reboot timer; Overcharge adds
  before the crit multiplier; Port Knock banks its 15s when the firewall is up.
- Cache drops: 10% each of the tier's one-time items, 5% each of its mods (Deep Scan x2, Skim / Footprint none);
  drop tables show one row each ("one-time item (10% each of 5)", "hacking mod (5% each of 5)").
- Rare items whose upload goal is met: 'phish -mod' bait, 1 per cast, every cast lands a mod of the rare's tier
  (Phishing.is_rare_bait / tier_mod_pool / bait_cost; offline too). 'ls <rare>' shows the row (before / after).
- Balance harness: tools/tests/modbal.gd (live fights, MODTIER / MODLAST / MODTARGET env). Finding: the +2 bandwidth
  per equipped mod makes non-damage mods slower at tier arrival (bandwidth-bound); asked Josh about lowering it.

## Music (2026-10-23)
- Audiomanager playlist: shuffled, no repeats in a row, 3s crossfade into the next track, 4s fade-in after boot.
  Tracks in audio/music (Pixabay Content License): En Transe Mission (O-KSI-D), Sunlit Waves (sergepavkinmusic); Technology Background removed;
  credits in Audiomanager.TRACK_INFO, shown by 'music'. Add a track: drop the file in audio/music, add it to MUSIC,
  DEFAULT_UNLOCKED and TRACK_INFO.
- 'music' (now playing), 'music next', 'music off' / 'music on' (Settings music_player, saved per device);
  volume: 'settings music=<0-100>'. Equipped mod bandwidth is now +1 per mod (SQL Booster 0).

## Pass 6 notes (2026-10-24, cdd)
- One-time items are now called **Exploits** in player text (ls header, run list, hacking console, decoding, cache drops, ls -h, whale/trap descriptions, upgrade effects). Code names unchanged.
- Cache drop rows: "Exploit" / "Hacking Mod" (chance = at least one of the tier's 5, each rolls on its own: 10% each -> 41%, 5% each -> 23%).
- 'info phishing mod' lists only the catchable pool (Phishing.mod_pool), with each mod's share.
- Offline Mod Phishing rolls whole catches (job.apply). It used to spread the average over every mod and round each to 0 on a big pool (XP but no mods).
- A hack's overclock ends with the hack (hacking.gd hacking_ended).
- PROCESS UNLOCKED banner wraps the description at 90 chars; Intel description shortened.
- Overcharge text: no "(crits double it)". hint: apt now above upload surplus.
- Lag Spike is now **Firewall Crack** (T1, 15 charge): knocks 30% off the firewall that's left (breaks it at 0; blocked while it's down; auto-use above 50%). Internal id stays lag_spike / item 329 for saves.

## Pass 7 notes (2026-10-25, cdd)
- Hacking game: new EXPLOITS card between COMBAT LOG and YIELD. Owned Exploits two per row: name (purple when affordable), xN, charge cost, effect; head shows '<name> -force' / 'run auto <name>'. Rebuilt only when owned / affordable / auto changes (_refresh_exploit_list).
- Firewall Crack text: "Knock 30% off the firewall."
- Tab completion for ls filters (types, skills, single-word locations, t1..t6, -h) in CommandRegistry.
- Principal counter 3 -> 6, Superintendent 6 -> 8. School normal targets integrity / firewall -15% (Student 88/11, Admin 260/13, VP 301/22, Principal 348/16, Superintendent 445/18). Hard modes unchanged.
- School upload goal: basics 300 -> 150, rares 3 -> 1. Uploads.complete_met_tiers() on boot completes a tier an old save already meets.
- Terminal keeps 40 text blocks (was 10, ~200 lines): a full 'ls' kept losing its top.
- Bug: Patient insurance data had id 49 (same as Prescription pad credentials), so its saves loaded as the other item. Now 50.
- tools/review/savegame.json is the copy linked for Steam review (made before these changes; keep it as is for that build). tools/review/gensave.gd regenerates one.

## Pass 8 notes (2026-10-26, cdd)
- School: Vice Principal counter 6 -> 8; Principal firewall 16 -> 20; Superintendent firewall 18 -> 20, reboot 10 -> 5 s, counter 8 -> 14 every 4.0 s (counter speed 25).
- Exploit costs: Proxy Hop 60, Firewall Crack 50, Packet Flood 80, Smoke Screen 80, Overcharge 50.
- defrag -upload: +100% upload speed (half the time per item), was 20%.
- Upgrades: no rare items in any cost. Capstones (slot 10) cost CAP_COST_MULT (3.66) x the slot's main resource (T1: 271 Logs, 200 School payload, 6 Superintendent caches ...). gen_upgrades.py + json costs regenerated.
- 'ls <mod>': USED IN row reworded; HACKING MOD block shows effect, duration, bandwidth, equip commands.
- AVAILABLE TO RUN header: location name, no T1/T2.
- 'version' command (reads application/config/version in project.godot, now 0.1.3).
- Fixes: offline Mod Phishing empty pool at boot (Phishing._ensure_mod_list), intel per-stat levels now load (Decoding load_data), offline intel shown in the download, offline download rows fill together, completed upload bars shader (shaders/upload_complete.gdshader), uploading rows first.

## PLAN: skills, drivers, firmware (agreed 2026-10-26, not built yet; build slowly, UI/workflow first)
- Minor processes lose their own level/XP/efficiency. Only main skills level (Mining, Parsing ...).
  Each process gives skill XP (higher-tier processes give more).
- Efficiency comes from the skill level: one curve per skill x a per-process multiplier
  (e.g. Mining eff 50%: Logs x1.0 = 50%, Archives x0.5 = 25%). Chances need caps. apt upgrades are the other source.
- Skill levels gate nothing else. Processes unlock with tiers (upload goal -> new location): each tier unlock brings
  its chain (Mining/Cracking/Matching/Compiling tier process) + 1-3 utility processes, shown on a big tier-unlock screen.
  Open: unlock table, incl. a few milestone unlocks inside School (tutorial done, first upload, Administrator ...).
- DRIVERS (name agreed; not "modules": clashes with Kernel Modules / Modules singleton / hacking mods):
  permanent per-skill items, live inside the skill (not in ls). Affect HACKING, themed by skill
  (Cracking crits, Matching firewall, Phishing anonymity/spoofs, Parsing intel/counters, Decoding loot/charge,
  Compiling SQL dmg/speed, Mining bandwidth/endurance). Hacking itself has no drivers.
  - Slots: level 10, 30, 60 (3 per skill). Start with 5 drivers per skill (35 total). Some drivers locked behind
    hard-mode targets (first win). Equip/unequip inside the skill = free respec ('driver' command, mirrors 'mod').
  - Mastery = driver rank: equipped drivers rank up from that skill's XP. 3 ranks, rank 3 a bit bigger, no choice.
- FIRMWARE: level 99 reward per skill (RuneScape/Melvor cape idea): strong passive for that skill's own production.
- Themed targets so builds matter (Fortress / Swarm / Glass / Regenerator / Escalator ...), hard modes exaggerate.
- Phases: 1 foundation (tier unlocks, skill-only levels, efficiency curve, tier-unlock screen) -> 2 drivers in Mining
  only (slot, 2 drivers, UI) -> 3 ranks -> 4 all skills + hard-mode drops -> 5 themed targets -> 6 firmware ->
  7 old saves (drain into VM tokens / mods / exploits) + new demo cut. Demo: later.

## Phase 1 built (branch skill-revamp, 2026-10-26)
- Processes: "unlock tier" (1 = start) + "efficiency level" (old unlock level). Exp.refresh_process_unlocks opens them
  with Upgrades.tier_unlocked(tier); Stats.unlock_location refreshes with announce. Saves don't store unlocks.
- Efficiency: Exp.process_efficiency = base + rate x max(0, skill level - efficiency level) (balance kept: a later
  process still starts at its base when its old unlock level is reached). Refreshed on every level up and load.
- Process level / XP no longer tracked (keys left in the dicts, unused; legacy save keys ignored). add_xp only levels
  the skill. Defrag XP (Police, +50% skill XP) in Exp.add_xp.
- Defragging per tier: VM start, Upload Lawfirm, Cooling Hospital, Heat Bank, XP Police (Defragging.XP), Government TBD.
- Tier screen: ContextCommands.tier_complete_text lists NEW PROCESSES (tier_process_rows) + ALSO NEW; the per-process
  PROCESS UNLOCKED banners are gone (_flush_unlocks just clears Exp.unlock_queue).
- UI: info tables' UNLOCK column = location; process pages "Opens with"; header cards "LOCKED · <LOCATION>" and
  "+N xp" per cycle; locked messages via Exp.tier_block_reason / idle_os_2._locked_text; tutorial lines updated.
- Tests: tutbot 26/26 (707 s game time, was ~600 s), old saves load (demonf, olddemo, review), offline mining/matching ok.

## Phase 2 built (skill-revamp, 2026-10-27): drivers, Mining only
- singletons/Drivers.gd (autoload): DEFS (Mining: deep_reserves, steady_flow, stockpile, cool_head, long_haul),
  owned {id: xp while equipped}, equipped {skill: [ids]}, SLOT_LEVELS [10, 60] (2 slots max), RANK_XP [0, 25k, 150k].
  Saved under "drivers". No drop source yet (gauntlet idea open): DEV_GIVE 'driver give <id|all>'.
- Commands: 'driver' (in a skill: slots + owned; at root: summary), 'driver -add <id|name>', 'driver -remove <id>'.
- Exp.add_xp -> Drivers.add_skill_xp (rank ups announced) and Drivers.on_level_up ("<Skill> Driver slot unlocked.
  cd into <skill> to view more details.").
- hacking_game: Steady Flow (+dmg at max bandwidth), Long Haul (+dmg per breach this run, 5 stacks, hack_index - 1),
  Stockpile (chance to fire 2 SQL, double damage), Deep Reserves (chance no bandwidth), Cool Head (first overheat of a
  hack -> temp reset, deferred after Stats sets the overheat). Log tag DRV (gold), YOU card DRIVERS row.
- Driver UI pass (2026-10-27): 'driver' screen wording (AVAILABLE, '-', "Drivers increase in rank with <Skill> XP",
  no next-slot note in the title); Stockpile / Long Haul text. Header: gold slot pips left of LV on root cards
  (skill_header._pip_label) and a small "Drivers" card after the skill's main card in skill view.
- Fix: parsing log area sized for 10 + Rows lines (log_parsing_terminal._fit_log_area): the terminal no longer dips.
- Driver card bar: HeaderBar.segment_values (one segment per slot: -1 empty, 0..1 toward next rank, 1 = max rank).
- Offline: equipped drivers' XP shown in the download (report.drivers rows + rank lines), slot unlocks listed there;
  Offline.computing keeps level / rank / slot notices out of the terminal during compute. Resume after offline syncs
  the header to the resumed skill (idle_os_2._sync_header_to_context).

## Phase 4 built (skill-revamp, 2026-10-27): drivers for every skill but Hacking (35 total, Drivers.DEFS)
- Cracking crits, Matching firewall, Phishing spoofs, Parsing intel/countermeasures, Decoding loot/charge, Compiling
  SQL. Hooks in hacking_game (search "driver"/"Drivers.value"): attack (dmg mults, Hash Collision every Nth attack of
  the RUN, Master Key bypass, Cracked Wide / Credential Reuse fw dmg, Salted Hash refund), defense (Social Proof,
  Burner, Cheap Spoof, Lure extra free spoof), counter (Cover Story miss, Countermeasure Log stacks, Signal Boost),
  _counter_rate (Read Ahead: first countermeasure / (1 + v)), firewall break/reboot (Session Hijack, Token Replay,
  arms Master Key), win (Bonus Cache, Salvage Rights), _remove_required_resources (Payload Recycler), use_exploit
  (Refund), _apply_intel (Intel Reserve), start_hack (Head Start, Warm Start), Exploits.add_charge (Charged Up).
- Interpretations: Salted Hash / Signal Boost = % of max bandwidth; Credential Reuse = +% firewall damage per hit;
  Read Ahead "100% slower" = twice as long; Head Start tops charge up to the value at each hack's start.

## Phase 5 in progress (skill-revamp, 2026-10-27): target traits
- Stats.TRAITS (fortress, regenerator, swarm, heavy, escalator, siphon, heater + throttle, encrypted, packet_loss
  defined but unassigned), target "traits": [..]; Stats.trait_stats(target) = stats after traits (cards, hints, fights).
  School: VP fortress, Principal heavy, Superintendent swarm. Lawfirm: Paralegal siphon, Associate fortress,
  Lawyer regenerator, Partner escalator. Card TRAITS section (tag + plain text, no hints); hack header chips.
- Current values: fortress fw x1.6, integrity x0.7, reboot x0.5, no damage leaks through while it's up; regenerator 2%/s
  after 2 s unhit; swarm speed x3 / dmg x0.2; heavy speed x0.4 / dmg x4; escalator +4% per 5 s of the RUN (max +150%);
  siphon empties bandwidth per countermeasure; heater heat x2.5; throttle +2 bw; encrypted exploits x1.5; packet loss 2.
- tools/tests/traitbal.gd: TIER, GEAR=late|early, N, RUN (hacks per run, anonymity carries), ONLY (=exact), INTEL=0,
  DBG=ATK,FW. Gear = apt hacking+system up to the tier, skills at LEVEL_AT_TIER, locations up to the tier only.
- Round 3 (2026-10-27): heavy x5 dmg / x0.3 speed; Superintendent 340 integrity / 11 counter (was 445 / 14);
  Partner 880 / 17 (was 1113 / 21); Paralegal throttle (siphon unassigned). Results in the chat log of that day.

### 2026-10-28: Salvage Sweep, firewall reboot intel, Vice Principal
- `decoding.compression` (was a 2nd Yield) -> `decoding.salvage_sweep` (Batch Decode was tried first, then dropped):
  +2% per install (6 tiers, max 12%) chance per cache to also drop one Exploit or Hacking Mod of the cache's tier
  (even odds between the two, then a random item). Rolled in `Exploits.roll_drops`, so it follows the same rules
  (none on Skim / Footprint) and works offline. Drop tables show a "Sweep: Exploit/Mod" row once it's installed.
  `RENAMED` maps compression and batch_decode to it.
- Intel has a 5th stat, "firewall reboot": +2% per step (max +10%) on how long the firewall stays down. Old saves pad
  the new stat with their lowest level. Target cards show a Reboot row (after traits; intel as old -> new).
  `Stats.trait_stats` returns "firewall reboot"; `_fw_down_time` = that x (1 + intel).
- Vice Principal: integrity 180 (126 after Fortress), firewall reboot 15.5 (7.75s after Fortress, 8.5s with full intel).
  Harness (tier 1 late gear, SQL every ~4.1s): 1 hit on the downed firewall without intel, 2 with full intel
  (the 2nd lands ~0.4s before the reboot).

### 2026-10-28: Compromise (replaces hard mode) - School only
- `singletons/Compromise.gd` (autoload): LINEUPS (School: Student swarm, Student fortress, Administrator heavy,
  Vice Principal fortress, Principal heavy+throttle, Superintendent swarm+heater; traits replace the target's own).
  Fights are copies of the real targets with "_base" (Stats.target_key / target_place follow it, so intel and
  heat tier work). Cost 20 x tier payloads up front; unlocks with the tier's upload goals; prize = random unowned
  driver of the tier (a driver's tier = its place among its skill's DEFS). Refuses to start with all 7 owned
  (repeat rewards TBD).
- hacking_game: `setup(..., fights)`; `_compromise_win` (XP banked, 1 mod tick per fight, no caches, no
  Stats.record_win, next target via `_load_target` + reset - everything else carries over), `_compromise_complete`
  (XP + driver + console card), forfeits on trace / kill (kill -s refused). Sub label: "SCHOOL COMPROMISE ■▣□□□□ 2/6 · next".
- hacking.gd: `recon <location>` (numbered cards, no hack/reward sections, rules text under them via
  hacking_box._set_recon_info), `compromise -<location> [-overclock]`. `view x -hard` says it was replaced.
- Access panel: 7-pip driver bar per tier (gold per driver owned, name gold at 7/7). Target card: drivers / recon.
- Hard mode retired: "hard mode unlocked" forced false, hard targets never load as unlocked (data kept).
- Test: tools/tests/comptest.gd (WIN=1 big anonymity, FORFEIT=1, SHOTS=1, TS=time scale).

## Tiers 1-3 balance (2026-10-29/30, skill-revamp) - CURRENT STATE
Tier pass order (Josh): combats / upgrades / mods / exploits / drivers > new processes > resource averages.
Tiers 1-3 (School, Lawfirm, Hospital) are done; next is tier 4 (Bank). Josh does a full combat/progression check
before release.

### Testing (device shell, this round)
- Test copy `$HOME/new`; sync: `rsync -a --exclude .git --exclude _to_delete --exclude .godot --exclude traitbal.gd
  $HOME/mnt/idle-os-prototype/ $HOME/new/` (the working harness is `$HOME/new/traitbal.gd`; copy it back to
  `tools/tests/traitbal.gd` after changing it). Clear `$HOME/.local/share/IdleOS_Demo/savegame.json` before runs.
- Test scenes: `sed "s#res://p4test.gd#res://X.gd#" p4test.tscn > X.tscn`. Screens: `xvfb-run -a -s "-screen 0
  1920x1080x24" ... --resolution 1920x1080`, PNG to `_to_delete/`, stage + Read.
- `grep -v 'Game saved'`, never `grep -v saved` (it hid real lines twice). `os.lines` is trimmed: read the
  RichTextLabel's parsed text instead. Run harness processes one at a time (parallel runs distort times).
- traitbal.gd env: TIER, GEAR=late|early, LEVEL, N, RUN, TS (time scale), INTEL (default full, 0 = none), ONLY
  (substring, "=" exact), SLOTS, BUILD=a,b, COMP=1 (the tier's compromise lineup), TYPED=1 (BUILDS_TYPED[tier],
  legal typed-slot builds), DBG/DBGN. It unlocks targets like a player would (earlier tiers all, this tier up to
  the tested target, compromise = all) so max anonymity matches. Helpers (device home, not in the project):
  `$HOME/bal/one.sh <target> [slots]`, `$HOME/bal/comp3.sh <filter> [N]` (T3 compromise, LEVEL 28, INTEL=0).
- Loss penalties take SQL, so the harness "sql/win" number is no longer reliable.

### Max anonymity (2026-10-30)
- `Stats.set_max_anon`: 100 + 12 per target unlocked past the first + 100 per location past the first
  (MAX_ANON_PER_TARGET / MAX_ANON_PER_LOCATION). Hacking level no longer adds any (it only raises crit chance).
  School 100-148, Lawfirm 260-308, Hospital 420-468, Bank 580-628, Police 740-788, Gov 900-948.
- Recalculated on unlock_target / unlock_location / load. Locked target cards show "+N max anonymity when unlocked"
  (`Stats.anon_for_unlock`; a location's first target shows +112).

### Hacking mods: typed slots + reshuffle (2026-10-29/30)
- `HackingMods.SLOT_PATTERN = ["offense", "defense", "utility"]` repeating, MAX_MOD_SLOTS 6. Each mod has a type
  (SLOT_TYPE); `current_mods[mod].slot` stores its slot. `mod -rm <slot>`; a full type refuses the add (no swap).
  load_data refits mods, refunds extras as items and refreshes equipped values. Header shows OFF/DEF/UTL tags;
  `mod` list has a SLOT column and tier headers ("Tier N Mods (X caches, 'phish -mod=x')").
- Tiers: T1 Booster, Fresh Start, Hardened Shell, Decoy, Latency | T2 Amp, Vuln, Backdoor, Handshake, Burst Buffer,
  Reset Loop | T3 Overflow, Double Tap, Hot Streak, Opening Spoof, Proxy Chain, Breach Strike | T4 Bleed, Breach
  Momentum, Jitter, Leech, Packet Shredder | T5 IP Rotator, Silent Entry, Zero Hour, Cold Boot | T6 Failsafe,
  Mirror, Cascade, Data Hoarder.
- Values: Critical Overflow x3 crits; Vuln Scanner +15% crit (flat); Fresh Start first 3 attacks are guaranteed crits (2026-10-30);
  Double Tap needs 2x bandwidth; Opening Spoof's first spoof deals 2x its heal as damage; Decoy 2; Silent Entry 7s;
  Failsafe 40%; Breach Strike +25% crit for 5s after a firewall break; Backdoor 40%; Proxy Chain -2s spoof fill.
- Fresh Start vs SQL Booster (2026-10-30): Booster = sustained speed, Fresh Start = 3 opening crits (strong burst,
  useless into Fortress). The doc "IdleOS Hacking Mods" (Claude Docs) has the full list.

### Traits (Stats.TRAITS, current)
- regenerator 2%/s (fw too), any SQL hit pauses it for 0.3s; siphon drains bandwidth and jams regen 1.5s per
  countermeasure; heater heat x2.5, breaking the firewall vents 20 degrees, no heat from countermeasures while
  overheated; fortress "Huge firewall. Nothing gets through until it's down" (reboot x0.5); adaptive firewall
  grows 50% per reboot (reboot x0.5); packet_loss: every SQL / spoof shot consumes 3 (no extra effect).

### Hacking game
- Loss penalties (`_loss_penalties`): lose 10-20% of SQL and 5-10% of spoofs, an extra mod duration, and
  `Decoding.intel_knock_down` (every intel stat -1 level). `kill` under 20% anonymity counts as a loss (KILL_LOSS_ANON).
- Win streak: `hacking.win_streak` capstone (tier 2, replaced Recycler; Evasion moved to tier 3). The 5th win of a
  run of 5+ (or -1) gives the target's rare; shown on the target card once owned.
- SQL card DMG shows drivers that apply right now, incl. Weak Point (full intel) and Steady Flow (full bandwidth).
- Firewall row: "down Xs once broken"; exploits list grouped by tier.

### Compromise lineups
- School tuned 2026-10-28/29; Lawfirm Partner 520 integrity / 25 counter / 33 firewall.
- Hospital (2026-10-30, tested at 468 max anonymity, right build, no intel): Receptionist packet_loss 980/44/17.6/9s,
  Receptionist heavy 810/32/17.6/9s, Orderly throttle 760/41/24.2/7s, Nurse fortress 390/39/19.8 (reboot kept 4s:
  3s won 0%), Doctor regen+heater 440/29/22/5s, Chief adaptive+escalator 1100/37/17.6/fw 48 (reboot kept 3.5s).
  Win rates ~50-100%, Chief ~70% with the Escalator build.
- Hospital targets: Receptionist 850/60fw/35/16/10s adaptive, Orderly 660/38/37/22/8s heavy, Nurse 340/60/35/18/8s
  regen, Doctor 650/44/38/20/6s siphon, Chief 1400/60/105/22.22/7s swarm. Payloads 3/6/9/12/15.

### Economy
- Cache basics: rolls 75/60/45%, quantities x0.6-1.2, first target x0.5, second x0.75; Hospital, School and
  Lawfirm x0.7 on top. Decoding apt costs /4; Decoding Efficiency = flat +2.5% basics per install.
- `decode -skim`: always drops every basic at its minimum (never the rare); efficiency = chance for +50% basics.
- Uploads RARE_GOALS [1,3,4,5,6,7]; ACCESS_RARE_BY_TIER [2,2,3,3,5,5].
- Network: line chance 1.5% -> 3.5% at 99, no Pattern Cache, paced by NETWORK_TIME_BY_TIER (~90/120/.../240
  tokens/h by tier); Network caches always drop 1 to tier+1 VM caches.
- Corruption (parsing): ~4 Exploits/h at base speed, ~100 Mining items each.
- Phishing (unlock order Spear T1, Trap T2, Smish T3, Whaling T4, Mod T1):
  - Trap: 45 min real-time fill; full haul 68 SQL + 17 spoofs + 1 Exploit + 1 hacking mod (x2 baited); efficiency
    = bonus Exploit chance (15% -> 25%, grows from level 15).
  - Whaling (big game): 25% bite, 60-120s wait, 240s reel split across lines, 40-60 bundle, 30% Exploit per landed
    whale, 2700 XP, heat 8.1 per whale; ~8 whales / ~410 SQL+spoofs / ~2.5 Exploits per hour at base. Offline
    rolls the Exploit chance too.
  - Spear: ~525 SQL+spoofs/h at base, no Exploits; bait is expensive (~10k basics/h vs Whaling ~330).
- Exploits: Throttle Patch = next 10 SQL; Booster Shot = one spoof x2; Credential Stuffing = next 2 hits +50%
  firewall damage.

### Drivers / misc
- Driver RANK_XP [0, 25000, 600000]. Driver Manager at tier 3: `driver` (full view), `driver -add/-rm/-swap <old>
  <new>`, `driver build N [-save|-clear]`. Deep Reserves rolls once per full bar and can fire at 0 bandwidth.
- Offline: under 5s resumes silently, under 60s a one-line summary; partial-cycle credit. Defrag Cooling x2 cooling;
  Defrag XP moved to tier 6 (Bank Heat and Police processes TBD).
- Commands: `cd hacking/<loc> [-r|-recon]`, a location name -> `info hacking`, a skill name -> `info <skill>`.
  Dev: `uploads set/complete`, `intel full/clear`, `tutorial complete`, `add/rm <item>`.

### Still open
- Tier 4+ (Bank onward) combat / mods / exploits / drivers pass; Bank+ cache and economy check.
- Tier 6 apt: replacement for the mod-slot upgrade. Defrag processes for Bank and Police.
- Release: `DEV_ITEM_COMMANDS`, `Drivers.DEV_GIVE` (and the other DEV flags) off.
