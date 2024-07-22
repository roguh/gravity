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

local gamera = require("external/gamera")
local worldFactory = require("worldFactory")

local cam = gamera.new(0, 0, worldFactory.bounds.x * worldFactory.edge, worldFactory.bounds.y * worldFactory.edge)
local isDown = love.keyboard.isDown

-- This stores most game state
local world

function love.load()
    print("Welcome to gravity by ROGUH")
    print("Version:", _VERSION)
    love.graphics.setDefaultFilter( 'nearest', 'nearest' )
    local h = 800
    local w = 800 * (.5 + 5 ^ .5 * .5)
    love.window.setMode(w, h, {resizable=true, centered=true})
    love.window.setTitle("GRAVITY")
    cam:setWindow(0, 0, w, h)
    cam:setScale(0.25)

    world = worldFactory.initWorld({})
end

function love.draw()
cam:draw(
function (_l, _t, _w, _h)
    for i, p in pairs(world.points) do
    if p.m > 0 then
        if p.m <= 0.5 then
            love.graphics.setColor(64, 255, 255)
        elseif p.m <= 10 then
            love.graphics.setColor(0, 64 + 196 * (p.m / 10), 64)
        else
            love.graphics.setColor(255, 0, 0)
        end
        local r
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
            for j=1,6 do
                love.graphics.setColor(64 + math.random() * 128, math.random() * 64, 64)
                love.graphics.circle("line", p.x, p.y, r * (1.05 + 0.05 * j / 6), 40)
            end
        end
        if world.settings.showLabels then
            love.graphics.setColor(255, 255, 255)
            love.graphics.print(string.format(
                    "%d %.4fME  %.1fAU",
                    -- TODO mass of earth=10
                    i - world.dustCount, p.m / 10, p.nearest or 0
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
        .. "  m: mode(" .. worldFactory.MODES[world.mode] .. ")"
        .. "  0-9: pick by mass (" .. (world.center.byMass or "n/a") ..")",
        10, 10
    )
    local t = 0
    if world.settings.showLabels then
        for _, c in pairs(world.count) do
            love.graphics.print(c.label .. " " .. c.count, 100, 100 + t * 16)
            t = t + 1
        end
    end
end

local function adjustCamera()
    local c
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
    local center = world.points[c]
    if not center then
        center = world.points[#world.points]
    end
    cam:setPosition(center.x, center.y)

    local camscale = isDown("down") and 0.9 or (isDown("up") and (1 / 0.9) or 1)
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
            local T = world.topByMass[t]
            if p.m >= (T and world.points[T].m or 0) then
                world.topByMass[t] = i
                break
            end
        end
        -- Count by mass
        local cat = math.floor(math.log10(p.m))
        world.count[cat + 5] = {count=(world.count[cat + 5] or {count=0}).count + 1, label=cat}
        for j, p2 in pairs(world.points) do
            if (i ~= j) then
                -- Force of gravity: F = G M_1 M_2 / R^2
                -- F / m_1 = a_1
                local r = ((p.x - p2.x) ^ 2 + (p.y - p2.y) ^ 2) ^ (1/2)
                local a = 0
                if r > 0.00000001 then
                    -- r = sqrt(x^2 + y^2)
                    -- ma = -GMmx/r^3
                    a = -world.G * p2.m / r ^ 3
                end
                p.v.x = p.v.x + dt * a * (p.x - p2.x)
                p.v.y = p.v.y + dt * a * (p.y - p2.y)

                -- Find distance to sun
                if p2.m > 5000 then
                    p.nearest = r / worldFactory.x_earth
                end
                -- Merge a bit if too close
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

function love.keypressed(key, _unicode)
     if key == "f" then
        love.window.setFullscreen(not love.window.getFullscreen())
     end
     if key == "r" then
        world = worldFactory.initWorld({mode=world.mode, pause=world.pause})
     end
     if key == "l" then
        world.settings.showLabels = not world.settings.showLabels
     end
     if key == "space" then
        world.pause = not world.pause
     end
     if key == "m" then
        local newMode = ((world.mode + 2) % #worldFactory.MODES) + 1
        world = worldFactory.initWorld({mode=newMode, pause=true})
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
        world.center = {point=worldFactory.randPoint(world)}
        cam:setScale(0.25)
     end
end

function love.wheelmoved(_x, y)
    if y > 0 then
        cam:setScale(cam:getScale() / 0.9)
    elseif y < 0 then
        cam:setScale(cam:getScale() * 0.9)
    end
end

function love.resize(w, h)
    cam:setWindow(0, 0, w, h)
end
