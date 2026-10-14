from pathlib import Path
import unittest
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
class ExpansionAssets(unittest.TestCase):
    def test_new_sheets_have_distinct_designs_and_motion(self):
        sheets=[]
        for kind in ['sen','tung','stalker','coal','guardian']:
            with Image.open(ROOT/'assets/sprites'/f'{kind}.png') as source:
                im=source.convert('RGBA')
                self.assertEqual(im.size,(288,192))
                frames=[im.crop((x*48,y*48,x*48+48,y*48+48)).tobytes() for y in range(4) for x in range(6)]
                self.assertGreaterEqual(len(set(frames)),12,kind)
                sheets.append(im.tobytes())
        self.assertEqual(len(set(sheets)),5)
    def test_regions_and_music(self):
        for kind in ['marsh','ash']:
            with Image.open(ROOT/'assets/terrain'/f'{kind}.png') as im: self.assertEqual(im.size,(1200,800))
        for kind in ['marsh','ash','boss']: self.assertGreater((ROOT/'assets/music'/f'{kind}.ogg').stat().st_size,10000)
