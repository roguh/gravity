local pi = math.pi
local worldFactory = {}
worldFactory.edge = 1000
-- If changing boundaries, must adjust STABLE SOLUTIONS
worldFactory.bounds = {x=2000, y=2000}
worldFactory.MODES = {"8", "1", "random", "jovian"}
local INIT_MODE = 3 -- random
worldFactory.x_earth = worldFactory.bounds.x / 4

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

function worldFactory.randPoint(world)
    return math.floor(rand(1, #world.points))
end

function worldFactory.newPoint(params)
    local m=params.m or math.random()
    return {
        x=params.x or rand(worldFactory.bounds.x),
        y=params.y or rand(worldFactory.bounds.y),
        v=params.v or {x=0, y=0},
        m=m,
        initM=m,
        nearest=nil,
        p=params.p or nil,
    }
end

function worldFactory.initWorld(params)
    if not params then
        params = {}
    end
    local world = {
        points={},
        -- STABLE SOLUTIONS!
        G=100,
        settings={showLabels=false},
        pause=params.pause or false,
        mode=params.mode or INIT_MODE,
        dust=true,
        dustCount=params.dustCount or 200,
        center={byMass=1},
        -- Dynamically computed
        topByMass={},
        count={},
    }

    local i = 1
    -- STABLE SOLUTIONS! Don't ask "why 10"
    -- x0, y0 are sun's position
    local x0 = worldFactory.bounds.x / 2
    local y0 = worldFactory.bounds.y / 2
    -- Distance from the sun
    local x_earth = x0 / 2
    -- Distances are in AU, relative to x_earth
    local xp = {0.3, 0.7, 1, 1.5, 5, 9, 19, 30}
    -- Distance from earth in Au
    local xe_moon = 0.002569
    -- 29.78 km/s 66,616MPH
    local v_earth = 2500
    -- Relative to earth, 2,288 MPH MURICAAAAAAAAA
    local ve_moon = 2288 / 66616
    local m_earth = 10
    local m_moon = 0.012 * m_earth
    local m_asteroids = 0.03 * m_moon
    -- WHY 10?? adjust v_earth
    local m_sun = 300000 * m_earth * 10
    -- From Mercury to Pluto, skipping Ceres and the Moon
    local mp = {0.0553, 0.815, 1, 0.107, 317.8, 95.2, 14.5, 17.1, 0.0022}

    local function makeMoon()
        world.points[i] = worldFactory.newPoint({
            m=m_moon,
            x=x0 + x_earth * (1 + xe_moon),
            y=y0,
            v={x=0, y=(ve_moon + v_earth) / (1 + xe_moon) ^ 0.5}})
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
                local vNew = v_earth / xNew ^ 0.5
                world.points[i] = worldFactory.newPoint({
                    m=rand(0.01, 0.1),
                    x=x0 + x_earth * xNew,
                    y=y0,
                    v={x=0, y=vNew}})
                i = i + 1
            end
        end

        -- Planets (small mass)
        for _=1,planetCount do
            local xNew = rand(0.01, 50)
            local vNew = v_earth / xNew ^ 0.5
            world.points[i] = worldFactory.newPoint({m=rand(1, 100), x=x0 + x_earth * xNew, y=y0, v={x=0, y=vNew}})
            i = i + 1
        end

        world.center = {point=worldFactory.randPoint(world)}
    elseif mode == "1" then
        if params.centerEarth then
            world.center = {byMass=2}
        end

        world.points[i] = worldFactory.newPoint({m=m_earth, x=x0 + x_earth, y=y0, v={x=0, y=v_earth, p=3}})
        i = i + 1
        makeMoon()
    elseif mode == "8" then
        if params.centerEarth then
            -- Nth most massive object
            world.center = {byMass=6}
        end

        -- Dust rendered first, least important
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
                local v_dust = v_earth / x_dust ^ 0.5
                world.points[i] = worldFactory.newPoint({
                    -- PUNYYYYYYYYYY
                    m=rand(2) * m_asteroids / world.dustCount,
                    -- Between mars and jupiter
                    x=x0 + x_earth * x_dust * math.sin(dustAngle),
                    y=y0 + x_earth * x_dust * math.cos(dustAngle),
                    v={x=v_dust * math.sin(dustAngle - pi / 2), y=v_dust * math.cos(dustAngle - pi / 2)}
                })
                i = i + 1
            end
        end
        -- Planets (small mass)
        for p=1,8 do
            world.points[i] = worldFactory.newPoint({
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
    world.points[i] = worldFactory.newPoint({x=x0, y=y0, v={x=0, y=0}, m=m_sun, p=0})

    -- Center within world boundaries
    for _, p in pairs(world.points) do
        p.x = p.x + worldFactory.bounds.x * worldFactory.edge / 2
        p.y = p.y + worldFactory.bounds.y * worldFactory.edge / 2
    end

    print("Created world", worldFactory.MODES[world.mode], "G " .. world.G, "# " .. #world.points)

    return world
end


return worldFactory
