local vector = dofile("mods/evaisa.bombergame/lib/vector.lua")

local world_gen = {
    arena_grid = {},
    spawn_points = {},
}

-- offset to ignore the outer walls
local arena_offset = vector.new(16, 16)

-- size of a grid cell
local grid_cell_size = 16

-- the inner arena size
local arena_size = vector.new(61, 61)

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

local grid_types = {
    wall = 1,
    open = 2,
    spawn = 3,
    crate = 4,
}


world_gen.generate = function(self, seed, crate_density)
    seed = seed or 0
    crate_density = crate_density or 0.6

    SetRandomSeed(seed, seed)
    -- create grid
    for x = 1, arena_size.x do
        self.arena_grid[x] = {}
        for y = 1, arena_size.y do
            -- if we are on the outer edge, always air
            if(x == 1 or x == arena_size.x or y == 1 or y == arena_size.y)then
                self.arena_grid[x][y] = grid_types.air
            elseif((x + 1) % 2 == 0 or (y + 1) % 2 == 0)then
                self.arena_grid[x][y] = grid_types.air
            else
                self.arena_grid[x][y] = grid_types.wall
            end
        end
    end

    create_spawn = function()
        local spawn_point = vector.new(Random(1, arena_size.x), Random(1, arena_size.y))
        if(self.arena_grid[spawn_point.x][spawn_point.y] == grid_types.air)then
            -- make sure we are at least 6 block away from another spawn
            for x = spawn_point.x - 6, spawn_point.x + 6 do
                for y = spawn_point.y - 6, spawn_point.y + 6 do
                    if(x >= 1 and x <= arena_size.x and y >= 1 and y <= arena_size.y)then
                        if(self.arena_grid[x][y] == grid_types.spawn)then
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


    -- distribute crates around the map
    -- leave 3 spaces around spawn points

    for x = 1, arena_size.x do
        for y = 1, arena_size.y do
            if self.arena_grid[x][y] == grid_types.air then
                local too_close_to_spawn = false
                for _, spawn_point in ipairs(self.spawn_points) do
                    local distance = math.sqrt((x - spawn_point.x)^2 + (y - spawn_point.y)^2)
                    if distance <= 3 then
                        too_close_to_spawn = true
                    end
                end
                if not too_close_to_spawn then
                    -- probability to create a crate (20%)
                    if Random() < crate_density then
                        self.arena_grid[x][y] = grid_types.crate
                        local world_position = (vector.new(x, y) * grid_cell_size + arena_offset) - grid_cell_size
                        np.ForceLoadPixelScene("mods/evaisa.bombergame/files/biome/scenes/box.png", "", world_position.x, world_position.y, "", true)
                    end
                end
            end
        end
    end


    local grid_test_string = ""

    local encode = require("pngencoder")

    local png = encode(arena_size.x, arena_size.y) 

    for x = 1, arena_size.x do
        for y = 1, arena_size.y do
            if(self.arena_grid[x][y] == grid_types.wall)then
                grid_test_string = grid_test_string .. "W"
                png:write {0, 0, 0}
            elseif(self.arena_grid[x][y] == grid_types.air)then
                grid_test_string = grid_test_string .. "O"
                png:write {0xFF, 0xFF, 0xFF}
            elseif(self.arena_grid[x][y] == grid_types.spawn)then
                grid_test_string = grid_test_string .. "S"
                png:write {0xFF, 0, 0}
            elseif(self.arena_grid[x][y] == grid_types.crate)then
                grid_test_string = grid_test_string .. "C"
                png:write {0xbf, 0x7a, 0x49}
            end
        end
        grid_test_string = grid_test_string .. "\n"
    end

    print(grid_test_string)
    local data = table.concat(png.output)

    local file = io.open("temptemp/arena_map.png", "wb")
    file:write(data)
    file:close()
end

world_gen.GetSpawnPoint = function(self)
    -- get random spawn point
    local spawn_point = self.spawn_points[Random(1, #self.spawn_points)]
    -- convert to world position
    return ((spawn_point * grid_cell_size + arena_offset) - grid_cell_size) + 8
end

return world_gen