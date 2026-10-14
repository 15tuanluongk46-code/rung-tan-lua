from pathlib import Path
import os,shutil
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
source=Path(os.environ['APPDATA'])/'Godot/app_userdata/Rừng Tàn Lửa/captures'
dest=ROOT/'docs/screenshots/live-qa-20261013';dest.mkdir(parents=True,exist_ok=True)
for name in ['menu','pause','settings','gameplay-input','journey-ending','chapter-two-ending']:
    p=source/(name+'.png')
    if p.exists():shutil.copy2(p,dest/p.name)
for p in (source/'live-qa').glob('*.png'):shutil.copy2(p,dest/p.name)
for name in ['settings-large','accessibility','boss-sector','map-lore']:
    p=source/'quality'/(name+'.png')
    if p.exists():shutil.copy2(p,dest/p.name)
sheet=Image.new('RGB',(480*4,480),'#102a30')
for i,name in enumerate(['idle','thrust-contact','heavy-contact','throw-release']):
    with Image.open(source/'live-qa'/(name+'.png')) as im:tile=im.convert('RGB').crop((250,70,410,230)).resize((480,480),Image.Resampling.NEAREST)
    sheet.paste(tile,(i*480,0));ImageDraw.Draw(sheet).text((i*480+5,5),name,fill='white')
sheet.save(dest/'player-poses-3x.png')
print('Live QA evidence frozen:',dest)
