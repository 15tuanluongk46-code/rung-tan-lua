"""Versioned Windows + source packages; keep previous deliveries untouched."""
from pathlib import Path
import os, hashlib, shutil, zipfile
ROOT=Path(__file__).resolve().parents[1]
STAMP='SmoothMotion-20261014'
def main():
    out=ROOT/'build'; win=out/'windows'
    exe=win/'RungTanLua.exe'
    if not exe.is_file(): raise RuntimeError('Export Windows first')
    for source in [ROOT/'LICENSE',ROOT/'assets/CREDITS.md',ROOT/'assets/fonts/LICENSE-DejaVu.txt']:
        shutil.copy2(source,win/source.name)
    (win/'README.txt').write_text('Rừng Tàn Lửa — Chương II\nChạy RungTanLua.exe, không cần Godot hay mạng.\nWASD đi; chuột ngắm; chuột trái giáo; phải đá; Space né; E tương tác; Q thuốc; M bản đồ; Esc nhật ký.\nAutosave nhiệm vụ/vật phẩm/điểm nghỉ. Tiếp tục tại checkpoint.\nSave: %APPDATA%/Godot/app_userdata/Rừng Tàn Lửa/journey.json\nGodot: https://godotengine.org/license/\n',encoding='utf-8')
    captures=Path(os.environ['APPDATA'])/'Godot/app_userdata/Rừng Tàn Lửa/captures'
    dest=ROOT/'docs/screenshots'/STAMP/'expansion'
    dest.mkdir(parents=True,exist_ok=True)
    for p in (captures/'expansion').glob('*.png'): shutil.copy2(p,dest/p.name)
    for name in ['marsh.png','ash.png','chapter-two-ending.png']:
        if (captures/name).exists(): shutil.copy2(captures/name,dest/name)
    quality=ROOT/'docs/screenshots'/STAMP/'quality'
    quality.mkdir(parents=True,exist_ok=True)
    for p in (captures/'quality').glob('*.png'): shutil.copy2(p,quality/p.name)
    depth=ROOT/'docs/screenshots'/STAMP/'depth'
    depth.mkdir(parents=True,exist_ok=True)
    for p in (captures/'depth').glob('*.png'): shutil.copy2(p,depth/p.name)
    weapons=ROOT/'docs/screenshots'/STAMP/'weapons'
    weapons.mkdir(parents=True,exist_ok=True)
    for p in (captures/'weapons').glob('*.png'): shutil.copy2(p,weapons/p.name)
    binary_zip=out/f'RungTanLua-Windows-{STAMP}.zip'
    source_zip=out/f'RungTanLua-Source-{STAMP}.zip'
    with zipfile.ZipFile(binary_zip,'w',zipfile.ZIP_DEFLATED) as z:
        for p in sorted(win.rglob('*')):
            if p.is_file(): z.write(p,Path('RungTanLua-Windows')/p.relative_to(win))
    with zipfile.ZipFile(source_zip,'w',zipfile.ZIP_DEFLATED) as z:
        for p in sorted(ROOT.rglob('*')):
            rel=p.relative_to(ROOT)
            if any(part in {'build','.godot','.git','.venv','__pycache__'} for part in rel.parts): continue
            if p.is_file() and not p.name.startswith('.env') and p.suffix!='.log': z.write(p,Path('rung-tan-lua')/rel)
    rows=[]
    for p in [exe,binary_zip,source_zip]:
        digest=hashlib.sha256(p.read_bytes()).hexdigest()
        rows.append(f'{digest}  {p.relative_to(out)}')
        print(p,p.stat().st_size,digest)
    (out/f'SHA256SUMS-{STAMP}.txt').write_text('\n'.join(rows)+'\n',encoding='utf-8')
if __name__=='__main__': main()
