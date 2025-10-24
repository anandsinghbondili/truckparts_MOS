#!/usr/bin/env python3
"""
Script to download truck parts images for the Truck Parts app.
This script provides multiple methods to get parts images.
"""

import os
import requests
import time
from urllib.parse import quote
import json

# List of parts that need images
PARTS_LIST = [
    "GASKETS", "CONNECTING BUSH", "COVER ASSY", "CONNECTING BEARING", "DRAG LINK",
    "VALVE", "DIFFERENTIAL", "BRAKE LINING", "CYLINDER LINER", "MAIN BEARING",
    "THRUST WASHER", "BALL SUSPENSION", "OILSEALS", "BRAKE SHOE", "CAM BUSH",
    "UJCROSS", "WHEEL BEARINGS", "FILTERS", "MAIN BUSH", "DISCPAD", "KITSET",
    "GEARBOX", "ENGINE", "PISTON RING SET", "TAPPET COVER", "PISTON SET",
    "RING SET", "UJ KIT", "CLUTCH", "DRIVE LINE", "GEAR PARTS", "FRONT AXLE",
    "MAIN BEARING KIT", "CLUTCH PLATE", "SUSPENSION", "BRAKE", "VR BUSH",
    "COOLING SYSTEM", "CLUTCH RELEASE BEARING", "SLIP YOKE", "ELECTRICALS",
    "TIE ROD", "IG BUSH", "MAIN & CR BRG", "BODYPARTS", "COOLANT", "FLYWHEEL",
    "TIE ROD REPAIR KIT", "CONNECTING BEARING KIT", "HUB", "SENSORS", "CABLES",
    "OIL SUMP", "HYDRAULIC JACK", "BALL SUSPENSION JOINT", "CENTER BEARING RUBBER",
    "FUEL INJECTION"
]

def create_directory_structure():
    """Create the parts images directory structure"""
    base_dir = "assets/images/parts"
    os.makedirs(base_dir, exist_ok=True)
    print(f"✅ Created directory: {base_dir}")

def sanitize_filename(part_name):
    """Convert part name to a valid filename"""
    # Replace spaces and special characters with underscores
    filename = part_name.replace(" ", "_").replace("&", "AND").replace("/", "_")
    # Remove any other special characters
    filename = "".join(c for c in filename if c.isalnum() or c in "_-")
    return filename.upper()

def download_from_unsplash(part_name, filename):
    """Download a generic truck/automotive image from Unsplash"""
    try:
        # Search for truck parts or automotive images
        search_terms = [
            f"truck {part_name.lower()}",
            f"automotive {part_name.lower()}",
            "truck parts",
            "automotive parts"
        ]
        
        for term in search_terms:
            url = f"https://source.unsplash.com/400x300/?{quote(term)}"
            response = requests.get(url, timeout=10)
            
            if response.status_code == 200:
                filepath = f"assets/images/parts/{filename}.jpg"
                with open(filepath, 'wb') as f:
                    f.write(response.content)
                print(f"✅ Downloaded: {part_name} -> {filepath}")
                return True
    except Exception as e:
        print(f"❌ Failed to download {part_name} from Unsplash: {e}")
    
    return False

def create_placeholder_image(part_name, filename):
    """Create a placeholder image with text"""
    try:
        from PIL import Image, ImageDraw, ImageFont
        
        # Create a 400x300 image with a light gray background
        img = Image.new('RGB', (400, 300), color='#f0f0f0')
        draw = ImageDraw.Draw(img)
        
        # Try to use a default font, fallback to basic if not available
        try:
            font = ImageFont.truetype("arial.ttf", 24)
        except:
            font = ImageFont.load_default()
        
        # Draw the part name
        text = part_name.replace("_", " ")
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        
        x = (400 - text_width) // 2
        y = (300 - text_height) // 2
        
        draw.text((x, y), text, fill='#333333', font=font)
        
        # Save the image
        filepath = f"assets/images/parts/{filename}.png"
        img.save(filepath)
        print(f"✅ Created placeholder: {part_name} -> {filepath}")
        return True
        
    except ImportError:
        print("❌ PIL not available for placeholder creation")
        return False
    except Exception as e:
        print(f"❌ Failed to create placeholder for {part_name}: {e}")
        return False

def download_parts_images():
    """Main function to download parts images"""
    print("🚛 Starting truck parts image download...")
    print("=" * 60)
    
    create_directory_structure()
    
    successful_downloads = 0
    failed_downloads = 0
    
    for part_name in PARTS_LIST:
        filename = sanitize_filename(part_name)
        print(f"\n📦 Processing: {part_name}")
        
        # Try to download from Unsplash first
        if download_from_unsplash(part_name, filename):
            successful_downloads += 1
            time.sleep(1)  # Be respectful to the API
        else:
            # Create placeholder if download fails
            if create_placeholder_image(part_name, filename):
                successful_downloads += 1
            else:
                failed_downloads += 1
                print(f"❌ Failed to get image for: {part_name}")
    
    print("\n" + "=" * 60)
    print(f"📊 Download Summary:")
    print(f"✅ Successful: {successful_downloads}")
    print(f"❌ Failed: {failed_downloads}")
    print(f"📁 Images saved to: assets/images/parts/")

def create_manual_download_instructions():
    """Create a file with manual download instructions"""
    instructions = """
# Manual Parts Images Download Instructions

## Option 1: Use Google Images
1. Go to https://images.google.com
2. Search for each part with terms like:
   - "truck [PART_NAME]"
   - "automotive [PART_NAME]"
   - "[PART_NAME] parts"
3. Right-click on good images and "Save image as..."
4. Save to: assets/images/parts/[PART_NAME].jpg

## Option 2: Use Stock Photo Sites
- Unsplash: https://unsplash.com/s/photos/truck-parts
- Pexels: https://www.pexels.com/search/truck%20parts/
- Pixabay: https://pixabay.com/images/search/truck%20parts/

## Option 3: Use Automotive Parts Suppliers
- AutoZone: https://www.autozone.com
- O'Reilly Auto Parts: https://www.oreillyauto.com
- NAPA Auto Parts: https://www.napaonline.com

## Recommended Image Specifications:
- Size: 400x300 pixels
- Format: JPG or PNG
- Quality: High resolution
- Background: White or transparent

## Parts List:
"""
    
    for part in PARTS_LIST:
        instructions += f"- {part}\n"
    
    with open("PARTS_IMAGES_DOWNLOAD_GUIDE.md", "w") as f:
        f.write(instructions)
    
    print("📝 Created manual download guide: PARTS_IMAGES_DOWNLOAD_GUIDE.md")

if __name__ == "__main__":
    print("🚛 Truck Parts Image Downloader")
    print("Choose an option:")
    print("1. Auto-download from Unsplash (requires internet)")
    print("2. Create manual download guide")
    print("3. Both")
    
    choice = input("Enter choice (1/2/3): ").strip()
    
    if choice in ["1", "3"]:
        download_parts_images()
    
    if choice in ["2", "3"]:
        create_manual_download_instructions()
    
    print("\n🎉 Done! Check the assets/images/parts/ folder for your images.")
