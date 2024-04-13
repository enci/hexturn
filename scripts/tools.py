import math
import random

class vec2:
    def __init__(self, x:float, y:float) -> None:
        self.x = x
        self.y = y

    def __add__(self, other):
        return vec2(self.x + other.x, self.y + other.y)
    
    def __sub__(self, other):
        return vec2(self.x - other.x, self.y - other.y)
    
    def __mul__(self, value:float):
        return vec2(self.x * value, self.y * value)
    
    def magnitude(self) -> float:
        return math.sqrt(self.x**2 + self.y**2)
    
    def normalize(self) -> None:
        m = self.magnitude()
        self.x /= m
        self.y /= m
    
    def normalized(self):
        m = self.magnitude()
        return vec2(self.x / m, self.y / m)

    def __str__(self) -> str:
        return "[{},{}]".format(self.x, self.y)
    
class color:
    def __init__(self, r : float, g : float,  b : float, a : float = 1.0):
        self.r = r
        self.g = g
        self.b = b
        self.a = a

    def from_hex(hex : int):
        r = (float)((hex >> 24) & 0xFF) / 255.0
        g = (float)((hex >> 16) & 0xFF) / 255.0
        b = (float)((hex >> 8) & 0xFF) / 255.0
        a = (float)(hex & 0xFF) / 255.0
        return color(r, g, b, a)
    
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

def hermite(a: float, b: float, c: float, d: float, t: float):
    tt = t * t
    ttt = tt * t
    return (2.0 * ttt - 3.0 * tt + 1.0) * a + (ttt - 2.0 * tt + t) * b + (-2.0 * ttt + 3.0 * tt) * c + (ttt - tt) * d

def smoothstep(a: float, b: float, t: float):
    t = clamp(0.0, 1.0, inv_lerp(a, b, t))
    return t * t * (3.0 - 2.0 * t)

def smootherstep(a: float, b: float, t: float):
    t = clamp(0.0, 1.0, inv_lerp(a, b, t))
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
