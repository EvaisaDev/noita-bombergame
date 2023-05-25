local json = dofile("mods/evaisa.mp/lib/json.lua")
local entity = GetUpdatedEntityID()
local x, y = EntityGetTransform(entity)

local players = EntityGetWithTag("player_unit")

local pickup_done = false

if(players ~= nil)then
    for key, player in pairs(players) do
        local px, py = EntityGetTransform(player)
        local distance = math.sqrt((px - x) ^ 2 + (py - y) ^ 2)
        if(distance < 8)then
            local current_pickups = GlobalsGetValue("current_pickups", "[]")
            local current_pickups_table = json.parse(current_pickups)
            table.insert(current_pickups_table, {x = x, y = y})
            GlobalsSetValue("current_pickups", json.stringify(current_pickups_table))
            pickup_done = true
        end
    end
end

if(pickup_done)then
    EntityKill(entity)
end