import matplotlib.pyplot as plt
from perlin_noise import PerlinNoise

noise = PerlinNoise(octaves=2, seed=1)
xpix, ypix = 100, 100
pic = [[noise([i/xpix * 2, j/ypix * 2]) for j in range(xpix)] for i in range(ypix)]

n0 = noise([1.342, 1.0])
print(n0)

n1 = noise([4.342, 1.0])
print(n1)

plt.imshow(pic, cmap='gray')
plt.show()