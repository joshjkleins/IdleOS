"""Reads the recalculated upgrade sheet and writes the game's data/upgrades.json.
Run after editing the sheet (and recalculating): python3 export_upgrades.py idleos_upgrades.xlsx out.json"""
import json, re, sys, openpyxl

src, out = sys.argv[1], sys.argv[2]
ws = openpyxl.load_workbook(src, data_only=True)["All Upgrades"]
hdr = [c.value for c in ws[1]]
col = {h: i for i, h in enumerate(hdr)}

def cost_items(text, amount):
    """'Logs' / 'IP address + Encrypted passwords + Usernames (each)' / 'Logs (decoded from caches)' / 'VM tokens (any skill)'"""
    if text.startswith("VM tokens"):
        return [{"item": "@vm_tokens", "amount": int(amount)}]
    each = text.endswith("(each)")
    text = re.sub(r"\s*\(.*\)\s*$", "", text)
    names = [n.strip() for n in text.split(" + ")]
    return [{"item": n, "amount": int(amount)} for n in names] if each else [{"item": names[0], "amount": int(amount)}]

groups, packages, order = [], {}, []
for r in ws.iter_rows(min_row=2, values_only=True):
    g = r[col["Group"]]
    if g is None:
        continue
    if g not in groups:
        groups.append(g)
    pid = r[col["Package id"]]
    stype = r[col["Slot type"]]
    name = r[col["Upgrade"]].replace("MAJOR: ", "")
    if pid not in packages:
        packages[pid] = {"id": pid, "group": g, "name": name, "type": stype.lower(),
                         "effect": r[col["Effect"]], "levels": []}
        order.append(pid)
    gv = r[col["Game value"]]
    level = {
        "tier": int(r[col["Tier"]]),
        "slot": int(r[col["Install #"]]),
        "value": gv if isinstance(gv, bool) else float(gv),
        "label": r[col["Per-install value"]],
        "before": r[col["Before install"]] or "",
        "after": r[col["Total after install"]] or ("installed" if stype == "Capstone" else ""),
        "effect": r[col["Effect"]],
        "costs": cost_items(r[col["Cost item"]], r[col["Amount"]]),
    }
    if r[col["Capstone rare"]]:
        level["costs"].append({"item": r[col["Capstone rare"]], "amount": int(r[col["Rares"]])})
    packages[pid]["levels"].append(level)

data = {"format": 2, "groups": groups, "packages": [packages[p] for p in order]}
with open(out, "w") as f:
    json.dump(data, f, indent=1)
print("groups", len(groups), "packages", len(order), "levels", sum(len(p["levels"]) for p in data["packages"]))
