dofile_once("data/scripts/lib/utilities.lua")
local json = dofile("mods/evaisa.mp/lib/json.lua")
local vector = dofile("mods/evaisa.bombergame/lib/vector.lua")

local players = EntityGetWithTag("player_unit") or {}

if(players == nil or #players <= 0)then
    return
end

local player = players[1]

local controls_component = EntityGetFirstComponentIncludingDisabled( player, "ControlsComponent" )

last_bomb_frame = last_bomb_frame or -99999
bombing = bombing or false

if(controls_component == nil)then
    return
end

------------------ PROPERTIES ------------------

local bomb_distance = 10
local bomb_throw_frame = 15
local throw_strength = tonumber(GlobalsGetValue("bomberguy_throw_strength", "1"))
local speed_multipier = tonumber(GlobalsGetValue("bomberguy_speed", "60"))
local bomb_cooldown = tonumber(GlobalsGetValue("bomberguy_bomb_cooldown", "30"))
local max_active_bombs = tonumber(GlobalsGetValue("bomberguy_max_active_bombs", "1"))
local bomb_collision = tonumber(GlobalsGetValue("bomberguy_bomb_collision", "1"))
local box_penetration = tonumber(GlobalsGetValue("bomberguy_box_penetration", "0"))
local bomb_power = tonumber(GlobalsGetValue("bomberguy_bomb_power", "1"))

------------------------------------------------



last_direction = last_direction or vector.new(0, 1)

local Keys = {
    Up = 0,
    Down = 1,
    Left = 2,
    Right = 3,
    Bomb = 4,
    Kick = 5,
}

local stick_x, stick_y = input:GetGamepadAxis("left_stick")

local IsKeyDown = function(key)
    
    if(key == Keys.Up)then
        return input:IsKeyDown("w") or input:IsGamepadButtonDown("up")
    elseif(key == Keys.Down)then
        return input:IsKeyDown("s") or input:IsGamepadButtonDown("down")
    elseif(key == Keys.Left)then
        return input:IsKeyDown("a") or input:IsGamepadButtonDown("left")
    elseif(key == Keys.Right)then
        return input:IsKeyDown("d") or input:IsGamepadButtonDown("right")
    elseif(key == Keys.Bomb)then
        return input:IsKeyDown("e") or input:IsGamepadButtonDown("button_a") or input:IsKeyDown("space")
    elseif(key == Keys.Kick)then
        return input:IsKeyDown("f") or input:IsGamepadButtonDown("button_b")
    end
    
end

local KeyPressed = function(key)
    
    if(key == Keys.Up)then
        return input:WasKeyPressed("w") or input:WasGamepadButtonPressed("up")
     elseif(key == Keys.Down)then
        return input:WasKeyPressed("s") or input:WasGamepadButtonPressed("down")
     elseif(key == Keys.Left)then
         return input:WasKeyPressed("a") or input:WasGamepadButtonPressed("left")
     elseif(key == Keys.Right)then
         return input:WasKeyPressed("d") or input:WasGamepadButtonPressed("right")
     elseif(key == Keys.Bomb)then
         return input:WasKeyPressed("e") or input:WasGamepadButtonPressed("button_a") or input:WasKeyPressed("space")
     elseif(key == Keys.Kick)then
         return input:WasKeyPressed("f") or input:WasGamepadButtonPressed("button_b")
     end
     
end

--local result = input:IsKeyDown("w") or input:IsGamepadButtonDown("up")


local current_animation = "stand"

local SpriteDirections = {
    down = vector.new(0, 1),
    downright = vector.new(1, 1),
    right = vector.new(1, 0),
    upright = vector.new(1, -1),
    up = vector.new(0, -1),
    upleft = vector.new(-1, -1),
    left = vector.new(-1, 0),
    downleft = vector.new(-1, 1),
}

local direction = vector.new(0, 0)

local moved_keys = false

if(IsKeyDown(Keys.Up))then
    direction.y = direction.y - 1
    moved_keys = true
end

if(IsKeyDown(Keys.Down))then
    direction.y = direction.y + 1
    moved_keys = true
end

if(IsKeyDown(Keys.Left))then
    direction.x = direction.x - 1
    moved_keys = true
end

if(IsKeyDown(Keys.Right))then
    direction.x = direction.x + 1
    moved_keys = true	
end

if(not moved_keys)then
    direction = vector.new(stick_x, stick_y)
end


local animation_map = {
    down = {
        bomb = "bomb_down",
        stand = "stand_down",
    },
    downright = {
        bomb = "bomb_down",
        stand = "stand_downright",
    },
    right = {
        bomb = "bomb_right",
        stand = "stand_right",
    },
    upright = {
        bomb = "bomb_right",
        stand = "stand_upright",
    },
    up = {
        bomb = "bomb_up",
        stand = "stand_up",
    },
    upleft = {
        bomb = "bomb_up",
        stand = "stand_upleft",
    },
    left = {
        bomb = "bomb_left",
        stand = "stand_left",
    },
    downleft = {
        bomb = "bomb_left",
        stand = "stand_downleft",
    },
}

-- get current animation
local sprite_comp = EntityGetFirstComponentIncludingDisabled( player, "SpriteComponent", "body_top" )

local last_animation = ComponentGetValue2(sprite_comp, "rect_animation")

--print(last_animation)

last_animation_direction = last_animation_direction or "down"

-- based on the direction change the player animation
for sprite_direction, sprite_direction_vector in pairs(SpriteDirections) do
    if(sprite_direction_vector == direction)then
        last_animation_direction = sprite_direction
        local animation_to_play = animation_map[sprite_direction][current_animation]
        if(animation_to_play ~= last_animation)then
            --print(animation_to_play)
            GamePlayAnimation( player, current_animation.."_"..sprite_direction, 10 )
        end
    end
end


local x, y, r, w, h = EntityGetTransform(player)


local character_platforming_component = EntityGetFirstComponentIncludingDisabled( player, "CharacterPlatformingComponent" )


if(character_platforming_component)then
    ComponentSetValue2(character_platforming_component, "mNextTurnAnimationFrame", GameGetFrameNum() + 10)
end

--EntitySetTransform(player, x, y, 0, 1, 1)

if(direction:len() > 0)then
    direction = direction:normalize()
end

if(direction:len() > 0 and bombing == false)then
    last_direction = direction
end

local velocity = direction * speed_multipier

--print(tostring(velocity))


local character_data_component = EntityGetFirstComponentIncludingDisabled( player, "CharacterDataComponent" )

if(character_data_component ~= nil and bombing == false)then
    ComponentSetValue2(character_data_component, "mVelocity", velocity.x, velocity.y)
end

local active_bomb_count = #(EntityGetWithTag("player_bomb") or {})


if(bombing == false and KeyPressed(Keys.Bomb) and active_bomb_count < max_active_bombs and GameGetFrameNum() > last_bomb_frame + bomb_cooldown)then

    local animation_to_play = animation_map[last_animation_direction].bomb
    --print(animation_to_play)
    GamePlayAnimation( player, animation_to_play, 11 )
    last_bomb_frame = GameGetFrameNum()

    bombing = true
end

if(bombing == true and GameGetFrameNum() > (last_bomb_frame + bomb_throw_frame))then

    --if(true)then return end


    bombing = false
    
    local bomb_location_x = x + (last_direction.x * bomb_distance)
    local bomb_location_y = y + (last_direction.y * bomb_distance)



    local throw_target_x = bomb_location_x + (last_direction.x * throw_strength)
    local throw_target_y = bomb_location_y + (last_direction.y * throw_strength)

    local bomb_projectile = "mods/evaisa.bombergame/files/entities/bomb.xml"
    
    if(bomb_collision == 0)then
        bomb_projectile = "mods/evaisa.bombergame/files/entities/bomb_nocollide.xml"
    end
    

    local bomb = EntityLoad(bomb_projectile, bomb_location_x, bomb_location_y)

    -- set penetration and power variablestoragecomponents
    local penetration = EntityGetFirstComponentIncludingDisabled(bomb, "VariableStorageComponent", "penetration")
    if(penetration ~= nil)then
        ComponentSetValue2(penetration, "value_int", box_penetration)
    end

    local power = EntityGetFirstComponentIncludingDisabled(bomb, "VariableStorageComponent", "power")
    if(power ~= nil)then
        ComponentSetValue2(power, "value_int", bomb_power)
    end

    EntityAddTag(bomb, "player_bomb")

    local custom_id = bomb + GameGetFrameNum() + bomb_location_x + bomb_location_y

    EntitySetName(bomb, "bomb_"..tostring(custom_id))

    local projectile_component = EntityGetFirstComponentIncludingDisabled(bomb, "ProjectileComponent")

    GameShootProjectile(player, bomb_location_x, bomb_location_y, throw_target_x, throw_target_y, bomb, true)

    --GameShootProjectile(player, 0, 0, 0, 0, bomb, true)
    
    local current_bombs = json.parse(GlobalsGetValue("bombergame_current_bombs", "[]"))

    table.insert(current_bombs, {
        id = custom_id,
        x = bomb_location_x,
        y = bomb_location_y,
        throw_target_x = throw_target_x,
        throw_target_y = throw_target_y,
        box_penetration = box_penetration,
        bomb_power = bomb_power,
    })

    GlobalsSetValue("bombergame_current_bombs", json.stringify(current_bombs))
    

end