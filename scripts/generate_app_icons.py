#!/usr/bin/env python3
"""
generate_app_icons.py
Gera o catálogo de ativos (Assets.xcassets) com todos os ícones necessários para o aplicativo OneWord (iOS 17/18+),
cobrindo iPhone, iPad e App Store, além do formato universal.
"""

import os
import json
from PIL import Image, ImageFilter

MASTER_ICON_PATH = "/Users/rogerioduraes/.gemini/antigravity/brain/750d76fa-c717-4590-96dd-a8098ec92802/oneword_app_icon_1024_master.png"
OUTPUT_DIR = "OneWord/Sources/OneWord/Resources/Assets.xcassets/AppIcon.appiconset"

ICON_SPECS = [
    # Universal / iOS 17+ Single-size format
    {
        "idiom": "universal",
        "platform": "ios",
        "size": "1024x1024",
        "pixels": 1024,
        "filename": "AppIcon-1024.png"
    },
    # App Store Marketing
    {
        "idiom": "ios-marketing",
        "scale": "1x",
        "size": "1024x1024",
        "pixels": 1024,
        "filename": "AppIcon-Marketing.png"
    },
    # iPhone Notification (20pt @2x, @3x)
    {
        "idiom": "iphone",
        "scale": "2x",
        "size": "20x20",
        "pixels": 40,
        "filename": "AppIcon-20@2x.png"
    },
    {
        "idiom": "iphone",
        "scale": "3x",
        "size": "20x20",
        "pixels": 60,
        "filename": "AppIcon-20@3x.png"
    },
    # iPhone Settings (29pt @2x, @3x)
    {
        "idiom": "iphone",
        "scale": "2x",
        "size": "29x29",
        "pixels": 58,
        "filename": "AppIcon-29@2x.png"
    },
    {
        "idiom": "iphone",
        "scale": "3x",
        "size": "29x29",
        "pixels": 87,
        "filename": "AppIcon-29@3x.png"
    },
    # iPhone Spotlight (40pt @2x, @3x)
    {
        "idiom": "iphone",
        "scale": "2x",
        "size": "40x40",
        "pixels": 80,
        "filename": "AppIcon-40@2x.png"
    },
    {
        "idiom": "iphone",
        "scale": "3x",
        "size": "40x40",
        "pixels": 120,
        "filename": "AppIcon-40@3x.png"
    },
    # iPhone App (60pt @2x, @3x)
    {
        "idiom": "iphone",
        "scale": "2x",
        "size": "60x60",
        "pixels": 120,
        "filename": "AppIcon-60@2x.png"
    },
    {
        "idiom": "iphone",
        "scale": "3x",
        "size": "60x60",
        "pixels": 180,
        "filename": "AppIcon-60@3x.png"
    },
    # iPad Notifications (20pt @1x, @2x)
    {
        "idiom": "ipad",
        "scale": "1x",
        "size": "20x20",
        "pixels": 20,
        "filename": "AppIcon-20.png"
    },
    {
        "idiom": "ipad",
        "scale": "2x",
        "size": "20x20",
        "pixels": 40,
        "filename": "AppIcon-20@2x-ipad.png"
    },
    # iPad Settings (29pt @1x, @2x)
    {
        "idiom": "ipad",
        "scale": "1x",
        "size": "29x29",
        "pixels": 29,
        "filename": "AppIcon-29.png"
    },
    {
        "idiom": "ipad",
        "scale": "2x",
        "size": "29x29",
        "pixels": 58,
        "filename": "AppIcon-29@2x-ipad.png"
    },
    # iPad Spotlight (40pt @1x, @2x)
    {
        "idiom": "ipad",
        "scale": "1x",
        "size": "40x40",
        "pixels": 40,
        "filename": "AppIcon-40.png"
    },
    {
        "idiom": "ipad",
        "scale": "2x",
        "size": "40x40",
        "pixels": 80,
        "filename": "AppIcon-40@2x-ipad.png"
    },
    # iPad App (76pt @1x, @2x)
    {
        "idiom": "ipad",
        "scale": "1x",
        "size": "76x76",
        "pixels": 76,
        "filename": "AppIcon-76.png"
    },
    {
        "idiom": "ipad",
        "scale": "2x",
        "size": "76x76",
        "pixels": 152,
        "filename": "AppIcon-76@2x.png"
    },
    # iPad Pro App (83.5pt @2x)
    {
        "idiom": "ipad",
        "scale": "2x",
        "size": "83.5x83.5",
        "pixels": 167,
        "filename": "AppIcon-83.5@2x.png"
    }
]

def main():
    print(f"Lendo imagem mestre: {MASTER_ICON_PATH}")
    master = Image.open(MASTER_ICON_PATH).convert("RGB")
    if master.size != (1024, 1024):
        print(f"Redimensionando mestre para 1024x1024 (tamanho atual: {master.size})")
        master = master.resize((1024, 1024), Image.Resampling.LANCZOS)

    # Diretório Assets.xcassets raiz
    assets_root = "OneWord/Sources/OneWord/Resources/Assets.xcassets"
    os.makedirs(assets_root, exist_ok=True)
    with open(os.path.join(assets_root, "Contents.json"), "w") as f:
        json.dump({"info": {"author": "xcode", "version": 1}}, f, indent=2)

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    contents_images = []
    generated_files = set()

    for spec in ICON_SPECS:
        px = spec["pixels"]
        fname = spec["filename"]
        out_path = os.path.join(OUTPUT_DIR, fname)

        if fname not in generated_files:
            resized = master.resize((px, px), Image.Resampling.LANCZOS)
            # Para ícones muito pequenos (<= 60px), aplicar leve filtro de nitidez para preservar os guias ópticos
            if px <= 60:
                resized = resized.filter(ImageFilter.UnsharpMask(radius=1.0, percent=130, threshold=3))
            resized.save(out_path, format="PNG", optimize=True)
            generated_files.add(fname)
            print(f"  ✓ Gerado: {fname} ({px}x{px} px)")

        # Entrada no Contents.json
        entry = {
            "filename": fname,
            "idiom": spec["idiom"],
            "size": spec["size"]
        }
        if "scale" in spec:
            entry["scale"] = spec["scale"]
        if "platform" in spec:
            entry["platform"] = spec["platform"]
        contents_images.append(entry)

    contents_json_path = os.path.join(OUTPUT_DIR, "Contents.json")
    with open(contents_json_path, "w") as f:
        json.dump({
            "images": contents_images,
            "info": {
                "author": "xcode",
                "version": 1
            }
        }, f, indent=2)

    print(f"✓ Catálogo de ícones gerado com sucesso em: {OUTPUT_DIR}")
    print(f"✓ Total de arquivos de ícone: {len(generated_files)}")

if __name__ == "__main__":
    main()
