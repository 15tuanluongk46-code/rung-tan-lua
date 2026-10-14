from pathlib import Path
import os,shutil,subprocess,json,hashlib,zipfile
ROOT=Path(__file__).resolve().parents[1]
def main():
    captures=Path(os.environ['APPDATA'])/'Godot/app_userdata/Rừng Tàn Lửa/captures'
    dest=ROOT/'docs/screenshots/FullAudit-20261013';dest.mkdir(parents=True,exist_ok=True)
    for source in (captures/'full-audit').glob('*.png'):shutil.copy2(source,dest/source.name)
    subprocess.run([shutil.which('ffmpeg'),'-v','error','-y','-framerate','60','-i',str(captures/'player-motion/frames/frame-%04d.png'),'-frames:v','896','-c:v','libx264','-pix_fmt','yuv420p',str(dest/'player-atlas-60fps.mp4')],check=True)
    print('Audit captures frozen:',dest)
if __name__=='__main__':main()
