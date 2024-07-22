# Gravity by ROGUH

We'll use this metric for a Euclidean 2-D space:

$$ R(x_1, y_1, x_2, y_2) = \sqrt{(x_1 - x_2)^2 + (y_1 - y_2)^2} $$

Setting $G$ to a sensible value, the attraction between two points of different masses $M_1$ and $M_2$ is:

$$ F_G = \frac{G M_1 M_2}{R^2}              $$

From $F = ma$ and $F_x/|F| = -x/r$, the acceleration in the horizontal x direction is:

$$ a_x = F_x / m = \frac{xGM_2}{R^3}        $$

Thank you, Dr. Feynman. You make math look fun.

## Solar system

With suitable initial velocities and positions, we can somewhat accurately model the solar system with any modern computer or phone!

![This screenshot of the solar system simulation is the result of a few seconds of computation with only 380 lines of lua code.](./preview.png)

The planets start aligned horizontally with relative spacing 0.3, 0.7, 1.0, 1.5, 9.0, 19.0, and 30.0 in Astronomical Units (AU), as in real life (approx.). Initial velocity of each planet is directly related to its position from the Sun in AU units:

$$v_0 = v_{earth} / \sqrt{d_{au}}$$

where $v_{earth}$ is the known orbital velocity of the earth in our unit system (this depends on $G$ and on exact sizes used).


## How to use

Download the Lua Love2D runtime and point it at this folder:

```
love .
```

