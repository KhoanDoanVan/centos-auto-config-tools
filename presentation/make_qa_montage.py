from pathlib import Path
import sys
from PIL import Image, ImageOps, ImageDraw

src = Path(sys.argv[1])
out = Path(sys.argv[2])
cols = int(sys.argv[3])
files = sorted(src.glob("page-*.png"), key=lambda p: int(p.stem.split("-")[1]))
thumb_w = 620
thumbs = []
for file in files:
    image = Image.open(file).convert("RGB")
    ratio = thumb_w / image.width
    thumb = image.resize((thumb_w, int(image.height * ratio)))
    thumb = ImageOps.expand(thumb, border=2, fill="#BDBDBD")
    canvas = Image.new("RGB", (thumb.width, thumb.height + 34), "white")
    canvas.paste(thumb, (0, 34))
    ImageDraw.Draw(canvas).text((12, 9), file.stem, fill="black")
    thumbs.append(canvas)
rows = (len(thumbs) + cols - 1) // cols
cell_w = max(x.width for x in thumbs)
cell_h = max(x.height for x in thumbs)
sheet = Image.new("RGB", (cell_w * cols, cell_h * rows), "#E8E8E8")
for index, thumb in enumerate(thumbs):
    x = (index % cols) * cell_w
    y = (index // cols) * cell_h
    sheet.paste(thumb, (x, y))
sheet.save(out)
print(out)
