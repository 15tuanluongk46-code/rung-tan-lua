"""Publish deterministic polish/layer/motion outputs only after staging succeeds.

No audio/font regeneration and no workspace fork. Timestamped build staging is
retained as a developer receipt. Mutable runtime PNGs are never polish input after
the first explicit baseline capture.
"""
from pathlib import Path
import os,sys,shutil,subprocess,hashlib,json,time
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
def main():
    assert (ROOT/'assets/fonts/DejaVuSans.ttf').is_file(),'Bundled font missing'
    baseline=ROOT/'assets/source_props'
    baseline.mkdir(exist_ok=True)
    for p in (ROOT/'assets/props').glob('*.png'):
        if not (baseline/p.name).exists():shutil.copy2(p,baseline/p.name)
    stage=ROOT/'build'/('asset-stage-'+str(time.time_ns()))
    (stage/'tools').mkdir(parents=True)
    (stage/'assets/props').mkdir(parents=True)
    (stage/'assets/terrain').mkdir()
    (stage/'assets/layers').mkdir()
    (stage/'assets/player_motion').mkdir()
    for p in (ROOT/'tools').glob('*.py'):shutil.copy2(p,stage/'tools'/p.name)
    (stage/'assets/sprites').mkdir()
    for p in (ROOT/'assets/sprites').glob('*.png'):shutil.copy2(p,stage/'assets/sprites'/p.name)
    for p in baseline.glob('*.png'):shutil.copy2(p,stage/'assets/props'/p.name)
    shutil.copy2(ROOT/'assets/world_routes.json',stage/'assets/world_routes.json')
    shutil.copy2(ROOT/'assets/action_spec.json',stage/'assets/action_spec.json')
    env=dict(os.environ,PYTHONDONTWRITEBYTECODE='1',RTL_ASSET_STAGING='1')
    for script in ['generate_world_polish.py','generate_weapon_layers.py','generate_player_motion.py']:
        subprocess.run([sys.executable,'-X','utf8',str(stage/'tools'/script)],check=True,env=env)
    outputs=[]
    for folder in ['props','terrain','layers','player_motion']:
        for p in (stage/'assets'/folder).iterdir():
            if p.suffix=='.png':
                with Image.open(p) as im:im.verify()
            if p.suffix in ['.png','.json']:outputs.append(p)
    receipt={};published=[];backup=stage/'previous'
    # Publish with rollback on a failed replacement; retain backup as receipt.
    try:
        for p in outputs:
            rel=p.relative_to(stage);dest=ROOT/rel;old=backup/rel
            old.parent.mkdir(parents=True,exist_ok=True)
            if dest.exists():shutil.copy2(dest,old)
            temp=dest.with_name(dest.name+'.publish.tmp')
            shutil.copy2(p,temp);os.replace(temp,dest);published.append((dest,old))
            receipt[str(rel)]=hashlib.sha256(dest.read_bytes()).hexdigest()
    except Exception:
        for dest,old in reversed(published):
            if old.exists():shutil.copy2(old,dest)
        raise
    (stage/'receipt.json').write_text(json.dumps(receipt,indent=2))
    print('Published validated assets; receipt:',stage/'receipt.json')
if __name__=='__main__':main()
