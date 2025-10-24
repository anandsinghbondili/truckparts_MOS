#!/usr/bin/env python3
"""
Fix Android launcher icons to follow adaptive icon guidelines
- Foreground should only use 66% of the canvas (safe zone)
- Proper padding to prevent clipping
- Multiple densities: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi
"""

from PIL import Image, ImageDraw
import os

# Adaptive icon sizes for different densities
SIZES = {
    'mdpi': 108,      # 1x
    'hdpi': 162,      # 1.5x
    'xhdpi': 216,     # 2x
    'xxhdpi': 324,    # 3x
    'xxxhdpi': 432,   # 4x
}

# Safe zone for adaptive icons (66% of total size)
SAFE_ZONE_RATIO = 0.50  # Use 50% to be extra safe with padding

# Paths
ICON_SOURCE = "assets/icons/TP_Icon.png"
ANDROID_RES = "android/app/src/main/res"

def create_adaptive_icon_foreground(density_name, size):
    """Create foreground drawable for adaptive icon with proper safe zone"""
    
    print(f"Creating {density_name} foreground ({size}x{size}px)...")
    
    # Create transparent canvas
    canvas = Image.new('RGBA', (size, size), (255, 255, 255, 0))
    
    # Load source icon
    icon = Image.open(ICON_SOURCE)
    
    # Calculate size for icon (safe zone)
    icon_size = int(size * SAFE_ZONE_RATIO)
    
    # Resize icon maintaining aspect ratio
    icon.thumbnail((icon_size, icon_size), Image.Resampling.LANCZOS)
    
    # Calculate position to center the icon
    x = (size - icon.width) // 2
    y = (size - icon.height) // 2
    
    # Paste icon onto canvas
    if icon.mode == 'RGBA':
        canvas.paste(icon, (x, y), icon)
    else:
        canvas.paste(icon, (x, y))
    
    # Save foreground drawable
    drawable_dir = f"{ANDROID_RES}/drawable-{density_name}"
    os.makedirs(drawable_dir, exist_ok=True)
    output_path = f"{drawable_dir}/ic_launcher_foreground.png"
    canvas.save(output_path, 'PNG')
    print(f"  ✅ Saved: {output_path}")
    
    return canvas

def create_legacy_launcher_icon(density_name, size):
    """Create legacy launcher icon (for pre-API 26 devices)"""
    
    print(f"Creating {density_name} launcher icon ({size}x{size}px)...")
    
    # For legacy icons, use standard sizes (not 108dp)
    legacy_sizes = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
    }
    
    legacy_size = legacy_sizes[density_name]
    
    # Create white background
    canvas = Image.new('RGBA', (legacy_size, legacy_size), (255, 255, 255, 255))
    
    # Load source icon
    icon = Image.open(ICON_SOURCE)
    
    # Calculate size for icon (80% of canvas)
    icon_size = int(legacy_size * 0.80)
    
    # Resize icon maintaining aspect ratio
    icon.thumbnail((icon_size, icon_size), Image.Resampling.LANCZOS)
    
    # Calculate position to center the icon
    x = (legacy_size - icon.width) // 2
    y = (legacy_size - icon.height) // 2
    
    # Paste icon onto canvas
    if icon.mode == 'RGBA':
        canvas.paste(icon, (x, y), icon)
    else:
        canvas.paste(icon, (x, y))
    
    # Save launcher icon
    mipmap_dir = f"{ANDROID_RES}/mipmap-{density_name}"
    os.makedirs(mipmap_dir, exist_ok=True)
    output_path = f"{mipmap_dir}/ic_launcher.png"
    canvas.save(output_path, 'PNG')
    print(f"  ✅ Saved: {output_path}")

def main():
    print("=" * 60)
    print("🔧 Fixing Android Launcher Icons")
    print("=" * 60)
    print()
    
    if not os.path.exists(ICON_SOURCE):
        print(f"❌ Error: Source icon not found: {ICON_SOURCE}")
        return
    
    print(f"📱 Source icon: {ICON_SOURCE}")
    print()
    
    # Create adaptive icon foregrounds
    print("📦 Creating Adaptive Icon Foregrounds (API 26+)...")
    print("-" * 60)
    for density_name, size in SIZES.items():
        create_adaptive_icon_foreground(density_name, size)
    print()
    
    # Create legacy launcher icons
    print("📦 Creating Legacy Launcher Icons (API < 26)...")
    print("-" * 60)
    for density_name in SIZES.keys():
        create_legacy_launcher_icon(density_name, SIZES[density_name])
    print()
    
    print("=" * 60)
    print("✅ All launcher icons generated successfully!")
    print("=" * 60)
    print()
    print("📌 Next steps:")
    print("   1. Clean and rebuild your app")
    print("   2. Uninstall old app from device")
    print("   3. Install fresh build")
    print("   4. Check launcher icon on device")

if __name__ == "__main__":
    main()

