from pathlib import Path
from PIL import Image,ImageDraw
import os,subprocess,shutil
ROOT=Path(__file__).resolve().parents[1]
def main():
    frames=Path(os.environ['APPDATA'])/'Godot/app_userdata/Rừng Tàn Lửa/captures/player-motion/frames'
    dest=ROOT/'docs/screenshots/front-spear';dest.mkdir(parents=True,exist_ok=True)
    subprocess.run([shutil.which('ffmpeg'),'-v','error','-y','-framerate','60','-i',str(frames/'frame-%04d.png'),'-c:v','libx264','-pix_fmt','yuv420p',str(dest/'player-motion-60fps.mp4')],check=True)
    # Compact crops in separate sheets rather than one enormous unreadable grid.
    for name,indices in [('horizontal',[0,5,6,7,8,10,12,15,18,20,22,26]),('cardinal',[o*28+i for o in [0,2,4,6] for i in [6,8,10,17,21,26]]),('diagonal',[o*28+i for o in [1,3,5,7] for i in [6,8,10,17,21,26]]),('throw',[336+i for i in [0,1,2,3,4,7,12,18,24,27]]),('dodge',[560+i for i in [0,2,4,6,9,12,16,20,24,27]]),('hurt',[672+i for i in [0,2,4,6,9,12,16,20,24,27]]),('dead',[784+i for i in [0,2,4,6,9,12,16,20,24,27]])]:
        columns=6 if name in ['cardinal','diagonal'] else 5
        w,h=480,480;result=Image.new('RGB',(columns*w,((len(indices)+columns-1)//columns)*(h+20)),'#102a30');d=ImageDraw.Draw(result)
        for n,index in enumerate(indices):
            with Image.open(frames/f'frame-{index:04d}.png') as im:tile=im.convert('RGB').crop((250,70,410,230)).resize((480,480),Image.Resampling.NEAREST)
            x,y=(n%columns)*w,(n//columns)*(h+20);result.paste(tile,(x,y+20));d.text((x+3,y+3),f'frame {index}',fill='white')
        result.save(dest/(name+'-render.png'))
    print('PlayerMotion: native full-speed clip + labeled phase crops frozen')
if __name__=='__main__':main()
