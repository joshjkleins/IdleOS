from PIL import Image, ImageDraw, ImageFont
import os
F = os.path.expanduser('~/full/fonts/ttf/')
W, H = 1920, 1080
BG = (10, 12, 15)
G=(51,255,51); DIM=(110,118,129); WHITE=(225,229,233); RED=(0xee,0x4a,0x3a); GOLD=(0xe3,0xb3,0x41)
def font(n, s): return ImageFont.truetype(F + n, s)
def centered(d, y, parts, f):
    total = sum(d.textlength(t, font=f) for t, _ in parts); x = (W - total) / 2
    for t, c in parts:
        d.text((x, y), t, font=f, fill=c); x += d.textlength(t, font=f)
def card(name, lines):
    im = Image.new('RGB', (W, H), BG); d = ImageDraw.Draw(im)
    hs = [l[2] for l in lines]; gap = 26
    y = (H - (sum(hs) * 1.25 + gap * (len(lines) - 1))) / 2
    for parts, fname, size in lines:
        centered(d, y, parts, font(fname, size)); y += size * 1.25 + gap
    im.save(name)
card('c_cmd.png', [([('> ', G), ('real terminal commands', WHITE)], 'JetBrainsMono-Bold.ttf', 84)])
card('c_hack.png', [([('hacking ', WHITE), ('auto-battler', RED)], 'JetBrainsMono-Bold.ttf', 92),
                    ([('build your own Mods to take down tough targets', DIM)], 'JetBrainsMono-Regular.ttf', 36)])
card('c_upgrade.png', [([('> ', G), ('upgrade ', WHITE), ('everything.', GOLD)], 'JetBrainsMono-Bold.ttf', 88),
                       ([('v0.0 -> v6.0', DIM)], 'JetBrainsMono-Regular.ttf', 34)])
card('c_stats.png', [([('30', G), (' unique hacking targets', WHITE)], 'JetBrainsMono-Bold.ttf', 66),
                     ([('42', G), (' processes', WHITE)], 'JetBrainsMono-Bold.ttf', 66),
                     ([('100+', G), (' upgrades', WHITE)], 'JetBrainsMono-Bold.ttf', 66),
                     ([('1', G), (' terminal', WHITE)], 'JetBrainsMono-Bold.ttf', 66)])
# end card
im = Image.new('RGB', (W, H), BG); d = ImageDraw.Draw(im)
centered(d, 230, [('Idle', WHITE), ('OS', G)], font('JetBrainsMono-ExtraBold.ttf', 230))
centered(d, 600, [('Wishlist on Steam', WHITE)], font('JetBrainsMono-Bold.ttf', 64))
centered(d, 710, [('Play the demo now', GOLD)], font('JetBrainsMono-Medium.ttf', 44))
centered(d, 790, [('Full release November 6th, 2026', DIM)], font('JetBrainsMono-Regular.ttf', 38))
im.save('c_end.png')
print('ok')
