#!/usr/bin/env python

import cairo
import random
import math
from tools import vec2, color, next_power_of_2, lerp, lerp_vec2, remap
from draw import rounded_hexagon, rounded_rectangle
from perlin_noise import PerlinNoise
import PIL.Image as Image

mul = 3
g_size = 15
eye_size = 5

def to_pil(surface):
    return Image.frombuffer(
        "ARGB",
        (surface.get_width(), surface.get_height()),
        surface.get_data(),
        "raw", "ARGB", 0, 1)

def output_rounded_hexagon(radius : float, rounding : float, color : color, thickness : float, file : str):
    next_p2 = next_power_of_2(radius * 2 + 1)
    colorSurf = cairo.ImageSurface(cairo.FORMAT_ARGB32, next_p2, next_p2)
    colorCtx = cairo.Context(colorSurf)
    rounded_hexagon(radius, rounding, color, thickness, vec2(next_p2 * 0.5, next_p2 * 0.5), colorCtx)
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
        rounded_hexagon(radius, 3.0 * mul , color(1.0, 1.0, 1.0, 1.0), 0.0, pos, colorCtx)
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
    small_radius = 6 * mul
    next_p2 = next_power_of_2(radius * 2 + 1)
    frames = 60
    colorSurf = cairo.ImageSurface(cairo.FORMAT_ARGB32, next_p2 * frames, next_p2)
    context = cairo.Context(colorSurf)
    context.set_line_cap(cairo.LINE_CAP_ROUND)
    context.set_line_width(2.5 * mul)
    pos = vec2(next_p2 * 0.5, next_p2 * 0.5)
    for i in range(0, frames):
        rounded_hexagon(radius, 3.0 * mul , color(1.0, 1.0, 1.0, 1.0), 0.0, pos, context)
        pos.x += next_p2

    pos = vec2(next_p2 * 0.5, next_p2 * 0.5)
    for i in range(0, frames):
        rounded_hexagon(small_radius, 3.0 * mul , color(0.0, 0.0, 0.0, 1.0), 0.0, pos, context)
        pos.x += next_p2

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
        rounded_hexagon(radius, 3.0 * mul , color(1.0, 1.0, 1.0, 1.0), 0.0, pos, context)
        pos.x += next_p2

    pos = vec2(next_p2 * 0.5, next_p2 * 0.5)    
    for i in range(0, frames):
        # draw a black line through the hexagon
        context.set_line_width(5.5 * mul)
        context.set_source_rgba(0.0, 0.0, 0.0, 1.0)
        context.move_to(pos.x - small_radius, pos.y)
        context.line_to(pos.x + small_radius, pos.y)
        context.stroke()
        pos.x += next_p2

    colorSurf.write_to_png("assets/images/generated/stealth.png")

def ranged():
    radius = g_size * mul
    small_radius = 1.6 * mul
    next_p2 = next_power_of_2(radius * 2 + 1)
    frames = 60
    colorSurf = cairo.ImageSurface(cairo.FORMAT_ARGB32, next_p2 * frames, next_p2)
    colorCtx = cairo.Context(colorSurf)
    pos = vec2(next_p2 * 0.5, next_p2 * 0.5)

    for i in range(0, frames):        
        rounded_hexagon(radius, 3.0 * mul , color(1.0, 1.0, 1.0, 1.0), 0.0, pos, colorCtx)
        rounded_hexagon(radius, 3.0 * mul , color(1.0, 1.0, 1.0, 1.0), 0.0, pos, colorCtx)
        pos.x += next_p2

    pos = vec2(next_p2 * 0.5, next_p2 * 0.5)
    for i in range(0, frames):
        offset = vec2(5.0, 2.0) * mul
        rounded_hexagon(small_radius * mul, 3.0 * mul , color(0.0, 0.0, 0.0, 1.0), 0.0, pos + offset, colorCtx)
        rounded_hexagon(small_radius * mul, 3.0 * mul , color(0.0, 0.0, 0.0, 1.0), 0.0, pos - offset, colorCtx)
        pos.x += next_p2
        
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
        rounded_hexagon(radius, 3.0 * mul , color(1.0, 1.0, 1.0, 1.0), 0.0, pos, context)
        pos.x += next_p2

    pos = vec2(next_p2 * 0.5, next_p2 * 0.5)
    for i in range(0, frames):
        for j in range(0, 6):
            t = -j * math.pi / 3.0
            dt = math.pi / 3.0
            r = radius * 0.5
            x = math.cos(t) * r
            y = math.sin(t) * r
            p = vec2(x, y)
            rounded_hexagon(2.0 * mul , 3.0 * mul , color(0.0, 0.0, 0.0, 1.0), 0.0, pos + p, context)
        pos.x += next_p2

    colorSurf.write_to_png("assets/images/generated/explode.png")

class metaball:
    def __init__(self, x : float, y : float, r : float) -> None:
        self.x = x
        self.y = y
        self.r = r
        self.r2 = r * r

class noise_point:
    def __init__(self) -> None:
        self.cx0 = random.uniform(0, 1)
        self.cy0 = random.uniform(0, 1)
        self.cz0 = random.uniform(0, 1)
        self.cx1 = random.uniform(0, 1)
        self.cy1 = random.uniform(0, 1)
        self.cz1 = random.uniform(0, 1)
    
    def noise(self, noise : PerlinNoise, t : float) -> vec2:
        # sample periodic noise by sample on a circle in 3D
        t = t * math.pi * 2.0
        x = math.cos(t)
        y = math.sin(t)
        z = 0.0
        return vec2(noise([x + self.cx0, y + self.cy0, z + self.cz0]), noise([x + self.cx1, y + self.cy1, z + self.cz1]))

def evaluate_metaballs(balls, x, y):
    sum = 0
    for b in balls:
        dx = x - b.x
        dy = y - b.y
        r2 = dx * dx + dy * dy
        if r2 > 0.0001:
            sum += b.r2 / r2
        else:
            sum += b.r2 / 0.0001
    return sum

def blobs():
    radius = g_size * mul * 2
    next_p2 = next_power_of_2(radius * 2 + 1)
    width = next_p2
    w2 = width * 0.5
    frames = 60
    surf = cairo.ImageSurface(cairo.FORMAT_ARGB32, next_p2 * frames, next_p2)
    data = surf.get_data()
    noise = PerlinNoise(octaves=1, seed=1)
    
    noise_points = []
    balls = []
    for f in range(0, 6):
        noise_points.append(noise_point())
        balls.append(metaball(0, 0,random.uniform(7, 12)))

    # draw the background hexagons per frame
    for f in range(0, frames):
        pos = vec2(w2 + f * next_p2, w2)
        rounded_hexagon(radius, 3.0 * 2.0 * mul, color(1.0, 1.0, 1.0, 1.0), 0.0, pos, cairo.Context(surf))


    for f in range(0, frames):
        t = f / frames
        for i in range(0, 6):
            balls[i].x = noise_points[i].noise(noise, t).x * 60 + w2
            balls[i].y = noise_points[i].noise(noise, t).y * 60 + w2

        for y in range(0, next_p2):
            for x in range(0, next_p2):
                i = x
                j = y
                idx = (x + f * next_p2 + y * next_p2 * frames) * 4 
                value = evaluate_metaballs(balls, x, y)
                if value > 1.0:
                    c = 0
                    data[idx] = c
                    data[idx + 1] = c
                    data[idx + 2] = c
                    data[idx + 3] = 255

    # manually downsample the image
    small_surf = cairo.ImageSurface(
        cairo.FORMAT_ARGB32,
        (int)(surf.get_width() / 2),
        (int)(surf.get_height() / 2))
    
    # go over each pixel and average the 4 pixels into one
    for y in range(0, small_surf.get_height()):
        for x in range(0, small_surf.get_width()):
            idx = (x * 2 + y * 2 * surf.get_width()) * 4
            idx0 = idx
            idx1 = idx + 4
            idx2 = idx + surf.get_width() * 4
            idx3 = idx + surf.get_width() * 4 + 4
            r = (data[idx] + data[idx1] + data[idx2] + data[idx3]) / 4
            g = (data[idx + 1] + data[idx1 + 1] + data[idx2 + 1] + data[idx3 + 1]) / 4
            b = (data[idx + 2] + data[idx1 + 2] + data[idx2 + 2] + data[idx3 + 2]) / 4
            a = (data[idx + 3] + data[idx1 + 3] + data[idx2 + 3] + data[idx3 + 3]) / 4
            idx = (x + y * small_surf.get_width()) * 4
            small_surf.get_data()[idx] = (int)(r)
            small_surf.get_data()[idx + 1] = (int)(g)
            small_surf.get_data()[idx + 2] = (int)(b)
            small_surf.get_data()[idx + 3] = (int)(a)
    
    small_surf.write_to_png("assets/images/generated/basic.png")

def blobs2():
    radius = g_size * mul * 2
    next_p2 = next_power_of_2(radius * 2 + 1)
    width = next_p2
    w2 = width * 0.5
    frames = 60
    surf = cairo.ImageSurface(cairo.FORMAT_ARGB32, next_p2 * frames, next_p2)
    data = surf.get_data()
    noise = PerlinNoise(octaves=1, seed=1)
    
    noise_points = []
    balls = []
    for f in range(0, 6):
        noise_points.append(noise_point())
        balls.append(metaball(0, 0,random.uniform(7, 12)))
    balls.append(metaball(w2, w2, 12))

    # draw the background hexagons per frame
    for f in range(0, frames):
        pos = vec2(w2 + f * next_p2, w2)
        rounded_hexagon(radius, 3.0 * 2.0 * mul, color(1.0, 1.0, 1.0, 1.0), 0.0, pos, cairo.Context(surf))

    for f in range(0, frames):
        t = f / frames
        R = t * 100
        for i in range(0, 6):
            a = i * math.pi / 3.0
            balls[i].x = math.cos(a) * R + w2
            balls[i].y = math.sin(a) * R + w2

        for y in range(0, next_p2):
            for x in range(0, next_p2):
                i = x
                j = y
                idx = (x + f * next_p2 + y * next_p2 * frames) * 4 
                value = evaluate_metaballs(balls, x, y)
                if value > 1.0:
                    c = 0
                    data[idx] = c
                    data[idx + 1] = c
                    data[idx + 2] = c
                    data[idx + 3] = 255

    # manually downsample the image
    small_surf = cairo.ImageSurface(
        cairo.FORMAT_ARGB32,
        (int)(surf.get_width() / 2),
        (int)(surf.get_height() / 2))
    
    # go over each pixel and average the
    for y in range(0, small_surf.get_height()):
        for x in range(0, small_surf.get_width()):
            idx = (x * 2 + y * 2 * surf.get_width()) * 4
            idx0 = idx
            idx1 = idx + 4
            idx2 = idx + surf.get_width() * 4
            idx3 = idx + surf.get_width() * 4 + 4
            r = (data[idx] + data[idx1] + data[idx2] + data[idx3]) / 4
            g = (data[idx + 1] + data[idx1 + 1] + data[idx2 + 1] + data[idx3 + 1]) / 4
            b = (data[idx + 2] + data[idx1 + 2] + data[idx2 + 2] + data[idx3 + 2]) / 4
            a = (data[idx + 3] + data[idx1 + 3] + data[idx2 + 3] + data[idx3 + 3]) / 4
            idx = (x + y * small_surf.get_width()) * 4
            small_surf.get_data()[idx] = (int)(r)
            small_surf.get_data()[idx + 1] = (int)(g)
            small_surf.get_data()[idx + 2] = (int)(b)
            small_surf.get_data()[idx + 3] = (int)(a)

    small_surf.write_to_png("assets/images/generated/explode.png")


def main():
    white = color(1.0, 1.0, 1.0)
    player()
    # basic()
    stealth()
    ranged()
    explode()

    output_rounded_hexagon(19 * mul, 4 * mul, white, 1.0  * mul, "hexagon")
    output_rounded_hexagon(19 * mul, 4 * mul, white, 1.0  * mul, "small_hexagon")
    output_rounded_hexagon(19 * mul, 3 * mul, white, 1.6 * mul, "thick_small_hexagon")
    
    output_rounded_hexagon(14 * mul, 3 * mul, white, 0.0, "filled_hexagon")
    output_rounded_hexagon(8 * mul, 3 * mul, white, 0.0, "small_filled_hexagon")
    hexagon_progress_arc(5 * mul, white, "direction_indicator")
    #hexagon_progress_arc(8 * mul, white, "powerup")
    #rounded_hexagon(12 * mul, 4 * mul, white, 0.0, "pawn")
    
    output_rounded_triangles(3 * mul, 1 * mul, white, "triangle")
    output_rounded_rectangle(624 * mul, 16 * mul, 1 * mul, white, "bar")
    output_rounded_rectangle(624 * mul, 120 * mul, 1 * mul, white, "big_bar")
    output_rounded_rectangle(70 * mul, 16 * mul, 1 * mul, white, "menu_bg_bar")
    explosion(16 * mul, 16, white, "explosion")

# run the main function
main()
    
blobs()
blobs2()
