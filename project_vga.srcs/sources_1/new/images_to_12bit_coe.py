from pathlib import Path
from PIL import Image
import sys

WIDTH = 320
HEIGHT = 240
PIXELS_PER_IMAGE = WIDTH * HEIGHT


def rgb888_to_rgb444_hex(rgb):
    r, g, b = rgb
    return f"{r >> 4:1X}{g >> 4:1X}{b >> 4:1X}"


def image_pixels(path):
    img = Image.open(path).convert("RGB")
    img = img.resize((WIDTH, HEIGHT), Image.Resampling.LANCZOS)
    pixels = img.load()

    for y in range(HEIGHT):
        for x in range(WIDTH):
            yield rgb888_to_rgb444_hex(pixels[x, y])


def main():
    if len(sys.argv) < 4:
        print("Usage: python images_to_12bit_coe.py output.coe image0 image1 [image2 ...]")
        print("Example: python images_to_12bit_coe.py multi_picture_12bit.coe bg0.png bg1.png bg2.png")
        return 1

    out_path = Path(sys.argv[1])
    image_paths = [Path(p) for p in sys.argv[2:]]

    for path in image_paths:
        if not path.exists():
            print(f"Missing image: {path}")
            return 1

    total_pixels = PIXELS_PER_IMAGE * len(image_paths)
    written = 0

    with out_path.open("w", encoding="ascii") as f:
        f.write("memory_initialization_radix=16;\n")
        f.write("memory_initialization_vector=\n")

        for image_index, path in enumerate(image_paths):
            print(f"[{image_index}] {path} -> address {image_index * PIXELS_PER_IMAGE} to {(image_index + 1) * PIXELS_PER_IMAGE - 1}")
            for value in image_pixels(path):
                written += 1
                suffix = ";\n" if written == total_pixels else ",\n"
                f.write(value + suffix)

    print(f"Wrote {len(image_paths)} image(s), {total_pixels} pixels total.")
    print(f"Block Memory Generator depth should be {total_pixels}, width should be 12.")
    print(f"Output: {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
