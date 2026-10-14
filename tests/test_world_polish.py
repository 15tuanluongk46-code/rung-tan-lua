from pathlib import Path
import json, math, unittest
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
class WorldPolish(unittest.TestCase):
    def test_route_pixels_include_northern_connectors_and_seams(self):
        data=json.loads((ROOT/'assets/world_routes.json').read_text())
        canvas=Image.new('RGB',(2400,2400))
        for name,x,y in [('camp',0,0),('forest',1200,0),('creek',0,800),('ruins',1200,800),('marsh',0,1600),('ash',1200,1600)]:
            with Image.open(ROOT/'assets/terrain'/f'{name}.png') as im: canvas.paste(im,(x,y))
        # Straight connector core must be painted, not merely clear of collisions.
        for x,y in [(530,1500),(530,1580),(530,1600),(1780,1420),(1200,1901)]:
            r,g,b=canvas.getpixel((x,y))
            self.assertGreater(r,g*.8,(x,y,'unpainted route'))
        for path in data['roads']+data['expansion_roads']:
            for x,y in path:
                for dx,dy in [(-5,0),(5,0),(0,-5),(0,5)]:
                    r,g,b=canvas.getpixel((x+dx,y+dy))
                    if [x,y] in [[297,980],[337,1201],[530,1951]]:
                        self.assertGreater(g,70,'bridge water has visible material')
                    else:self.assertGreater(r,g*.8,(x,y,'junction hole'))
    def test_cloak_overlay_is_local_and_pose_aligned(self):
        for suffix,size in [('',(288,192)),('_poses',(144,384))]:
            with Image.open(ROOT/'assets/layers'/f'player_cloak{suffix}.png') as im:
                self.assertEqual(im.size,size)
                self.assertGreater(im.getchannel('A').getbbox()[2],0)
                self.assertEqual(im.getpixel((0,0))[3],0)
    def test_creek_survives_biome_transition(self):
        with Image.open(ROOT/'assets/terrain/creek.png') as im:
            r,g,b=im.getpixel((375,770))
            self.assertGreater(b,r,'south creek must remain water not repainted ground')
