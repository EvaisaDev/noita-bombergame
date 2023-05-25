local json = dofile("mods/evaisa.mp/lib/json.lua")
function damage_received( damage, message, entity_thats_responsible, is_fatal, projectile_thats_responsible )
    local entity_id = GetUpdatedEntityID()
    
    local damage_details = GetDamageDetails()
    --[[
        {
            ragdoll_fx = 1 
            damage_types = 16 -- bitflag
            knockback_force = 0    
            impulse = {0, 0},
            world_pos = {216.21, 12.583},
        }
    ]]
    local details = {
        damage = damage,
        message = message,
        details = damage_details,
    }
    
    -- check if would kill
    GameAddFlagRun("took_damage")
    GlobalsSetValue("last_damage_details", tostring(json.stringify(details)))

end