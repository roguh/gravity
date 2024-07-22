# Gravity by ROGUH

Every planet is modeled as a point in 2D space, $p=(x,y)$.

We'll use this distance metric to measure distances between two points $p_1=(x_1, y_1)$ and $p_2=(x_2, y_2)$ in a two dimensional Euclidean space:

$$ R(p_1, p_2) = \sqrt{(x_1 - x_2)^2 + (y_1 - y_2)^2} $$

Where $G$ is a sensible constant, the gravitational attraction (aka force) between two points of different masses $M_1$ and $M_2$ depends on the inverse square of their distance:

$$ F = \frac{G M_1 M_2}{R^2} $$

From Newton's 2nd law $F = ma$ and some trigonometry $F_x/|F| = -x/r$, we can find the acceleration in the horizontal direction for point $p = (x, y)$ with mass $M_1$:

$$ a_x = F_x / M_1 = \sum_{p_2} \frac{xGM_2}{R(p, p_2)^3} $$

The $\sum$ is a symbol that means we will use a for loop to **sum** the force from every other point $p_2$.

```
for p2 in points:
    if p == p2:
        continue
    a_x += G * x * p2.M / distance(p, p2)**3
```

Once the acceleration is found, we can use these equations to find how much to adjust the position $x$ and velocity $v$ of point $p$:

$$v' = v + a_x \cdot dt$$
$$x' = x + v_x \cdot dt$$

Here, $dt$ represents the tiny amount of time that has passed.

With modern computers, we can run this upate step many times per second to get good accuracy.
Then $dt$ will be fairly small at perhaps 1/60th of a second, also known as your frames per second (FPS).

We can do the same in the vertical direction $y$.


Unfortunately, the accuracy of this simple method is not enough and Mercury's orbit collapses far too quickly. Earth's orbit also varies too much between 1.0AU and 1.1AU, when these things have been stable for millenia!
Still, this is a good start to the simulation.


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
