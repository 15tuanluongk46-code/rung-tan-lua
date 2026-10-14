from pathlib import Path
import unittest
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
class WeaponLayers(unittest.TestCase):
    def test_directional_weapons(self):
        for kind in ['spear','guardian','hammer','staff','bow','stone']:
            with Image.open(ROOT/'assets/layers'/f'{kind}_directions.png') as im:
                self.assertEqual(im.size,(768,96))
                self.assertEqual(im.mode,'RGBA')
                self.assertEqual(im.getpixel((0,0))[3],0)
                frames=[im.crop((i*96,0,(i+1)*96,96)).tobytes() for i in range(8)]
                self.assertGreaterEqual(len(set(frames)),4,kind)
    def test_body_masters_preserved(self):
        for kind in ['player','melee','archer','shaman','hunter','smith','guardian','coal']:
            with Image.open(ROOT/'assets/layers'/f'{kind}_body.png') as body, Image.open(ROOT/'assets/sprites'/f'{kind}.png') as original:
                self.assertEqual(body.size,(288,192))
                self.assertNotEqual(body.tobytes(),original.tobytes())
