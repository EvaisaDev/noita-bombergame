function damage_about_to_be_received( damage, x, y, entity_thats_responsible, critical_hit_chance )
    local entity_id = GetUpdatedEntityID()

    if(entity_thats_responsible ~= GameGetWorldStateEntity())then
        local damageModelComponent = EntityGetFirstComponentIncludingDisabled( entity_id, "DamageModelComponent" )
        if damageModelComponent ~= nil then
            local health = ComponentGetValue2( damageModelComponent, "hp" )
            if health then
                ComponentSetValue2( damageModelComponent, "hp", health + damage )
            end
        end
    end

    if(entity_thats_responsible == GameGetWorldStateEntity())then
        print("damage from world state")
        damage = 100000
    end

    return damage, 0
end