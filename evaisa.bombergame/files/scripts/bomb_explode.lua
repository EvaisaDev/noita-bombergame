local vector = dofile("mods/evaisa.bombergame/lib/vector.lua")
local explosion_helper = dofile("mods/evaisa.bombergame/files/scripts/explosion_helper.lua")

local bomb = GetUpdatedEntityID()

local bomb_x, bomb_y = EntityGetTransform( bomb )

local box_penetration = 0
local bomb_power = 1

-- get variable storage components
local variable_storage_components = EntityGetComponent( bomb, "VariableStorageComponent" )
-- get power and penetration from variable storage
if variable_storage_components ~= nil then
    for key, component in pairs(variable_storage_components) do
        local name = ComponentGetValue2( component, "name" )
        if name == "power" then
            bomb_power = ComponentGetValue2( component, "value_int" )
        elseif name == "penetration" then
            box_penetration = ComponentGetValue2( component, "value_int" )
        end
    end
end

--local box_penetration = tonumber(GlobalsGetValue("bomberguy_box_penetration", "0"))
--local bomb_power = tonumber(GlobalsGetValue("bomberguy_bomb_power", "1"))




explosion_helper.Explode(bomb_power, box_penetration, bomb_x, bomb_y)