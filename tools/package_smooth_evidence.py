from pathlib import Path
import os,shutil,json
ROOT=Path(__file__).resolve().parents[1]
base=Path(os.environ['APPDATA'])/'Godot/app_userdata/Rừng Tàn Lửa'
dest=ROOT/'docs/screenshots/SmoothMotion-20261014';dest.mkdir(parents=True,exist_ok=True)
for label in ['baseline','after','final']:
    source=base/f'movement-{label}.json'
    if source.exists():shutil.copy2(source,dest/source.name)
for source in (base/'captures/full-audit').glob('*.png'):shutil.copy2(source,dest/source.name)
print('SmoothMotion timing and native capture evidence:',dest)
