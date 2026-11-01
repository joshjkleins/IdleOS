# comp6.sh <name filter> [N]: Government compromise fights matching the filter
cd $HOME/new
COMP=1 TYPED=1 TIER=6 GEAR=late LEVEL=42 INTEL=0 SLOTS=6 N=${2:-3} RUN=1 TS=100 ONLY="$1" timeout ${T:-85} $HOME/Godot_v4.4.1-stable_linux.x86_64 --headless --path . res://traitbal.tscn 2>&1 | grep '>>>' | grep -v 'TIER\|skipped\|max anon' | sed 's/>>> //;s/hacks  //' | sed 's/  sql.*anon end/  anon end/'
