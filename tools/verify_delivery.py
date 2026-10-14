from pathlib import Path
import hashlib,zipfile
ROOT=Path(__file__).resolve().parents[1]
B=ROOT/'build';STAMP='SmoothMotion-20261014'
paths=[B/'windows/RungTanLua.exe',B/f'RungTanLua-Windows-{STAMP}.zip',B/f'RungTanLua-Source-{STAMP}.zip']
for p,line in zip(paths,(B/f'SHA256SUMS-{STAMP}.txt').read_text().splitlines()):
    assert hashlib.sha256(p.read_bytes()).hexdigest()==line.split()[0],p
for p in paths[1:]:
    with zipfile.ZipFile(p) as z:assert z.testzip() is None,p
with zipfile.ZipFile(paths[1]) as z:assert z.read('RungTanLua-Windows/RungTanLua.exe')==paths[0].read_bytes()
with zipfile.ZipFile(paths[2]) as z:
    for name in ['scripts/main.gd','assets/action_spec.json','docs/SMOOTH_MOTION_REPORT.md']:
        assert z.read('rung-tan-lua/'+name)==(ROOT/name).read_bytes()
print('FullAudit EXE, source, ZIP CRC and SHA256 verified')
