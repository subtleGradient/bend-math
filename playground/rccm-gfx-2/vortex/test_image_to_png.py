import struct
import unittest
import zlib

from image_to_png import decode, png


class ImageEncodingTests(unittest.TestCase):
    def test_solid_pixel_fills_region(self):
        self.assertEqual(decode("Pix{16711680}", 2), bytes((255, 0, 0)) * 4)

    def test_quadrant_order(self):
        self.assertEqual(
            decode("Qua{Pix{16711680},Pix{65280},Pix{255},Pix{0}}", 2),
            bytes((255, 0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0)),
        )

    def test_bad_tree_rejected(self):
        for text in ("Pix{16777216}", "Pix{1} junk", "Qua{Pix{1}}", "Unknown{0}"):
            with self.subTest(text=text), self.assertRaises(ValueError):
                decode(text, 2)

    def test_png_header_crc_and_pixels(self):
        image = png(bytes((10, 20, 30)), 1)
        self.assertEqual(image[:8], b"\x89PNG\r\n\x1a\n")
        offset = 8
        chunks = {}
        while offset < len(image):
            length = struct.unpack(">I", image[offset:offset + 4])[0]
            kind = image[offset + 4:offset + 8]
            data = image[offset + 8:offset + 8 + length]
            crc = struct.unpack(">I", image[offset + 8 + length:offset + 12 + length])[0]
            self.assertEqual(crc, zlib.crc32(kind + data) & 0xFFFFFFFF)
            chunks[kind] = data
            offset += length + 12
        self.assertEqual(struct.unpack(">II", chunks[b"IHDR"][:8]), (1, 1))
        self.assertEqual(zlib.decompress(chunks[b"IDAT"]), bytes((0, 10, 20, 30)))
        self.assertIn(b"IEND", chunks)


if __name__ == "__main__":
    unittest.main()
