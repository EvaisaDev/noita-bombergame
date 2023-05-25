local vector = dofile("mods/evaisa.bombergame/lib/vector.lua")
local explosion_helper = dofile("mods/evaisa.bombergame/files/scripts/explosion_helper.lua")

local bomb = GetUpdatedEntityID()

local bomb_x, bomb_y = EntityGetTransform( bomb )


explosion_helper.Explode(3, 1, bomb_x, bomb_y)