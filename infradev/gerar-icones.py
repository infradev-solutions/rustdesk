#!/usr/bin/env python3
"""Gera os ícones e logos do InfraDev Remote em infradev/assets/.

Uso (precisa do Pillow): python3 infradev/gerar-icones.py
As imagens de origem ficam em infradev/source/ (vindas do site da InfraDev).
Para trocar o ícone, substitua infradev/source/icone.png (de preferência 1024x1024) e rode de novo.
O apply-branding.sh copia infradev/assets/ por cima do código antes do build.
"""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
SRC = ROOT / "source"
OUT = ROOT / "assets"
BG = (6, 10, 20, 255)  # #060a14, fundo escuro do site
LANCZOS = Image.Resampling.LANCZOS

logo_icon = Image.open(SRC / "icone.png").convert("RGBA")


def fit(img, size, fill):
    """Centraliza img ocupando a fração `fill` de um quadrado transparente de lado `size`."""
    box = int(size * fill)
    w, h = img.size
    scale = box / max(w, h)
    r = img.resize((max(1, round(w * scale)), max(1, round(h * scale))), LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(r, ((size - r.width) // 2, (size - r.height) // 2))
    return canvas


def mask(size, shape):
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    if shape == "circle":
        d.ellipse((0, 0, size - 1, size - 1), fill=255)
    else:
        d.rounded_rectangle((0, 0, size - 1, size - 1), radius=int(size * 0.22), fill=255)
    return m


def app_icon(size, shape="rounded"):
    """Ícone com fundo escuro arredondado (ou redondo) e a marca no centro."""
    work = size * 4  # desenha grande e reduz, para bordas suaves
    bg = Image.new("RGBA", (work, work), (0, 0, 0, 0))
    bg.paste(Image.new("RGBA", (work, work), BG), (0, 0), mask(work, shape))
    bg.alpha_composite(fit(logo_icon, work, 0.80))
    return bg.resize((size, size), LANCZOS)


def save(img, rel):
    p = OUT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    img.save(p)
    print("ok", rel)


def save_ico(rel, sizes):
    p = OUT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    app_icon(256).save(p, sizes=[(s, s) for s in sizes])
    print("ok", rel)


# Linux / geral
save(app_icon(1024), "res/icon.png")
save(app_icon(1024), "res/mac-icon.png")
for s, name in [(32, "32x32.png"), (64, "64x64.png"), (128, "128x128.png"), (256, "128x128@2x.png")]:
    save(app_icon(s), f"res/{name}")

# Windows
save_ico("res/icon.ico", [16, 32, 48, 64, 128, 256])
save_ico("res/tray-icon.ico", [16, 32])
save_ico("flutter/windows/runner/resources/app_icon.ico", [16, 32, 48, 64, 128, 256])

# macOS
icns = OUT / "flutter/macos/Runner/AppIcon.icns"
icns.parent.mkdir(parents=True, exist_ok=True)
app_icon(1024).save(icns, sizes=[(16, 16), (32, 32), (64, 64), (128, 128), (256, 256), (512, 512), (1024, 1024)])
print("ok", icns.relative_to(OUT))

# Android
mip = "flutter/android/app/src/main/res"
for dpi, base in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)]:
    save(app_icon(base), f"{mip}/mipmap-{dpi}/ic_launcher.png")
    save(app_icon(base, "circle"), f"{mip}/mipmap-{dpi}/ic_launcher_round.png")
    fg = int(base * 2.25)  # 108dp; a área segura é o círculo central de 66dp
    save(fit(logo_icon, fg, 0.58), f"{mip}/mipmap-{dpi}/ic_launcher_foreground.png")
    stat = base // 2
    white = Image.new("LA", (stat, stat), (255, 0))
    white.putalpha(fit(logo_icon, stat, 0.95).getchannel("A"))
    save(white, f"{mip}/mipmap-{dpi}/ic_stat_logo.png")

# Dentro do app (ícone da barra de abas e logo da tela inicial, máx. 300x60)
save(fit(logo_icon, 256, 1.0), "flutter/assets/icon.png")
for src, dst in [("logo-claro.png", "logo_light.png"), ("logo-escuro.png", "logo_dark.png"), ("logo-claro.png", "logo.png")]:
    img = Image.open(SRC / src).convert("RGBA")
    img = img.crop(img.getbbox())
    img.thumbnail((600, 120), LANCZOS)
    save(img, f"flutter/assets/{dst}")
