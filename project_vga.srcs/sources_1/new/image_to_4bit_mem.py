from pathlib import Path
from PIL import Image
import sys

WIDTH = 640
HEIGHT = 480

PALETTE = [
    (0x1, 0x0, 0x2),
    (0x1, 0x2, 0x3),
    (0x1, 0x4, 0x5),
    (0x1, 0x6, 0x7),
    (0x1, 0x8, 0x9),
    (0x1, 0xA, 0xB),
    (0x2, 0xC, 0xD),
    (0x4, 0xE, 0xF),
    (0x6, 0x3, 0x2),
    (0x8, 0x5, 0x4),
    (0xA, 0x7, 0x6),
    (0xC, 0x9, 0x8),
    (0xE, 0xA, 0x9),
    (0xF, 0xC, 0xB),
    (0xF, 0xE, 0xD),
    (0xF, 0xF, 0xF),
]


def nearest_palette_index(rgb):
    r, g, b = rgb
    r4, g4, b4 = r >> 4, g >> 4, b >> 4
    best_i = 0
    best_dist = 10**9
    for i, (pr, pg, pb) in enumerate(PALETTE):
        dist = (r4 - pr) ** 2 + (g4 - pg) ** 2 + (b4 - pb) ** 2
        if dist < best_dist:
            best_i = i
            best_dist = dist
    return best_i


def main():
    if len(sys.argv) != 3:
        print("Usage: python image_to_4bit_mem.py input_image output_mem")
        return 1

    image_path = Path(sys.argv[1])
    mem_path = Path(sys.argv[2])

    image = Image.open(image_path).convert("RGB")
    image = image.resize((WIDTH, HEIGHT), Image.Resampling.LANCZOS)

    with mem_path.open("w", encoding="ascii") as f:
        for y in range(HEIGHT):
            for x in range(WIDTH):
                f.write(f"{nearest_palette_index(image.getpixel((x, y))):X}\n")

    print(f"Wrote {WIDTH * HEIGHT} pixels to {mem_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
