#!/usr/bin/env python3
"""
Adjust icon size to make background more prominent
"""

from PIL import Image
import os

def create_icon_with_background(source_path, output_path, size, bg_color="#0F0F23", icon_scale=0.5):
    """
    Create an icon with specified background color and size
    icon_scale: factor to scale icon size (0.5 = 50% of max possible size)
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
        
        # Calculate scaling to fit icon in the background with more background space
        # Use icon_scale to make icon smaller relative to background
        padding_x = int(width * 0.2)  # 20% padding for more background
        padding_y = int(height * 0.2)  # 20% padding for more background
        max_icon_width = width - (padding_x * 2)
        max_icon_height = height - (padding_y * 2)
        
        # Apply icon_scale to make icon even smaller
        max_icon_width = int(max_icon_width * icon_scale)
        max_icon_height = int(max_icon_height * icon_scale)
        
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
        print(f"Created {output_path} ({width}x{height}) with icon scale {icon_scale}")

def main():
    # Source icon path
    source_icon = "images/icon.png"
    
    # Output paths with correct Roku dimensions
    outputs = {
        "images/icon_hd.png": (290, 218),     # HD icon correct size
        "images/icon_sd.png": (246, 140),     # SD icon correct size  
        "images/splash_hd.png": (1280, 720)   # Splash screen correct size
    }
    
    # Check if source exists
    if not os.path.exists(source_icon):
        print(f"Error: Source icon {source_icon} not found!")
        return
    
    # Generate each icon with smaller icon scale (more background)
    for output_path, size in outputs.items():
        try:
            create_icon_with_background(source_icon, output_path, size, icon_scale=0.4)
        except Exception as e:
            print(f"Error creating {output_path}: {e}")

if __name__ == "__main__":
    main()

