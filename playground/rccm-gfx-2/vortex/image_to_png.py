#!/usr/bin/env python3
"""Convert Bend's printed Image quadtree to PNG. No rendering or physics here."""

import argparse
from pathlib import Path
import re
import struct
import zlib


def decode(source: str, size: int) -> bytes:
    pixels = bytearray(size * size * 3)
    token = re.compile(r"\s*(Pix|Qua|[{},]|[0-9]+)")
    position = 0

    def read(expected=None):
        nonlocal position
        match = token.match(source, position)
        if match is None:
            raise ValueError(f"Invalid Image token at offset {position}")
        position = match.end()
        value = match.group(1)
        if expected is not None and value != expected:
            raise ValueError(f"Expected {expected}, got {value}")
        return value

    def draw(x, y, width):
        constructor = read()
        read("{")
        if constructor == "Pix":
            color = int(read())
            if not 0 <= color <= 0xFFFFFF:
                raise ValueError("Expected a packed 24-bit RGB color")
            row = bytes((color >> 16, (color >> 8) & 255, color & 255)) * width
            for row_y in range(y, y + width):
                start = (row_y * size + x) * 3
                pixels[start:start + width * 3] = row
        elif constructor == "Qua" and width > 1:
            half = width // 2
            for index, (dx, dy) in enumerate(((0, 0), (half, 0), (0, half), (half, half))):
                if index:
                    read(",")
                draw(x + dx, y + dy, half)
        else:
            raise ValueError(f"Invalid Image node {constructor} at width {width}")
        read("}")

    draw(0, 0, size)
    if source[position:].strip():
        raise ValueError("Unexpected content after Image")
    return bytes(pixels)


def png(pixels: bytes, size: int) -> bytes:
    def chunk(kind, data):
        return (struct.pack(">I", len(data)) + kind + data
                + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF))

    rows = b"".join(
        b"\0" + pixels[y * size * 3:(y + 1) * size * 3] for y in range(size)
    )
    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(rows))
            + chunk(b"IEND", b""))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--size", type=int, default=512)
    args = parser.parse_args()
    if args.size < 1 or args.size > 4096 or args.size & (args.size - 1):
        parser.error("size must be a power of two between 1 and 4096")
    args.output.write_bytes(png(decode(args.input.read_text(), args.size), args.size))
    print(f"Wrote {args.size} x {args.size} PNG to {args.output}")


if __name__ == "__main__":
    main()
