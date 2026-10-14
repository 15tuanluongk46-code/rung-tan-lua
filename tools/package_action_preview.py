from pathlib import Path
import os,shutil,subprocess
ROOT=Path(__file__).resolve().parents[1]
def main():
    source=Path(os.environ['APPDATA'])/'Godot/app_userdata/Rừng Tàn Lửa/captures/action-sync'
    dest=ROOT/'docs/screenshots/action-sync'
    dest.mkdir(parents=True,exist_ok=True)
    for file in source.glob('*.png'): shutil.copy2(file,dest/file.name)
    subprocess.run([shutil.which('ffmpeg'),'-v','error','-y','-framerate','60','-i',str(source/'frames/frame-%04d.png'),'-frames:v','192','-c:v','libx264','-pix_fmt','yuv420p',str(dest/'spear-continuous-eight-directions.mp4')],check=True)
    shutil.copy2(source/'frames/frame-0004.png',dest/'contact-east.png')
    print('ACTION SYNC: sequential rendered animation clip and human hand palette captures saved',dest)
if __name__=='__main__': main()
