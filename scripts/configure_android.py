#!/usr/bin/env python3
"""Configure app label and network permission on GitHub runner only."""
from pathlib import Path

manifest = Path("android/app/src/main/AndroidManifest.xml")
text = manifest.read_text(encoding="utf-8")
if 'android:label="paledu"' in text:
    text = text.replace('android:label="paledu"',
                        'android:label="تعلّم فلسطين"')
if 'android.permission.INTERNET' not in text:
    text = text.replace('<application', '<uses-permission android:name="android.permission.INTERNET"/>\n    <application', 1)
manifest.write_text(text, encoding="utf-8")
print("Configured Android application identity.")
