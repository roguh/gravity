local C = {}

C.edge = 1000
-- If changing boundaries, must adjust STABLE SOLUTIONS
C.bounds = {x=2000, y=2000}
C.x_earth = C.bounds.x / 4

-- STABLE SOLUTIONS! Don't ask "why 10"
-- C.x0, C.y0 are sun's position
C.x0 = C.bounds.x / 2
C.y0 = C.bounds.y / 2
-- Distance from the sun
C.x_earth = C.x0 / 2
-- Distances are in AU, relative to C.x_earth
C.xp = {0.3, 0.7, 1, 1.5, 5, 9, 19, 30}
-- Distance from earth in Au
C.xe_moon = 0.002569
-- 29.78 km/s 66,C.616MPH
C.v_earth = 2500
-- Relative to earth, 2,288 C.MPH MURICAAAAAAAAA
C.ve_moon = 2288 / 66616
C.m_earth = 10
C.m_moon = 0.012 * C.m_earth
C.m_asteroids = 0.03 * C.m_moon
-- WHY 10?? adjust C.v_earth
C.m_sun = 300000 * C.m_earth * 10
-- From Mercury to Pluto, skipping Ceres and the Moon
C.mp = {0.0553, 0.815, 1, 0.107, 317.8, 95.2, 14.5, 17.1, 0.0022}

return C
