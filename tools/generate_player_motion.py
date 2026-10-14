"""Player: front-only spear motion and no animated arms in any action."""
from pathlib import Path
import math,json
from PIL import Image,ImageDraw
import hashlib,os
from generate_weapon_layers import body_function
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/player_motion'
CELL=192;ORIGIN=(96,128)
FIXED_BODY=body_function('generate_assets.py',{'arms','weapon'})
REFERENCE=Image.open(ROOT/'assets/sprites/player.png').convert('RGBA')
SPEC=json.loads((ROOT/'assets/action_spec.json').read_text())
DURATIONS={name:entry['duration'] for name,entry in SPEC['actions'].items()}
CONTACT={name:entry['contact'] for name,entry in SPEC['actions'].items() if 'contact' in entry}
def lerp(a,b,t):return a+(b-a)*t
def row_for(o):return [2,0,0,0,1,3,3,3][o]
def spear(d,grip,angle,length=32,front_connector=0):
    f=(math.cos(angle),math.sin(angle));s=(-f[1],f[0])
    def p(a,b=0):return round(grip[0]+f[0]*a+s[0]*b),round(grip[1]+f[1]*a+s[1]*b)
    # Connector stops at the forward body edge, never behind the character.
    d.line([p(-front_connector),p(length-8)],fill='#162632',width=3)
    d.line([p(-front_connector),p(length-8)],fill='#c09c63',width=1)
    d.polygon([p(length),p(length-9,-3),p(length-7),p(length-9,3)],fill='#c2d1bd',outline='#162632')
    d.line([p(length-7),p(length-2)],fill='#f1e4b8')
def frame(name,o,t):
    im=Image.new('RGBA',(CELL,CELL));row=row_for(o)
    f=(math.cos(o*math.tau/8),math.sin(o*math.tau/8))
    carry=(ORIGIN[0]+(-12 if row==1 else 11),ORIGIN[1]-18)
    if name in ['thrust','heavy','throw'] and t>=DURATIONS[name]-.00001:
        im.alpha_composite(REFERENCE.crop((0,row*48,48,(row+1)*48)),(72,83));return im
    body=FIXED_BODY('player',row,0)
    if name=='dead':
        q=min(1,t/.24);angle=[0,20,45,70,90][min(4,int(q*5))]
        # Entire body falls; no separately animated or restored arm clusters.
        fallen=body.rotate(-angle if f[0]>=0 else angle,resample=Image.Resampling.NEAREST,expand=True)
        im.alpha_composite(fallen,(round(96-fallen.width/2),round(128-fallen.height+q*12)))
        return im
    dip=round(math.sin(min(t/.22,1)*math.pi)*3) if name=='dodge' else 0
    recoil=round(-2*math.sin(min(t/.18,1)*math.pi)) if name=='hurt' else 0
    im.alpha_composite(body,(72+round(f[0]*recoil),83+dip+round(f[1]*recoil)))
    d=ImageDraw.Draw(im)
    if name in ['thrust','heavy','charge']:
        contact=CONTACT.get(name,.13);duration=DURATIONS[name]
        maximum=SPEC['normal_reach' if name=='thrust' else 'heavy_reach']-SPEC['spear_length']
        if name=='charge':distance=14;recover=0
        elif t<contact:
            # Small retract stays outside the body; never travels behind it.
            q=t/contact
            distance=lerp(16,14,q/.55) if q<.55 else lerp(14,maximum,(q-.55)/.45)
            recover=0
        else:
            hold=contact+.025
            distance=maximum if t<=hold else lerp(maximum,14,min(1,(t-hold)/(duration-hold-.055)))
            recover=max(0,min(1,(t-(duration-.055))/.055))
        angle=o*math.tau/8
        grip=(ORIGIN[0]+f[0]*distance+(10 if o in [2,6] else 0),ORIGIN[1]-13+f[1]*distance)
        delta=(-math.pi/2-angle+math.pi)%math.tau-math.pi
        angle+=delta*recover
        grip=(lerp(grip[0],carry[0],recover),lerp(grip[1],carry[1],recover))
        spear(d,grip,angle,lerp(32,22,recover),max(0,distance-10)*(1-recover))
    else:
        spear(d,carry,-math.pi/2,22)
        if name=='throw' and t<CONTACT['throw']:
            q=t/CONTACT['throw'];release=SPEC['stone_release']
            x=round(ORIGIN[0]+f[0]*lerp(12,release['distance'],q));y=round(ORIGIN[1]+release['height']+f[1]*lerp(12,release['distance'],q))
            d.polygon([(x-2,y-2),(x+1,y-3),(x+3,y),(x+1,y+2),(x-2,y+1)],fill='#99aaa0',outline='#162632')
    return im
def main():
    OUT.mkdir(parents=True,exist_ok=True);manifest={}
    for name,length in DURATIONS.items():
        times=sorted(set([round(i/120,6) for i in range(math.ceil(length*120))]+[length]+([CONTACT[name]] if name in CONTACT else [])))
        unique=[];lookup={};indices=[];bounds=None
        for o in range(8):
            for t in times:
                tile=frame(name,o,t);key=hashlib.sha256(tile.tobytes()).digest()
                if key not in lookup:
                    lookup[key]=len(unique);unique.append(tile)
                    b=tile.getbbox()
                    bounds=b if bounds is None else (min(bounds[0],b[0]),min(bounds[1],b[1]),max(bounds[2],b[2]),max(bounds[3],b[3]))
                indices.append(lookup[key])
        bounds=(bounds[0]-2,bounds[1]-2,bounds[2]+2,bounds[3]+2)
        w,h=bounds[2]-bounds[0],bounds[3]-bounds[1];columns=min(len(unique),max(1,2048//w))
        sheet=Image.new('RGBA',(w*columns,h*math.ceil(len(unique)/columns)))
        for n,tile in enumerate(unique):sheet.alpha_composite(tile.crop(bounds),((n%columns)*w,(n//columns)*h))
        temp=OUT/(name+'.tmp.png');sheet.save(temp);os.replace(temp,OUT/(name+'.png'))
        manifest[name]={'times':times,'columns':len(times),'duration':length,'indices':indices,'cell':[w,h],'atlas_columns':columns,'bounds':list(bounds),'unique':len(unique)}
    (OUT/'timelines.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    evidence=ROOT/'docs/screenshots/front-spear';evidence.mkdir(parents=True,exist_ok=True)
    samples=[0,.025,.05,.08,.12,.17,.21,.24]
    result=Image.new('RGB',(8*192,192),'#102a30');d=ImageDraw.Draw(result)
    for i,t in enumerate(samples):
        tile=frame('thrust',0,t);result.paste(tile,(i*192,0),tile);d.text((i*192+4,4),str(t)+'s',fill='white')
    result.resize((3072,384),Image.Resampling.NEAREST).save(evidence/'horizontal-design.png')
    print('FrontSpear: no arm animation functions; spear painted in front from forward anchor')
    total=sum(Image.open(OUT/(name+'.png')).width*Image.open(OUT/(name+'.png')).height*4 for name in manifest)
    print('ATLAS RGBA8 BYTES:',total,'MiB:',round(total/1048576,3))
if __name__=='__main__':main()
