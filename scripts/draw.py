import math
import cairo
from tools import vec2, color

def rounded_hexagon(radius : float, rounding : float, color : color, thickness : float, pos : vec2, context : cairo.Context):
    if thickness != 0.0 :
        context.set_line_width(thickness)

    t = 0.0
    dt = math.pi / 3.0
    dtt = dt * 0.5
    cx = pos.x
    cy = pos.y
    r = radius - rounding

    # Draw the rounding
    for i in range(0, 6):
        x = math.cos(t) * r + cx
        y = math.sin(t) * r + cy
        context.arc(x, y, rounding, t - dtt, t + dtt)    
        t += dt

    context.set_source_rgba(color.r, color.g, color.b, color.a)
    context.close_path()  
    if thickness == 0.0:
        context.fill()
    else:
        context.stroke()

def rounded_rectangle(width: float, height: float, rounding: float, pos : vec2, rotation: float, context : cairo.Context):
    matrix = cairo.Matrix()
    matrix.translate(pos.x, pos.y)
    matrix.rotate(rotation) 
    context.set_matrix(matrix)
    cx = -width * 0.5
    cy = -height * 0.5        
    context.arc(cx + width - rounding, cy + rounding, rounding, math.pi * 1.5, math.pi * 2.0)
    context.arc(cx + width - rounding, cy + height - rounding, rounding, 0.0, math.pi * 0.5)
    context.arc(cx + rounding, cy + height - rounding, rounding, math.pi * 0.5, math.pi)
    context.arc(cx + rounding, cy + rounding, rounding, math.pi, math.pi * 1.5)
    context.close_path()
    context.fill()

def rounded_triangle(radius, rounding, color, context : cairo.Context):
    t = 0.0
    dt = math.pi / 3.0
    dtt = dt * 0.5
    cx = 0.0
    cy = 0.0
    r = radius - rounding

    # Draw the rounding
    for i in range(0, 3):
        x = math.cos(t) * r + cx
        y = math.sin(t) * r + cy
        context.arc(x, y, rounding, t - dtt, t + dtt)
        t += dt
    context.set_source_rgba(color.r, color.g, color.b, color.a)
    context.close_path()  
    context.fill()