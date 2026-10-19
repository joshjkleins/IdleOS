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
- Testing flags stay ON while developing: `Tutorial.DEV_ALWAYS_SHOW_INTRO := true` (intro every launch), `idle_os_2.DEV_ITEM_COMMANDS := true` (add/rm), `Exp.DEV_MAX_ALL := true` (all skills/processes level 99,
  unlocked) and `Upgrades.DEV_UNLOCK_ALL_TIERS := true`. Turn both off before release.
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

### Left (designs are in the sheet; wire one per step, add the group to WIRED_GROUPS)
- ~~Phishing~~ DONE (kept for reference): speed, efficiency (bite chance, 20% max), lines (+1/tier), bait_power (+5%),
  bait_recycling (+5% bait kept), quick_hook (-5% reel). Capstones: overclock, tackle_box, lure (mod:
  -50% speed, heat x1.5, 3% per catch to also hook a hacking mod item), chum (mod: -40% speed, catches
  doubled, token x2, heat x2), survey, deep_water. All done. Re-measure Phishing's rate
  for the sheet afterwards.
- **Decoding:** speed, efficiency (rare chance, +4% max), yield (+10% basics), rare_tracker (+0.25% rare
  chance per dry cache per tier level, resets on a rare), compression (+10% packaged), field_notes
  (+1 intel hack). Capstones: overclock, token_vault, index (mod: -50% speed, heat x1.5, each decoded
  cache adds 1 intel point on its target), forensics (mod: -40% speed, one-time item chance x2, token x2,
  heat x2), survey, clean_room. ALSO: rare chance down — CACHE "efficiency" 0.1 -> 0.04,
  "efficiency rate" 0.001 -> 0.0004 (4% at L1, ~8% at L99).
- **Compiling:** speed (Compiling uses `get_fill_rate`, which doesn't apply modifier speed yet),
  efficiency (burst chance, 20%), recovery (20%), linker (+2.5% double payload), mod_tuning (+5% compiled
  mod strength). Capstones: overclock, build_cache, debug (mod: -50% speed, heat x1.5, compiled mods last
  +50% hacks), optimize (mod: -40% speed, burst x2, token x2, heat x2), survey, cold_build.
- **Hacking:** damage (+5, and +0.1 attack heat per level), firewall (+2), bandwidth_recovery
  (+0.5/s, 2 per tier), max_bandwidth (+5), healing (Packet Spoof restores 5% of max anonymity, +1% per
  tier — percent-based now), mod_slots (+1/tier; HackingMods.refresh_slots already reads it),
  spoof_threshold (+10%: 30% -> 90%), persistent_session (+10% EXPLOIT charge gain). Capstones:
  clean_exit (keep 50% banked caches when traced), evasion (10% dodge), recycler (50% SQL not consumed),
  siphon (each SQL hit restores 1 anonymity), dead_mans_switch (once per session survive at 1 + restore
  25%), exploit_kit (50% one-time item not consumed). Max anonymity becomes hybrid:
  100 + 5 x (Hacking level - 1) + 100 x (tiers unlocked - 1); then remove LEGACY_DEFAULTS. Hacking
  overclock and `-r` stay always available unless Josh decides otherwise.

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

## Backlog (Josh's list, in order after upgrades)
1. Offline progression (Background Services sets the cap; 24 h at max).
2. Game-loop chart.
3. `ls` filters (`ls school`, `ls cache`) and inventory display (items have a `tier` field).
- Later: unique combat interactions (maybe a final enemy per location, likely hard mode only),
  Phishing higher tiers (Whaling/Smish/Trap placeholders).
