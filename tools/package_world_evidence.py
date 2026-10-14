from pathlib import Path
import os, shutil, subprocess
ROOT=Path(__file__).resolve().parents[1]
def main():
    captures=Path(os.environ['APPDATA'])/'Godot/app_userdata/Rừng Tàn Lửa/captures'
    dest=ROOT/'docs/screenshots/world-polish';dest.mkdir(parents=True,exist_ok=True)
    for source in (captures/'world-polish').glob('*.png'):shutil.copy2(source,dest/source.name)
    for source in (captures/'detail-polish/sheets').glob('*.png'):shutil.copy2(source,dest/(source.stem+'-sheet.png'))
    for source in (captures/'detail-polish').glob('hud-*.png'):shutil.copy2(source,dest/source.name)
    subprocess.run([shutil.which('ffmpeg'),'-v','error','-y','-framerate','60','-i',str(captures/'action-sync/frames/frame-%04d.png'),'-frames:v','192','-c:v','libx264','-pix_fmt','yuv420p',str(dest/'cloak-spear-eight-directions.mp4')],check=True)
    print('WorldPolish visual evidence frozen:',dest)
if __name__=='__main__':main()
