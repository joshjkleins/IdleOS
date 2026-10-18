import subprocess, os
FPS = 30
# (source, start, duration_in_source, speed, effect, extra). No push-ins: footage is static (v2's zoompan caused the shake).
segs = [
 ("breach.avi", 48.9, 2.7, 1.0, "plain", None),        # cold open: final hits + BREACHED
 ("swarm.avi", 5.0, 3.4, 1.0, "plain", None),          # VM swarm + uploads + ledger
 ("c_cmd.png", 0, 2.1, 1, "card", None),               # ~1.8 s on screen
 ("typing.avi", 4.3, 3.6, 1.0, "punch", 6.07 - 4.3),   # punch-in on the prompt, zoom out on enter
 ("mining.avi", 4.0, 3.0, 1.0, "plain", None),         # 3 VMs + ledger
 ("c_hack.png", 0, 2.1, 1, "card", None),
 ("breach.avi", 24.0, 10.0, 3.0, "plain", None),       # fight, sped up
 ("c_upgrade.png", 0, 2.0, 1, "card", None),
 ("install.avi", 4.6, 4.0, 1.15, "crop", None),        # single install, static 1.5x crop of the top-left
 ("c_stats.png", 0, 2.5, 1, "card", None),
 ("c_end.png", 0, 4.6, 1, "card", None),
]
trans = [("hlslice", 0.2), ("smoothleft", 0.3), ("pixelize", 0.35), ("hrslice", 0.2), ("smoothup", 0.3),
         ("pixelize", 0.35), ("smoothleft", 0.3), ("pixelize", 0.35), ("vuslice", 0.25), ("dissolve", 0.45)]
os.makedirs("seg3", exist_ok=True)
lens = []
for i, (src, ss, dur, sp, eff, extra) in enumerate(segs):
    od = dur / sp; n = int(round(od * FPS)); lens.append(n / FPS)
    out = f"seg3/s{i:02d}.mp4"
    if eff == "card":
        vf = f"fps={FPS},scale=1920:1080,format=yuv420p"
        inp = ["-loop", "1", "-t", f"{od:.3f}", "-i", src]
    else:
        if eff == "punch":
            fe = int(round(extra * FPS))
            z = f"if(lt(on,{fe}),3.5,1+2.5*pow(max(0,1-(on-{fe})/14),2))"
            post = f"scale=3840:2160:flags=lanczos,zoompan=z='{z}':x='0':y='ih-ih/zoom':d=1:s=1920x1080:fps={FPS}"
        elif eff == "crop":
            post = "crop=1280:720:0:0,scale=1920:1080:flags=lanczos"
        else:
            post = "scale=1920:1080"
        vf = f"setpts=(PTS-STARTPTS)/{sp},fps={FPS},{post},format=yuv420p"
        inp = ["-ss", str(ss), "-t", f"{dur:.3f}", "-i", src]
    subprocess.run(["ffmpeg", "-v", "error", "-y", *inp, "-vf", vf, "-frames:v", str(n), "-an", "-c:v", "libx264", "-preset", "medium", "-crf", "17", out], check=True)
inputs = []; fc = []; prev = "[0:v]"; t = lens[0]
for i in range(len(segs)):
    inputs += ["-i", f"seg3/s{i:02d}.mp4"]
for i, (name, d) in enumerate(trans):
    off = t - d
    fc.append(f"{prev}[{i+1}:v]xfade=transition={name}:duration={d}:offset={off:.3f}[x{i}]")
    prev = f"[x{i}]"; t = off + lens[i + 1]
subprocess.run(["ffmpeg", "-v", "error", "-y", *inputs, "-filter_complex", ";".join(fc), "-map", prev, "-c:v", "libx264", "-preset", "medium", "-crf", "17", "-pix_fmt", "yuv420p", "video3.mp4"], check=True)
total = t
music = os.environ.get("MUSIC") or os.path.expanduser("~/full/audio/music/background_music_1.mp3")
subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", "video3.mp4", "-i", music, "-filter_complex",
  f"[1:a]atrim=0:{total:.3f},asetpts=PTS-STARTPTS,afade=t=in:st=0:d=0.3,afade=t=out:st={total-2.5:.3f}:d=2.5,volume=0.8[a]",
  "-map", "0:v", "-map", "[a]", "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", "-shortest", "IdleOS_trailer_v3.mp4"], check=True)
print("total %.2fs" % total)
