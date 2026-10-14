import unittest,json
import sys
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from generate_player_motion import FIXED_BODY
def expand(im,entry,o,n):
    tile=entry['indices'][o*entry['columns']+n];w,h=entry['cell'];cols=entry['atlas_columns']
    crop=im.crop(((tile%cols)*w,(tile//cols)*h,(tile%cols+1)*w,(tile//cols+1)*h))
    result=Image.new('RGBA',(192,192));result.alpha_composite(crop,tuple(entry['bounds'][:2]));return result
class PlayerMotionAssets(unittest.TestCase):
    def test_spear_actions_have_fixed_body_without_hands(self):
        data=json.loads((ROOT/'assets/player_motion/timelines.json').read_text())
        for name in ['thrust','heavy','charge','throw']:
            with Image.open(ROOT/'assets/player_motion'/f'{name}.png') as im:
                for o,row in enumerate([2,0,0,0,1,3,3,3]):
                    body=FIXED_BODY('player',row,0)
                    for n in range(data[name]['columns']-1):
                        tile=expand(im,data[name],o,n).crop((72,83,120,131))
                        for y in range(48):
                            for x in range(48):
                                pixel=body.getpixel((x,y))
                                # Foreground spear may occlude body; body colors outside
                                # the narrow weapon palette must remain exact.
                                weapon_colors={(22,38,50),(192,156,99),(194,209,189),(241,228,184),(153,170,160)}
                                actual=tile.getpixel((x,y))
                                if pixel[3] and actual[:3] not in weapon_colors:self.assertEqual(actual,pixel,(name,o,n,x,y))
                        # Both former 3x4 skin blocks must be absent, even at t=0.
                        for x in [15,31]:
                            for xx in range(x-1,x+2):
                                for yy in range(27,31):
                                    self.assertNotEqual(tile.getpixel((xx,yy))[:3],(212,162,118),(name,o,n,'visible small hand'))
    def test_reference_endpoints_and_contact(self):
        reference=Image.open(ROOT/'assets/sprites/player.png').convert('RGBA')
        data=json.loads((ROOT/'assets/player_motion/timelines.json').read_text())
        for name in ['thrust','heavy','throw']:
            entry=data[name]
            self.assertIn({'thrust':.08,'heavy':.13,'throw':.06}[name],entry['times'])
            with Image.open(ROOT/'assets/player_motion'/f'{name}.png') as im:
                for o,row in enumerate([2,0,0,0,1,3,3,3]):
                    for n in [entry['columns']-1]:
                        tile=expand(im,entry,o,n).crop((72,83,120,131))
                        self.assertEqual(tile.tobytes(),reference.crop((0,row*48,48,(row+1)*48)).tobytes(),(name,o,n))
    def test_front_spear_contact_tip_and_no_rear_tail(self):
        data=json.loads((ROOT/'assets/player_motion/timelines.json').read_text())
        import math
        for name,reach in [('thrust',49),('heavy',62)]:
            entry=data[name];n=entry['times'].index({'thrust':.08,'heavy':.13}[name])
            with Image.open(ROOT/'assets/player_motion'/f'{name}.png') as im:
                for o in range(8):
                    angle=o*math.tau/8
                    tip=(round(96+math.cos(angle)*reach+(10 if o in [2,6] else 0)),round(115+math.sin(angle)*reach))
                    tile=expand(im,entry,o,n)
                    self.assertGreater(tile.getpixel(tip)[3],0,(name,o,'visible front tip'))
                    behind=(round(96-math.cos(angle)*20),round(115-math.sin(angle)*20))
                    body=FIXED_BODY('player',[2,0,0,0,1,3,3,3][o],0)
                    local=(behind[0]-72,behind[1]-83)
                    expected=body.getpixel(local)[3] if 0<=local[0]<48 and 0<=local[1]<48 else 0
                    self.assertEqual(tile.getpixel(behind)[3],expected,(name,o,'rear weapon tail'))
    def test_frames_dont_clip_weapons(self):
        data=json.loads((ROOT/'assets/player_motion/timelines.json').read_text())
        for name,entry in data.items():
            with Image.open(ROOT/'assets/player_motion'/f'{name}.png') as im:
                for o in range(8):
                    for n in range(entry['columns']):
                        bbox=expand(im,entry,o,n).getbbox()
                        self.assertTrue(bbox and bbox[0]>0 and bbox[1]>0 and bbox[2]<192 and bbox[3]<192,(name,o,n))
