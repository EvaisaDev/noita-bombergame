local vector = dofile("mods/evaisa.bombergame/lib/vector.lua")

local world_gen = {
    arena_grid = {},
    powerup_positions = {},
    spawn_points = {},
}

-- offset to ignore the outer walls
local arena_offset = vector.new(16, 16)

-- size of a grid cell
local grid_cell_size = 16


-- example for a 16x16 arena:
-- WWWWWWWWWWWWWWWWW
-- WOOOOOOOOOOOOOOOW
-- WOWOWOWOWOWOWOWOW
-- WOOOOOOOOOOOOOOOW
-- WOWOWOWOWOWOWOWOW
-- WOOOOOOOOOOOOOOOW
-- WOWOWOWOWOWOWOWOW
-- WOOOOOOOOOOOOOOOW
-- WOWOWOWOWOWOWOWOW
-- WOOOOOOOOOOOOOOOW
-- WOWOWOWOWOWOWOWOW
-- WOOOOOOOOOOOOOOOW
-- WOWOWOWOWOWOWOWOW
-- WOOOOOOOOOOOOOOOW
-- WOWOWOWOWOWOWOWOW
-- WWWWWWWWWWWWWWWWW


local function GetWeightedItem(table)
    local total_weight = 0
    for _, item in ipairs(table) do
        total_weight = total_weight + item.weight
    end

    local random_weight = Random(0, total_weight * 1000)
    --print("weight: "..(random_weight / 1000))
    local current_weight = 0
    for _, item in ipairs(table) do
        current_weight = current_weight + item.weight
        if (current_weight >= (random_weight / 1000)) then
            return item
        end
    end
end

world_gen.generate = function(self, lobby, arena_size, seed, crate_density, powerup_density)
    --print(tostring(lobby))
    local destroyed_boxes = GetDestroyedBoxes(lobby)
    local taken_powerups = GetTakenPowerups(lobby)
    local spawned_powerups = GetSpawnedPowerups(lobby)

    arena_size = arena_size or vector.new(61, 61)
    seed = seed or 0
    crate_density = crate_density or 0.8
    powerup_density = powerup_density or 0.1
    local clear_space = 2

    SetRandomSeed(seed, seed)
    -- create grid
    self.spawn_points = {}
    self.arena_grid = {}
    self.powerup_positions = {}
    for x = 1, arena_size.x do
        self.arena_grid[x] = {}
        self.powerup_positions[x] = {}
        for y = 1, arena_size.y do
            self.powerup_positions[x][y] = powerup_types.none
            -- if we are on the outer edge, always air
            if (x == 1 or x == arena_size.x or y == 1 or y == arena_size.y) then
                self.arena_grid[x][y] = grid_types.air
            elseif ((x + 1) % 2 == 0 or (y + 1) % 2 == 0) then
                self.arena_grid[x][y] = grid_types.air
            else
                self.arena_grid[x][y] = grid_types.wall
            end
        end
    end

    

    create_spawn = function()
        local spawn_point = vector.new(Random(1, arena_size.x), Random(1, arena_size.y))
        if (self.arena_grid[spawn_point.x][spawn_point.y] == grid_types.air) then
            -- make sure we are at least 6 block away from another spawn
            for x = spawn_point.x - 3, spawn_point.x + 3 do
                for y = spawn_point.y - 3, spawn_point.y + 3 do
                    if (x >= 1 and x <= arena_size.x and y >= 1 and y <= arena_size.y) then
                        if (self.arena_grid[x][y] == grid_types.spawn) then
                            return create_spawn()
                        end
                    end
                end
            end
            return spawn_point
        else
            return create_spawn()
        end
    end

    -- create 32 spawn points
    -- random even distribution

    for i = 1, 32 do
        self.spawn_points[i] = create_spawn()
        self.arena_grid[self.spawn_points[i].x][self.spawn_points[i].y] = grid_types.spawn
    end

    for x = 1, arena_size.x do
        for y = 1, arena_size.y do
            if self.arena_grid[x][y] == grid_types.air then

                local world_position = (vector.new(x, y) * grid_cell_size + arena_offset) -
                grid_cell_size
                local crate_spawn = (world_position) + 8

                if(debugging)then
                    local grid_marker = EntityLoad("mods/evaisa.bombergame/files/entities/grid_marker_debug.xml", world_position.x + 2, world_position.y + 2)
                    local sprite_comp = EntityGetFirstComponent(grid_marker, "SpriteComponent")
                    if(sprite_comp ~= nil)then
                        ComponentSetValue2(sprite_comp, "text", tostring(x) .. "," .. tostring(y))
                    end
                end

                local too_close_to_spawn = false
                for _, spawn_point in ipairs(self.spawn_points) do
                    local distance = math.sqrt((x - spawn_point.x) ^ 2 + (y - spawn_point.y) ^ 2)
                    if distance <= clear_space then
                        too_close_to_spawn = true
                    end
                end
                if not too_close_to_spawn then
                    if Random() < crate_density then
                        --[[
                        self.arena_grid[x][y] = grid_types.crate
                        local world_position = (vector.new(x, y) * grid_cell_size + arena_offset) - grid_cell_size

                        local crate_spawn = (world_position) + 8

                        EntityLoad("mods/evaisa.bombergame/files/entities/crate.xml", crate_spawn.x, crate_spawn.y)
                        ]]
                        -- spawn items based on spawn list weights
                        local spawn_item = GetWeightedItem(spawn_list)
   

                        self.arena_grid[x][y] = spawn_item.type

                        if(spawn_item.can_contain_powerups)then
                            if Random() < powerup_density then
                                local powerup_type = GetWeightedItem(powerup_list)
                                self.powerup_positions[x][y] = powerup_type.type
                            end
                        end
            
                        local box_destroyed = GetBoxDestroyed(destroyed_boxes, x, y)

                        if(box_destroyed)then
                            local powerup = GetPowerup(taken_powerups, x, y)
                            if(powerup ~= nil)then
                                local id = GetSpawnedPowerup(spawned_powerups, x, y)
                                if(id ~= nil)then
                                    LoadPowerupEntity(id, powerup, x, y)
                                end
                            end
                        end
                        if(not box_destroyed)then
                            EntityLoad(spawn_item.entity, crate_spawn.x, crate_spawn.y)
                        end
                    end
                end
            end
        end
    end


    --local grid_test_string = ""

    --local encode = require("pngencoder")

    --local png = encode(arena_size.x * 3, arena_size.y * 3)

    --for y = 1, arena_size.y do
    --    for i = 1, 3 do
    --        local rowPixels = {}
    --
    --        for x = 1, arena_size.x do
    --            local color = spawn_colors[self.arena_grid[x][y]]
    --            local powerup = self.powerup_positions[x][y]
    --
    --            for j = 1, 3 do
    --                if(color)then
    --                    if(powerup ~= powerup_types.none and i == 2 and j == 2)then
    --                        local powerup_color = powerup_colors[powerup]
    --                        table.insert(rowPixels, {powerup_color[1], powerup_color[2], powerup_color[3]})
    --                    else
    --                        table.insert(rowPixels, {color[1], color[2], color[3]})
    --                    end
    --                else
    --                    table.insert(rowPixels, {0xff, 0, 0xff})
    --                end
    --            end
    --        end
    --
    --        -- Write the entire row to the png
    --        for _, pixel in ipairs(rowPixels) do
    --            png:write {pixel[1], pixel[2], pixel[3]}
    --        end
    --    end
    --    grid_test_string = grid_test_string .. "\n"
    --end

    ----print(grid_test_string)
    --local data = table.concat(png.output)

    --local file = io.open("temptemp/arena_map.png", "wb")
    --file:write(data)
    --file:close()
end

world_gen.GetSpawnPoint = function(self, index)
    -- get random spawn point
    local spawn_point = self.spawn_points[index]
    -- convert to world position
    return ((spawn_point * grid_cell_size + arena_offset) - grid_cell_size) + 8
end

return world_gen
