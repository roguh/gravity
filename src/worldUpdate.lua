local worldUpdate = {}

local astronomicalConstants = require("astronomicalConstants")

function worldUpdate.findForce(G, p, p2)
    -- Force of gravity: F = G M_1 M_2 / R^2
    -- F / m_1 = a_1
    local r = ((p.x - p2.x) ^ 2 + (p.y - p2.y) ^ 2) ^ (1/2)
    local a = 0
    if r > 0.00000001 then
        -- r = sqrt(x^2 + y^2)
        -- ma = -GMmx/r^3
        a = -G * p2.m / r ^ 3
    end
    local ax = a * (p.x - p2.x)
    local ay = a * (p.y - p2.y)
    return ax, ay, r
end

function worldUpdate.worldUpdate(world, dt)
    -- If dt is too high, then run extra iterations to prevent instability
    world.simState.totalTime = world.simState.totalTime + dt
    world.simState.fps = 1 / dt
    local minFPS = 120
    local F = dt / (1 / minFPS)
    local subUpdates = math.max(1, math.min(10, math.ceil(F)))
    dt = dt / subUpdates
    if subUpdates > 3 and math.floor(100 * world.simState.totalTime) % 100 == 0 then
        print("LAG! extra updates needed=" .. subUpdates)
    end
    for _=1,subUpdates do
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
        world.count[cat] = {count=(world.count[cat] or {count=0}).count + 1, label=cat}
        local ax, ay, r
        for j, p2 in pairs(world.points) do
            if (i ~= j) then
                ax, ay, r = worldUpdate.findForce(world.G, p, p2)
                p.v.x = p.v.x + dt * ax
                p.v.y = p.v.y + dt * ay
            end

            -- Find distance to sun
            if p2.m > 5000 then
                p.nearest = r / astronomicalConstants.x_earth
            end
        end
        if world.extraForces.fromMouse.active then
            local force = world.extraForces.fromMouse
            ax, ay = worldUpdate.findForce(world.G, p, force)
            p.v.x = p.v.x + dt * ax
            p.v.y = p.v.y + dt * ay
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
    end
end

return worldUpdate
