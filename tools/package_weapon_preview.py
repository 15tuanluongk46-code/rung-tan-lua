"""Compose actual Godot captures into a contact sheet and brief before/after clip."""
from pathlib import Path
import os, shutil, subprocess
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
CAP=Path(os.environ['APPDATA'])/'Godot/app_userdata/Rừng Tàn Lửa/captures/weapons'
DEST=ROOT/'docs/screenshots/weapons'
def main():
    DEST.mkdir(parents=True,exist_ok=True)
    for p in CAP.glob('*.png'): shutil.copy2(p,DEST/p.name)
    # Consistent crop around the actor from actual viewport screenshots.
    grid=Image.new('RGB',(8*192,3*190),'#102a30'); d=ImageDraw.Draw(grid)
    for direction in range(8):
        for row,phase in enumerate(['pull','extend','return']):
            im=Image.open(CAP/f'spear-{direction}-{phase}.png').convert('RGB')
            crop=im.crop((245,75,410,218)).resize((192,166),Image.Resampling.NEAREST)
            grid.paste(crop,(direction*192,row*190+22))
            d.text((direction*192+5,row*190+5),f'{direction} / {phase}',fill='#f6daa2')
    grid.save(DEST/'spear-eight-directions.png')
    ffmpeg=shutil.which('ffmpeg')
    if ffmpeg:
        frames=[]
        old=ROOT/'docs/screenshots/gameplay-input.png'
        if old.exists(): frames.extend([Image.open(old).convert('RGB').resize((640,360))]*20)
        for direction in range(8):
            for phase,count in [('pull',8),('extend',5),('return',8)]:
                frames.extend([Image.open(CAP/f'spear-{direction}-{phase}.png').convert('RGB')]*count)
        video=DEST/'weapon-motion-review.mp4'
        proc=subprocess.Popen([ffmpeg,'-v','error','-y','-f','rawvideo','-pixel_format','rgb24','-video_size','640x360','-framerate','25','-i','-','-an','-c:v','libx264','-pix_fmt','yuv420p',str(video)],stdin=subprocess.PIPE)
        for frame in frames: proc.stdin.write(frame.tobytes())
        proc.stdin.close()
        if proc.wait()!=0: raise RuntimeError('preview encode failed')
        print(video)
    print('Frame contact sheet uses actual captures; clip is sampled pose review, not uninterrupted gameplay.')
if __name__=='__main__': main()
