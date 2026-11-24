"""UTF-8-safe multi replace:  python patch.py file.json
JSON: {"file": "...", "subs": [["old", "new"], ...]}  -- every old must match exactly once."""
import json
import sys

spec = json.load(open(sys.argv[1], encoding="utf-8"))
for item in spec:
    path = item["file"]
    s = open(path, encoding="utf-8").read()
    for old, new in item["subs"]:
        n = s.count(old)
        if n != 1 and not item.get("all"):
            print("MISS (%d) in %s: %s" % (n, path, old[:70].replace("\n", "\\n")))
            continue
        s = s.replace(old, new)
    open(path, "w", encoding="utf-8", newline="\n").write(s)
print("patched")
