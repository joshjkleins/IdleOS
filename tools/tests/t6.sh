# t6.sh <=name> [N]: tier 6 normal target, GEAR=prog (T=timeout, B=builds)
cd $HOME/new
TYPED=1 TIER=6 GEAR=prog LEVEL=${L:-42} INTEL=0 SLOTS=6 N=${2:-3} RUN=1 TS=100 BUILD="${B:-}" ONLY="$1" timeout ${T:-85} $HOME/Godot_v4.4.1-stable_linux.x86_64 --headless --path . res://traitbal.tscn 2>&1 | grep '>>>\|SCRIPT ERR' | grep -v 'TIER\|skipped\|max anon' | sed 's/>>> //;s/hacks  //' | sed 's/  sql.*anon end/  anon end/'
