import subprocess, os
FPS = 30
B = 60 / 83.354            # one beat of trailer_music.mp3
MUSIC_START = 2.95         # first beat in the track
# cut points in beats: every cut/transition is centered on a beat
cuts = [0, 4, 8, 11, 16, 20, 24, 28, 32, 35, 40, 44, 50]
# (source, start_in_source, speed, effect, extra) one per span between cuts
segs = [
 ("breach.avi", 48.7, 1.0, "plain", None),       # cold open: final hits + BREACHED
 ("swarm.avi", 5.0, 1.0, "plain", None),         # VM swarm + uploads + ledger
 ("c_cmd.png", 0, 1, "card", None),
 ("typing4k.avi", 4.4, 1.0, "punch", 6.07),      # 4K source: crisp punch-in, zoom out on enter
 ("mining.avi", 4.0, 1.0, "plain", None),
 ("c_hack.png", 0, 1, "card", None),
 ("breach.avi", 23.5, 3.0, "plain", None),       # fight, sped up
 ("c_stats.png", 0, 1, "card", None),
 ("c_upgrade.png", 0, 1, "card", None),
 ("install.avi", 4.6, 1.15, "crop", None),       # single install, static 1.5x crop
 ("cook.avi", 5.0, 1.0, "plain", None),          # everything cooking -> slow fade
 ("c_end.png", 0, 1, "card", None),
]
trans = [("hlslice", 0.2), ("smoothleft", 0.3), ("pixelize", 0.35), ("hrslice", 0.2), ("smoothup", 0.3),
         ("pixelize", 0.35), ("vuslice", 0.25), ("smoothleft", 0.3), ("pixelize", 0.35), ("hlslice", 0.2), ("fadeblack", 1.4)]
assert len(segs) == len(cuts) - 1 == len(trans) + 1
os.makedirs("seg4", exist_ok=True)
lens = []
for i, (src, ss, sp, eff, extra) in enumerate(segs):
    d_in = trans[i - 1][1] if i > 0 else 0.0
    d_out = trans[i][1] if i < len(trans) else 0.0
    od = (cuts[i + 1] - cuts[i]) * B + d_in / 2 + d_out / 2
    n = int(round(od * FPS)); lens.append(n / FPS)
    out = f"seg4/s{i:02d}.mp4"
    if eff == "card":
        vf = f"fps={FPS},scale=1920:1080,format=yuv420p"
        inp = ["-loop", "1", "-t", f"{od:.3f}", "-i", src]
    else:
        if eff == "punch":
            fe = int(round((extra - ss) * FPS))
            z = f"if(lt(on,{fe}),2.5,1+1.5*pow(max(0,1-(on-{fe})/14),2))"
            post = f"zoompan=z='{z}':x='0':y='ih-ih/zoom':d=1:s=3840x2160:fps={FPS},scale=1920:1080:flags=lanczos"
        elif eff == "crop":
            post = "crop=1280:720:0:0,scale=1920:1080:flags=lanczos"
        else:
            post = "scale=1920:1080:flags=lanczos"
        vf = f"setpts=(PTS-STARTPTS)/{sp},fps={FPS},{post},format=yuv420p"
        inp = ["-ss", str(ss), "-t", f"{od * sp + 0.2:.3f}", "-i", src]
    subprocess.run(["ffmpeg", "-v", "error", "-y", *inp, "-vf", vf, "-frames:v", str(n), "-an", "-c:v", "libx264", "-preset", "medium", "-crf", "17", out], check=True)
inputs = []; fc = []; prev = "[0:v]"; t = lens[0]
for i in range(len(segs)):
    inputs += ["-i", f"seg4/s{i:02d}.mp4"]
for i, (name, d) in enumerate(trans):
    off = t - d
    fc.append(f"{prev}[{i+1}:v]xfade=transition={name}:duration={d}:offset={off:.3f}[x{i}]")
    prev = f"[x{i}]"; t = off + lens[i + 1]
subprocess.run(["ffmpeg", "-v", "error", "-y", *inputs, "-filter_complex", ";".join(fc), "-map", prev, "-c:v", "libx264", "-preset", "medium", "-crf", "17", "-pix_fmt", "yuv420p", "video4.mp4"], check=True)
total = t
subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", "video4.mp4", "-ss", str(MUSIC_START), "-i", "trailer_music.mp3", "-filter_complex",
  f"[1:a]atrim=0:{total:.3f},asetpts=PTS-STARTPTS,afade=t=out:st={total-2.8:.3f}:d=2.8,volume=0.78[a]",
  "-map", "0:v", "-map", "[a]", "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", "-shortest", "IdleOS_trailer_v4.mp4"], check=True)
print("total %.2fs, cuts at %s" % (total, [round(c * B, 2) for c in cuts]))
