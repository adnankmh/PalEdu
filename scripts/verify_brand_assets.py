#!/usr/bin/env python3
"""Check that native icon and splash generation did not silently regress."""
from pathlib import Path
from PIL import Image

root=Path(__file__).resolve().parent.parent
for folder,size in [
  ("mipmap-mdpi",48),("mipmap-hdpi",72),("mipmap-xhdpi",96),
  ("mipmap-xxhdpi",144),("mipmap-xxxhdpi",192)
]:
  p=root/"android/app/src/main/res"/folder/"ic_launcher.png"
  with Image.open(p) as im:
    assert im.size==(size,size), f"Incorrect icon dimensions: {p}"
    assert im.getpixel((0,0))[1] > 30, "Missing emerald app background"
for filename,size in [("Icon-192.png",192),("Icon-512.png",512)]:
  p=root/"web/icons"/filename
  with Image.open(p) as im:
    assert im.size==(size,size)
assert (root/"android/app/src/main/res/drawable/launch_background.xml").exists()
print("PalEdu launcher icons, native splash, PWA artwork: verified")

xml=(root/"android/app/src/main/res/drawable/launch_background.xml").read_text(encoding="utf-8")
assert 'android:drawable="#' not in xml, "Invalid literal color in drawable reference"
assert 'android:color="#053628"' in xml
