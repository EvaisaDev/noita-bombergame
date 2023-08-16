local vector = dofile("mods/evaisa.bombergame/lib/vector.lua")

local world_gen = {
    arena_grid = {},
    powerup_positions = {},
    spawn_points = {},
}

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
        local item_weight = type(item.weight) == "function" and item.weight() or item.weight
        total_weight = total_weight + item_weight
    end

    local random_weight = random.range(0, total_weight * 1000)
    --print("weight: "..(random_weight / 1000))
    local current_weight = 0
    for _, item in ipairs(table) do
        local item_weight = type(item.weight) == "function" and item.weight() or item.weight
        current_weight = current_weight + item_weight
        if (current_weight >= (random_weight / 1000)) then
            return item
        end
    end
end

world_gen.generate = function(self, lobby, arena_size, crate_density, powerup_density, spawn_count)
    --print(tostring(lobby))
    local destroyed_boxes = GetDestroyedBoxes(lobby)
    local taken_powerups = GetTakenPowerups(lobby)
    local spawned_powerups = GetSpawnedPowerups(lobby)

    arena_size = arena_size or vector.new(61, 61)
    --seed = seed or 0
    crate_density = crate_density or 0.9
    powerup_density = powerup_density or 0.2
    local clear_space = 2

    arena_size = arena_size + 2

    LoadPixelScene("mods/evaisa.bombergame/files/biome/scenes/clear.png", "", 0, 0, "", true, true, nil, 0, true)

    --SetRandomSeed(seed, seed)
    -- create grid
    self.spawn_points = {}
    self.arena_grid = {}
    self.powerup_positions = {}
    for x = 1, arena_size.x do
        self.arena_grid[x] = {}
        self.powerup_positions[x] = {}
        for y = 1, arena_size.y do
            self.powerup_positions[x][y] = powerup_types.none
            -- if we are on the outer edge, always wall
            if (x == 1 or x == arena_size.x or y == 1 or y == arena_size.y) then
                self.arena_grid[x][y] = grid_types.wall
            elseif ((x) % 2 == 0 or (y) % 2 == 0) then
                self.arena_grid[x][y] = grid_types.air
            else
                self.arena_grid[x][y] = grid_types.wall
            end
        end
    end

    

    create_spawn = function(iteration)
        iteration = iteration or 0
        if(iteration > 100)then
            return
        end
        local spawn_point = vector.new(random.range(1, arena_size.x), random.range(1, arena_size.y))
        if (self.arena_grid[spawn_point.x][spawn_point.y] == grid_types.air) then
            -- make sure we are at least 6 block away from another spawn
            for x = spawn_point.x - 3, spawn_point.x + 3 do
                for y = spawn_point.y - 3, spawn_point.y + 3 do
                    if (x >= 1 and x <= arena_size.x and y >= 1 and y <= arena_size.y) then
                        if (self.arena_grid[x][y] == grid_types.spawn) then
                            return create_spawn(iteration + 1)
                        end
                    end
                end
            end
            return spawn_point
        else
            return create_spawn(iteration + 1)
        end
    end

    -- create spawn points
    -- random even distribution

    for i = 1, math.min(math.floor((arena_size.x + arena_size.y / 2) / 2), spawn_count) do
        local spawn_point = create_spawn()

        if(spawn_point ~= nil)then
            self.spawn_points[i] = spawn_point
            self.arena_grid[self.spawn_points[i].x][self.spawn_points[i].y] = grid_types.spawn
        end
    end

    local crate_indexes = {}
    local valid_crates = {}
    for x = 2, arena_size.x - 1 do
        for y = 2, arena_size.y - 1 do
            if (self.arena_grid[x][y] == grid_types.air) then
                table.insert(crate_indexes, vector.new(x, y))
            end
        end
    end

    -- shuffle crate_indexes
    for i = #crate_indexes, 2, -1 do
        local j = random.range(1, i)
        crate_indexes[i], crate_indexes[j] = crate_indexes[j], crate_indexes[i]
    end

    -- generate valid crates based on crate density
    for i = 1, #crate_indexes do
        local crate = crate_indexes[i]
        if(i <  math.floor(#crate_indexes * crate_density))then
            if(not valid_crates[crate.x])then
                valid_crates[crate.x] = {}
            end
            valid_crates[crate.x][crate.y] = true
        end
    end

    local powerup_indexes = {}
    local valid_powerups = {}

    for x = 2, arena_size.x - 1 do
        for y = 2, arena_size.y - 1 do
            if (valid_crates[x] and valid_crates[x][y]) then
                table.insert(powerup_indexes, vector.new(x, y))
            end
        end
    end

    -- shuffle powerup indexes
    for i = #powerup_indexes, 2, -1 do
        local j = random.range(1, i)
        powerup_indexes[i], powerup_indexes[j] = powerup_indexes[j], powerup_indexes[i]
    end

    -- generate valid powerups based on powerup density
    for i = 1, #powerup_indexes do
        local powerup = powerup_indexes[i]
        if(i <  math.floor(#powerup_indexes * powerup_density))then
            if(not valid_powerups[powerup.x])then
                valid_powerups[powerup.x] = {}
            end
            valid_powerups[powerup.x][powerup.y] = true
        else
            if(not valid_powerups[powerup.x])then
                valid_powerups[powerup.x] = {}
            end
            valid_powerups[powerup.x][powerup.y] = false
        end
    end
    
    

    for x = 1, arena_size.x do
        for y = 1, arena_size.y do
            if self.arena_grid[x][y] == grid_types.air then

                local world_position = (vector.new(x, y) * grid_cell_size) -
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
                    if valid_crates[x] and valid_crates[x][y] then
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
                            if valid_powerups[x] and valid_powerups[x][y] then
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
            elseif(self.arena_grid[x][y] == grid_types.wall)then
                local world_position = (vector.new(x, y) * grid_cell_size) - grid_cell_size

                --print("wall at: " .. tostring(world_position.x) .. "," .. tostring(world_position.y))

                local visual_overlay = ""
                local scene = "mods/evaisa.bombergame/files/biome/scenes/box_wall_smooth.png"

                if(y == arena_size.y)then
                    visual_overlay = "mods/evaisa.bombergame/files/biome/scenes/steel_wall_edge_smooth.png"
                    if(x == 1)then
                        visual_overlay = "mods/evaisa.bombergame/files/biome/scenes/steel_wall_edge_bl.png"
                        scene = "mods/evaisa.bombergame/files/biome/scenes/box_wall_bl.png"
                    elseif(x == arena_size.x)then
                        visual_overlay = "mods/evaisa.bombergame/files/biome/scenes/steel_wall_edge_br.png"
                        scene = "mods/evaisa.bombergame/files/biome/scenes/box_wall_br.png"
                    end
                elseif((x ~= 1 and x ~= arena_size.x and y == 1))then
                    visual_overlay = "mods/evaisa.bombergame/files/biome/scenes/steel_wall_edge_smooth.png"
                elseif(y == 1)then
                    if(x == 1)then
                        scene = "mods/evaisa.bombergame/files/biome/scenes/box_wall_tl.png"
                    elseif(x == arena_size.x)then
                        scene = "mods/evaisa.bombergame/files/biome/scenes/box_wall_tr.png"
                    end
                elseif(not ((x == 1 or x == arena_size.x) and y ~= 1 and y ~= arena_size.y))then
                    visual_overlay = "mods/evaisa.bombergame/files/biome/scenes/steel_wall_edge.png"
                    scene = "mods/evaisa.bombergame/files/biome/scenes/box_wall.png"
                end

                LoadPixelScene(scene, visual_overlay, world_position.x, world_position.y, visual_overlay, true, true, nil, 0, true)
            end
        end
    end


    local grid_test_string = ""

    local encode = require("pngencoder")

    local png = encode(arena_size.x * 3, arena_size.y * 3)

    for y = 1, arena_size.y do
        for i = 1, 3 do
            local rowPixels = {}
    
            for x = 1, arena_size.x do
                local color = spawn_colors[self.arena_grid[x][y]]
                local powerup = self.powerup_positions[x][y]
    
                for j = 1, 3 do
                    if(color)then
                        if(powerup ~= powerup_types.none and i == 2 and j == 2)then
                            local powerup_color = powerup_colors[powerup]
                            table.insert(rowPixels, {powerup_color[1], powerup_color[2], powerup_color[3]})
                        else
                            table.insert(rowPixels, {color[1], color[2], color[3]})
                        end
                    else
                        table.insert(rowPixels, {0xff, 0, 0xff})
                    end
                end
            end
    
            -- Write the entire row to the png
            for _, pixel in ipairs(rowPixels) do
                png:write {pixel[1], pixel[2], pixel[3]}
            end
        end
        grid_test_string = grid_test_string .. "\n"
    end

    --print(grid_test_string)
    local data = table.concat(png.output)

    --[[local file = io.open("temptemp/arena_map.png", "wb")
    file:write(data)
    file:close()]]
end

world_gen.GetSpawnPoint = function(self, index)
    local spawn_point_count = #self.spawn_points
    -- if index is past the end of the spawn points, loop back around
    if (index > spawn_point_count) then
        index = math.floor(index % spawn_point_count)
    end

    -- get random spawn point
    local spawn_point = self.spawn_points[index]
    -- convert to world position
    return ((spawn_point * grid_cell_size) - grid_cell_size) + 8
end

return world_gen
