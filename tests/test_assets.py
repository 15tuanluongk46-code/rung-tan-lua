"""Asset delivery contract. Run after tools/generate_assets.py."""
from pathlib import Path
import unittest
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
KINDS = 'player chief hunter healer smith gatherer melee archer shaman bear deer rabbit bird'.split()

class AssetContract(unittest.TestCase):
    def test_all_unique_animated_directional_designs(self):
        fingerprints = set()
        for kind in KINDS:
            p = ROOT / 'assets/sprites' / (kind + '.png')
            self.assertTrue(p.exists(), str(p))
            im = Image.open(p).convert('RGBA')
            self.assertEqual(im.size, (288, 192))
            self.assertEqual(im.getpixel((0, 0))[3], 0)
            frames = [im.crop((x*48,y*48,x*48+48,y*48+48)).tobytes() for y in range(4) for x in range(6)]
            self.assertGreaterEqual(len(set(frames)), 12, kind)
            fingerprints.add(im.tobytes())
        self.assertEqual(len(fingerprints), 13)

    def test_complete_props_terrain_font(self):
        for name in 'ember herb bag potion stone checkpoint altar arrow magic tree0 tree1 tree2 pine bush rock tent forge table sign bridge column wall'.split():
            self.assertTrue((ROOT/'assets/props'/f'{name}.png').exists(), name)
        for name in 'camp forest creek ruins'.split():
            with Image.open(ROOT/'assets/terrain'/f'{name}.png') as image:
                self.assertEqual(image.size,(1200,800))
        self.assertTrue((ROOT/'assets/fonts/DejaVuSans.ttf').exists())

if __name__ == '__main__':
    unittest.main()
