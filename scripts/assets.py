#!/usr/bin/env python

import cairo
import random
import math
from tools import vec2, color, next_power_of_2, lerp, lerp_vec2, remap, hermite, smootherstep, smoothstep
from draw import rounded_hexagon, rounded_rectangle, rounded_triangle

mul = 3
g_size = 15
eye_size = 5

def output_rounded_hexagon(radius : float, rounding : float, color : color, thickness : float, rotation: float, file : str):
    next_p2 = next_power_of_2(radius * 2 + 1)
    colorSurf = cairo.ImageSurface(cairo.FORMAT_ARGB32, next_p2, next_p2)
    colorCtx = cairo.Context(colorSurf)
    rounded_hexagon(radius, rounding, color, thickness, vec2(next_p2 * 0.5, next_p2 * 0.5), rotation, colorCtx)
    colorSurf.write_to_png("assets/images/generated/" + file + ".png")

def output_rounded_rectangle(width: float, height: float, rounding: float, color: color, file: str):
    next_p2 = next_power_of_2(width * 2 + 1)
    colorSurf = cairo.ImageSurface(cairo.FORMAT_ARGB32, next_p2, next_p2)
    colorCtx = cairo.Context(colorSurf)
    rounded_rectangle(width, height, rounding, vec2(next_p2 * 0.5, next_p2 * 0.5), 0.0, colorCtx)
    colorSurf.write_to_png("assets/images/generated/" + file + ".png")

# Draw six rounded triangles with a given radius and rounding in one image
def output_rounded_triangles(radius, rounding, color, file):
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
        particles.append(particle(pos, vel, color, random.uniform(4.0 * mul, 8.0 * mul), random.uniform(0.5, 1.0)))
    
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
        rounded_hexagon(radius, 3.0 * mul , color(1.0, 1.0, 1.0, 1.0), 0.0, pos, 0.0, colorCtx)
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

    colorSurf.write_to_png("assets/images/generated/player.png")

def basic():
    radius = g_size * mul
    small_radius = 2.5 * mul
    next_p2 = next_power_of_2(radius * 2 + 1)
    frames = 60
    colorSurf = cairo.ImageSurface(cairo.FORMAT_ARGB32, next_p2 * frames, next_p2)
    context = cairo.Context(colorSurf)
    context.set_line_cap(cairo.LINE_CAP_ROUND)
    context.set_line_width(2.5 * mul)
    pos = vec2(next_p2 * 0.5, next_p2 * 0.5)
    for i in range(0, frames):
        rounded_hexagon(radius, 3.0 * mul , color(1.0, 1.0, 1.0, 1.0), 0.0, pos, 0.0, context)
        pos.x += next_p2

    pos = vec2(next_p2 * 0.5, next_p2 * 0.5)
    for i in range(0, frames):
        f = (i / frames)
        f = 1.0 - math.pow(f, 2.0)
        s = small_radius + (small_radius * f) * 0.5
        context.set_source_rgba(0.0, 0.0, 0.0, 1.0)
        context.arc(pos.x, pos.y, s, 0.0, math.pi * 2.0)
        context.fill()

        # r = f * math.pi / 3.0
        # s = math.sin(f * math.pi * 2.0)
        # rounded_triangle(small_radius, 3.0 * mul , color(0.0, 0.0, 0.0, 1.0), r, context)
        # rounded_hexagon(small_radius, 3.0 * mul , color(0.0, 0.0, 0.0, 1.0), 0.0, pos, f, context)        
        pos.x += next_p2

    colorSurf.write_to_png("assets/images/generated/basic.png")

def stealth():
    radius = g_size * mul
    small_radius = radius * 0.9
    next_p2 = next_power_of_2(radius * 2 + 1)
    frames = 60
    colorSurf = cairo.ImageSurface(cairo.FORMAT_ARGB32, next_p2 * frames, next_p2)
    context = cairo.Context(colorSurf)
    context.set_line_cap(cairo.LINE_CAP_ROUND)    
    pos = vec2(next_p2 * 0.5, next_p2 * 0.5)
    for i in range(0, frames):
        rounded_hexagon(radius, 3.0 * mul , color(1.0, 1.0, 1.0, 1.0), 0.0, pos,0.0, context)
        pos.x += next_p2

    pos = vec2(next_p2 * 0.5, next_p2 * 0.5)    
    for i in range(0, frames):
        f = (i / frames)
        f = 1.0 - math.pow(f, 1.0 / 2.0)
        # draw a black line through the hexagon
        context.set_line_width(5.5 * mul * f + 1)
        x = small_radius * (1.0 - f)
        context.set_source_rgba(0.0, 0.0, 0.0, 1.0)
        context.move_to(pos.x - x, pos.y)
        context.line_to(pos.x + x, pos.y)
        context.stroke()
        pos.x += next_p2

    colorSurf.write_to_png("assets/images/generated/stealth.png")

def ranged():
    radius = g_size * mul
    small_radius = radius * 0.4
    point_size = 2.5 * mul
    next_p2 = next_power_of_2(radius * 2 + 1)
    frames = 60
    colorSurf = cairo.ImageSurface(cairo.FORMAT_ARGB32, next_p2 * frames, next_p2)
    colorCtx = cairo.Context(colorSurf)
    pos = vec2(next_p2 * 0.5, next_p2 * 0.5)

    for i in range(0, frames):        
        rounded_hexagon(radius, 3.0 * mul , color(1.0, 1.0, 1.0, 1.0), 0.0, pos, 0.0, colorCtx)        
        pos.x += next_p2

    """
    pos = vec2(next_p2 * 0.5, next_p2 * 0.5)
    for i in range(0, frames):
        f = (i / frames)
        f = hermite(0.0, 0.0, 1.0, 0.0, f)
        f *= math.pi
        s0 = 1.0 + math.sin(f + math.pi * 0.5) * 0.5
        s1 = 1.0 - math.sin(f + math.pi * 0.5) * 0.5
        f = math.sin(f)
        
        colorCtx.set_source_rgba(0.0, 0.0, 0.0, 1.0)
        colorCtx.arc(pos.x + f * small_radius, pos.y, point_size * s0, 0.0, math.pi * 2.0)
        colorCtx.fill()
        colorCtx.arc(pos.x - f * small_radius, pos.y, point_size * s1, 0.0, math.pi * 2.0)
        colorCtx.fill()
        pos.x += next_p2
    """

    pos = vec2(next_p2 * 0.5, next_p2 * 0.5)
    for i in range(0, frames):        
        matrix = cairo.Matrix()
        matrix.translate(pos.x, pos.y)
        colorCtx.set_matrix(matrix)
        f = (i / frames)
        f0 = remap(0.3, 1.0, 0.0, 1.0, f)
        f = math.pow(f, 1.0 / 2.0)
        f0 = math.pow(f, 1.0 / 2.0)
        f *= math.pi
        x = math.cos(f) * -small_radius
        y = math.sin(f) * -small_radius        
        colorCtx.set_source_rgba(0.0, 0.0, 0.0, 1.0)
        colorCtx.arc(x, y, point_size, 0.0, math.pi * 2.0)
        colorCtx.fill()
        x = lerp(0.0, -small_radius, f0)
        colorCtx.arc(x, 0.0, point_size, 0.0, math.pi * 2.0)
        colorCtx.fill()
        x = lerp(small_radius, 0.0, f0)
        colorCtx.arc(x, 0.0, point_size, 0.0, math.pi * 2.0)
        colorCtx.fill()
        pos.x += next_p2

    colorSurf.write_to_png("assets/images/generated/range.png")

def explode():
    radius = g_size * mul
    small_radius = radius * 0.6
    next_p2 = next_power_of_2(radius * 2 + 1)
    frames = 60
    colorSurf = cairo.ImageSurface(cairo.FORMAT_ARGB32, next_p2 * frames, next_p2)
    context = cairo.Context(colorSurf)
    context.set_line_cap(cairo.LINE_CAP_ROUND)
    context.set_line_width(4 * mul)
    pos = vec2(next_p2 * 0.5, next_p2 * 0.5)

    for i in range(0, frames):
        rounded_hexagon(radius, 3.0 * mul , color(1.0, 1.0, 1.0, 1.0), 0.0, pos, 0.0, context)
        pos.x += next_p2

    pos = vec2(next_p2 * 0.5, next_p2 * 0.5)
    for i in range(0, frames):
        f = (i / frames)
        f = math.pow(f, 1.0 / 3.0)
        for j in range(0, 6):
            t = -j * math.pi / 3.0 + (math.pi / 3.0) * 1.5            
            dir = vec2(math.cos(t), math.sin(t))
            f0 = remap(0.2, 0.7, 0.0, math.pi * 0.5, f)
            f1 = remap(0.3, 0.8, 0.0, math.pi * 0.5, f)
            r0 = math.sin(f0)
            r1 = math.sin(f1)            
            r0 = r0 * 0.6 + 0.4
            r1 = r1 * 0.6 + 0.4            
            p0 = dir * r0 * small_radius
            p1 = dir * r1 * small_radius
            context.set_source_rgba(0.0, 0.0, 0.0, 1.0)            
            context.move_to(pos.x + p0.x, pos.y + p0.y)
            context.line_to(pos.x + p1.x, pos.y + p1.y)
            context.stroke()

        pos.x += next_p2

    colorSurf.write_to_png("assets/images/generated/explode.png")

def level():
    radius = 12 * mul
    next_p2 = next_power_of_2(radius * 2 + 1)
    colorSurf = cairo.ImageSurface(cairo.FORMAT_ARGB32, next_p2, next_p2)
    context = cairo.Context(colorSurf)
    context.set_line_cap(cairo.LINE_CAP_ROUND)
    rot = math.pi / 6.0

    pos = vec2(next_p2 * 0.5, next_p2 * 0.5)
    rounded_hexagon(radius, 4.0 * mul , color(0.0, 0.0, 0.0, 1.0), 0.0, pos, rot, context)
    rounded_hexagon(radius, 4.0 * mul , color(1.0, 1.0, 1.0, 1.0), 1.5 * mul, pos, rot, context)
    colorSurf.write_to_png("assets/images/generated/level.png")

def main():
    white = color(1.0, 1.0, 1.0)
    player()
    basic()
    stealth()
    ranged()
    explode()
    level()

    output_rounded_hexagon(19 * mul, 4 * mul, white, 1.0  * mul, 0.0,  "hexagon")
    output_rounded_hexagon(19 * mul, 4 * mul, white, 1.0  * mul, 0.0, "small_hexagon")
    output_rounded_hexagon(19 * mul, 3 * mul, white, 1.6 * mul, 0.0, "thick_small_hexagon")
    
    output_rounded_hexagon(14 * mul, 3 * mul, white, 0.0, 0.0, "filled_hexagon")
    output_rounded_hexagon(8 * mul, 3 * mul, white, 0.0, 0.0, "small_filled_hexagon")
    hexagon_progress_arc(5 * mul, white, "direction_indicator")
    
    output_rounded_triangles(3 * mul, 1 * mul, white, "triangle")
    output_rounded_rectangle(624 * mul, 16 * mul, 1 * mul, white, "bar")
    output_rounded_rectangle(624 * mul, 120 * mul, 1 * mul, white, "big_bar")
    output_rounded_rectangle(70 * mul, 16 * mul, 1 * mul, white, "menu_bg_bar")
    explosion(16 * mul, 16, white, "explosion")

# run the main function
main()
