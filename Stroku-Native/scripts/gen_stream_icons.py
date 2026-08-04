"""Generate small gray icons matching the Stremio stream list style.

Icons are simple line-art on transparent backgrounds, 48x48 with a
3-pixel stroke and 8-bit+alpha. The StreamCard will scale them to ~28px.
"""
from PIL import Image, ImageDraw
from pathlib import Path

SIZE = 48
STROKE = 4
COLOR = (200, 200, 210, 255)
OUTPUT_DIR = Path(__file__).resolve().parents[1] / "images"


def new_canvas():
    return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))


# 1) People / seeders — three small heads + shoulders
def draw_people():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    # Three head circles
    head_y = 14
    cx = [12, 24, 36]
    for x in cx:
        d.ellipse([x - 5, head_y - 5, x + 5, head_y + 5], outline=COLOR, width=STROKE)
    # Shoulder arcs beneath
    for x in cx:
        d.arc([x - 8, head_y + 2, x + 8, head_y + 22], 200, 340, fill=COLOR, width=STROKE)
    # Base connecting line
    d.line([(6, 38), (42, 38)], fill=COLOR, width=STROKE)
    return img


# 2) Floppy disk / file size
def draw_floppy():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    # Body with notched top-right
    d.rectangle([8, 10, 40, 40], outline=COLOR, width=STROKE)
    # Metal shutter (top)
    d.rectangle([14, 10, 30, 20], outline=COLOR, width=STROKE)
    # Label area
    d.rectangle([14, 24, 34, 36], outline=COLOR, width=STROKE)
    # Bottom red bar (the Stremio accent)
    d.rectangle([8, 36, 40, 40], fill=(220, 60, 70, 255))
    return img


# 3) Gear / tracker source
def draw_gear():
    img = new_canvas()
    d = ImageDraw.Draw(img)
    cx, cy, r_outer, r_inner = 24, 24, 16, 8
    # Eight teeth as rotated rectangles
    import math
    for i in range(8):
        a = i * (math.pi / 4)
        x1 = cx + math.cos(a) * (r_outer - 2)
        y1 = cy + math.sin(a) * (r_outer - 2)
        x2 = cx + math.cos(a) * (r_outer + 4)
        y2 = cy + math.sin(a) * (r_outer + 4)
        d.line([(x1, y1), (x2, y2)], fill=COLOR, width=STROKE)
    # Outer ring
    d.ellipse([cx - r_outer, cy - r_outer, cx + r_outer, cy + r_outer],
              outline=COLOR, width=STROKE)
    # Inner hole
    d.ellipse([cx - r_inner, cy - r_inner, cx + r_inner, cy + r_inner],
              outline=COLOR, width=STROKE)
    return img


for name, fn in [("icon_seeds.png", draw_people),
                 ("icon_size.png", draw_floppy),
                 ("icon_tracker.png", draw_gear)]:
    out = fn()
    out.save(OUTPUT_DIR / name)
    print(name, out.size)
