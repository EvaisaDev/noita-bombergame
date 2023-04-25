dofile_once("data/scripts/lib/utilities.lua")

local vector = dofile("mods/evaisa.bombergame/lib/vector.lua")

local player = GetUpdatedEntityID()

local controls_component = EntityGetFirstComponentIncludingDisabled( player, "ControlsComponent" )

last_bomb_frame = last_bomb_frame or -99999


if(controls_component == nil)then
    return
end

------------------ PROPERTIES ------------------

local bomb_distance = 10
local throw_strength = tonumber(GlobalsGetValue("bomberguy_throw_strength", "1"))
local speed_multipier = tonumber(GlobalsGetValue("bomberguy_speed", "60"))
local bomb_cooldown = tonumber(GlobalsGetValue("bomberguy_bomb_cooldown", "30"))
local max_active_bombs = tonumber(GlobalsGetValue("bomberguy_max_active_bombs", "1"))

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

local IsKeyDown = function(key)
    if(key == Keys.Up)then
       return ComponentGetValue2(controls_component, "mButtonDownUp")
    elseif(key == Keys.Down)then
       return ComponentGetValue2(controls_component, "mButtonDownDown")
    elseif(key == Keys.Left)then
        return ComponentGetValue2(controls_component, "mButtonDownLeft")
    elseif(key == Keys.Right)then
        return ComponentGetValue2(controls_component, "mButtonDownRight")
    elseif(key == Keys.Bomb)then
        return ComponentGetValue2(controls_component, "mButtonDownInteract")
    elseif(key == Keys.Kick)then
        return ComponentGetValue2(controls_component, "mButtonDownKick")
    end
end

local KeyPressed = function(key)
    if(key == Keys.Up)then
       return ComponentGetValue2(controls_component, "mButtonDownUp") and ComponentGetValue2(controls_component, "mButtonFrameUp") == GameGetFrameNum()
    elseif(key == Keys.Down)then
       return ComponentGetValue2(controls_component, "mButtonDownDown") and ComponentGetValue2(controls_component, "mButtonFrameDown") == GameGetFrameNum()
    elseif(key == Keys.Left)then
        return ComponentGetValue2(controls_component, "mButtonDownLeft") and ComponentGetValue2(controls_component, "mButtonFrameLeft") == GameGetFrameNum()
    elseif(key == Keys.Right)then
        return ComponentGetValue2(controls_component, "mButtonDownRight") and ComponentGetValue2(controls_component, "mButtonFrameRight") == GameGetFrameNum()
    elseif(key == Keys.Bomb)then
        return ComponentGetValue2(controls_component, "mButtonDownInteract") and ComponentGetValue2(controls_component, "mButtonFrameInteract") == GameGetFrameNum()
    elseif(key == Keys.Kick)then
        return ComponentGetValue2(controls_component, "mButtonDownKick") and ComponentGetValue2(controls_component, "mButtonFrameKick") == GameGetFrameNum()
    end
end

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

if(IsKeyDown(Keys.Up))then
    direction.y = direction.y - 1
end

if(IsKeyDown(Keys.Down))then
    direction.y = direction.y + 1
end

if(IsKeyDown(Keys.Left))then
    direction.x = direction.x - 1
end

if(IsKeyDown(Keys.Right))then
    direction.x = direction.x + 1
end


-- based on the direction change the player animation
for sprite_direction, sprite_direction_vector in pairs(SpriteDirections) do
    if(sprite_direction_vector == direction)then
        --print(current_animation.."_"..sprite_direction)
        GamePlayAnimation( player, current_animation.."_"..sprite_direction, 0 )
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

if(direction:len() > 0)then
    last_direction = direction
end

local velocity = direction * speed_multipier

local character_data_component = EntityGetFirstComponentIncludingDisabled( player, "CharacterDataComponent" )

if(character_data_component ~= nil)then
    ComponentSetValue2(character_data_component, "mVelocity", velocity.x, velocity.y)
end

local active_bomb_count = #(EntityGetWithTag("player_bomb") or {})


if(KeyPressed(Keys.Bomb) and active_bomb_count < max_active_bombs and GameGetFrameNum() > last_bomb_frame + bomb_cooldown)then

    
    local bomb_location_x = x + (last_direction.x * bomb_distance)
    local bomb_location_y = y + (last_direction.y * bomb_distance)



    local throw_target_x = bomb_location_x + (last_direction.x * throw_strength)
    local throw_target_y = bomb_location_y + (last_direction.y * throw_strength)

    local bomb = EntityLoad("mods/evaisa.bombergame/files/entities/bomb.xml", bomb_location_x, bomb_location_y)

    EntityAddTag(bomb, "player_bomb")

    last_bomb_frame = GameGetFrameNum()

    GameShootProjectile(player, bomb_location_x, bomb_location_y, throw_target_x, throw_target_y, bomb, true)
end