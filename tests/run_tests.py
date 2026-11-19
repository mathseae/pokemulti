"""Runs every test. Prints ALL OK when everything passes.
Needs Python 3.8+ and lua5.1 (or lua) on PATH."""
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LUA = shutil.which("lua5.1") or shutil.which("lua")


def run(cmd, **kw):
    r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, **kw)
    sys.stdout.write(r.stdout + r.stderr)
    return r.returncode == 0


def two_player_scenario():
    """Both player scripts on a fake DeSmuME. P2 must draw P1 two tiles to the right."""
    with tempfile.TemporaryDirectory() as tmp:
        luadir = os.path.join(tmp, "lua")
        shutil.copytree(os.path.join(ROOT, "lua"), luadir)
        os.makedirs(os.path.join(tmp, "link"))
        with open(os.path.join(luadir, "addresses_local.lua"), "w") as f:
            f.write('return { IRBO = { map = { addr = 0x02200000 }, x = { addr = 0x02200010 },'
                    ' y = { addr = 0x02200014 } } }\n')
        fake = os.path.join(ROOT, "tests", "fake_desmume.lua")
        log1, log2 = os.path.join(tmp, "g1.log"), os.path.join(tmp, "g2.log")
        ok = run([LUA, fake, luadir + os.sep, "1", "20", "389", "12", "30", log1])
        ok = ok and run([LUA, fake, luadir + os.sep, "2", "20", "389", "10", "30", log2])
        if not ok:
            return False
        p1_file = open(os.path.join(tmp, "link", "p1.txt")).read()
        boxes = [l for l in open(log2).read().splitlines() if l.startswith("box|")]
        # P1 at x=12, P2 at x=10 -> marker center 128 + 2*16 = 160.
        good = p1_file.startswith("PM1|") and boxes and boxes[-1] == "box|153|97|167|111"
        print("scenario:", "ok" if good else f"FAIL p1={p1_file!r} boxes={boxes[-1:]}")
        return good


def main():
    if not LUA:
        print("lua5.1 not found")
        return 1
    results = [
        run([LUA, "tests/test_lua.lua"]),
        run([sys.executable, "-I", "tests/test_relay.py"]),
        two_player_scenario(),
    ]
    print("ALL OK" if all(results) else "FAILED")
    return 0 if all(results) else 1


if __name__ == "__main__":
    sys.exit(main())
