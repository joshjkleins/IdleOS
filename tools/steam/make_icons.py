"""2026-11-03: Steam achievement icons (256x256 PNG, <API>_ACHIEVED / <API>_UNACHIEVED for the Steamworks bulk upload) in IdleOS's terminal style.
Run from the project root: python3 tools/steam/make_icons.py -> tools/steam/achievements/<API>.png / <API>_locked.png
(drawn at 4x and scaled down for clean edges). Also writes tools/steam/achievements.csv for the Steamworks entries."""
import os, csv, re
from PIL import Image, ImageDraw, ImageFont, ImageOps, ImageEnhance
S = 4; W = 64 * S
OUT = "tools/steam/achievements"
FONT = "fonts/ttf/JetBrainsMono-ExtraBold.ttf"
BG = (11, 14, 17); TILE = (16, 21, 26)
TIER = ["#3d8a3d", "#2aa198", "#3B82F6", "#c6a700", "#d8743a", "#d83a3a"]
SK = {"Mining": "#7a4a2e", "Parsing": "#ec4899", "Cracking": "#f2600c", "Matching": "#eab308", "Compiling": "#8b5cf6", "Phishing": "#3b82f6"}
G, GOLD, PURP, RED, BLUE, TXT = "#4ec994", "#ffc24a", "#c084fc", "#e5484d", "#60a5fa", "#e6e8eb"
# API -> (glyph, caption, colour) ; glyph "HAT_W"/"HAT_B" = drawn hat, "DOTS" caption = the 5 skill dots
ICONS = {
	"FIRST_BREACH": (">_", "BREACH", G),
	**{"TIER_%d" % t: ("T%d" % t, "UPLOAD", TIER[t - 1]) for t in range(1, 7)},
	**{"COMPROMISE_%d" % t: ("C%d" % t, "PWNED", TIER[t - 1]) for t in range(1, 7)},
	"WHITE_HAT": ("HAT_W", "WHITE", "#d7dde3"), "BLACK_HAT": ("HAT_B", "BLACK", RED),
	"SKILL_50": ("50", "LEVEL", G), "SKILL_99": ("99", "LEVEL", GOLD), "ALL_99": ("99", "ALL", GOLD),
	"FIRMWARE_1": ("FW", "FLASH", "#e0c068"), "FIRMWARE_ALL": ("FW", "ALL 9", GOLD),
	"HACKS_100": ("100", "WINS", G), "FIRST_EXPLOIT": ("0D", "EXPLOIT", PURP), "FULL_MODS": ("MOD", "6/6", "#e0c068"),
	"DRIVER_R3": ("R3", "DRIVER", GOLD), "FIRST_VM": ("VM", "SSH", BLUE), "QUEUE_6": ("Q6", "QUEUE", G),
	"OFFLINE_24": ("24h", "AFK", BLUE), "ALERT_CLEARED": ("0%", "ALERT", G), "OVERHEAT": ("°C", "HOT", "#ff5a3c"),
	"SUDO_RM": ("rm", "-rf", RED), "STUDENT_100": ("A+", "x100", G), "FULLY_AUTOMATED": ("AUTO", "DOTS", TXT),
	"HACKERMAN": ("#", "ROOT", GOLD),
}
def rgb(h): h = h.lstrip("#"); return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))
def font(px): return ImageFont.truetype(FONT, px)
def fit(d, text, max_w, start):
	px = start
	while px > 8:
		f = font(px); b = d.textbbox((0, 0), text, font=f)
		if b[2] - b[0] <= max_w: return f
		px -= 2
	return font(px)
def hat(d, col, mirror):
	pts = [(0.30, 0.80), (0.45, 0.42), (0.52, 0.18), (0.60, 0.06), (0.74, 0.04), (0.64, 0.14), (0.60, 0.30), (0.66, 0.55), (0.72, 0.80)]
	brim = [(0.02, 0.86), (0.12, 0.76), (0.88, 0.76), (0.98, 0.86), (0.90, 0.96), (0.10, 0.96)]
	ox, oy, sz = 14 * S, 8 * S, 36 * S
	tr = lambda p: (ox + ((1 - p[0]) if mirror else p[0]) * sz, oy + p[1] * sz)
	d.polygon([tr(p) for p in pts], fill=col); d.polygon([tr(p) for p in brim], fill=col)
def icon(api):
	glyph, cap, col = ICONS[api]; c = rgb(col)
	im = Image.new("RGB", (W, W), BG); d = ImageDraw.Draw(im)
	m = 3 * S
	d.rounded_rectangle([m, m, W - m, W - m], radius=4 * S, fill=TILE, outline=tuple(int(x * 0.55) for x in c), width=S)
	d.rectangle([m + 2 * S, m, W - m - 2 * S, m + 2 * S], fill=c) # top accent, like the target cards
	for y in range(m + 4 * S, W - m, 3 * S): # faint scanlines
		d.line([(m + S, y), (W - m - S, y)], fill=(20, 26, 32), width=1)
	if glyph.startswith("HAT"):
		hat(d, c, glyph == "HAT_W")
	else:
		f = fit(d, glyph, 46 * S, 30 * S if len(glyph) <= 2 else 24 * S)
		b = d.textbbox((0, 0), glyph, font=f)
		d.text(((W - (b[2] - b[0])) / 2 - b[0], 27 * S - (b[3] - b[1]) / 2 - b[1]), glyph, font=f, fill=c)
	if cap == "DOTS":
		for i, k in enumerate(["Mining", "Parsing", "Cracking", "Matching", "Compiling"]):
			cx = W / 2 + (i - 2) * 8 * S
			d.ellipse([cx - 2.5 * S, 50 * S - 2.5 * S, cx + 2.5 * S, 50 * S + 2.5 * S], fill=rgb(SK[k]))
	else:
		f = fit(d, cap, 44 * S, 8 * S)
		b = d.textbbox((0, 0), cap, font=f)
		d.text(((W - (b[2] - b[0])) / 2 - b[0], 50 * S - (b[3] - b[1]) / 2 - b[1]), cap, font=f, fill=(136, 136, 136))
	# 2026-11-03: Steam recommends 256x256 (S = 4 draws at that size already)
	locked = ImageEnhance.Brightness(ImageOps.grayscale(im).convert("RGB")).enhance(0.55)
	return im, locked
# names / descriptions / hidden from singletons/Achievements.gd DEFS
src = open("singletons/Achievements.gd", encoding="utf-8").read()
defs = re.findall(r'\["([A-Z0-9_]+)", "([^"]*)", "([^"]*)", (true|false)\]', src)
os.makedirs(OUT, exist_ok=True)
with open("tools/steam/achievements.csv", "w", newline="", encoding="utf-8") as fh:
	w = csv.writer(fh); w.writerow(["API name", "Display name", "Description", "Hidden", "Icon", "Locked icon", "Progress stat"])
	for api, name, desc, hidden in defs:
		a, l = icon(api)
		a.save("%s/%s_ACHIEVED.png" % (OUT, api)); l.save("%s/%s_UNACHIEVED.png" % (OUT, api)) # Steamworks bulk upload names
		w.writerow([api, name, desc, "yes" if hidden == "true" else "no", "%s_ACHIEVED.png" % api, "%s_UNACHIEVED.png" % api, "HACKS_WON >= 100" if api == "HACKS_100" else ""])
# contact sheet for a quick look
cols = 9; rows = (len(defs) + cols - 1) // cols
sheet = Image.new("RGB", (cols * 72, rows * 2 * 72), BG)
for i, (api, *_r) in enumerate(defs):
	x, y = (i % cols) * 72 + 4, (i // cols) * 144 + 4
	sheet.paste(Image.open("%s/%s_ACHIEVED.png" % (OUT, api)).resize((64, 64), Image.LANCZOS), (x, y)); sheet.paste(Image.open("%s/%s_UNACHIEVED.png" % (OUT, api)).resize((64, 64), Image.LANCZOS), (x, y + 72))
sheet.save("_to_delete/screens/achievement_icons.png")
print(len(defs), "achievements ->", OUT)
