# Gravity by ROGUH

We'll use this metric to measure distances between two points $p=(x,y)$ in a Euclidean 2-D space:

$$ R(p_1, p_2) = \sqrt{(x_1 - x_2)^2 + (y_1 - y_2)^2} $$

Setting $G$ to a sensible value, the attraction between two points of different masses $M_1$ and $M_2$ is:

$$ F_G = \frac{G M_1 M_2}{R^2} $$

From $F = ma$ and $F_x/|F| = -x/r$, the acceleration in the horizontal direction x for point $p_1 = (x, y)$ with mass $M_1$ depends on the sum total of all forces from every other point $p_2$.

$$ a_x = F_x / M_1 = \sum_{p_2} \frac{xGM_2}{R(p, p_2)^3} $$



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


## Credits

Thank you, Dr. Feynman. You make math look fun.
