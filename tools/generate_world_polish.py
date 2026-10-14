"""Terrain + material polish only. No actor originals, audio, fonts or save writes.

All six crops come from one canvas: shared route masks are unioned before painting
to eliminate wedge joins and guarantee the northern Chapter-II connectors exist.
"""
from pathlib import Path
import json, math, random
from PIL import Image, ImageDraw, ImageChops, ImageFilter

ROOT=Path(__file__).resolve().parents[1]
A=ROOT/'assets'
SIZE=(2400,2400)
ROUTES=json.loads((A/'world_routes.json').read_text(encoding='utf-8'))
REGIONS=[('camp',0,0),('forest',1200,0),('creek',0,800),('ruins',1200,800),('marsh',0,1600),('ash',1200,1600)]

def stroke_mask(paths,width):
    im=Image.new('L',SIZE);d=ImageDraw.Draw(im)
    # Union disks along each segment: deterministic rounded joins/caps at 1:1.
    for path in paths:
        for index,(p,q) in enumerate(zip(path,path[1:])):
            length=math.dist(p,q)
            for step in range(int(length/5)+1):
                t=min(1,step*5/max(1,length)); x=p[0]+(q[0]-p[0])*t;y=p[1]+(q[1]-p[1])*t
                radius=width/2+(1.4*math.sin((x+y)*.028) if width<110 else 0)
                d.ellipse((round(x-radius),round(y-radius),round(x+radius),round(y+radius)),fill=255)
        x,y=path[-1];r=width/2;d.ellipse((x-r,y-r,x+r,y+r),fill=255)
    return im

def terrain():
    rng=random.Random(641)
    full=Image.new('RGB',SIZE);d=ImageDraw.Draw(full)
    grounds=['#314f43','#314f43','#314f43','#314f43','#304f4b','#484543']
    for (name,x,y),color in zip(REGIONS,grounds):
        d.rectangle((x,y,x+1199,y+799),fill=color)
        palette=['#355648','#395b49','#3f614b','#2d4b40'] if y<1600 else (['#365d56','#41675d','#2b4745','#586f60'] if x==0 else ['#534d48','#60564b','#3b3f3e','#6b594b'])
        for _ in range(22000):
            px=x+rng.randrange(1200);py=y+rng.randrange(800)
            d.rectangle((px,py,px+rng.choice([1,2,3]),py+rng.choice([0,1,2])),fill=rng.choice(palette))
    # Shallow water and banks form continuous masks too, without angular cracks.
    stream=ROUTES['creek']
    bank=stroke_mask([stream],136);water=stroke_mask([stream],91);deep=stroke_mask([stream],63)
    full.paste('#637b61',mask=bank);full.paste('#acaa7c',mask=stroke_mask([stream],112))
    full.paste('#315f60',mask=water);full.paste('#417778',mask=deep)
    d=ImageDraw.Draw(full)
    for _ in range(2300):
        x=rng.randrange(180,470);y=rng.randrange(800,1600)
        if water.getpixel((x,y)): d.line((x,y,x+rng.randrange(3,14),y),fill=rng.choice(['#649b92','#568d89','#8eb5a2']))
    # Marsh ponds: irregular rims and a few stepping-bank stones.
    for cx,cy in [(180,1840),(760,1980),(1060,2190),(490,2280)]:
        for r,color in [(1,'#6b8675'),(.88,'#376c6b')]:
            points=[]
            for i in range(48):
                a=i*math.tau/48;f=1+.045*math.sin(i*2.1)
                points.append((round(cx+math.cos(a)*120*r*f),round(cy+math.sin(a)*61*r*f)))
            d.polygon(points,fill=color)
        for _ in range(28):
            x=cx+rng.randrange(-75,85);y=cy+rng.randrange(-32,35)
            d.line((x,y,x+rng.randrange(4,15),y),fill='#75a69a')
    roads=ROUTES['roads']+ROUTES['expansion_roads']
    outer=stroke_mask(roads,98);edge=stroke_mask(roads,74);inner=stroke_mask(roads,53)
    # Draw all shoulders, then all cores. Crossroads have no intersecting seams.
    palettes=[('#4c6250','#767354','#8b805d')]*4+[('#536d5e','#76876c','#929579'),('#514b45','#72604f','#91765d')]
    for region,(name,x,y) in enumerate(REGIONS):
        crop=(x,y,x+1200,y+800)
        for mask,color in zip([outer,edge,inner],palettes[region]):
            full.paste(color,(x,y),mask.crop(crop))
    # Camp worn clearing and small believable approach footpaths.
    clearing=Image.new('L',SIZE);c=ImageDraw.Draw(clearing)
    c.ellipse((270,260,620,540),fill=255)
    full.paste('#817858',mask=clearing)
    c.ellipse((315,305,570,513),fill=255)
    d=ImageDraw.Draw(full);d.ellipse((315,305,570,513),fill='#918361')
    combined=ImageChops.lighter(edge,clearing)
    for _ in range(55000):
        x=rng.randrange(2400);y=rng.randrange(2400)
        if combined.getpixel((x,y)):
            colors=['#9d916a','#ab9b74','#7d7755','#77704e'] if y<1600 else (['#a1a284','#7b886e','#6a7966','#919778'] if x<1200 else ['#a28669','#80674f','#655748','#97816c'])
            d.line((x,y,x+rng.randrange(1,5),y),fill=rng.choice(colors))
            if rng.random()<.025:
                d.rectangle((x,y,x+2,y+1),fill='#536452' if y<1600 or x<1200 else '#443f3b')
    # Border grass stays outside the clear core, texture is clustered at shoulders.
    for _ in range(19000):
        x=rng.randrange(2400);y=rng.randrange(2400)
        if inner.getpixel((x,y)) or clearing.getpixel((x,y)) or bank.getpixel((x,y)):continue
        if y>=1600 and x>=1200:
            if outer.getpixel((x,y)):d.line((x,y,x+3,y-1),fill='#47453d')
            continue
        color=rng.choice(['#77935d','#56784d','#698963','#4b7253'])
        d.line((x-2,y,x-3,y-rng.randrange(3,6)),fill=color);d.line((x,y,x+1,y-5),fill=color)
        if rng.random()<.06:d.point((x,y-5),fill='#b7b88b')
    # Stone courts: chipped, varied stones with an irregular footprint and approach.
    for bounds,south in [((1620,1035,2060,1420),False),((1770,2070,2170,2370),True)]:
        x0,y0,x1,y1=bounds
        for gy in range(y0,y1,28):
            for gx in range(x0,x1,34):
                if rng.random()<.12:continue
                x=gx+rng.randrange(-3,4);y=gy+rng.randrange(-2,3)
                color=rng.choice(['#6b7d67','#77866c','#657b65'] if not south else ['#777066','#6b655d','#82796b'])
                points=[(x+3,y),(x+29,y+1),(x+31,y+5),(x+29,y+23),(x+2,y+24),(x,y+19),(x+1,y+4)]
                d.polygon(points,fill=color,outline='#3e5349' if not south else '#3a3d3e')
                d.line((x+4,y+2,x+25,y+2),fill='#8d9677' if not south else '#a19781')
                if rng.random()<.35:d.line((x+12,y+3,x+10,y+9,x+15,y+12),fill='#475c50' if not south else '#504c45')
                if not south and rng.random()<.4:d.line((x+2,y+22,x+8,y+22),fill='#56774d')
    # Mud and wheel/foot wear by work areas, leaving actor-width central space.
    for path in roads:
        for p,q in zip(path,path[1:]):
            if p[1]<1600:continue
            vx,vy=q[0]-p[0],q[1]-p[1];length=math.hypot(vx,vy)
            for n in range(0,int(length),35):
                t=n/max(1,length);x=round(p[0]+vx*t);y=round(p[1]+vy*t)
                col='#7b856d' if x<1200 else '#715b49'
                d.line((x-4,y-2,x,y+1),fill=col,width=2)
    # Small creek crossing under the repaired shortcut and muddy abutments.
    wx,wy,ww,wh=ROUTES['bridge']['water']
    d.rectangle((wx-7,wy-7,wx+ww+7,wy+wh+7),fill='#6b8675')
    d.rectangle((wx,wy,wx+ww,wy+wh),fill='#376c6b')
    for y in range(wy+8,wy+wh,17):d.line((wx+5,y,wx+ww-5,y),fill='#75a69a')
    for box in [(452,1935,478,1967),(582,1935,617,1967)]:
        d.ellipse(box,fill='#899578')
    # Palette ramp with tiny seeded clusters, no checkerboard stripe or ruler seam.
    pix=full.load();blend_rng=random.Random(9137)
    def blend_pixel(x,y,left,right,t):
        noise=blend_rng.randrange(-5,6)
        pix[x,y]=tuple(max(0,min(255,round(a*(1-t)+b*t)+noise)) for a,b in zip(left,right))
    for y in range(1600,2400):
        for x in range(1120,1280):
            t=(x-1120)/160
            left,right=(48,79,75),(72,69,67)
            if inner.getpixel((x,y)):left,right=(146,149,121),(145,118,93)
            elif outer.getpixel((x,y)):left,right=(83,109,94),(81,75,69)
            blend_pixel(x,y,left,right,t)
    for y in range(1540,1660):
        for x in range(2400):
            if bank.getpixel((x,y)):continue
            t=(y-1540)/120
            left=(49,79,67);right=(48,79,75) if x<1200 else (72,69,67)
            if inner.getpixel((x,y)):left,right=(139,128,93),((146,149,121) if x<1200 else (145,118,93))
            elif outer.getpixel((x,y)):left,right=(76,98,80),((83,109,94) if x<1200 else (81,75,69))
            blend_pixel(x,y,left,right,t)
    # Reintroduce local grit and irregular edge clusters so transition bands do
    # not look like smooth rectangular airbrushed strips against the pixel ground.
    for y in range(1515,1685,2):
        for x in range(0,2400,3):
            if blend_rng.random()<.7:continue
            xx=x+blend_rng.randrange(3);yy=y+blend_rng.randrange(2)
            if bank.getpixel((xx,yy)):continue
            col=pix[xx,yy];shift=blend_rng.choice([-11,-7,7,10])
            d.rectangle((xx,yy,xx+1,yy),fill=tuple(max(0,min(255,c+shift)) for c in col))
    for y in range(1660,2400,2):
        for x in range(1100,1300,3):
            if blend_rng.random()<.7:continue
            xx=x+blend_rng.randrange(3);yy=y+blend_rng.randrange(2)
            col=pix[xx,yy];shift=blend_rng.choice([-11,-7,7,10])
            d.rectangle((xx,yy,xx+1,yy),fill=tuple(max(0,min(255,c+shift)) for c in col))
    for name,x,y in REGIONS: full.crop((x,y,x+1200,y+800)).save(A/'terrain'/f'{name}.png')
    # Developer evidence masks; do not ship full developer canvas as a game asset.
    evidence=ROOT/'docs/screenshots/world-polish';evidence.mkdir(parents=True,exist_ok=True)
    full.resize((1200,1200),Image.Resampling.NEAREST).save(evidence/'terrain-overview.png')
    for name,box in [('camp-junction',(700,410,830,530)),('marsh-junction',(540,1820,740,2020)),('north-south-creek',(450,1460,610,1690)),('east-west-south',(1090,1830,1310,1990)),('creek-bend',(240,1000,400,1180))]:
        full.crop(box).resize(((box[2]-box[0])*3,(box[3]-box[1])*3),Image.Resampling.NEAREST).save(evidence/f'{name}-terrain.png')
    return outer,inner

def save_prop(im,name):im.save(A/'props'/f'{name}.png')

def props():
    ink='#162632'
    # Preserve authored silhouettes and add material inside their existing alpha.
    for name in ['hut','tower','well','valve','bell','charred_tree','reed','bridge','broken_bridge','sign','herb']:
        with Image.open(A/'props'/f'{name}.png') as source: im=source.convert('RGBA')
        original_alpha=im.getchannel('A');d=ImageDraw.Draw(im)
        if name=='hut':
            for x in range(22,75,8):d.line((x,20,x+5,25),fill='#8eac89')
            for y in [47,59,71]:d.line((20,y,76,y),fill='#465e50')
            d.rectangle((44,44,51,82),fill='#263d36');d.line((43,45,43,80),fill='#b6b591')
            d.line((19,79,76,79),fill='#425348',width=3);d.rectangle((23,49,32,60),fill='#253e38');d.line((24,50,31,50),fill='#bdc79a')
        elif name=='tower':
            for y in range(40,125,16):
                for x in range(26,70,14):
                    offset=7 if (y//16)%2 else 0;d.line((x+offset,y-10,x+offset,y),fill='#525550')
            d.rectangle((39,83,56,125),fill='#1b2c2d');d.line((35,79,59,79),fill='#a29a80',width=2)
            d.line((24,120,70,120),fill='#4a514b',width=3);d.line((26,16,70,16),fill='#979381')
            d.line((60,55,55,63,61,68),fill='#444c47');d.line((18,25,75,25),fill='#b1a789')
        elif name=='well':
            for x in [17,28,41,49]:d.line((x,47,x,54),fill='#465e57')
            d.line((17,21,17,40),fill='#c5b88a');d.line((47,21,47,41),fill='#645640')
            d.line((33,22,33,39),fill='#d2bf91');d.rectangle((30,34,36,40),fill='#8f9b8e')
            d.arc((15,33,48,47),0,160,fill='#aac1aa');d.line((22,42,29,42),fill='#86b8ad')
        elif name=='valve':
            d.arc((18,11,46,39),185,280,fill='#dfc58b',width=2);d.arc((18,11,46,39),10,120,fill='#685842',width=2)
            d.rectangle((29,24,35,29),fill='#cead73');d.line((35,38,35,59),fill='#504c41')
        elif name=='bell':
            d.line((22,14,18,37),fill='#e0bd77',width=2);d.line((43,15,47,37),fill='#806943',width=2)
            d.arc((18,35,45,45),0,180,fill='#5b4e38',width=2);d.line((22,39,42,39),fill='#eacb8c')
        elif name=='charred_tree':
            d.line((39,125,43,68,45,41),fill='#8b7765');d.line((47,111,48,67),fill='#2a3432',width=2)
            d.line((24,51,36,59,42,68),fill='#665e50');d.line((53,43,64,33),fill='#817361')
            d.polygon([(36,124),(29,132),(46,129),(56,135),(50,122)],fill='#353c38')
        elif name=='reed':
            for x,y in [(12,34),(23,22),(37,25),(46,32)]:d.line((x,y,x+3,y+10),fill='#b1b88e')
            d.line((31,48,31,58),fill='#415c4c',width=2)
        elif name in ['bridge','broken_bridge']:
            for y in range(8,im.height-5,8):
                d.line((12,y+1,min(im.width-10,im.width-1),y+1),fill='#c6ad78')
                d.line((14,y+3,28,y+3),fill='#735c40')
                for x in [12,im.width-13]:d.point((x,y+2),fill='#303d36')
            d.line((6,4,6,im.height-5),fill='#d0b880');d.line((im.width-6,4,im.width-6,im.height-5),fill='#69543c')
        elif name=='sign':
            d.line((10,13,27,13),fill='#d8ba7e');d.line((16,31,16,51),fill='#6f573b')
            d.point((17,18),fill=ink)
        elif name=='herb':
            d.line((10,8,10,21),fill='#203f36');d.point((12,3),fill='#ffe0a2');d.point((10,4),fill='#f1c18d')
        im.putalpha(original_alpha);save_prop(im,name)
        if name in ['reed','charred_tree']:
            save_prop(im.transpose(Image.Transpose.FLIP_LEFT_RIGHT),name+'_variant1')
            variation=im.copy();v=ImageDraw.Draw(variation)
            if name=='reed':v.line((26,40,20,21),fill='#95aa82',width=2)
            else:v.line((43,92,51,77,63,68),fill='#6b6c5b',width=2)
            variation.putalpha(original_alpha);save_prop(variation,name+'_variant2')
    # Dedicated downward board matches southern direction metadata; post stays upright.
    im=Image.new('RGBA',(48,56));d=ImageDraw.Draw(im)
    d.rectangle((22,18,26,54),fill='#6f573b',outline=ink)
    d.polygon([(14,4),(34,4),(34,17),(39,17),(24,31),(9,17),(14,17)],fill='#a88453',outline=ink)
    d.line((17,6,31,6),fill='#d8ba7e');d.point((24,12),fill=ink)
    save_prop(im,'sign_down')
    print('Material polish and registered vegetation/direction variants')

def main():
    terrain();props()
    print('Six seamless terrain crops rebuilt from assets/world_routes.json')
if __name__=='__main__':main()
