local vector = dofile("mods/evaisa.bombergame/lib/vector.lua")
local explosion_helper = {}

explosion_helper.Explode = function(power, penetration, bomb_x, bomb_y, explosion_entity)
    if(GameHasFlagRun("DisableExplosions"))then return end


    explosion_entity = explosion_entity or "mods/evaisa.bombergame/files/entities/explosion.xml"

    local arena_offset = 16
    local cell_size = 16
    local grid_position = vector((math.floor((bomb_x) / cell_size) * cell_size) + (cell_size / 2),
        (math.floor((bomb_y) / cell_size) * cell_size) + (cell_size / 2))

    local debug = false

    local debug_marker_entity = "mods/evaisa.bombergame/files/entities/debug_marker.xml"

    local exploded_cells = {
        vector.new(grid_position.x, grid_position.y)
    }

    --EntityLoad(debug_marker_entity, grid_position.x + 8, grid_position.y + 8)

    local ray_distance = power * 16

    local max_cells_left = power
    local max_cells_right = power
    local max_cells_up = power
    local max_cells_down = power

    local left_hit, left_x, left_y = RaytraceSurfaces(grid_position.x, grid_position.y, grid_position.x - ray_distance,
        grid_position.y)

    if left_hit then
        -- calculate how many cells we can go left
        local distance = math.sqrt((left_x - grid_position.x) ^ 2 + (left_y - grid_position.y) ^ 2)
        max_cells_left = math.floor(distance / cell_size)
    end

    local right_hit, right_x, right_y = RaytraceSurfaces(grid_position.x, grid_position.y, grid_position.x + ray_distance,
        grid_position.y)

    if right_hit then
        -- calculate how many cells we can go right
        local distance = math.sqrt((right_x - grid_position.x) ^ 2 + (right_y - grid_position.y) ^ 2)
        max_cells_right = math.floor(distance / cell_size)
    end



    local up_hit, up_x, up_y = RaytraceSurfaces(grid_position.x, grid_position.y, grid_position.x,
        grid_position.y - ray_distance)

    if up_hit then
        -- calculate how many cells we can go up
        local distance = math.sqrt((up_x - grid_position.x) ^ 2 + (up_y - grid_position.y) ^ 2)
        max_cells_up = math.floor(distance / cell_size)
    end

    local down_hit, down_x, down_y = RaytraceSurfaces(grid_position.x, grid_position.y, grid_position.x,
        grid_position.y + ray_distance)

    if down_hit then
        -- calculate how many cells we can go down
        local distance = math.sqrt((down_x - grid_position.x) ^ 2 + (down_y - grid_position.y) ^ 2)
        max_cells_down = math.floor(distance / cell_size)
    end

    if (debug) then
        GameCreateSpriteForXFrames("data/ui_gfx/debug_marker.png", grid_position.x, grid_position.y, true, 0, 0, 120,
            true)
        GameCreateSpriteForXFrames("data/ui_gfx/debug_marker.png", grid_position.x - ray_distance, grid_position.y, true,
            0, 0, 120, true)
        GameCreateSpriteForXFrames("data/ui_gfx/debug_marker.png", grid_position.x, grid_position.y, true, 0, 0, 120,
            true)
        GameCreateSpriteForXFrames("data/ui_gfx/debug_marker.png", grid_position.x + ray_distance, grid_position.y, true,
            0, 0, 120, true)
        GameCreateSpriteForXFrames("data/ui_gfx/debug_marker.png", grid_position.x, grid_position.y, true, 0, 0, 120,
            true)
        GameCreateSpriteForXFrames("data/ui_gfx/debug_marker.png", grid_position.x, grid_position.y - ray_distance, true,
            0, 0, 120, true)
        GameCreateSpriteForXFrames("data/ui_gfx/debug_marker.png", grid_position.x, grid_position.y, true, 0, 0, 120,
            true)
        GameCreateSpriteForXFrames("data/ui_gfx/debug_marker.png", grid_position.x, grid_position.y + ray_distance, true,
            0, 0, 120, true)
    end




    -- Calculate the maximum number of cells the explosion can reach in any direction
    local max_cells = math.max(max_cells_left, max_cells_right, max_cells_up, max_cells_down)

    -- Initialize penetration counters for each direction
    local left_penetration = 0
    local right_penetration = 0
    local up_penetration = 0
    local down_penetration = 0

    -- Loop through the maximum cells and calculate each explosion point in all directions
    for i = 1, max_cells do
        -- [LEFT] If the current loop index is within the range of max_cells_left,
        -- calculate the x and y coordinates of the explosion point and add the point to the exploded_cells table
        if i <= max_cells_left then
            local x = grid_position.x - (i * cell_size)
            local y = grid_position.y

            local nearby_crates = EntityGetInRadiusWithTag(x, y, 8, "bomb_hittable")

            if (#nearby_crates > 0 and left_penetration < penetration) then
                -- Increment penetration counter if we hit a box
                left_penetration = left_penetration + 1
            elseif (#nearby_crates > 0) then
                -- Stop the explosion if we reached maximum penetration
                max_cells_left = i
            end

            table.insert(exploded_cells, vector.new(x, y))
        end

        -- [RIGHT] Same logic as for the left, but applied to the right direction
        if i <= max_cells_right then
            local x = grid_position.x + (i * cell_size)
            local y = grid_position.y

            local nearby_crates = EntityGetInRadiusWithTag(x, y, 8, "bomb_hittable")

            if (#nearby_crates > 0 and right_penetration < penetration) then
                -- Increment penetration counter if we hit a box
                right_penetration = right_penetration + 1
            elseif (#nearby_crates > 0) then
                -- Stop the explosion if we reached maximum penetration
                max_cells_right = i
            end

            table.insert(exploded_cells, vector.new(x, y))
        end

        -- [UP] Same logic as for the left, but applied to the up direction
        if i <= max_cells_up then
            local x = grid_position.x
            local y = grid_position.y - (i * cell_size)

            local nearby_crates = EntityGetInRadiusWithTag(x, y, 8, "bomb_hittable")

            if (#nearby_crates > 0 and up_penetration < penetration) then
                -- Increment penetration counter if we hit a box
                up_penetration = up_penetration + 1
            elseif (#nearby_crates > 0) then
                -- Stop the explosion if we reached maximum penetration
                max_cells_up = i
            end

            table.insert(exploded_cells, vector.new(x, y))
        end

        -- [DOWN] Same logic as for the left, but applied to the down direction
        if i <= max_cells_down then
            local x = grid_position.x
            local y = grid_position.y + (i * cell_size)

            local nearby_crates = EntityGetInRadiusWithTag(x, y, 8, "bomb_hittable")

            if (#nearby_crates > 0 and down_penetration < penetration) then
                -- Increment penetration counter if we hit a box
                down_penetration = down_penetration + 1
            elseif (#nearby_crates > 0) then
                -- Stop the explosion if we reached maximum penetration
                max_cells_down = i
            end

            table.insert(exploded_cells, vector.new(x, y))
        end
    end

    for k, v in pairs(exploded_cells) do
        local x = v.x
        local y = v.y

        if (debug) then
            GameCreateSpriteForXFrames("data/ui_gfx/debug_marker.png", x, y, true, 0, 0, 120, true)
        end




        EntityLoad(explosion_entity, x, y)
    end
end

return explosion_helper
