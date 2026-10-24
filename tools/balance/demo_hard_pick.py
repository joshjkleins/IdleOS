import demo_hard_tune as h, itertools, combat_sim as cs
from multiprocessing import Pool
C = [(250,28,16,19.0),(270,24,18,18.0),(250,24,19,18.0),(300,24,18,17.0)]
def one(E4):
    I,F,Cc,S = E4
    E = {"integrity": I, "firewall": F, "counter": Cc, "counter speed": S, "heat": 0.5, "firewall reboot": 10.0}
    n = 40
    sing = {k: round(cs.summary(h.P({k: v}), E, 0, n)["win"], 2) for k, v in h.MODS.items()}
    pr = {}
    for a, b in itertools.combinations(h.MODS, 2):
        r = cs.summary(h.P({a: h.MODS[a], b: h.MODS[b]}), E, 0, n)
        pr[a + "+" + b] = (round(r["win"], 2), int(r["time"]))
    return E4, sing, pr
if __name__ == "__main__":
    with Pool() as p:
        for E4, s, pr in p.map(one, C):
            good = {k: v for k, v in pr.items() if v[0] >= 0.7}
            print(E4, "singles", s)
            print("   pairs>=70%:", len(good), good)
