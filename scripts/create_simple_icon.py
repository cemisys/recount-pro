#!/usr/bin/env python3
"""
Script para crear un icono simple para ReCount Pro
Requiere: pip install Pillow
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_app_icon():
    # Crear imagen de 512x512
    size = 512
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Fondo con gradiente simulado (azul a púrpura)
    for y in range(size):
        # Interpolación de color de azul (#667eea) a púrpura (#764ba2)
        ratio = y / size
        r = int(102 + (118 - 102) * ratio)  # 667eea -> 764ba2
        g = int(126 + (75 - 126) * ratio)
        b = int(234 + (162 - 234) * ratio)
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))
    
    # Esquinas redondeadas (simuladas)
    corner_radius = 80
    
    # Dibujar contador principal (rectángulo blanco)
    counter_width = 280
    counter_height = 350
    counter_x = (size - counter_width) // 2
    counter_y = (size - counter_height) // 2 + 20
    
    # Sombra del contador
    shadow_offset = 8
    draw.rounded_rectangle(
        [counter_x + shadow_offset, counter_y + shadow_offset, 
         counter_x + counter_width + shadow_offset, counter_y + counter_height + shadow_offset],
        radius=20, fill=(0, 0, 0, 50)
    )
    
    # Contador principal
    draw.rounded_rectangle(
        [counter_x, counter_y, counter_x + counter_width, counter_y + counter_height],
        radius=20, fill=(255, 255, 255, 255), outline=(200, 200, 200, 255), width=2
    )
    
    # Pantalla del contador (rectángulo negro)
    screen_margin = 20
    screen_height = 60
    screen_x = counter_x + screen_margin
    screen_y = counter_y + screen_margin
    screen_width = counter_width - 2 * screen_margin
    
    draw.rounded_rectangle(
        [screen_x, screen_y, screen_x + screen_width, screen_y + screen_height],
        radius=10, fill=(30, 41, 59, 255)
    )
    
    # Texto "COUNT" en la pantalla
    try:
        # Intentar usar una fuente del sistema
        font_size = 32
        font = ImageFont.truetype("arial.ttf", font_size)
    except:
        # Usar fuente por defecto si no encuentra arial
        font = ImageFont.load_default()
    
    text = "COUNT"
    text_bbox = draw.textbbox((0, 0), text, font=font)
    text_width = text_bbox[2] - text_bbox[0]
    text_height = text_bbox[3] - text_bbox[1]
    text_x = screen_x + (screen_width - text_width) // 2
    text_y = screen_y + (screen_height - text_height) // 2
    
    draw.text((text_x, text_y), text, fill=(16, 185, 129, 255), font=font)
    
    # Botones del contador (círculos)
    button_radius = 25
    button_spacing = 70
    start_x = counter_x + 60
    start_y = counter_y + 120
    
    # Números 1-9
    numbers = ['1', '2', '3', '4', '5', '6', '7', '8', '9']
    for i, num in enumerate(numbers):
        row = i // 3
        col = i % 3
        btn_x = start_x + col * button_spacing
        btn_y = start_y + row * button_spacing
        
        # Círculo del botón
        draw.ellipse(
            [btn_x - button_radius, btn_y - button_radius,
             btn_x + button_radius, btn_y + button_radius],
            fill=(241, 245, 249, 255), outline=(203, 213, 225, 255), width=1
        )
        
        # Número
        try:
            num_font = ImageFont.truetype("arial.ttf", 20)
        except:
            num_font = ImageFont.load_default()
        
        num_bbox = draw.textbbox((0, 0), num, font=num_font)
        num_width = num_bbox[2] - num_bbox[0]
        num_height = num_bbox[3] - num_bbox[1]
        num_x = btn_x - num_width // 2
        num_y = btn_y - num_height // 2
        
        draw.text((num_x, num_y), num, fill=(71, 85, 105, 255), font=num_font)
    
    # Botones especiales en la última fila
    last_row_y = start_y + 3 * button_spacing
    
    # Botón C (Clear)
    c_btn_x = start_x
    draw.rounded_rectangle(
        [c_btn_x - 30, last_row_y - 15, c_btn_x + 30, last_row_y + 15],
        radius=15, fill=(239, 68, 68, 255), outline=(220, 38, 38, 255), width=1
    )
    c_text_bbox = draw.textbbox((0, 0), "C", font=num_font)
    c_text_width = c_text_bbox[2] - c_text_bbox[0]
    c_text_height = c_text_bbox[3] - c_text_bbox[1]
    draw.text((c_btn_x - c_text_width // 2, last_row_y - c_text_height // 2), 
              "C", fill=(255, 255, 255, 255), font=num_font)
    
    # Botón 0
    zero_btn_x = start_x + button_spacing
    draw.ellipse(
        [zero_btn_x - button_radius, last_row_y - button_radius,
         zero_btn_x + button_radius, last_row_y + button_radius],
        fill=(241, 245, 249, 255), outline=(203, 213, 225, 255), width=1
    )
    zero_bbox = draw.textbbox((0, 0), "0", font=num_font)
    zero_width = zero_bbox[2] - zero_bbox[0]
    zero_height = zero_bbox[3] - zero_bbox[1]
    draw.text((zero_btn_x - zero_width // 2, last_row_y - zero_height // 2), 
              "0", fill=(71, 85, 105, 255), font=num_font)
    
    # Botón OK
    ok_btn_x = start_x + 2 * button_spacing
    draw.rounded_rectangle(
        [ok_btn_x - 30, last_row_y - 15, ok_btn_x + 30, last_row_y + 15],
        radius=15, fill=(16, 185, 129, 255), outline=(5, 150, 105, 255), width=1
    )
    ok_text_bbox = draw.textbbox((0, 0), "OK", font=num_font)
    ok_text_width = ok_text_bbox[2] - ok_text_bbox[0]
    ok_text_height = ok_text_bbox[3] - ok_text_bbox[1]
    draw.text((ok_btn_x - ok_text_width // 2, last_row_y - ok_text_height // 2), 
              "OK", fill=(255, 255, 255, 255), font=num_font)
    
    # Icono de vehículo pequeño
    vehicle_x = size - 120
    vehicle_y = size - 120
    vehicle_width = 80
    vehicle_height = 50
    
    # Fondo del vehículo
    draw.rounded_rectangle(
        [vehicle_x, vehicle_y, vehicle_x + vehicle_width, vehicle_y + vehicle_height],
        radius=8, fill=(255, 255, 255, 230)
    )
    
    # Carrocería del vehículo
    draw.rounded_rectangle(
        [vehicle_x + 10, vehicle_y + 10, vehicle_x + 70, vehicle_y + 30],
        radius=4, fill=(59, 130, 246, 255)
    )
    
    # Ruedas
    wheel_radius = 6
    draw.ellipse(
        [vehicle_x + 15 - wheel_radius, vehicle_y + 35 - wheel_radius,
         vehicle_x + 15 + wheel_radius, vehicle_y + 35 + wheel_radius],
        fill=(55, 65, 81, 255)
    )
    draw.ellipse(
        [vehicle_x + 65 - wheel_radius, vehicle_y + 35 - wheel_radius,
         vehicle_x + 65 + wheel_radius, vehicle_y + 35 + wheel_radius],
        fill=(55, 65, 81, 255)
    )
    
    # Texto "RC" en la esquina
    try:
        rc_font = ImageFont.truetype("arial.ttf", 48)
    except:
        rc_font = ImageFont.load_default()
    
    rc_text = "RC"
    rc_bbox = draw.textbbox((0, 0), rc_text, font=rc_font)
    rc_width = rc_bbox[2] - rc_bbox[0]
    rc_x = size - 80 - rc_width // 2
    rc_y = 60
    
    draw.text((rc_x, rc_y), rc_text, fill=(255, 255, 255, 230), font=rc_font)
    
    return img

def main():
    print("🎨 Creando icono de ReCount Pro...")
    
    # Crear directorio si no existe
    os.makedirs("assets/images", exist_ok=True)
    
    # Crear el icono
    icon = create_app_icon()
    
    # Guardar como PNG
    icon_path = "assets/images/app_icon.png"
    icon.save(icon_path, "PNG")
    
    print(f"✅ Icono creado: {icon_path}")
    print("📱 Ahora ejecuta: flutter packages pub run flutter_launcher_icons:main")

if __name__ == "__main__":
    main()
