#!/usr/bin/env python3
"""Seeds the GrowLog database with data that makes every count-dependent string appear.

usage: seed_db.py <growlog.db> <app files dir for photos>
Plants: 17 in 3 rooms (Room A 2, Room B 3, Room C 12). Watering state (frequency 7 days unless noted):
  P01 overdue 2, P02 overdue 1, P03 overdue 5, P04 overdue 15, P05 due in 5, P06..P16 due today, P17 (14 day cycle) due in 12.
  => 15 plants need care today. Two wishlist plants. Photos: P01 has 3, P02 has 2, P03 has 11. P01 has 2 Doctor scans.
"""
import sqlite3, sys, datetime as dt

db, photodir = sys.argv[1], sys.argv[2]
now = dt.datetime.now().replace(microsecond=0)
iso = lambda d: d.isoformat()
ago = lambda days: now - dt.timedelta(days=days)
con = sqlite3.connect(db); con.execute("PRAGMA foreign_keys=OFF"); cur = con.cursor()
for t in ("care_logs", "photos", "measurements", "scans", "plants", "rooms"):
    try: cur.execute(f"DELETE FROM {t}")
    except Exception as e: print("skip", t, e)

def cols(t): return {r[1]: (r[2], r[3], r[4]) for r in cur.execute(f"PRAGMA table_info({t})")}
def insert(t, **kw):
    c = cols(t); row = {}
    for name, (typ, notnull, dflt) in c.items():
        if name in kw: row[name] = kw[name]
        elif notnull and dflt is None: row[name] = "" if "TEXT" in typ.upper() else 0
    ks = list(row); cur.execute(f"INSERT INTO {t}({','.join(ks)}) VALUES({','.join('?'*len(ks))})", [row[k] for k in ks])

for rid, name in (("r1", "Room A"), ("r2", "Room B"), ("r3", "Room C")):
    insert("rooms", id=rid, name=name, icon="", sortOrder=0)

plan = []  # (id, name, room, waterDays, lastWateredDaysAgo)
plan += [("p01", "P01", "r1", 7, 9), ("p02", "P02", "r1", 7, 8), ("p03", "P03", "r2", 7, 12), ("p04", "P04", "r2", 7, 22), ("p05", "P05", "r2", 7, 2)]
plan += [(f"p{n:02d}", f"P{n:02d}", "r3", 7, 7) for n in range(6, 17)]
plan += [("p17", "P17", "r3", 14, 2)]
for pid, name, room, wd, last in plan:
    insert("plants", id=pid, name=name, species="Monstera deliciosa", roomId=room, acquiredDate=iso(ago(60)), createdAt=iso(ago(60)),
           isDead=0, isWishlist=0, waterFrequencyDays=wd)
    insert("care_logs", id=f"c_{pid}", plantId=pid, type="water", date=iso(ago(last)))
for wid, name in (("w1", "Wish A"), ("w2", "Wish B")):
    insert("plants", id=wid, name=name, species="", roomId=None, acquiredDate=iso(ago(1)), createdAt=iso(ago(1)), isDead=0, isWishlist=1)

def photo(n): return f"{photodir}/seed_{n % 3}.jpg"
k = 0
for pid, days in (("p01", (40, 20, 1)), ("p02", (10, 1)), ("p03", tuple(range(20, -1, -2)))):
    for d in days:
        k += 1; insert("photos", id=f"ph{k}", plantId=pid, date=iso(ago(d)), path=photo(k))
for i, (d, health, issue) in enumerate(((5, "healthy", ""), (2, "attention", "Yellow lower leaves"))):
    insert("scans", id=f"s{i}", plantId="p01", imagePath=photo(i), createdAt=iso(ago(d)), isPlant=1, commonName="Swiss cheese plant",
           latinName="Monstera deliciosa", confidence="high", health=health, issue=issue, severity="mild", summary="Seeded scan for the test.",
           treatment="", prevention="", waterDays=7, fertilizeDays=30)
con.commit()
print({t: cur.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0] for t in ("rooms", "plants", "care_logs", "photos", "scans")})
con.close()
