local C = require("astronomicalConstants")

local pi = math.pi
local worldFactory = {}
worldFactory.MODES = {"8", "1", "random", "jovian"}
local INIT_MODE = 3 -- random

local function rand(a, b)
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

local function normal01()
    -- Normally distributed random number with distribution centered on 0.5
    -- box-muller method
    local u = math.random()
    local v = math.random()
    local r = (-2.0 * math.log10(u)) ^ 0.5 * math.cos(2.0 * math.pi * v)
    r = r / 4
    r = r + 0.5
    return r
end

function worldFactory.initWorld(params)
    if not params then
        params = {}
    end
    if params.mainMenu then
        return {simState={mode="main_menu"}}
    end
    local world = {
        points={},
        -- STABLE SOLUTIONS!
        G=100,
        settings={showLabels=false},
        simState={pause=params.pause or false, fastForward=false, mode="simulation", zoom=nil},
        mode=params.mode or INIT_MODE,
        dust=true,
        dustCount=params.dustCount or 200,
        center={byMass=1},
        -- Dynamically C.computed
        topByMass={},
        count={},
    }

    local i = 1

    local function makeMoon()
        world.points[i] = worldFactory.newPoint({
            m=C.m_moon,
            x=C.x0 + C.x_earth * (1 + C.xe_moon),
            y=C.y0,
            v={x=0, y=(C.ve_moon + C.v_earth) / (1 + C.xe_moon) ^ 0.5}})
        i = i + 1
    end

    -- Convert int to string
    local mode = worldFactory.MODES[world.mode]
    if mode == "random" then
        -- Number of planets
        local planetCount = 50
        if world.dust then
            -- Dust!!!
            for _=1,world.dustCount do
                local xNew = rand(0.01, 50)
                local vNew = C.v_earth / xNew ^ 0.5
                world.points[i] = worldFactory.newPoint({
                    m=rand(0.01, 0.1),
                    x=C.x0 + C.x_earth * xNew,
                    y=C.y0,
                    v={x=0, y=vNew}})
                i = i + 1
            end
        end

        -- Planets (small mass)
        for _=1,planetCount do
            local xNew = rand(0.01, 50)
            local vNew = C.v_earth / xNew ^ 0.5
            world.points[i] = worldFactory.newPoint({
                m=rand(1, 100),
                x=C.x0 + C.x_earth * xNew,
                y=C.y0,
                v={x=0, y=vNew}})
            i = i + 1
        end

        world.center = {point=worldFactory.randPoint(world)}
    elseif mode == "1" then
        if params.centerEarth then
            world.center = {byMass=2}
        end

        world.points[i] = worldFactory.newPoint({m=C.m_earth, x=C.x0 + C.x_earth, y=C.y0, v={x=0, y=C.v_earth, p=3}})
        i = i + 1
        makeMoon()
    elseif mode == "8" then
        if params.centerEarth then
            -- Nth most massive object
            world.center = {byMass=6}
        end

        -- Dust rendered first, least C.important
        if world.dust then
            for _=1,world.dustCount do
                -- Between Mars and Jupiter at 2.2 to 3.2 AU
                -- x_dust = rand(2.2, 3.2)
                local x_dust = 2 * normal01() + 2.7
                local is_wild = rand() > 0.8
                if is_wild then
                    x_dust = rand(2.2, 50)
                end
                local dustAngle = rand(0, 2 * pi)
                local v_dust = C.v_earth / x_dust ^ 0.5
                world.points[i] = worldFactory.newPoint({
                    -- PUNYYYYYYYYYY
                    m=rand(2) * C.m_asteroids / world.dustCount,
                    -- Between mars and jupiter
                    x=C.x0 + C.x_earth * x_dust * math.sin(dustAngle),
                    y=C.y0 + C.x_earth * x_dust * math.cos(dustAngle),
                    v={x=v_dust * math.sin(dustAngle - pi / 2), y=v_dust * math.cos(dustAngle - pi / 2)}
                })
                i = i + 1
            end
        end
        -- Planets (small mass)
        for p=1,8 do
            world.points[i] = worldFactory.newPoint({
                -- Earth is about m=10
                m=C.m_earth * C.mp[p],
                x=(C.x0 + C.xp[p] * C.x_earth),
                y=C.y0,
                v={x=0, y=C.v_earth / C.xp[p] ^ 0.5},
                p=p,
            })
            i = i + 1
        end
        -- why u no stayyy
        -- makeMoon()
    end

    -- Sun
    world.points[i] = worldFactory.newPoint({x=C.x0, y=C.y0, v={x=0, y=0}, m=C.m_sun, p=0})

    -- Center within world boundaries
    for _, p in pairs(world.points) do
        p.x = p.x + C.bounds.x * C.edge / 2
        p.y = p.y + C.bounds.y * C.edge / 2
    end

    print("Created world", worldFactory.MODES[world.mode], "G " .. world.G, "# " .. #world.points)

    return world
end

function worldFactory.randPoint(world)
    return math.floor(rand(1, #world.points))
end

function worldFactory.newPoint(params)
    local m=params.m or math.random()
    return {
        x=params.x or rand(C.bounds.x),
        y=params.y or rand(C.bounds.y),
        v=params.v or {x=0, y=0},
        m=m,
        initM=m,
        nearest=nil,
        p=params.p or nil,
    }
end


return worldFactory
