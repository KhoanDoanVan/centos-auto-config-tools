from pathlib import Path
import sys
import fitz

pdf_path = Path(sys.argv[1])
out_dir = Path(sys.argv[2])
out_dir.mkdir(parents=True, exist_ok=True)
doc = fitz.open(pdf_path)
matrix = fitz.Matrix(1.7, 1.7)
for index, page in enumerate(doc):
    pix = page.get_pixmap(matrix=matrix, alpha=False)
    pix.save(out_dir / f"page-{index + 1}.png")
print(f"Rendered {len(doc)} pages from {pdf_path}")
