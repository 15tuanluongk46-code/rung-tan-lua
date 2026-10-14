"""Read published hashes before/after a staged rebuild; no user data touched."""
from pathlib import Path
import hashlib,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
def hashes():
    return {str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for folder in ['props','terrain','layers','player_motion'] for p in (ROOT/'assets'/folder).iterdir() if p.suffix in ['.png','.json']}
before=hashes()
subprocess.run([sys.executable,'-X','utf8',str(ROOT/'tools/regenerate_assets.py')],check=True)
after=hashes()
assert before==after, 'Asset regeneration is not byte-repeatable: '+str([k for k in after if before.get(k)!=after[k]])
print('ASSET REPEATABILITY:',len(after),'files byte-identical')
