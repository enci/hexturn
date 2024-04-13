from tools import hermite

# draw hermite curve using mathplotlib

import matplotlib.pyplot as plt

a = 0.0
b = 0.0
c = 1.0
d = 0.0

x = []
y = []

for i in range(0, 100):
    t = i / 100.0
    x.append(t)
    y.append(hermite(a, b, c, d, t))

plt.plot(x, y)
plt.show()