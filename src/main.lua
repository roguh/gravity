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
-- TODO draw trails to indicate velocity or direction
-- TODO legend and scale ACCURATE (orbital AU and width shown on screen)
--      toggle accuracy (realistic size is too tiny!!!) (realistic luminance is too tiny)
-- TODO COMETS!!!!!!!!!!!
-- TODO pan and zoom with phone
-- TODO pan with arrows and mouse

-- Import dependencies
local ButtonManager = require('external/simplebutton')
local gamera = require("external/gamera")
local worldFactory = require("worldFactory")

local handleEvent
local cam = gamera.new(0, 0, worldFactory.bounds.x * worldFactory.edge, worldFactory.bounds.y * worldFactory.edge)
local isDown = love.keyboard.isDown

local buttons = {}

-- This stores most game state
local world = nil

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

    local bH = 30
    local bP = 20
    ButtonManager.default.width = 60
    ButtonManager.default.height = bH
    ButtonManager.default.alignment = 'center'
    ButtonManager.default.fillType = 'line'
    ButtonManager.default.color = {1, 1, 1, 1}
    ButtonManager.default.textColor = {1, 1, 1, 1}

    -- Make sure replaced label is the same character count as initial label, self.setLabel is buggy
    buttons.start = ButtonManager.new("START", love.graphics.getWidth() / 2, bP + bH)
    buttons.start.onClick = function()
        if world then
            handleEvent("r")
            return
        end

        world = worldFactory.initWorld({})
        buttons.start:setLabel(" NEW ")
        buttons.start.x = 15

        buttons.zoomIn = ButtonManager.new("+", 3 * 15 + 60, (bP + bH) * 2)
        buttons.zoomIn.onClick = function() handleEvent("+") end

        buttons.zoomOut = ButtonManager.new("-", 3 * 15 + 60, (bP + bH) * 3)
        buttons.zoomOut.onClick = function() handleEvent("-") end

        -- Button count
        -- Button count
        local i = 2

        buttons.pause = ButtonManager.new("PAUSE", 15, (bP + bH) * i)
        buttons.pause.onClick = function() handleEvent("space") end
        i = i + 1

        buttons.mode = ButtonManager.new("M", 15, (bP + bH) * i)
        buttons.mode.onClick = function() handleEvent("m") end
        i = i + 1

        -- BUG MINE FIELD!!!!!!!!!
        -- rework the step event
        local X = false
        buttons.step = ButtonManager.new("C", 15, (bP + bH) * i)
        buttons.step.onClick = function() handleEvent("space") ; X = true end
        buttons.step.onRelease = function() if X then handleEvent("space") end end
        i = i + 1

        for k=0,9 do
            local label = k == 0 and "random" or (k .. "")
            buttons[label] = ButtonManager.new(label, 15, (bP + bH) * i)
            buttons[label].onClick = function() handleEvent(k .. "") end
            i = i + 1
        end

    end
end

function love.draw()
    if not world then
        love.graphics.print(
            "Welcome to GRAVITY!"
            .. " Press the button below to start the simulation :)",
            10, 10, 0, 1.3)
        ButtonManager.draw()
        return
    end

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
        -- TODO m_earth
        -- Draw sun or huge object
        if p.p == 0 or p.m > 10000 then
            r = 120
            -- Sun's temperature is 5500 celsius
            -- Color is from https://andi-siess.de/rgb-to-color-temperature/
            love.graphics.setColor(255, 236, 224)
            love.graphics.circle("fill", p.x, p.y, r, 40)
        else
            r = math.max(10, 20 * p.m ^ 0.4)
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
                ), 15 + r + p.x, p.y, 0, 1)
        end
    end
    end

end)
    love.graphics.setColor(255, 255, 255)
    if world.pause then
        love.graphics.print("PAUSE", 100, 100, 0, 4)
    end

    love.graphics.print(
           "  m: mode(" .. worldFactory.MODES[world.mode] .. ")"
        .. "  0-9: pick by mass (" .. (world.center.byMass or "n/a") ..")"
        .. "  f: fullscreen  space: pause"
        .. "  c: step  r: start anew"
        ,
        10, 10, 0, 1.3
    )
    local t = 0
    if world.settings.showLabels then
        for _, c in pairs(world.count) do
            love.graphics.print(c.label .. " " .. c.count, 100, 100 + t * 16)
            t = t + 1
        end
    end

    ButtonManager.draw()
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
    if not world then
        return
    end
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

handleEvent = function(key)
     print("Handling key", key)

     if key == "q" or key == "escape" then
        love.event.quit()
     end
     if key == "f" then
        love.window.setFullscreen(not love.window.getFullscreen())
     end

     -- Main menu
     if not world then
        return
     end

     if key == "+" then
        cam:setScale(cam:getScale() / 0.8)
     end
     if key == "-" then
        cam:setScale(cam:getScale() * 0.8)
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
        -- TODO if velocity too large, pause
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
        cam:setScale(cam:getScale() / 0.93)
    elseif y < 0 then
        cam:setScale(cam:getScale() * 0.93)
    end
end

function love.resize(w, h)
    if not world then
        -- Centered main menu
        for _, button in pairs(buttons) do
            button.x = w / 2
        end
    end
    cam:setWindow(0, 0, w, h)
end

function love.mousepressed(x, y, msbutton, _istouch, _presses)
    ButtonManager.mousepressed(x, y, msbutton)
end

function love.mousereleased(x, y, msbutton, _istouch, _presses)
    ButtonManager.mousereleased(x, y, msbutton)
end

function love.keypressed(key, _unicode)
    handleEvent(key)
end

