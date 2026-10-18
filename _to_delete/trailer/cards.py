from PIL import Image, ImageDraw, ImageFont
import os
F = os.path.expanduser('~/full/fonts/ttf/')
W, H = 1920, 1080
BG = (10, 12, 15)
def font(name, size): return ImageFont.truetype(F + name, size)
def card(name, parts, size=72, sub=None, sub_color=(110,118,129)):
    im = Image.new('RGB', (W, H), BG); d = ImageDraw.Draw(im)
    f = font('JetBrainsMono-Bold.ttf', size)
    total = sum(d.textlength(t, font=f) for t, _ in parts)
    x = (W - total) / 2; y = H / 2 - size * 0.6
    for t, c in parts:
        d.text((x, y), t, font=f, fill=c); x += d.textlength(t, font=f)
    if sub:
        fs = font('JetBrainsMono-Regular.ttf', 30)
        d.text(((W - d.textlength(sub, font=fs)) / 2, y + size * 1.5), sub, font=fs, fill=sub_color)
    im.save(name)
G=(51,255,51); DIM=(110,118,129)
MINE=(0xF5,0x9E,0x0B); PARSE=(0xEC,0x48,0x99); CRACK=(0xF2,0x60,0x0C); MATCH=(0xEA,0xB3,0x08); RED=(0xee,0x4a,0x3a); GOLD=(0xe3,0xb3,0x41)
card('card_pipeline.png', [('> ', G), ('mine', MINE), (' · ', DIM), ('parse', PARSE), (' · ', DIM), ('crack', CRACK), (' · ', DIM), ('match', MATCH)], sub='every skill feeds the next')
card('card_hack.png', [('> ', G), ('then ', (220,224,228)), ('hack.', RED)], size=96, sub='auto-battle your way through real targets')
card('card_upgrade.png', [('> ', G), ('upgrade ', (220,224,228)), ('everything.', GOLD)], size=88, sub='v0.0 -> v6.0')
card('card_scope.png', [('6', G), (' locations   ', (220,224,228)), ('9', G), (' modules   ', (220,224,228)), ('1', G), (' terminal', (220,224,228))], size=64, sub='school -> lawfirm -> hospital -> bank -> police -> government')
# end card
im = Image.new('RGB', (W, H), BG); d = ImageDraw.Draw(im)
ft = font('JetBrainsMono-ExtraBold.ttf', 220)
t = 'IdleOS'; d.text(((W - d.textlength(t, font=ft)) / 2, 250), t, font=ft, fill=G)
fs = font('JetBrainsMono-Regular.ttf', 40)
t = 'an idle hacking operating system'; d.text(((W - d.textlength(t, font=fs)) / 2, 520), t, font=fs, fill=DIM)
fb = font('JetBrainsMono-Bold.ttf', 60)
t = 'Wishlist now on Steam'; d.text(((W - d.textlength(t, font=fb)) / 2, 680), t, font=fb, fill=(230,233,237))
fm = font('JetBrainsMono-Medium.ttf', 38)
t = 'Play the free demo in Steam Next Fest'; d.text(((W - d.textlength(t, font=fm)) / 2, 790), t, font=fm, fill=GOLD)
fs2 = font('JetBrainsMono-Regular.ttf', 32)
t = 'Coming November 6, 2026'; d.text(((W - d.textlength(t, font=fs2)) / 2, 870), t, font=fs2, fill=DIM)
im.save('card_end.png')
print('cards ok')
