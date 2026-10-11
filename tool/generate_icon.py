"""Genera icona e splash in assets/icon e assets/splash (richiede Pillow: pip install pillow).
Uso, dalla cartella del progetto: python3 tool/generate_icon.py "$PWD"
"""
import sys
from PIL import Image, ImageDraw, ImageFont

root = sys.argv[1]
font_path = f"{root}/assets/fonts/Manrope-ExtraBold.ttf"
DARK = (0x16, 0x18, 0x1D, 255)
LIGHT = (0xF7, 0xF7, 0xF5, 255)
EXPENSE = (0xC2, 0x41, 0x0C, 255)
INCOME = (0x1D, 0x4E, 0xD8, 255)

def _mark(size, scale, bg=None, radius=0):
    """Simbolo: € chiaro con due pillole (spesa, entrata). scale = frazione del lato occupata."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0) if bg is None else bg)
    d = ImageDraw.Draw(img)
    if bg is None and radius:
        d.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=DARK)
    box = size * scale
    font = ImageFont.truetype(font_path, int(box * 0.78))
    text = "€"
    l, t, r, b = d.textbbox((0, 0), text, font=font)
    tw, th = r - l, b - t
    pill_h = box * 0.075
    gap = box * 0.07
    total_h = th + gap + pill_h
    x = (size - tw) / 2 - l
    y = (size - total_h) / 2 - t
    d.text((x, y), text, font=font, fill=LIGHT)
    pill_w = box * 0.30
    py = (size - total_h) / 2 + th + gap
    space = box * 0.05
    px = size / 2 - pill_w - space / 2
    d.rounded_rectangle((px, py, px + pill_w, py + pill_h), radius=pill_h / 2, fill=EXPENSE)
    px2 = size / 2 + space / 2
    d.rounded_rectangle((px2, py, px2 + pill_w, py + pill_h), radius=pill_h / 2, fill=INCOME)
    return img

def mark(size, scale, bg=None, radius=0):
    """Disegna a 4× e riduce: bordi morbidi (Pillow non fa antialiasing sulle forme)."""
    big = _mark(size * 4, scale, bg=bg, radius=radius * 4)
    return big.resize((size, size), Image.LANCZOS)

# Icona principale (iOS e Android legacy): quadrato pieno, senza trasparenza.
mark(1024, 0.62, bg=DARK).convert("RGB").save(f"{root}/assets/icon/icon.png")
# Android adattiva: primo piano trasparente; flutter_launcher_icons aggiunge un margine del 16%,
# così il simbolo resta nella zona sicura (66%). Lo sfondo è un colore.
mark(1024, 0.62).save(f"{root}/assets/icon/icon_foreground.png")
# Splash: riquadro arrotondato scuro (si vede su sfondo chiaro e scuro).
mark(768, 0.62, radius=170).save(f"{root}/assets/splash/splash.png")
# Android 12: icona dentro un cerchio di 768 su 1152; il sistema ritaglia il cerchio.
a12 = Image.new("RGBA", (1152, 1152), (0, 0, 0, 0))
a12.paste(mark(768, 0.62, bg=DARK), (192, 192))
a12.save(f"{root}/assets/splash/splash_android12.png")
print("ok")
