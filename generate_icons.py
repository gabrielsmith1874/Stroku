#!/usr/bin/env python3
"""
Generate Roku app icons based on existing icon.png with purple background
"""

from PIL import Image, ImageDraw
import os

def create_icon_with_background(source_path, output_path, size, bg_color="#0F0F23"):
    """
    Create an icon with specified background color and size
    """
    # Open the source icon
    with Image.open(source_path) as source:
        # Convert to RGBA if not already
        if source.mode != 'RGBA':
            source = source.convert('RGBA')
        
        # Handle size as tuple (width, height)
        if isinstance(size, int):
            width, height = size, size
        else:
            width, height = size
        
        # Create background
        background = Image.new('RGBA', (width, height), bg_color)
        
        # Calculate scaling to fit icon in the background with some padding
        padding_x = int(width * 0.1)  # 10% padding
        padding_y = int(height * 0.1)  # 10% padding
        max_icon_width = width - (padding_x * 2)
        max_icon_height = height - (padding_y * 2)
        
        # Calculate scale factor
        scale_factor = min(max_icon_width / source.width, max_icon_height / source.height)
        new_size = (int(source.width * scale_factor), int(source.height * scale_factor))
        
        # Resize the icon
        resized_icon = source.resize(new_size, Image.Resampling.LANCZOS)
        
        # Calculate position to center the icon
        x_offset = (width - new_size[0]) // 2
        y_offset = (height - new_size[1]) // 2
        
        # Paste the icon onto the background
        background.paste(resized_icon, (x_offset, y_offset), resized_icon)
        
        # Convert to RGB and save
        rgb_background = Image.new('RGB', background.size, bg_color)
        rgb_background.paste(background, mask=background.split()[-1])
        
        # Ensure output directory exists
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        rgb_background.save(output_path, 'PNG')
        print(f"Created {output_path} ({width}x{height})")

def main():
    # Source icon path
    source_icon = "images/icon.png"
    
    # Output paths with correct Roku dimensions
    outputs = {
        "images/icon_hd.png": (540, 405),    # HD icon size from backup
        "images/icon_sd.png": (290, 218),    # SD icon size from backup
        "images/splash_hd.png": (1920, 1080) # Splash screen size from backup
    }
    
    # Check if source exists
    if not os.path.exists(source_icon):
        print(f"Error: Source icon {source_icon} not found!")
        return
    
    # Generate each icon
    for output_path, size in outputs.items():
        try:
            create_icon_with_background(source_icon, output_path, size)
        except Exception as e:
            print(f"Error creating {output_path}: {e}")

if __name__ == "__main__":
    main()
