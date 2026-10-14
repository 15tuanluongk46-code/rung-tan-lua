"""Chapter II original pixel assets + synthesized scores; does not rewrite base art."""
from pathlib import Path
import random, math, json, shutil
import os
from PIL import Image, ImageDraw
import generate_audio as audio

ROOT = Path(__file__).resolve().parents[1]
A = ROOT / 'assets'
INK = '#17262b'

def save(im, folder, name):
    im.save(A / folder / (name + '.png'))

def actor(kind, row, frame):
    im = Image.new('RGBA', (48,48)); d = ImageDraw.Draw(im)
    bob = -1 if frame == 2 else 0
    stride = [0,-2,1,2,0,0][frame]
    cx, cy = 24, 22+bob
    side = -1 if row == 1 else 1
    palettes = {'sen':('#779987','#cfb575'), 'tung':('#805649','#d7a575'), 'stalker':('#527d71','#9cd7bf'), 'coal':('#5c5354','#f39253'), 'guardian':('#585769','#edbb74')}
    coat, accent = palettes[kind]
    for x,s in [(18,1),(27,-1)]:
        d.rectangle((x,32+bob,x+4,41+stride*s),INK)
        d.rectangle((x+1,33+bob,x+3,39+stride*s),'#4a5b55')
    if kind == 'guardian':
        d.polygon([(10,20),(37,20),(40,34),(32,38),(15,38),(8,31)],fill=INK)
        d.polygon([(12,21),(35,21),(37,33),(30,35),(16,35),(11,29)],fill=coat)
        d.line((14,25,34,25),fill=accent,width=2)
        d.polygon([(13,8),(33,8),(35,21),(12,21)],fill=INK)
        d.rectangle((15,10,31,19),coat)
        if row != 3: d.rectangle((18,15,29,16),'#ffe5a0')
        d.line((14,9,10,3),fill=accent,width=3); d.line((32,9,36,3),fill=accent,width=3)
        # layer: weapon
        d.line((39,9,39,42),fill='#a88a66',width=2)
        # layer: weapon
        d.polygon([(39,2),(34,13),(44,13)],fill='#ffd58c',outline=INK)
    elif kind == 'stalker':
        d.polygon([(16,20),(31,20),(35,35),(12,36)],fill=coat,outline=INK)
        d.polygon([(12,20),(14,9),(25,5),(34,12),(36,22)],fill=INK)
        d.polygon([(14,19),(16,11),(25,8),(32,13),(33,20)],fill=coat)
        if row != 3:
            d.rectangle((18,15,29,20),'#213c38'); d.point((20,17),accent); d.point((28,17),accent)
        d.line((13,23,8,34),fill=accent,width=2)
        d.line((34,24,40,36),fill='#bbc8ba',width=2)
        for x in [16,23,29]: d.line((x,27,x-2,36),fill=accent)
    elif kind == 'coal':
        d.rectangle((12,20,35,35),INK); d.rectangle((14,21,33,33),coat)
        d.rectangle((17,9,31,21),INK); d.rectangle((19,11,29,19),'#777065')
        if row != 3: d.line((20,15,28,15),fill=accent,width=2)
        d.line((17,25,23,29,20,33),fill=accent,width=2)
        # layer: weapon
        d.line((37,18,38,40),fill='#9b7f5c',width=2)
        # layer: weapon
        d.rectangle((33,13,43,21),'#676b69'); d.line((34,14,42,14),fill='#d4b886')
    else:
        d.polygon([(16,21),(31,21),(34,35),(14,35)],fill=coat,outline=INK)
        d.rectangle((18,10,30,21),INK); d.rectangle((19,11,29,20),'#d6ad84')
        if row != 3:
            d.point((21 if row != 2 else 28,16),INK); d.line((23,19,27,19),fill='#956649')
        if kind == 'sen':
            d.polygon([(10,13),(24,4),(38,13)],fill='#b4ae78',outline=INK)
            d.line((12,25,9,36),fill=accent,width=2)
            d.rectangle((5,29,13,40),INK); d.rectangle((7,31,11,38),'#ffc775')
            d.arc((6,25,12,32),180,360,fill=accent)
        else:
            d.rectangle((19,23,30,35),'#5f4840'); d.rectangle((21,27,28,30),accent)
            d.rectangle((19,12,29,15),'#645952'); d.line((20,13,28,13),fill='#c7d7c5')
            d.line((35,27,38,39),fill=accent,width=2); d.rectangle((32,24,41,28),'#777f77')
    if frame == 4:
        # layer: arms
        d.line((33,25,44,25),fill=accent,width=3)
    if frame == 5:
        tint = Image.new('RGBA', im.size, '#f5c897'); tint.putalpha(im.getchannel('A')); im=Image.blend(im,tint,.3)
    if row == 1: im=im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    return im

def main():
    if os.environ.get('RTL_ASSET_STAGING') != '1': raise RuntimeError('Use tools/regenerate_assets.py')
    if not shutil.which('ffmpeg'): raise RuntimeError('FFmpeg required before any generation')
    for kind in ['sen','tung','stalker','coal','guardian']:
        sheet=Image.new('RGBA',(288,192))
        for row in range(4):
            for frame in range(6): sheet.paste(actor(kind,row,frame),(frame*48,row*48))
        save(sheet,'sprites',kind)
    for name in ['lantern','well','valve','bell','memory','broken_bridge','plank','bell_part','charred_tree','reed','hut','tower']:
        size=(96,136) if name in ['tower','charred_tree'] else ((96,88) if name=='hut' else (64,64))
        im=Image.new('RGBA',size); d=ImageDraw.Draw(im)
        if name=='lantern':
            d.rectangle((29,18,33,61),'#7d674a'); d.line((30,20,47,20),fill='#c0a176',width=2)
            d.rectangle((41,22,53,40),INK); d.rectangle((43,24,51,36),'#f4be72')
        elif name=='well':
            d.ellipse((5,34,59,60),INK); d.ellipse((7,32,57,55),'#7b9b90'); d.ellipse((13,34,51,46),'#2e6468')
            d.rectangle((15,20,19,43),'#8c7b58'); d.rectangle((46,20,50,43),'#8c7b58'); d.line((12,20,52,20),fill='#c9b98a',width=3)
            for x in [14,28,42]: d.line((x,49,x,55),fill='#465e57')
        elif name=='valve':
            d.rectangle((28,23,36,61),'#7f7063'); d.ellipse((15,8,49,42),INK); d.ellipse((18,11,46,39),'#a89067'); d.ellipse((23,16,41,34),'#514f48')
            d.line((20,25,44,25),fill='#d5bd8b',width=2); d.line((32,13,32,37),fill='#d5bd8b',width=2)
        elif name in ['bell','bell_part']:
            d.polygon([(20,10),(42,10),(49,42),(14,42)],fill='#b7985d',outline=INK); d.line((18,41,47,41),fill='#f4d398',width=3)
            d.ellipse((28,41,36,50),'#d9b875'); d.arc((26,3,38,17),180,360,fill='#9b8b63',width=2)
            if name=='bell_part': d.polygon([(32,9),(48,9),(48,51),(28,35)],fill=(0,0,0,0))
        elif name=='memory':
            d.polygon([(12,57),(14,20),(26,10),(45,17),(51,57)],fill=INK)
            d.polygon([(15,54),(17,22),(28,14),(42,20),(47,54)],fill='#758d82')
            for y in [27,35,43]: d.line((22,y,38,y),fill='#bcd1b7',width=2)
        elif name=='plank':
            for y in [20,31,42]: d.polygon([(9,y+6),(48,y),(54,y+7),(14,y+13)],fill='#a58258',outline=INK)
        elif name=='broken_bridge':
            for y in [9,19,43,53]: d.rectangle((4,y,59,y+7),'#93724e',outline=INK)
            d.line((6,3,6,62),fill='#c0a079',width=3); d.line((57,3,57,62),fill='#c0a079',width=3)
        elif name=='charred_tree':
            d.polygon([(37,130),(43,45),(28,27),(16,23),(12,12),(33,22),(45,35),(47,7),(54,5),(55,43),(76,27),(83,12),(86,16),(77,39),(59,54),(61,130)],fill='#3e3d3c',outline=INK)
            d.line((47,125,50,61,54,32),fill='#c16c45',width=2)
        elif name=='reed':
            for x in range(12,56,8):
                d.line((32,60,x,15+x%11),fill='#789985',width=2); d.line((x,14+x%11,x,24+x%11),fill='#c0b688',width=3)
        elif name=='hut':
            d.rectangle((17,34,81,81),'#6a7060',outline=INK); d.rectangle((37,48,57,81),'#293d3c')
            d.polygon([(5,40),(48,5),(92,40)],fill='#8fa382',outline=INK)
            for y in [46,60,72]: d.line((20,y,34,y),fill='#b7b58a'); d.line((60,y,78,y),fill='#b7b58a')
        else:
            d.rectangle((18,25,76,128),INK); d.rectangle((22,29,72,124),'#59595c')
            for y in range(34,125,16): d.line((23,y,71,y),fill='#86847b',width=2)
            d.polygon([(12,27),(20,7),(75,7),(84,27)],fill='#7d776a',outline=INK)
            d.rectangle((35,79,59,128),'#292f33'); d.ellipse((32,20,64,49),'#cf844b'); d.ellipse((40,26,58,41),'#ffe1a0')
        save(im,'props',name)
    roads=[[(530,0),(480,160),(620,310),(900,480)],[(540,0),(460,150),(650,330),(760,540)],[(620,310),(1050,280),(1200,310)],[(0,310),(200,330),(650,330)],[(480,160),(320,400),(620,610),(900,480)]]
    for biome in ['marsh','ash']:
        r=random.Random(811 if biome=='marsh' else 812)
        im=Image.new('RGB',(1200,800),'#304f4b' if biome=='marsh' else '#484543'); d=ImageDraw.Draw(im)
        colors=['#365d56','#41675d','#2b4745','#6e8270'] if biome=='marsh' else ['#534d48','#60564b','#3b3f3e','#7c6651']
        for _ in range(35000):
            x,y=r.randrange(1200),r.randrange(800); d.rectangle((x,y,x+2,y+1),r.choice(colors))
        if biome=='marsh':
            for cx,cy in [(180,240),(760,380),(1060,590),(490,680)]:
                d.ellipse((cx-110,cy-50,cx+130,cy+75),'#6b8675'); d.ellipse((cx-98,cy-42,cx+119,cy+64),'#376c6b')
                for j in range(25):
                    x,y=cx+r.randrange(-80,100),cy+r.randrange(-30,50); d.line((x,y,x+r.randrange(5,18),y),fill='#75a69a')
        else:
            for x,y in [(640,440),(920,490),(240,340)]:
                d.line((x-40,y-12,x-8,y,x+20,y+5,x+40,y+15),fill='#ad5b3e',width=4)
            d.ellipse((570,440,950,780),'#5c5550')
            for y in range(480,760,30):
                for x in range(600,930,35): d.rectangle((x,y,x+30,y+24),'#777066',outline='#3a3d3e')
        local=roads[:1]+roads[2:3]+roads[4:] if biome=='marsh' else roads[1:2]+roads[3:4]
        for path in local:
            d.line(path,fill='#63735e' if biome=='marsh' else '#6c5e50',width=88)
            d.line(path,fill='#899578' if biome=='marsh' else '#92775c',width=48)
        save(im,'terrain',biome)
    from generate_world_polish import terrain, props
    terrain(); props()
    expansion={}
    for key in ['marsh','ash','boss']:
        signal=audio.music(key)
        entry=audio.encode(signal,A/'music'/(key+'.ogg'),shutil.which('ffmpeg'),True)
        expansion[key]=entry
    (A/'expansion_audio_manifest.json').write_text(json.dumps(expansion,indent=2),encoding='utf-8')
    print('Expansion: 5 directional actor sheets, 12 props, 2 terrains and 3 original music loops.')

if __name__=='__main__': main()
