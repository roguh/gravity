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
-- TODO rotational momentum (how does this change w.r.t F_g?), hardcode for the 9 planets
-- TODO add a fuel-accurate starship?
-- TODO experiment with randomized system and higher merging rates
-- TODO draw trails to indicate velocity or direction; or strongest sources of gravity
-- TODO legend and scale ACCURATE (orbital AU and width shown on screen)
--      toggle accuracy (realistic size is too tiny!!!) (realistic luminance is too tiny)
-- TODO COMETS!!!!!!!!!!! hardcode Haley's? velocity?
-- TODO pan and zoom with phone
-- TODO pan with arrows and mouse
-- TODO pluto ceres makemake and the other dwarf planets

-- Import dependencies
local ButtonManager = require('external/Simple-Button/simplebutton')
local gamera = require("external/gamera/gamera")
local worldFactory = require("worldFactory")
local worldUpdate = require("worldUpdate")
local C = require("astronomicalConstants")

local cam = gamera.new(0, 0, C.bounds.x * C.edge, C.bounds.y * C.edge)

local buttons = {}
-- Button dimensions
local bH = 30
local bP = 20
local bW = 30

-- Scope
local handleEvent, begin

-- This stores most game state
local world = worldFactory.initWorld({mainMenu=true})

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

    ButtonManager.default.width = bW
    ButtonManager.default.height = bH
    ButtonManager.default.alignment = 'center'
    ButtonManager.default.fillType = 'line'
    ButtonManager.default.color = {1, 1, 1, 1}
    ButtonManager.default.textColor = {1, 1, 1, 1}

    -- Make sure replaced label is the same character count as initial label, self.setLabel is buggy
    buttons.start = ButtonManager.new("GO", love.graphics.getWidth() / 2, bP + bH)
    buttons.start.onClick = function()
        if world then
            handleEvent("r")
            return
        else
            -- In main menu, begin the simulation
            begin()
        end
    end
end

function begin()
    world = worldFactory.initWorld({})
    buttons.start:setLabel(" R")
    buttons.start.x = bP

    buttons.zoomIn = ButtonManager.new("+", 2 * bP + bW, (bP + bH) * 3)
    buttons.zoomIn.onClick = function()
        world.simState.zoom = "+"
    end
    buttons.zoomIn.onRelease = function()
        world.simState.zoom = nil
    end

    buttons.zoomOut = ButtonManager.new("-", 2 * bP + bW, (bP + bH) * 4)
    buttons.zoomOut.onClick = function()
        world.simState.zoom = "-"
    end
    buttons.zoomOut.onRelease = function()
        world.simState.zoom = nil
    end

    -- Button count
    local i = 2

    buttons.pause = ButtonManager.new("||", bP, (bP + bH) * i, bW * 2 + bP)
    buttons.pause.onClick = function() handleEvent("space") end

    buttons.step = ButtonManager.new(">>", bP + 2 * (bP + bW), (bP + bH) * i)
    buttons.step.onClick = function()
        world.simState.pause = true
        world.simState.fastForward = true
    end
    buttons.step.onRelease = function()
        world.simState.fastForward = false
    end
    i = i + 1

    buttons.label = ButtonManager.new("L", bP, (bP + bH) * i)
    buttons.label.onClick = function() handleEvent("l") end
    i = i + 1

    buttons.mode = ButtonManager.new("M", bP, (bP + bH) * i)
    buttons.mode.onClick = function() handleEvent("m") end
    i = i + 1

    for k=0,9 do
        local label = k == 0 and "Rnd" or (k .. "")
        buttons[label] = ButtonManager.new(
            label,
            bP + (bP + bW) * (k % 2),
            (i - math.ceil(k / 2)) * (bP + bH))
        buttons[label].onClick = function() handleEvent(k .. "") end
        i = i + 1
    end
end

function love.draw()
    if world.simState.mode == "main_menu" then
        -- Main menu
        love.graphics.print(
            "Welcome to GRAVITY!"
            .. " Press GO or any button to begin the simulation :)",
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
    if world.simState.pause then
        local msg = world.simState.fastForward and ">>" or "PAUSED"
        love.graphics.print(msg, 4 * (bW + bP), 50, 0, 4)
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
        --NOPE table.sort(world.count, function(a, b) return a and b and a.label > b.label end)
        for _, c in pairs(world.count) do
            -- TODO button width aligned
            love.graphics.print(string.format("10 ^ %4.1f: %d", c.label, c.count), 190, 60 + t * 16)
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

    local camscale = world.simState.zoom == "-" and 0.9
        or (world.simState.zoom == "+" and (1 / 0.9) or 1)
    cam:setScale(cam:getScale() * camscale)
end

function love.update(dt)
    if world.simState.mode == "main_menu" then
        return
    end
    if world.simState.pause and not world.simState.fastForward then
        adjustCamera()
        return
    end
    worldUpdate.worldUpdate(world, dt)
    adjustCamera()
end

handleEvent = function(key)
     print("Handling key", key)

     if key == "q" or key == "escape" then
        love.event.quit()
        return
     elseif key == "f" then
        love.window.setFullscreen(not love.window.getFullscreen())
        return
     end

     -- Main menu
    if world.simState.mode == "main_menu" then
        -- Start simulation when any key is pressed
        begin()
        return
     end

     if key == "=" then
        key = "+"
     end
     if key == "+" or key == "-" then
        world.simState.zoom = key
     end
     if key == "r" then
        world = worldFactory.initWorld({mode=world.mode, pause=world.simState.pause})
     end
     if key == "l" then
        world.settings.showLabels = not world.settings.showLabels
     end
     if key == "space" then
        world.simState.pause = not world.simState.pause
     end
     if key == "s" then
        world.simState.pause = true
        world.simState.fastForward = true
     end
     if key == "m" then
        local newMode = ((world.mode + 2) % #worldFactory.MODES) + 1
        world = worldFactory.initWorld({mode=newMode, pause=true})
     end
     -- Digits 1 to 9
     if tonumber(key) and tonumber(key) < 10 then
        world.center = {byMass=tonumber(key)}
     end
     if key == "0" then
        world.center = {point=worldFactory.randPoint(world)}
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
    if world.simState.mode == "main_menu" then
        -- Centered main menu
        for _, button in pairs(buttons) do
            button.x = w / 2
        end
    end
    cam:setWindow(0, 0, w, h)
end

function love.mousepressed(x, y, msbutton, _istouch, _presses)
    if world.simState.mode == "main_menu" then
        begin()
    else
        local changes = ButtonManager.mousepressed(x, y, msbutton)
        if not changes and world.simState.pause then
            world.simState.pause = false
        end
    end
end

function love.mousereleased(x, y, msbutton, _istouch, _presses)
    ButtonManager.mousereleased(x, y, msbutton)
end

function love.keypressed(key, _unicode)
    handleEvent(key)
end

function love.keyreleased(key, _unicode)
    if key == "s" then
        world.simState.fastForward = false
    end
     if key == "=" then
        key = "+"
     end
     if key == "+" or key == "-" then
        world.simState.zoom = nil
     end
end
