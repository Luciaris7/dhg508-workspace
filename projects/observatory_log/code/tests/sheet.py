"""python tests/sheet.py out.png a b c ...  -> 2-column contact sheet at 640x360 per shot."""
import sys
import os
from PIL import Image

here = os.path.dirname(os.path.abspath(__file__))
out = sys.argv[1]
names = sys.argv[2:]
cols = 2
w, h = 640, 360
rows = (len(names) + cols - 1) // cols
sheet = Image.new("RGB", (cols * w, rows * h), (30, 30, 30))
for i, n in enumerate(names):
    im = Image.open(os.path.join(here, "_shots", n + ".png")).convert("RGB").resize((w, h), Image.NEAREST)
    sheet.paste(im, ((i % cols) * w, (i // cols) * h))
sheet.save(out)
