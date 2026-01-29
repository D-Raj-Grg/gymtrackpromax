#!/usr/bin/env python3
"""
GymTrack Pro App Icon Generator

Generates app icons for iOS with:
- Radial gradient background (dark blue to indigo)
- Stylized dumbbell with gradient fill
- Light, dark, and tinted variants
"""

from PIL import Image, ImageDraw
import math
import os

# Icon dimensions
SIZE = 1024
CENTER = SIZE // 2

# Color palette (matching app theme)
COLORS = {
    'background': (15, 23, 42),       # #0F172A - gym background
    'card': (30, 41, 59),             # #1E293B - gym card
    'primary': (99, 102, 241),        # #6366F1 - gym primary (indigo)
    'primary_light': (129, 140, 248), # #818CF8 - primary light
    'accent': (34, 211, 238),         # #22D3EE - gym accent (cyan)
    'white': (248, 250, 252),         # #F8FAFC - gym text
}


def create_radial_gradient(size, center_color, edge_color):
    """Create a radial gradient from center to edge."""
    img = Image.new('RGB', (size, size), center_color)
    pixels = img.load()

    max_dist = math.sqrt(2) * (size // 2)

    for y in range(size):
        for x in range(size):
            # Distance from center
            dist = math.sqrt((x - size // 2) ** 2 + (y - size // 2) ** 2)
            ratio = min(dist / max_dist, 1.0)

            # Interpolate colors
            r = int(center_color[0] + (edge_color[0] - center_color[0]) * ratio)
            g = int(center_color[1] + (edge_color[1] - center_color[1]) * ratio)
            b = int(center_color[2] + (edge_color[2] - center_color[2]) * ratio)

            pixels[x, y] = (r, g, b)

    return img


def interpolate_color(color1, color2, ratio):
    """Interpolate between two colors."""
    return tuple(int(color1[i] + (color2[i] - color1[i]) * ratio) for i in range(3))


def draw_rounded_rect(draw, bbox, radius, fill):
    """Draw a rounded rectangle."""
    x1, y1, x2, y2 = bbox

    # Draw main rectangle
    draw.rectangle([x1 + radius, y1, x2 - radius, y2], fill=fill)
    draw.rectangle([x1, y1 + radius, x2, y2 - radius], fill=fill)

    # Draw corners
    draw.ellipse([x1, y1, x1 + 2*radius, y1 + 2*radius], fill=fill)
    draw.ellipse([x2 - 2*radius, y1, x2, y1 + 2*radius], fill=fill)
    draw.ellipse([x1, y2 - 2*radius, x1 + 2*radius, y2], fill=fill)
    draw.ellipse([x2 - 2*radius, y2 - 2*radius, x2, y2], fill=fill)


def draw_dumbbell(img, primary_color, accent_color):
    """Draw a stylized dumbbell icon with gradient."""
    draw = ImageDraw.Draw(img)

    # Dumbbell dimensions (centered, modern minimal style)
    bar_height = 60
    bar_width = 400
    weight_width = 120
    weight_height = 280
    weight_radius = 30

    # Center positions
    cx, cy = CENTER, CENTER

    # Bar position
    bar_left = cx - bar_width // 2
    bar_top = cy - bar_height // 2

    # Left weight plate
    left_weight_left = bar_left - 20
    left_weight_right = left_weight_left + weight_width
    weight_top = cy - weight_height // 2
    weight_bottom = cy + weight_height // 2

    # Right weight plate
    right_weight_right = cx + bar_width // 2 + 20
    right_weight_left = right_weight_right - weight_width

    # Draw with gradient effect (left to right: primary to accent)

    # Left weight plate (primary color)
    draw_rounded_rect(draw,
                      [left_weight_left, weight_top, left_weight_right, weight_bottom],
                      weight_radius, primary_color)

    # Inner detail on left weight
    inner_margin = 20
    draw_rounded_rect(draw,
                      [left_weight_left + inner_margin, weight_top + inner_margin,
                       left_weight_right - inner_margin, weight_bottom - inner_margin],
                      weight_radius - 10,
                      interpolate_color(primary_color, COLORS['primary_light'], 0.3))

    # Bar (gradient from primary to accent)
    bar_segments = 20
    segment_width = bar_width / bar_segments
    for i in range(bar_segments):
        ratio = i / (bar_segments - 1)
        color = interpolate_color(primary_color, accent_color, ratio)
        seg_left = bar_left + i * segment_width
        seg_right = bar_left + (i + 1) * segment_width + 1  # +1 to avoid gaps
        draw.rectangle([seg_left, bar_top, seg_right, bar_top + bar_height], fill=color)

    # Right weight plate (accent color)
    draw_rounded_rect(draw,
                      [right_weight_left, weight_top, right_weight_right, weight_bottom],
                      weight_radius, accent_color)

    # Inner detail on right weight
    draw_rounded_rect(draw,
                      [right_weight_left + inner_margin, weight_top + inner_margin,
                       right_weight_right - inner_margin, weight_bottom - inner_margin],
                      weight_radius - 10,
                      interpolate_color(accent_color, COLORS['white'], 0.2))

    return img


def generate_main_icon():
    """Generate the main app icon."""
    # Create radial gradient background
    img = create_radial_gradient(SIZE, COLORS['card'], COLORS['background'])

    # Draw dumbbell
    draw_dumbbell(img, COLORS['primary'], COLORS['accent'])

    return img


def generate_dark_icon():
    """Generate dark mode variant (slightly different contrast)."""
    # Darker gradient for dark mode
    dark_center = (20, 30, 50)
    dark_edge = (10, 15, 30)
    img = create_radial_gradient(SIZE, dark_center, dark_edge)

    # Draw dumbbell with slightly brighter colors
    draw_dumbbell(img, COLORS['primary_light'], COLORS['accent'])

    return img


def generate_tinted_icon():
    """Generate tinted/monochrome variant."""
    # Create grayscale gradient background
    img = create_radial_gradient(SIZE, (60, 60, 60), (30, 30, 30))

    # Draw dumbbell in grayscale
    draw_dumbbell(img, (180, 180, 180), (220, 220, 220))

    return img


def main():
    """Generate all icon variants and save them."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)
    output_dir = os.path.join(project_dir, 'gymtrackpromax', 'Assets.xcassets', 'AppIcon.appiconset')

    print(f"Output directory: {output_dir}")

    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)

    # Generate and save icons
    print("Generating main icon...")
    main_icon = generate_main_icon()
    main_icon.save(os.path.join(output_dir, 'AppIcon.png'), 'PNG')
    print("  Saved AppIcon.png")

    print("Generating dark mode icon...")
    dark_icon = generate_dark_icon()
    dark_icon.save(os.path.join(output_dir, 'AppIcon-Dark.png'), 'PNG')
    print("  Saved AppIcon-Dark.png")

    print("Generating tinted icon...")
    tinted_icon = generate_tinted_icon()
    tinted_icon.save(os.path.join(output_dir, 'AppIcon-Tinted.png'), 'PNG')
    print("  Saved AppIcon-Tinted.png")

    print("\nAll icons generated successfully!")
    print(f"Icons saved to: {output_dir}")


if __name__ == '__main__':
    main()
