#!/usr/bin/env python

import cairo
import random
import math
from xsmath import vec2, color

mul = 3
g_size = 15
eye_size = 5

def next_power_of_2(x):  
    return 1 if x == 0 else 2**(x - 1).bit_length()

def random_on_circle(radius: float):
    angle = random.uniform(0.0, math.pi * 2.0)
    return vec2(math.cos(angle) * radius, math.sin(angle) * radius)

def lerp_vec2(a: vec2, b: vec2, t: float):
    return vec2(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t)

def clamp(a: float, b: float, v: float):
    return max(a, min(b, v))

def lerp(a: float, b: float, t: float):
    t = clamp(0.0, 1.0, t)
    return a + (b - a) * t

def inv_lerp(a: float, b: float, v: float):
    return (v - a) / (b - a)

def remap(a1: float, b1: float, a2: float, b2: float, v: float):
    return lerp(a2, b2, inv_lerp(a1, b1, v))

def draw_rounded_hexagon(radius : float, rounding : float, color : color, thickness : float, pos : vec2, context : cairo.Context):
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

def rounded_hexagon(radius : float, rounding : float, color : color, thickness : float, file : str):
    next_p2 = next_power_of_2(radius * 2 + 1)
    colorSurf = cairo.ImageSurface(cairo.FORMAT_ARGB32, next_p2, next_p2)
    colorCtx = cairo.Context(colorSurf)
    draw_rounded_hexagon(radius, rounding, color, thickness, vec2(next_p2 * 0.5, next_p2 * 0.5), colorCtx)
    colorSurf.write_to_png("assets/images/generated/" + file + ".png")

# Draw six rounded triangles with a given radius and rounding in one image
def rounded_triangles(radius, rounding, color, file):
    next_p2 = next_power_of_2(radius * 2 + 1)
    colorSurf = cairo.ImageSurface(cairo.FORMAT_ARGB32, next_p2 * 6, next_p2)
    colorCtx = cairo.Context(colorSurf)

    for i in range(0, 6):
        t = -i * math.pi / 3.0 - (math.pi / 3.0) * 1.5
        dt = math.pi / 1.5
        dtt = dt * 0.5
        cx = next_p2 * 0.5 + next_p2 * i
        cy = next_p2 * 0.5
        r = radius - rounding

        # Draw the rounding
        for j in range(0, 3):
            x = math.cos(t) * r + cx 
            y = math.sin(t) * r + cy
            colorCtx.arc(x, y, rounding, t - dtt, t + dtt)
            t += dt
        # colorCtx.line_to(cx, cy)
        
        colorCtx.set_source_rgba(color.r, color.g, color.b, color.a)
        colorCtx.close_path()  
        colorCtx.fill()  
    colorSurf.write_to_png("assets/images/generated/" + file + ".png")


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

class particle :
    def __init__(self, pos : vec2, vel : vec2, color : color, size: float,  life : float) -> None:
        self.pos = pos
        self.vel = vel
        self.color = color
        self.life = life
        self.size = size

    def update(self, dt : float) -> None:
        self.pos += self.vel * dt
        self.life -= dt
        self.size = self.size * 0.8

    def draw(self, ctx : cairo.Context, offset) -> None:
        ctx.set_source_rgba(self.color.r, self.color.g, self.color.b, self.color.a)
        ctx.arc(self.pos.x + offset.x, self.pos.y + offset.y, self.size, 0.0, math.pi * 2.0)
        ctx.fill()

def hexagon_progress_arc(radius: float, color: color, file: str):
    next_p2 = next_power_of_2(radius * 2 + 1)
    colorSurf = cairo.ImageSurface(cairo.FORMAT_ARGB32, next_p2 * 7, next_p2)
    colorCtx = cairo.Context(colorSurf)

    for i in range(1, 7):
        t = -i * math.pi / 3.0
        dt = math.pi / 3.0
        cx = next_p2 * 0.5 + next_p2 * i
        cy = next_p2 * 0.5
        r = radius

        # A triangle
        colorCtx.move_to(cx, cy)
        for j in range(0, i + 1):
            x = math.cos(t) * r + cx 
            y = math.sin(t) * r + cy
            colorCtx.line_to(x, y)
            t += dt

        colorCtx.set_source_rgba(color.r, color.g, color.b, color.a)
        colorCtx.close_path()  
        colorCtx.fill()
            

    colorSurf.write_to_png("assets/images/generated/" + file + ".png")

def random_on_hexagon(radius: float):
    side = random.randint(0, 5)
    a0 = math.pi / 3.0 * side
    a1 = math.pi / 3.0 * ((side + 1) % 6)
    p0 = vec2(math.cos(a0) * radius, math.sin(a0) * radius)
    p1 = vec2(math.cos(a1) * radius, math.sin(a1) * radius)    
    return lerp_vec2(p0, p1, random.random())

def explosion(radius: float, frames: int, color: color, file: str):
    next_p2 = next_power_of_2(radius * 4 + 1)
    colorSurf = cairo.ImageSurface(cairo.FORMAT_ARGB32, next_p2 * frames, next_p2)
    colorCtx = cairo.Context(colorSurf)

    # init particles
    particles = []
    num_particles = 100
    for i in range(0, num_particles):
        pos = random_on_hexagon(radius)
        vel = pos.normalized() * random.uniform(10.0, 20.0)
        particles.append(particle(pos, vel, color, random.uniform(4.0, 8.0), random.uniform(0.5, 1.0)))
    
    for i in range(0, frames):        
        center = vec2(next_p2 * i + next_p2 * 0.5, next_p2 * 0.5)
        
        # update particles
        for p in particles:
            p.update(1.0 / 60.0)

        # draw particles
        for p in particles:
            p.draw(colorCtx, center)

    colorSurf.write_to_png("assets/images/generated/" + file + ".png")

def player():
    radius = g_size * mul
    next_p2 = next_power_of_2(radius * 2 + 1)
    frames = 60
    colorSurf = cairo.ImageSurface(cairo.FORMAT_ARGB32, next_p2 * frames, next_p2)
    colorCtx = cairo.Context(colorSurf)
    pos = vec2(next_p2 * 0.5, next_p2 * 0.5)
    colorCtx.set_line_cap(cairo.LINE_CAP_ROUND)
    colorCtx.set_line_width(eye_size * mul)

    for i in range(0, frames):
        draw_rounded_hexagon(radius, 3.0 * mul , color(1.0, 1.0, 1.0, 1.0), 0.0, pos, colorCtx)
        pos.x += next_p2

    
    # draw a gray circle
    for i in range(0, frames):
        t = (i / frames)
        think = math.sin(t * math.pi * 2.0) * 2.0 * mul * 0.0
        matrix = cairo.Matrix()
        matrix.translate(next_p2 * i + next_p2 * 0.5 + think, next_p2 * 0.5)
        colorCtx.set_matrix(matrix)
        
        # draw eyes as lines
        blink = 0 if t > 0.9 else 1
        colorCtx.set_source_rgba(0.0, 0.0, 0.0, 1.0)
        colorCtx.move_to(radius * 0.3, radius * 0.16 * blink)
        colorCtx.line_to(radius * 0.3, -radius * 0.16 * blink)
        colorCtx.move_to(-radius * 0.3, radius * 0.16 * blink)
        colorCtx.line_to(-radius * 0.3, -radius * 0.16 * blink)
        colorCtx.stroke()

    # draw breathing circle
        """
    for i in range(0, frames):
        t = (i / frames) 
        t = math.pow(t, 1.0 / 4.0)
        t *= math.pi * 0.5
        t = math.sin(t)
        colorCtx.set_source_rgba(0.0, 0.0, 0.0, 1.0)
        colorCtx.arc(next_p2 * i + next_p2 * 0.5, next_p2 * 0.5, radius * (0.2 + t * 0.3), 0.0, math.pi * 2.0)
        colorCtx.set_line_width(2.0 * mul)
        colorCtx.stroke()
        """

    colorSurf.write_to_png("assets/images/generated/player.png")

def basic():
    radius = g_size * mul
    small_radius = 8 * mul
    next_p2 = next_power_of_2(radius * 2 + 1)
    frames = 60
    colorSurf = cairo.ImageSurface(cairo.FORMAT_ARGB32, next_p2 * frames, next_p2)
    context = cairo.Context(colorSurf)
    context.set_line_cap(cairo.LINE_CAP_ROUND)
    context.set_line_width(2.5 * mul)
    pos = vec2(next_p2 * 0.5, next_p2 * 0.5)

    for i in range(0, frames):
        draw_rounded_hexagon(radius, 3.0 * mul , color(1.0, 1.0, 1.0, 1.0), 0.0, pos, context)
        pos.x += next_p2

    for i in range(0, frames):
        t = (i / frames)
        #t = 1.0 - math.pow(t, 1.0 / 4)
        #sz = small_radius * t * 0.5 + small_radius * 0.5
        #t *= math.pi * 0.5
        # pos = vec2(next_p2 * i + next_p2 * 0.5, next_p2 * 0.5)        
        matrix = cairo.Matrix()
        matrix.translate(next_p2 * i + next_p2 * 0.5, next_p2 * 0.5)
        context.set_matrix(matrix)
        context.set_source_rgba(0.0, 0.0, 0.0, 1.0)

        # draw mean eyes
        y = -radius * 0.1        
        sz = eye_size * mul * 0.5
        if t < 0.45 and t > 0.05:
            context.arc(radius * 0.4, y, sz, 0.0, math.pi * 2.0)
            context.arc(-radius * 0.2, y, sz, 0.0, math.pi * 2.0)
            context.fill()            
        elif t > 0.55 and t < 0.95:
            context.arc(-radius * 0.4, y, sz, 0.0, math.pi * 2.0)
            context.arc(radius * 0.2, y, sz, 0.0, math.pi * 2.0)
            context.fill()
        else:
            context.move_to(-radius * 0.4, y)
            context.line_to(-radius * 0.2, y)
            context.move_to(radius * 0.4, y)
            context.line_to(radius * 0.2, y)
            context.stroke()

    colorSurf.write_to_png("assets/images/generated/basic.png")

def stealth():
    radius = g_size * mul
    small_radius = 8 * mul
    next_p2 = next_power_of_2(radius * 2 + 1)
    frames = 60
    colorSurf = cairo.ImageSurface(cairo.FORMAT_ARGB32, next_p2 * frames, next_p2)
    context = cairo.Context(colorSurf)
    context.set_line_cap(cairo.LINE_CAP_ROUND)    
    pos = vec2(next_p2 * 0.5, next_p2 * 0.5)

    for i in range(0, frames):
        draw_rounded_hexagon(radius, 3.0 * mul , color(1.0, 1.0, 1.0, 1.0), 0.0, pos, context)
        pos.x += next_p2

    for i in range(0, frames):
        t = (i / frames)        
        matrix = cairo.Matrix()
        matrix.translate(next_p2 * i + next_p2 * 0.5, next_p2 * 0.5)
        context.set_matrix(matrix)
        context.set_source_rgba(0.0, 0.0, 0.0, 1.0)

        blink = 1 if t < 0.9 else lerp(1.0, 0.0, (t - 0.9) * 10.0)
        context.set_line_width(eye_size * mul * blink)
        y = -radius * 0.1        
        context.move_to(-radius * 0.65, y)
        context.line_to(radius * 0.65, y)
        context.stroke()        
        
    colorSurf.write_to_png("assets/images/generated/stealth.png")

def ranged():
    radius = g_size * mul
    small_radius = 2 * mul
    next_p2 = next_power_of_2(radius * 2 + 1)
    frames = 60
    colorSurf = cairo.ImageSurface(cairo.FORMAT_ARGB32, next_p2 * frames, next_p2)
    colorCtx = cairo.Context(colorSurf)
    pos = vec2(next_p2 * 0.5, next_p2 * 0.5)

    for i in range(0, frames):
        draw_rounded_hexagon(radius, 3.0 * mul , color(1.0, 1.0, 1.0, 1.0), 0.0, pos, colorCtx)
        pos.x += next_p2

    # draw two circles rotating around each other
    for i in range(0, frames):
        t = (i / frames)
        t = remap(0.75, 1.0, 0.0, 1.0, t)
        t = math.pow(t, 4.0)
        matrix = cairo.Matrix()
        matrix.translate(next_p2 * i + next_p2 * 0.5, next_p2 * 0.5 - radius * 0.1)
        t = t * math.pi
        sz = eye_size * mul * 0.5
        # matrix.rotate(-t)
        colorCtx.set_matrix(matrix)        
        colorCtx.set_source_rgba(0.0, 0.0, 0.0, 1.0)
        cx = math.cos(t) * (radius) * 0.3
        cy = math.sin(t) * (radius) * 0.3
        # colorCtx.arc(cx, cy, sz , 0.0, math.pi * 2.0)
        colorCtx.arc(-cx, -cy, sz , 0.0, math.pi * 2.0)
        cx = lerp(-radius * 0.3, radius * 0.3, t)   
        cy = 0.0
        colorCtx.arc(-cx, -cy, sz , 0.0, math.pi * 2.0)
        colorCtx.fill()
        
    colorSurf.write_to_png("assets/images/generated/range.png")

def explode():
    radius = g_size * mul
    next_p2 = next_power_of_2(radius * 2 + 1)
    frames = 60
    colorSurf = cairo.ImageSurface(cairo.FORMAT_ARGB32, next_p2 * frames, next_p2)
    context = cairo.Context(colorSurf)
    context.set_line_cap(cairo.LINE_CAP_ROUND)
    context.set_line_width(eye_size * mul * 0.5)
    pos = vec2(next_p2 * 0.5, next_p2 * 0.5)

    for i in range(0, frames):
        draw_rounded_hexagon(radius, 3.0 * mul , color(1.0, 1.0, 1.0, 1.0), 0.0, pos, context)
        pos.x += next_p2


    for i in range(0, frames):
        t = (i / frames)
        matrix = cairo.Matrix()
        matrix.translate(next_p2 * i + next_p2 * 0.5, next_p2 * 0.5)
        context.set_matrix(matrix)
        context.set_source_rgba(0.0, 0.0, 0.0, 1.0)        

        y = -radius * 0.1     
        sz = eye_size * mul * 0.5
        context.arc(-radius * 0.3, y, sz, 0.0, math.pi * 2.0)
        context.fill()
        if t < 0.5:
            context.arc(radius * 0.3, y, sz, 0.0, math.pi * 2.0)
            context.fill()
        else:   
            y = -radius * 0.1 + math.sin(t * math.pi * 20) * radius * 0.08
            context.move_to(radius * 0.45, y)
            context.line_to(radius * 0.15, y)            
            context.stroke()


    """
    # draw six lines
    for i in range(0, frames):
        t = (i / frames)
        t0 = math.pow(t, 1.0)
        t1 = math.pow(t, 1.0 / 4)
        t0 = t0 * 0.6 + 0.2
        t1 = t1 * 0.8
        matrix = cairo.Matrix()
        matrix.translate(next_p2 * i + next_p2 * 0.5, next_p2 * 0.5)                    
        colorCtx.set_matrix(matrix)
        for j in range(0, 6):
            theta = j * math.pi / 3.0 + math.pi / 6.0

            x0 = math.cos(theta) * radius * t0
            y0 = math.sin(theta) * radius * t0
            x1 = math.cos(theta) * radius * t1
            y1 = math.sin(theta) * radius * t1

            colorCtx.move_to(x0, y0)
            colorCtx.line_to(x1, y1)
            colorCtx.set_source_rgba(0.0, 0.0, 0.0, 1.0)
            colorCtx.set_line_width(2.0 * mul)
            colorCtx.stroke()
    """
            
    colorSurf.write_to_png("assets/images/generated/explode.png")


def main():
    white = color(1.0, 1.0, 1.0)
    player()
    basic()
    stealth()
    ranged()
    explode()

    rounded_hexagon(19 * mul, 4 * mul, white, 1.0  * mul, "hexagon")
    rounded_hexagon(19 * mul, 4 * mul, white, 1.0  * mul, "small_hexagon")
    rounded_hexagon(19 * mul, 3 * mul, white, 1.6 * mul, "thick_small_hexagon")
    
    #rounded_hexagon(14 * mul, 3 * mul, white, 0.0, "filled_hexagon")
    #rounded_hexagon(8 * mul, 3 * mul, white, 0.0, "small_filled_hexagon")
    #hexagon_progress_arc(5 * mul, white, "direction_indicator")
    #hexagon_progress_arc(8 * mul, white, "powerup")
    #rounded_hexagon(12 * mul, 4 * mul, white, 0.0, "pawn")
    
    rounded_triangles(3 * mul, 1 * mul, white, "triangle")
    rounded_rectangle(624 * mul, 16 * mul, 1 * mul, white, "bar")
    rounded_rectangle(624 * mul, 120 * mul, 1 * mul, white, "big_bar")
    rounded_rectangle(70 * mul, 16 * mul, 1 * mul, white, "menu_bg_bar")
    explosion(16, 16, white, "explosion")

# run the main function
main()
