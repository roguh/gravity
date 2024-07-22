-- ROGUH 2024
--      made by human hands
-- Simple Solar System simulation in Love2D.lua
-- No attempt made at accurate differential equation solver, Mercury's orbit is especially unstable



-- TODOS are in order of perceived difficulty:
-- TODO hyperbolic space is ez, just add -t^2
-- TODO 3D
-- TODO galaxy spirals and galaxy collisions
-- TODO recognizable planet shapes and colors?
-- TODO MOOOOOOOOOOOOOON
-- TODO Jovian lunar system with resonance
-- TODO when asteroids start in one point, they perturb Mercury and send it flying away
-- TODO higher accuracy differential equations solver
-- TODO 3D view all head on!!!! like our night sky
-- TODO experiment with randomized system and higher merging rates
-- TODO legend and scale ACCURATE (orbital AU and width shown on screen)
--      toggle accuracy (realistic size is too tiny!!!) (realistic luminance is too tiny)
-- TODO COMETS!!!!!!!!!!!
-- TODO UI buttons
-- TODO pan and zoom with phone
-- TODO pan with arrows and mouse

local pi = math.pi
local gamera = require("external/gamera")
local world
local edge = 1000
-- If changing these, must adjust STABLE SOLUTIONS
local max = {x=2000, y=2000}
local cam = gamera.new(0, 0, max.x * edge, max.y * edge)
local isDown = love.keyboard.isDown
local MODES = {"8", "1", "random", "jovian"}
local INIT_MODE = 1

function love.load()
    print("Welcome to gravity by ROGUH")
    print("Version:", _VERSION)
    love.graphics.setDefaultFilter( 'nearest', 'nearest' )
    h = 800
    w = 800 * (.5 + 5 ^ .5 * .5)
    love.window.setMode(w, h, {resizable=true, centered=true})
    love.window.setTitle("GRAVITY")
    cam:setWindow(0, 0, w, h)
    cam:setScale(0.25)

    initWorld({mode=INIT_MODE})
end

function rand(a, b)
    -- Uniformly distributed between a and b
    -- default: a=0 b=1 or a=0 b=a if a+b or b are missing
    if not b then
        b = a
        a = 0
    end
    if not b then
        b = 1
    end
    return math.random() * (b - a) + a
end

function normal01()
    -- Normally distributed random number with distribution centered on 0.5
    -- box-muller method
    local u = math.random()
    local v = math.random()
    local r = (-2.0 * math.log10(u)) ^ 0.5 * math.cos(2.0 * math.pi * v)
    r = r / 4
    r = r + 0.5
    return r
end

function randPoint()
    return math.floor(rand(1, #world.points))
end

function newPoint(params)
    m=params.m or math.random()
    return {
        x=params.x or rand(max.x),
        y=params.y or rand(max.y),
        v=params.v or {x=0, y=0},
        m=m,
        initM=m,
        nearest=nil,
        p=params.p or nil,
    }
end

function initWorld(params)
    if not params then
        params = {}
    end
    D = 200
    world = {
        points={},
        G=100,
        settings={showLabels=false},
        pause=params.pause or false,
        mode=params.mode or INIT_MODE,
        dust=true,
        center={byMass=1},
        -- Dynamically computed
        topByMass={},
        count={},
    }

    i = 1
    -- STABLE SOLUTIONS! Don't ask "why 10"
    -- x0, y0 are sun's position
    x0 = max.x / 2
    y0 = max.y / 2
    -- Distance from the sun
    x_earth = x0 / 2
    -- Distances are in AU, relative to x_earth
    xp = {0.3, 0.7, 1, 1.5, 5, 9, 19, 30}
    -- Distance from earth in Au
    xe_moon = 0.002569
    -- 29.78 km/s 66,616MPH
    v_earth = 2500
    -- Relative to earth, 2,288 MPH MURICAAAAAAAAA
    ve_moon = 2288 / 66616
    m_earth = 10
    m_moon = 0.012 * m_earth
    m_asteroids = 0.03 * m_moon
    m_sun = 300000 * m_earth
    -- From Mercury to Pluto, skipping Ceres and the Moon
    mp = {0.0553, 0.815, 1, 0.107, 317.8, 95.2, 14.5, 17.1, 0.0022}

    function makeMoon()
        world.points[i] = newPoint({
            m=m_moon,
            x=x0 + x_earth * (1 + xe_moon),
            y=y0,
            v={x=0, y=(ve_moon + v_earth) / (1 + xe_moon) ^ 0.5}})
        i = i + 1
    end

    -- Convert int to string
    mode = MODES[world.mode]
    if mode == "random" then
        -- Number of planets
        N = 50
        if world.dust then
            -- Dust!!!
            for _=1,D do
                x_new = rand(0.01, 50)
                v_new = v_earth / x_new ^ 0.5
                world.points[i] = newPoint({m=rand(0.01, 0.1), x=x0 + x_earth * x_new, y=y0, v={x=0, y=v_new}})
                i = i + 1
            end
        end
        
        -- Planets (small mass)
        for _=1,N do
            x_new = rand(0.01, 50)
            v_new = v_earth / x_new ^ 0.5
            world.points[i] = newPoint({m=rand(1, 100), x=x0 + x_earth * x_new, y=y0, v={x=0, y=v_new}})
            i = i + 1
        end

        world.center = {point=randPoint()}
    elseif mode == "1" then
        if params.centerEarth then
            world.center = {byMass=2}
        end

        world.points[i] = newPoint({m=m_earth, x=x0 + x_earth, y=y0, v={x=0, y=v_earth, p=3}})
        i = i + 1
        makeMoon()
    elseif mode == "8" then
        if params.centerEarth then
            -- Nth most massive object
            world.center = {byMass=6}
        end

        -- Dust rendered first, least important
        if world.dust then
            for _=1,D do
                -- Between Mars and Jupiter at 2.2 to 3.2 AU
                -- x_dust = rand(2.2, 3.2)
                x_dust = 2 * normal01() + 2.7
                is_wild = rand() > 0.8
                if is_wild then
                    x_dust = rand(2.2, 50)
                end
                dust_angle = rand(0, 2 * pi)
                v_dust = v_earth / x_dust ^ 0.5
                world.points[i] = newPoint({
                    -- PUNYYYYYYYYYY
                    m=rand(2) * m_asteroids / D,
                    -- Between mars and jupiter
                    x=x0 + x_earth * x_dust * math.sin(dust_angle),
                    y=y0 + x_earth * x_dust * math.cos(dust_angle),
                    v={x=v_dust * math.sin(dust_angle - pi / 2), y=v_dust * math.cos(dust_angle - pi / 2)}
                })
                i = i + 1
            end
        end
        -- Planets (small mass)
        for p=1,8 do
            world.points[i] = newPoint({
                -- Earth is about m=10
                m=m_earth * mp[p],
                x=(x0 + xp[p] * x_earth),
                y=y0,
                v={x=0, y=v_earth / xp[p] ^ 0.5},
                p=p,
            })
            i = i + 1
        end
        -- why u no stayyy
        -- makeMoon()
    end
    
    -- Sun
    world.points[i] = newPoint({x=x0, y=y0, v={x=0, y=0}, m=m_sun * 10, p=0})
    
    -- Center within world boundaries
    for i, p in pairs(world.points) do
        p.x = p.x + max.x * edge / 2
        p.y = p.y + max.y * edge / 2
    end

    print("Starting world", MODES[world.mode], "G " .. world.G, "# " .. #world.points)
end

function love.draw()
cam:draw(
function (l, t, w, h)
    for i, p in pairs(world.points) do
    if p.m > 0 then
        if p.m <= 0.5 then
            love.graphics.setColor(64, 255, 255)
        elseif p.m <= 10 then
            love.graphics.setColor(0, 64 + 196 * (p.m / 10), 64)
        else
            love.graphics.setColor(255, 0, 0)
        end
        r = nil
        if p.m > 5000 then
            r = 120
            love.graphics.setColor(196, 196, 0)
            love.graphics.circle("fill", p.x, p.y, r, 40)
        else
            r = math.max(5, 3 * p.m ^ 0.5)
            love.graphics.circle("fill", p.x, p.y, r, 40)
        end
        -- Jove or Saturn
        if p.p == 5 or p.p == 6 then
            for i=1,6 do
                love.graphics.setColor(64 + math.random() * 128, math.random() * 64, 64)
                love.graphics.circle("line", p.x, p.y, r * (1.05 + 0.05 * i / 6), 40)
            end
        end
        if world.settings.showLabels then
            love.graphics.setColor(255, 255, 255)
            love.graphics.print(string.format(
                    "%d %.4fME  %.1fAU",
                    i - D, p.m / m_earth, p.nearest or 0
                ), 15 + r + p.x, p.y, 0, 2)
        end
    end
    end

end)
    love.graphics.setColor(255, 255, 255)
    if world.pause then
        love.graphics.print("PAUSE (press SPACE or C)", 50, 50, 0, 4)
    end

    love.graphics.print(
        "GRAVITY  f: fullscreen  space: pause  c: step"
        .. "  m: mode(" .. MODES[world.mode] .. ")"
        .. "  0-9: pick by mass (" .. (world.center.byMass or "n/a") ..")",
        10, 10
    )
    t = 0
    if world.settings.showLabels then
        for i, c in pairs(world.count) do
            love.graphics.print(c.label .. " " .. c.count, 100, 100 + t * 16)
            t = t + 1
        end
    end
end

function adjustCamera()
    if world.center.point then
        -- Pick random center
        c = world.center.point
    elseif world.center.byMass then
        -- If integer, pick N-th most massive object
        c = world.topByMass[world.center.byMass]
    else
        -- usually the last object is the sun
        c = #world.points
    end
    center = world.points[c]
    if not center then
        center = world.points[#world.points]
    end
    cam:setPosition(center.x, center.y)
    camscale = isDown("down") and 0.9 or (isDown("up") and (1 / 0.9) or 1)
    cam:setScale(cam:getScale() * camscale)
end

function love.update(dt)
    if world.pause and not isDown("c") then
        adjustCamera()
        return
    end
    for i, p in pairs(world.points) do
    if (p.m > 0.0000001) then
        for t=1,9 do
            -- Find top 9 most massive objects
            T = world.topByMass[t]
            if p.m >= (T and world.points[T].m or 0) then
                world.topByMass[t] = i
                break
            end
        end
        -- Count by mass
        cat = math.floor(math.log10(p.m))
        world.count[cat + 5] = {count=(world.count[cat + 5] or {count=0}).count + 1, label=cat}
        for j, p2 in pairs(world.points) do
            if (i ~= j) then
                -- Force of gravity: F = G M_1 M_2 / R^2
                -- F / m_1 = a_1
                r = ((p.x - p2.x) ^ 2 + (p.y - p2.y) ^ 2) ^ (1/2)
                if r > 0.00000001 then
                    -- r = sqrt(x^2 + y^2)
                    -- ma = -GMmx/r^3
                    a = -world.G * p2.m / r ^ 3
                else
                    a = 0
                end
                p.v.x = p.v.x + dt * a * (p.x - p2.x)
                p.v.y = p.v.y + dt * a * (p.y - p2.y)

                -- Merge a bit if too close
                if p2.m > 5000 then
                    p.nearest = r / x_earth
                end
                if r < 1 and p.m > p2.m then
                    p.m = p.m + p2.m / 2
                    p2.m = p2.m / 2
                    -- print("merge", i, j)
                end
            end
        end
        p.x = p.x + dt * p.v.x
        p.y = p.y + dt * p.v.y
    else
        -- RIP
        p.m = 0
        p.v.x = 0
        p.v.y = 0
        -- print("death", i)
    end
    end
    adjustCamera()
end

function love.keypressed(key, unicode)
     if key == "f" then
        love.window.setFullscreen(not love.window.getFullscreen())
     end
     if key == "r" then
        initWorld({mode=world.mode, pause=world.pause})
     end
     if key == "l" then
        world.settings.showLabels = not world.settings.showLabels 
     end
     if key == "space" then
        world.pause = not world.pause
     end
     if key == "m" then
        newMode = ((world.mode + 2) % #MODES) + 1
        initWorld({mode=newMode, pause=true})
     end
     -- Digits 1 to 9
     if tonumber(key) and tonumber(key) < 10 then
        world.center = {byMass=tonumber(key)}
        if world.center == 1 then
            cam:setScale(0.25)
        else
            cam:setScale(2)
        end
     end
     if key == "0" then
        world.center = {point=randPoint()}
        cam:setScale(0.25)
     end
end

function love.wheelmoved(x, y)
    if y > 0 then
        cam:setScale(cam:getScale() / 0.9)
    elseif y < 0 then
        cam:setScale(cam:getScale() * 0.9)
    end
end

function love.resize(w, h)
    cam:setWindow(0, 0, w, h)
end
