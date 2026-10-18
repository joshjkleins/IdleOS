import subprocess, os
segs = [  # (kind, source, start, duration_in_source, speed)
 ("clip", "intro.avi", 0.3, 3.5, 1.0),
 ("clip", "intro.avi", 7.0, 4.5, 1.5),
 ("card", "card_pipeline.png", 0, 1.6, 1),
 ("clip", "mining.avi", 3.5, 5.0, 1.0),
 ("clip", "cracking.avi", 2.5, 2.5, 1.0),
 ("clip", "matching.avi", 3.5, 2.5, 1.0),
 ("clip", "phishing.avi", 3.5, 2.5, 1.0),
 ("card", "card_hack.png", 0, 1.6, 1),
 ("clip", "hack.avi", 12.0, 15.0, 1.7),
 ("card", "card_upgrade.png", 0, 1.6, 1),
 ("clip", "apt.avi", 2.0, 5.0, 1.0),
 ("card", "card_scope.png", 0, 2.2, 1),
 ("card", "card_end.png", 0, 5.4, 1),
]
os.makedirs("seg", exist_ok=True)
lst = []
total = 0.0
for i, (k, src, ss, dur, sp) in enumerate(segs):
    out = f"seg/s{i:02d}.mp4"
    od = dur / sp
    total += od
    fo = max(0.0, od - 0.17)
    if k == "clip":
        vf = f"setpts=(PTS-STARTPTS)/{sp},fps=30,scale=1920:1080,format=yuv420p,fade=t=in:st=0:d=0.17,fade=t=out:st={fo:.3f}:d=0.17"
        cmd = ["ffmpeg","-v","error","-y","-ss",str(ss),"-t",str(dur),"-i",src,"-vf",vf,"-an","-c:v","libx264","-preset","medium","-crf","18","-t",f"{od:.3f}",out]
    else:
        vf = f"fps=30,format=yuv420p,fade=t=in:st=0:d=0.25,fade=t=out:st={od-0.3:.3f}:d=0.3"
        cmd = ["ffmpeg","-v","error","-y","-loop","1","-t",str(od),"-i",src,"-vf",vf,"-c:v","libx264","-preset","medium","-crf","18","-tune","stillimage",out]
    subprocess.run(cmd, check=True)
    lst.append(f"file '{out}'")
open("list.txt","w").write("\n".join(lst))
subprocess.run(["ffmpeg","-v","error","-y","-f","concat","-safe","0","-i","list.txt","-c","copy","video.mp4"], check=True)
music = os.path.expanduser("~/full/audio/music/background_music_1.mp3")
fade_st = total - 2.5
subprocess.run(["ffmpeg","-v","error","-y","-i","video.mp4","-i",music,"-filter_complex",
  f"[1:a]atrim=0:{total:.3f},asetpts=PTS-STARTPTS,afade=t=in:st=0:d=0.6,afade=t=out:st={fade_st:.3f}:d=2.5,volume=0.8[a]",
  "-map","0:v","-map","[a]","-c:v","copy","-c:a","aac","-b:a","192k","-movflags","+faststart","-shortest","IdleOS_trailer_v1.mp4"], check=True)
print("total %.2fs" % total)
