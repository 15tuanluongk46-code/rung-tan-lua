"""Original body-only sheets + eight-direction pixel weapon masters.

Reuse authored actor functions through AST extraction, without running generators
that overwrite terrain/audio/fonts. Original combined sheets remain intact.
"""
import ast
import math
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets' / 'layers'

def body_function(filename, layers):
    source=(ROOT/'tools'/filename).read_text(encoding='utf-8')
    lines=source.splitlines();remove_lines=set()
    for index,line in enumerate(lines):
        if line.strip().startswith('# layer:') and line.split(':',1)[1].strip() in layers: remove_lines.add(index+2)
    if not remove_lines:raise ValueError('Required actor layer markers absent: '+filename)
    tree = ast.parse(source)
    fn = next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='actor')
    class Filter(ast.NodeTransformer):
        def visit(self,node):
            if getattr(node,'lineno',0) in remove_lines: return None
            return super().visit(node)
    fn = Filter().visit(fn)
    for node in ast.walk(fn):
        if isinstance(node,(ast.If,ast.For)) and not node.body: node.body=[ast.Pass()]
    ast.fix_missing_locations(fn)
    scope = {'Image':Image,'ImageDraw':ImageDraw,'INK':'#162632','SKIN':'#d4a276','LIGHT':'#f5d4a0'}
    scope['canvas'] = lambda w=48,h=48: (lambda im:(im,ImageDraw.Draw(im)))(Image.new('RGBA',(w,h)))
    scope['shade'] = lambda color,f: tuple(min(255,int(int(color.lstrip('#')[i:i+2],16)*f)) for i in (0,2,4))
    exec(compile(ast.Module(body=[fn],type_ignores=[]),str(filename),'exec'),scope)
    return scope['actor']

def weapon(name,octant):
    im=Image.new('RGBA',(96,96)); d=ImageDraw.Draw(im)
    a=octant*math.tau/8
    f=(math.cos(a),math.sin(a)); p=(-f[1],f[0])
    def pt(x,y=0): return (round(48+f[0]*x+p[0]*y),round(48+f[1]*x+p[1]*y))
    def line(x0,y0,x1,y1,color,w=1): d.line((pt(x0,y0),pt(x1,y1)),fill=color,width=w)
    if name in ('spear','guardian'):
        length=32 if name=='spear' else 40
        line(-16,0,length-8,0,'#162632',3)
        line(-15,0,length-8,0,'#bf9662',1)
        d.polygon([pt(length,0),pt(length-9,-3),pt(length-7,0),pt(length-9,3)],fill='#b8ccc1',outline='#162632')
        line(length-7,0,length-2,0,'#f3e4b8')
        for x in (-4,-1,2): line(x,-1,x,1,'#66533d')
        if name=='guardian':
            d.polygon([pt(length-3,-5),pt(length-13,-10),pt(length-16,-3),pt(length-8,-1)],fill='#deba78',outline='#162632')
    elif name=='hammer':
        line(-13,0,22,0,'#162632',4); line(-12,0,22,0,'#b99365',2)
        d.polygon([pt(17,-9),pt(29,-9),pt(29,9),pt(17,9)],fill='#72867d',outline='#162632')
        line(18,-7,27,-7,'#c1cdb1',2); line(28,-7,28,7,'#41504e',2)
        d.polygon([pt(17,4),pt(28,4),pt(28,8),pt(17,8)],fill='#4c5e59')
        line(19,-5,19,2,'#92a498'); line(20,-6,25,-6,'#dce0bd')
        for x in (-8,-5,-2): line(x,-1,x,1,'#66533d')
    elif name=='staff':
        line(-17,0,25,0,'#162632',3); line(-16,0,25,0,'#b99770')
        d.ellipse((pt(27,0)[0]-5,pt(27,0)[1]-5,pt(27,0)[0]+5,pt(27,0)[1]+5),fill='#6aab9e',outline='#162632')
        d.ellipse((pt(27,0)[0]-2,pt(27,0)[1]-2,pt(27,0)[0]+2,pt(27,0)[1]+2),fill='#e0eec1')
        for x in (-6,-3,0): line(x,-1,x,1,'#66533d')
        line(21,-2,24,-2,'#d5b987')
    elif name=='bow':
        path=[pt(4,-15),pt(11,-10),pt(13,0),pt(11,10),pt(4,15)]
        d.line(path,fill='#162632',width=4); d.line(path,fill='#c19d6e',width=2)
    elif name=='stone':
        d.polygon([pt(-3,-2),pt(1,-4),pt(5,-1),pt(3,4),pt(-3,3)],fill='#99aaa0',outline='#162632')
        line(-1,-2,2,-2,'#dce2c1')
    return im

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    base=body_function('generate_assets.py',{'arms','weapon'})
    extra=body_function('generate_expansion.py',{'arms','weapon'})
    for kind in ['player','melee','archer','shaman','hunter','smith','guardian','coal']:
        sheet=Image.new('RGBA',(288,192))
        cloak_sheet=Image.new('RGBA',(288,192))
        fn=extra if kind in ['guardian','coal'] else base
        for row in range(4):
            for frame in range(6):
                sheet.paste(fn(kind,row,frame),(48*frame,48*row))
                if kind=='player': cloak_sheet.paste(cloak(frame),(48*frame,48*row))
        sheet.save(OUT/f'{kind}_body.png')
        if kind=='player': cloak_sheet.save(OUT/'player_cloak.png')
        # Eight directional action silhouettes, three phases. Preserve authored
        # identity/head pixels while shifting torso and planting separate feet.
        poses=Image.new('RGBA',(144,384))
        cloak_poses=Image.new('RGBA',(144,384))
        for octant in range(8):
            a=octant*math.tau/8; fx,fy=math.cos(a),math.sin(a)
            row=(2 if fx>0 else 1) if abs(fx)>abs(fy)+.01 else (3 if fy<0 else 0)
            for stage in range(3):
                source=fn(kind,row,0)
                pose=Image.new('RGBA',(48,48))
                cape=Image.new('RGBA',(48,48))
                cape_source=cloak(0)
                drive=[-1,2,0][stage]
                for y in range(48):
                    for x in range(48):
                        pixel=source.getpixel((x,y))
                        if not pixel[3]: continue
                        dx=round(fx*drive*(1 if y<24 else .6))
                        dy=round(fy*drive*.45) if y<32 else 0
                        if y>=35:
                            dx=round(fx*(2 if x<24 else -2)*(1 if stage==1 else .5))
                            dy=round(fy*(2 if x<24 else -2)) if stage==1 else 0
                        if 0<=x+dx<48 and 0<=y+dy<48: pose.putpixel((x+dx,y+dy),pixel)
                        if kind=='player' and 0<=x+dx<48 and 0<=y+dy<48:
                            cape.putpixel((x+dx,y+dy),cape_source.getpixel((x,y)))
                poses.paste(pose,(stage*48,octant*48))
                cloak_poses.paste(cape,(stage*48,octant*48))
        poses.save(OUT/f'{kind}_poses.png')
        if kind=='player': cloak_poses.save(OUT/'player_cloak_poses.png')
    for name in ['spear','guardian','hammer','staff','bow','stone']:
        sheet=Image.new('RGBA',(768,96))
        for octant in range(8): sheet.paste(weapon(name,octant),(96*octant,0))
        sheet.save(OUT/f'{name}_directions.png')
    print('Layered art: 8 body-only sheets, 6 hand-authored eight-direction weapon sheets.')

def cloak(frame):
    """Original red shoulder drape, separated for local arm occlusion."""
    im=Image.new('RGBA',(48,48)); d=ImageDraw.Draw(im)
    bob=-1 if frame==2 else 0
    d.polygon([(16,23+bob),(20,22+bob),(21,34+bob),(15,37+bob),(13,30+bob)],fill='#843b26',outline='#162632')
    d.line((16,25+bob,17,33+bob),fill='#b85236')
    d.line((18,25+bob,19,32+bob),fill='#c86b44')
    if frame==5:
        overlay=Image.new('RGBA',im.size,'#f4caa0');overlay.putalpha(im.getchannel('A'));im=Image.blend(im,overlay,.32)
    return im

if __name__=='__main__': main()
