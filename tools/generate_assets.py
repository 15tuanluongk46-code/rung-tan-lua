"""Original pixel-art assets for Rừng Tàn Lửa. Deterministic, no scraped art.
Raster illustration uses authored silhouettes, palette ramps and seeded texture.
Run from anywhere: python3 tools/generate_assets.py
"""
from pathlib import Path
import random, math, shutil
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
A=ROOT/'assets'
for folder in ['sprites','props','terrain','fonts','sfx','music']:
    (A/folder).mkdir(parents=True,exist_ok=True)
INK='#162632'; SKIN='#d4a276'; LIGHT='#f5d4a0'

def save(im,folder,name): im.save(A/folder/(name+'.png'))
def canvas(w=48,h=48):
    im=Image.new('RGBA',(w,h)); return im,ImageDraw.Draw(im)
def shade(hexcolor,factor):
    c=tuple(int(hexcolor.lstrip('#')[i:i+2],16) for i in (0,2,4))
    return tuple(min(255,int(v*factor)) for v in c)

def actor(kind,direction,frame):
    im,d=canvas(); moving=frame in (1,2,3)
    bob=-1 if frame==2 else 0; stride=[0,-2,1,2,0,0][frame]
    cx=24; cy=27+bob; front=direction==0; back=direction==3
    side=direction in (1,2); face=-1 if direction==1 else 1
    if kind in ['bear','deer','rabbit','bird']:
        # Four-direction anatomy, with side profiles and distinct stance frames.
        if kind=='bear':
            fur='#694534'; high='#9d6a45'; body=(9,19+bob,36,37+bob) if side else (12,15+bob,35,37+bob)
            d.ellipse(body,INK); d.ellipse((body[0]+1,body[1]+1,body[2]-1,body[3]-2),fur)
            for x in [13,29]: d.rectangle((x,31,x+6,40+stride*(1 if x==13 else -1)),INK); d.rectangle((x+1,32,x+5,38+stride*(1 if x==13 else -1)),fur)
            hx=13 if direction==1 else (33 if direction==2 else 24); hy=23 if side else (16 if back else 28)
            d.ellipse((hx-8,hy-8,hx+8,hy+7),INK); d.ellipse((hx-7,hy-7,hx+7,hy+6),fur)
            for dx in [-5,5]: d.ellipse((hx+dx-3,hy-10,hx+dx+2,hy-5),INK); d.point((hx+dx,hy-8),high)
            if not back:
                d.ellipse((hx-5,hy,hx+5,hy+5),high); d.rectangle((hx-2,hy+1,hx+2,hy+2),INK)
                d.point((hx-4,hy-2),LIGHT); d.point((hx+4,hy-2),LIGHT)
            for i in range(15):
                x=13+(i*7)%19; y=20+(i*11)%12; d.line((x,y,x+2,y-1),fill=high)
        elif kind=='deer':
            color='#b98c64'; d.ellipse((12,23+bob,34,34+bob),INK); d.ellipse((13,24+bob,33,32+bob),color)
            for x,s in [(15,1),(28,-1)]: d.line((x,31,x+s*stride,41),fill=INK,width=3); d.line((x,32,x+s*stride,39),fill=color)
            hx=12 if direction==1 else (34 if direction==2 else 24); hy=18 if back else 23
            d.polygon([(hx-3,hy+9),(hx-5,hy-3),(hx+4,hy-5),(hx+5,hy+6)],fill=color,outline=INK)
            d.polygon([(hx-4,hy),(hx-9,hy-6),(hx-3,hy-5)],fill=color,outline=INK)
            d.polygon([(hx+3,hy),(hx+8,hy-6),(hx+3,hy-5)],fill=color,outline=INK)
            d.line((hx-2,hy-5,hx-4,hy-13,hx-8,hy-15),fill='#d6bf8b'); d.line((hx+2,hy-5,hx+4,hy-13,hx+8,hy-15),fill='#d6bf8b')
            if not back: d.point((hx-2,hy),INK); d.point((hx+3,hy),INK)
            for p in [(18,26),(23,28),(29,26)]: d.rectangle((p[0],p[1]+bob,p[0]+1,p[1]+bob+1),LIGHT)
        elif kind=='rabbit':
            hx=19 if direction==1 else (29 if direction==2 else 24)
            d.ellipse((15,29+bob,32,40+bob),INK); d.ellipse((16,30+bob,31,39+bob),'#b2b5a7')
            d.ellipse((hx-5,25+bob,hx+5,35+bob),'#d4d1b5')
            for dx in [-3,3]: d.ellipse((hx+dx-2,15+bob,hx+dx+1,29+bob),INK); d.line((hx+dx-1,18+bob,hx+dx-1,26+bob),fill='#d7a599')
            if not back: d.point((hx-3,29+bob),INK); d.point((hx+3,29+bob),INK)
            d.rectangle((18+stride,39,21+stride,41),INK); d.ellipse((30,32,34,36),'#e0dac1')
        else:
            d.ellipse((19,30+bob,30,38+bob),INK); d.ellipse((20,30+bob,29,36+bob),'#56a7a2')
            hx=20 if direction==1 else 28
            d.ellipse((hx-3,27+bob,hx+3,33+bob),'#95cec0'); d.point((hx,29+bob),INK)
            if not back: d.polygon([(hx+face*3,30+bob),(hx+face*6,31+bob),(hx+face*3,32+bob)],fill='#dbb36c')
            wing=7 if moving else 1
            d.polygon([(24,33),(14,33-wing),(18,38),(25,36)],fill='#3c7287')
            d.line((23,37,22+stride,40),fill='#c8a46b'); d.line((27,37,28-stride,40),fill='#c8a46b')
        if frame==4: im=im.transform(im.size,Image.Transform.AFFINE,(1,0,-2*face,0,1,1),Image.Resampling.NEAREST)
        if frame==5:
            overlay=Image.new('RGBA',im.size,'#f2b685'); overlay.putalpha(im.getchannel('A')); im=Image.blend(im,overlay,.25)
        return im
    palettes={'player':('#4f9792','#b85236'),'chief':('#8a7960','#d6a85f'),'hunter':('#547054','#777f43'),'healer':('#c2c5a3','#5d9390'),'smith':('#765444','#ba854b'),'gatherer':('#ac795b','#dda65b'),'melee':('#7d8c4b','#865040'),'archer':('#627d45','#b79258'),'shaman':('#665482','#8a75a4')}
    coat,accent=palettes[kind]; gob=kind in ['melee','archer','shaman']; skin='#91a45f' if gob else SKIN
    # Boots/legs give a readable two-leg locomotion silhouette, not a sliding disc.
    for x,s in [(19,1),(26,-1)]:
        end=41+stride*s; d.rectangle((x,31+bob,x+4,end),INK); d.rectangle((x+1,32+bob,x+3,end-3),'#46534c'); d.rectangle((x-1,end-2,x+4,end),'#49382f')
    torso=[(17,23+ bob),(30,23+bob),(33,34+bob),(27,37+bob),(16,35+bob)]
    d.polygon(torso,fill=INK); d.polygon([(18,24+bob),(29,24+bob),(31,33+bob),(25,35+bob),(18,34+bob)],fill=coat)
    d.rectangle((19,25+bob,21,32+bob),shade(coat,1.2)); d.line((18,33+bob,30,33+bob),fill='#564331',width=2); d.rectangle((24,32+bob,26,34+bob),'#d3b774')
    if kind in ['player','chief','shaman']:
        d.polygon([(16,23+bob),(20,22+bob),(21,34+bob),(15,37+bob),(13,30+bob)],fill=shade(accent,.72),outline=INK)
        d.line((16,25+bob,17,33+bob),fill=accent)
    hx=24+(face if side else 0); hy=17+bob
    if gob:
        d.polygon([(hx-6,hy-3),(hx-12,hy-5),(hx-8,hy+2),(hx+7,hy+2),(hx+12,hy-5),(hx+5,hy-3)],fill=skin,outline=INK)
    d.rectangle((hx-6,hy-6,hx+6,hy+5),INK); d.rectangle((hx-5,hy-5,hx+5,hy+4),skin)
    d.rectangle((hx-5,hy-5,hx+5,hy-2),'#493e35' if not gob else shade(skin,.65))
    d.point((hx-4,hy-1),LIGHT)
    if not back:
        if side: d.rectangle((hx+face*3,hy,hx+face*3+1,hy+1),INK); d.point((hx+face*6,hy+2),skin)
        else:
            d.rectangle((hx-3,hy,hx-2,hy+1),INK); d.rectangle((hx+2,hy,hx+3,hy+1),INK)
        d.line((hx-2,hy+3,hx+2,hy+3),fill=shade(skin,.7))
    if back: d.rectangle((hx-5,hy-4,hx+5,hy+3),'#57483c' if not gob else shade(skin,.8))
    # Identity, not recolors: hood/scarf/crown/beard/hat/backpack/apron/tools.
    if kind=='player':
        d.line((hx-6,hy-5,hx-2,hy-8,hx+6,hy-5),fill='#416c6b',width=3)
        d.rectangle((18,23+bob,30,25+bob),accent); d.polygon([(29,24+bob),(36,27+bob),(32,30+bob),(27,26+bob)],fill=accent)
    if kind=='chief':
        d.rectangle((hx-6,hy-6,hx+6,hy-5),'#ddb973'); d.polygon([(hx-4,hy+3),(hx+4,hy+3),(hx+2,hy+10),(hx-2,hy+10)],fill='#c8c1a5')
    if kind=='hunter':
        d.polygon([(hx-7,hy-3),(hx,hy-10),(hx+7,hy-3)],fill=accent,outline=INK); d.line((hx+5,hy-7,hx+9,hy-13),fill='#d9c493',width=2)
    if kind=='healer':
        d.rectangle((hx-6,hy-6,hx+6,hy-3),'#ddd9b8'); d.line((hx-5,hy-3,hx-7,hy+6),fill=coat,width=3); d.rectangle((21,26+bob,27,32+bob),'#e4d3a0'); d.rectangle((23,27+bob,25,31+bob),'#4e8180')
    if kind=='smith':
        d.rectangle((hx-6,hy-6,hx+6,hy-3),'#9b704b'); d.rectangle((19,26+bob,29,36+bob),'#493d35'); d.line((20,26+bob,28,26+bob),fill=accent); d.rectangle((hx-4,hy+3,hx+4,hy+7),'#6c4c34')
    if kind=='gatherer':
        d.ellipse((hx-8,hy-9,hx+8,hy-4),'#c8a362'); d.rectangle((hx-10,hy-5,hx+10,hy-3),'#e0bf78'); d.rectangle((12,27+bob,17,35+bob),'#a47b4b'); d.line((12,29+bob,17,29+bob),fill=LIGHT)
    if kind=='melee':
        d.polygon([(hx-5,hy-6),(hx-2,hy-9),(hx+2,hy-9),(hx+5,hy-6)],fill='#817e6c'); d.line((20,25+bob,29,31+bob),fill='#a28a61',width=2)
    if kind=='archer':
        d.polygon([(hx-7,hy-2),(hx-5,hy-8),(hx+4,hy-9),(hx+7,hy-2)],fill='#586742',outline=INK); d.line((17,24+bob,29,34+bob),fill=accent,width=2)
    if kind=='shaman':
        d.polygon([(hx-8,hy-4),(hx-4,hy-13),(hx+2,hy-14),(hx+6,hy-4)],fill=coat,outline=INK); d.rectangle((hx-7,hy-4,hx+7,hy-3),accent); d.ellipse((22,25+bob,26,29+bob),'#aee0bb')
    arm_y=27+bob-(4 if frame==4 else 0)
    for x in [15,31]: d.line((x,25+bob,x+(face*2 if frame==4 else 0),arm_y+4),fill=INK,width=4); d.rectangle((x-1,arm_y,x+1,arm_y+3),skin)
    if kind in ['player','chief','shaman','melee','smith','archer','hunter']:
        x=35 if direction!=1 else 12
        if kind in ['archer','hunter']:
            d.arc((x-4,15+bob,x+5,38+bob),-85,85,fill='#bd9464',width=2); d.line((x,16+bob,x,37+bob),fill='#b9c2a7')
        elif kind=='smith':
            d.line((x,22+bob,x,35+bob),fill='#b38a59',width=2); d.rectangle((x-4,21+bob,x+4,25+bob),'#859695'); d.line((x-4,21+bob,x+4,21+bob),fill=LIGHT)
        else:
            d.line((x,13+bob,x,41+bob),fill='#634d36',width=3); d.line((x,14+bob,x,39+bob),fill='#c09c63')
            if kind=='shaman': d.ellipse((x-4,9+bob,x+4,17+bob),'#8abaaa'); d.ellipse((x-2,10+bob,x+1,13+bob),'#d8f1c0')
            else: d.polygon([(x-3,14+bob),(x,5+bob),(x+3,14+bob)],fill='#c2d1bd',outline=INK)
    if frame==5:
        overlay=Image.new('RGBA',im.size,'#f4caa0'); overlay.putalpha(im.getchannel('A')); im=Image.blend(im,overlay,.32)
    return im

for kind in 'player chief hunter healer smith gatherer melee archer shaman bear deer rabbit bird'.split():
    sheet=Image.new('RGBA',(288,192))
    for row in range(4):
        for col in range(6): sheet.paste(actor(kind,row,col),(col*48,row*48))
    save(sheet,'sprites',kind)

def tree(index):
    r=random.Random(index+33); im,d=canvas(112,136)
    d.polygon([(49,131),(54,72),(62,68),(66,129),(77,135),(59,132),(43,135)],fill=INK)
    d.polygon([(53,128),(57,73),(61,73),(63,129),(58,126)],fill='#765942'); d.line((59,78,59,125),fill='#a28155',width=2)
    d.line((57,100,33,77),fill='#694d3a',width=5); d.line((61,92,83,62),fill='#694d3a',width=4)
    colors=[['#1c403d','#28574b','#347159','#458567','#659574'],['#273c3a','#345548','#426d52','#587c58','#809460'],['#283e3b','#3c5142','#57654a','#79805b','#a29b6c']][index%3]
    centers=[(56,29,28),(34,45,25),(79,48,25),(23,68,21),(51,66,30),(82,75,26),(50,87,27)]
    for cx,cy,rad in centers:
        d.ellipse((cx-rad,cy-rad,cx+rad,cy+rad),INK)
        d.ellipse((cx-rad+2,cy-rad+1,cx+rad-1,cy+rad-4),colors[0])
    for cx,cy,rad in centers:
        for j in range(55):
            x=int(r.gauss(cx,rad*.53)); y=int(r.gauss(cy-5,rad*.47)); w=r.randint(3,9); h=r.randint(2,5)
            if ((x-cx)/rad)**2+((y-cy)/rad)**2<.85:
                color=colors[r.choices(range(1,5),[3,4,3,1])[0]]; d.rectangle((x,y,x+w,y+h),color); d.point((x+1,y-1),color)
    return im
for i in range(3): save(tree(i),'props','tree'+str(i))
im,d=canvas(80,132)
d.polygon([(34,131),(36,55),(45,55),(46,131)],fill='#72523a',outline=INK)
for y,w in [(87,38),(66,32),(44,25),(25,16)]:
    d.polygon([(40,y-24),(40-w,y+22),(32,y+18),(38,y+25),(40+w,y+19)],fill='#23443e',outline=INK)
    d.polygon([(40,y-20),(42-w,y+16),(35,y+12),(41,y+17),(36+w,y+13)],fill='#3b6851')
    d.line((40,y-15,30,y+8),fill='#68906b',width=2)
save(im,'props','pine')
im,d=canvas(48,32); r=random.Random(14)
for x,y,rr in [(12,20,10),(25,14,13),(37,20,10)]:
    d.ellipse((x-rr,y-rr,x+rr,y+rr),INK); d.ellipse((x-rr+1,y-rr+1,x+rr-1,y+rr-2),'#416c4d')
    for i in range(20):
        a=r.uniform(0,6.28); rad=r.uniform(0,rr-3); px=x+int(math.cos(a)*rad); py=y+int(math.sin(a)*rad); d.line((px,py,px+2,py),fill=r.choice(['#66895a','#88a064','#315b46']))
save(im,'props','bush')
im,d=canvas(48,40); d.polygon([(5,32),(7,18),(19,9),(34,12),(43,27),(37,36),(16,37)],fill=INK); d.polygon([(7,29),(9,18),(20,11),(33,14),(38,28),(26,31)],fill='#788b81'); d.polygon([(7,30),(26,31),(39,26),(36,34),(16,35)],fill='#475e59'); d.line((10,19,21,13,31,16),fill='#b2b69a',width=2); d.rectangle((14,30,22,32),'#617d4b'); save(im,'props','rock')
im,d=canvas(112,94)
d.polygon([(4,84),(52,5),(70,11),(107,82),(80,90),(23,89)],fill=INK)
d.polygon([(8,81),(53,9),(60,16),(37,82)],fill='#a57149'); d.polygon([(55,9),(70,14),(102,80),(65,84)],fill='#c69762')
d.polygon([(57,23),(39,82),(79,82)],fill='#4b4136'); d.polygon([(58,23),(45,81),(54,77)],fill='#dfb576')
d.line((53,11,9,82),fill='#dab378',width=2); d.line((71,17,96,76),fill='#e6c18a',width=2)
for x in [10,99]: d.line((x,79,x,91),fill='#7b5d40',width=3)
d.line((56,12,4,80),fill='#d1b27a'); d.rectangle((31,83,82,87),'#5d5340'); save(im,'props','tent')
im,d=canvas(64,48)
d.rectangle((7,30,13,45),'#644d39'); d.rectangle((51,30,57,45),'#644d39'); d.rectangle((3,19,61,31),INK); d.rectangle((4,20,60,28),'#9a754c')
for y in [22,26]: d.line((6,y,57,y),fill='#c09a62')
for x in [13,45]: d.rectangle((x,15,x+8,22),'#b69d72'); d.rectangle((x+2,12,x+6,16),'#497560')
save(im,'props','table')
im,d=canvas(64,60)
d.rectangle((11,30,52,56),INK); d.rectangle((13,31,50,54),'#66736c')
for y in [34,43,51]: d.line((14,y,50,y),fill='#3d514d'); d.line((27+(y%2)*7,y,27+(y%2)*7,y+7),fill='#3d514d')
d.ellipse((20,32,44,51),'#2f322c'); d.ellipse((24,39,41,50),'#df703b'); d.ellipse((30,39,38,49),'#f8ca73')
d.polygon([(9,14),(21,14),(24,21),(50,21),(53,28),(45,34),(25,34),(18,25),(9,21)],fill='#475955',outline=INK); d.line((11,15,20,15,25,22,49,22),fill='#b1b89c',width=2)
save(im,'props','forge')
im,d=canvas(48,56); d.rectangle((22,16,26,53),'#8c6b47'); d.polygon([(6,9),(35,9),(44,17),(35,25),(6,25)],fill='#a67e4e',outline=INK); d.line((11,14,29,14),fill='#e2c282'); d.line((11,19,25,19),fill='#584a38'); save(im,'props','sign')
im,d=canvas(128,78)
for y in range(5,72,9):
    d.rectangle((2,y,125,y+7),INK); d.rectangle((4,y+1,123,y+5),'#9d784c'); d.line((8,y+2,118,y+2),fill='#c7a66a'); d.point((13,y+3),INK); d.point((111,y+3),INK)
for x in [6,117]: d.rectangle((x,0,x+4,76),'#574d39'); d.line((x,0,x,75),fill='#c6a168')
save(im,'props','bridge')
im,d=canvas(48,94); d.rectangle((11,12,37,82),INK); d.rectangle((13,13,35,79),'#83978b'); d.rectangle((28,14,35,80),'#5b736d'); d.rectangle((6,77,42,90),INK); d.rectangle((8,78,40,87),'#758b7e'); d.polygon([(9,13),(10,5),(22,3),(24,7),(35,4),(40,14)],fill='#9ca996',outline=INK)
d.line((18,20,18,71),fill='#b9c2a3',width=2); d.line((30,23,25,34,29,43),fill='#425e57'); d.rectangle((9,79,21,82),'#6f8751'); save(im,'props','column')
im,d=canvas(96,58)
for y in range(12,54,12):
    for x in range(-12 if y%24 else 0,94,24):
        d.rectangle((max(x,0),y,min(x+23,95),y+11),INK); d.rectangle((max(x+1,0),y+1,min(x+22,95),y+9),'#6e8579'); d.line((max(x+2,0),y+1,min(x+21,95),y+1),fill='#a5b197')
d.rectangle((3,48,20,51),'#6a8953'); d.rectangle((61,22,79,25),'#6a8953'); save(im,'props','wall')

# Inventory/world items: richly shaded icons with transparent margins.
for name in 'ember herb bag potion stone checkpoint altar arrow magic'.split():
    im,d=canvas(64,64) if name in ['checkpoint','altar'] else canvas(24,24)
    if name=='ember':
        d.polygon([(12,1),(20,13),(17,20),(8,22),(3,15),(8,7),(9,14)],fill='#c05d37',outline=INK); d.polygon([(12,7),(16,14),(13,20),(8,17)],fill='#f7b95c'); d.rectangle((11,12,13,17),'#ffe3a0')
    elif name=='herb':
        d.line((11,22,12,5),fill='#b6c58a',width=2)
        for x,y,s in [(11,10,-1),(12,14,1),(11,18,-1)]: d.polygon([(x,y+3),(x+s*7,y-1),(x+s*6,y-5),(x,y)],fill='#66a776',outline='#284f43')
        d.ellipse((10,2,14,6),'#dba487')
    elif name=='bag':
        d.rounded_rectangle((4,6,20,22),radius=3,fill='#97704a',outline=INK); d.rectangle((5,8,19,13),'#bf9964'); d.rectangle((10,11,14,16),'#dac58a'); d.arc((7,1,17,12),180,360,fill='#6a543c',width=2)
    elif name=='potion':
        d.rectangle((9,2,15,7),INK); d.rectangle((10,2,14,4),'#b79962'); d.ellipse((5,7,19,22),INK); d.ellipse((6,8,18,21),'#adc6b1'); d.ellipse((7,12,17,20),'#b76053'); d.line((8,10,8,15),fill='#e3e0b4',width=2)
    elif name=='stone':
        d.polygon([(3,17),(6,9),(15,7),(21,15),(17,20),(6,21)],fill='#869892',outline=INK); d.line((7,11,14,9,18,14),fill='#c2c6ab',width=2)
    elif name=='arrow':
        d.line((2,12,20,12),fill='#b69665',width=2); d.polygon([(18,8),(23,12),(18,16)],fill='#c6d4ba'); d.line((3,9,7,12,3,15),fill='#aaba9c')
    elif name=='magic':
        for rad,col in [(10,'#554973'),(7,'#8b77af'),(4,'#c2b3cd'),(2,'#fff0c5')]: d.ellipse((12-rad,12-rad,12+rad,12+rad),col)
    elif name=='checkpoint':
        d.ellipse((5,37,59,61),INK)
        for i in range(9):
            a=i*math.tau/9; x=32+int(math.cos(a)*23); y=49+int(math.sin(a)*10); d.ellipse((x-6,y-4,x+6,y+4),'#849083')
        for points in [(17,50,44,40),(18,40,46,52)]: d.line(points,fill='#79543a',width=5)
        d.polygon([(18,43),(20,25),(27,34),(34,8),(38,30),(47,23),(43,45),(33,51)],fill='#c66537'); d.polygon([(25,42),(31,27),(33,35),(38,23),(40,42),(32,48)],fill='#f1ab4d'); d.polygon([(30,42),(34,32),(36,44)],fill='#ffe4a0')
    else:
        d.ellipse((4,41,60,61),INK); d.ellipse((6,40,58,56),'#6f847c'); d.rectangle((14,31,50,48),INK); d.rectangle((16,32,48,46),'#95a798'); d.ellipse((8,22,56,37),INK); d.ellipse((10,23,54,33),'#b2bca0'); d.ellipse((18,24,46,31),'#485f59'); d.polygon([(27,24),(24,12),(32,3),(41,14),(36,27)],fill='#74b8a1',outline=INK); d.line((31,8,29,17,32,22),fill='#ddedb5',width=2)
    save(im,'props',name)

# Hand-designed terrain: connected meandering paths, leaf litter, creek banks,
# scattered flowers and flagstones. Work in 1:1 pixels, no blurred upscaling.
r=random.Random(641); full=Image.new('RGB',(2400,1600),'#314f43'); d=ImageDraw.Draw(full)
for i in range(155000):
    x=r.randrange(2400); y=r.randrange(1600); col=r.choice(['#355648','#395b49','#3f614b','#2d4b40','#355244'])
    d.rectangle((x,y,x+r.choice([1,2,3]),y+r.choice([0,1,2])),col)
roads=[[(420,340),(430,470),(760,465),(1060,375),(1380,380),(1740,390),(1980,450)],[(445,470),(410,720),(550,960),(530,1190),(760,1200),(1010,1160),(1420,1190),(1830,1190)],[(1770,400),(1840,720),(1730,940),(1830,1190)],[(830,1160),(830,1390)]]
for path in roads:
    d.line(path,fill='#4c6250',width=99); d.line(path,fill='#767354',width=70); d.line(path,fill='#8b805d',width=49)
for i in range(24000):
    x=r.randrange(2400); y=r.randrange(1600)
    if full.getpixel((x,y)) in [(139,128,93),(118,115,84)]:
        d.line((x,y,x+r.randint(1,5),y),fill=r.choice(['#9d916a','#b0a074','#7d7755','#67694d']))
# Camp clearing with dusty concentric footpaths.
d.ellipse((270,260,620,540),fill='#7f7857'); d.ellipse((315,305,570,513),fill='#918361')
for i in range(1800):
    x=r.randrange(280,620); y=r.randrange(260,540)
    if full.getpixel((x,y)) in [(127,120,87),(145,131,97)]: d.line((x,y,x+2,y),fill=r.choice(['#a09268','#766f51','#ada078']))
# Creek is visual shallow water: walkable with a prominent bridge on route.
stream=[(255,800),(300,920),(300,1060),(345,1200),(325,1370),(390,1600)]
d.line(stream,fill='#637b61',width=136); d.line(stream,fill='#b3ac7a',width=111); d.line(stream,fill='#315f60',width=91); d.line(stream,fill='#417778',width=64)
for i in range(1600):
    y=r.randrange(805,1600); x=r.randrange(210,450)
    if full.getpixel((x,y)) in [(49,95,96),(65,119,120)]: d.line((x,y,x+r.randint(3,15),y),fill=r.choice(['#649b92','#568d89','#8eb5a2']))
for gy in range(1050,1400,28):
    for gx in range(1640,2020,34):
        if r.random()<.12: continue
        x=gx+r.randint(-2,2); y=gy+r.randint(-2,2)
        d.rectangle((x,y,x+31,y+24),'#4b6457'); d.rectangle((x+1,y+1,x+29,y+21),r.choice(['#6b7d67','#77866c','#657b65'])); d.line((x+3,y+2,x+26,y+2),fill='#8d9677')
for i in range(9000):
    x=r.randrange(2400); y=r.randrange(1600)
    if full.getpixel((x,y))[1] > full.getpixel((x,y))[0]*1.2:
        color=r.choice(['#77935d','#56784d','#85a268','#4b7253']); d.line((x-2,y,x-3,y-4),fill=color); d.line((x,y,x+1,y-6),fill=color)
        if i%9==0: d.rectangle((x,y-6,x+1,y-5),r.choice(['#cca975','#a6bd8c','#92bcb0','#c9958e']))
for name,x,y in [('camp',0,0),('forest',1200,0),('creek',0,800),('ruins',1200,800)]: save(full.crop((x,y,x+1200,y+800)),'terrain',name)

shutil.copyfile('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',A/'fonts/DejaVuSans.ttf')
license_path=Path('/usr/share/doc/fonts-dejavu-core/copyright')
if license_path.exists(): shutil.copyfile(license_path,A/'fonts/LICENSE-DejaVu.txt')
print('Generated 13 directional actor sheets, 25 props, 4 terrain regions, font.')
