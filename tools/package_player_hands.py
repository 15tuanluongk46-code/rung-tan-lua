from pathlib import Path
from PIL import Image,ImageDraw
import os,shutil
ROOT=Path(__file__).resolve().parents[1]
def sheet(dest,name,entries,box,columns):
    w,h=(box[2]-box[0])*3,(box[3]-box[1])*3
    result=Image.new('RGB',(w*columns,(h+20)*((len(entries)+columns-1)//columns)),'#102a30');d=ImageDraw.Draw(result)
    for n,(path,label) in enumerate(entries):
        with Image.open(path) as im: tile=im.convert('RGB').crop(box).resize((w,h),Image.Resampling.NEAREST)
        x,y=(n%columns)*w,(n//columns)*(h+20);result.paste(tile,(x,y+20));d.text((x+4,y+4),label,fill='white')
    result.save(dest/(name+'.png'))
def main():
    base=Path(os.environ['APPDATA'])/'Godot/app_userdata/Rừng Tàn Lửa/captures'
    dest=ROOT/'docs/screenshots/player-hands';dest.mkdir(parents=True,exist_ok=True)
    for p in (base/'player-hands').glob('*.png'):shutil.copy2(p,dest/p.name)
    sheet(dest,'idle-run-reference',[(base/'player-hands'/f'{i}-{a}.png',f'{i} {a}') for i in [2,4,0,6] for a in ['idle','run']],(275,95,365,200),2)
    sheet(dest,'spear',[(base/'detail-polish'/f'spear-{i}-{a}.png',f'{i} {a}') for i in range(8) for a in ['pull','contact','return']],(255,70,410,245),3)
    sheet(dest,'throw',[(base/'detail-polish'/f'stone-{i}-{a}.png',f'{i} {a}') for i in [0,2,4,6] for a in ['pull','release','return']],(265,85,400,220),3)
    shutil.copy2(ROOT/'assets/sprites/player.png',dest/'approved-reference.png')
    print('PlayerHands reference + render evidence:',dest)
if __name__=='__main__':main()
