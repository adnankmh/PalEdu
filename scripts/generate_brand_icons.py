#!/usr/bin/env python3
"""Build offline Android/Web/iOS branding from PalEdu's approved vector symbol."""
import json
from io import BytesIO
from pathlib import Path
import xml.etree.ElementTree as ET

import cairosvg
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ART = ROOT / "assets/brand/paledu_symbol.svg"
BACKGROUND = (5, 54, 40, 255)

def symbol(size):
    return Image.open(BytesIO(cairosvg.svg2png(url=str(ART),
        output_width=size, output_height=size))).convert("RGBA")

def icon(size, maskable=False):
    canvas = Image.new("RGBA", (size,size), BACKGROUND)
    mark = symbol(round(size * (.80 if not maskable else .66)))
    canvas.alpha_composite(mark, ((size-mark.width)//2,(size-mark.height)//2))
    return canvas.convert("RGB")

def write(image, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, "PNG", optimize=True)

def main():
    tree = ET.parse(ART).getroot()
    assert tree.attrib.get("viewBox") == "0 0 400 400"
    assert len(list(tree)) >= 6, "Incomplete approved logo vector"
    write(symbol(1024), ROOT/"assets/brand/paledu_symbol_1024.png")

    android = ROOT/"android/app/src/main/res"
    if android.is_dir():
        for density,size in {
            "mipmap-mdpi":48,"mipmap-hdpi":72,"mipmap-xhdpi":96,
            "mipmap-xxhdpi":144,"mipmap-xxxhdpi":192
        }.items():
            write(icon(size), android/density/"ic_launcher.png")
        # Native Android launch background references generated drawable.
        for d in ("drawable", "drawable-v21"):
            folder=android/d
            if not folder.is_dir():
                continue
            write(symbol(256),folder/"paledu_splash.png")
            (folder/"launch_background.xml").write_text(
                '<?xml version="1.0" encoding="utf-8"?>\n'
                '<layer-list xmlns:android="http://schemas.android.com/apk/res/android">\n'
                '  <item android:drawable="#053628"/>\n'
                '  <item><bitmap android:gravity="center" '
                'android:src="@drawable/paledu_splash"/></item>\n'
                '</layer-list>\n', encoding="utf-8")

    web=ROOT/"web"
    if web.is_dir():
        for name,px,mask in [
            ("Icon-192.png",192,False),("Icon-512.png",512,False),
            ("Icon-maskable-192.png",192,True),
            ("Icon-maskable-512.png",512,True)
        ]:
            write(icon(px,mask),web/"icons"/name)
        write(icon(48),web/"favicon.png")
        manifest=web/"manifest.json"
        if manifest.exists():
            config=json.loads(manifest.read_text(encoding="utf-8"))
            config.update({
                "name":"PalEdu | تعلّم فلسطين","short_name":"PalEdu",
                "background_color":"#053628","theme_color":"#053628"
            })
            manifest.write_text(json.dumps(config,ensure_ascii=False,indent=2),
                encoding="utf-8")

    # If an iOS scaffold exists, update its previously declared icon sizes.
    ios=ROOT/"ios/Runner/Assets.xcassets/AppIcon.appiconset"
    if (ios/"Contents.json").exists():
        manifest=json.loads((ios/"Contents.json").read_text(encoding="utf-8"))
        for item in manifest.get("images",[]):
            filename=item.get("filename")
            if not filename:continue
            points=float(item.get("size","20x20").split("x")[0])
            scale=float(item.get("scale","1x").rstrip("x"))
            write(icon(round(points*scale)),ios/filename)
    print("PalEdu brand generated: Android, Web, optional iOS, splash.")

if __name__=="__main__":
    main()
