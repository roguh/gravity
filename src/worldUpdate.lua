local worldUpdate = {}

local astronomicalConstants = require("astronomicalConstants")

function worldUpdate.worldUpdate(world, dt)
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
                    p.nearest = r / astronomicalConstants.x_earth
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
end

return worldUpdate
