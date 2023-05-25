local json = dofile("mods/evaisa.mp/lib/json.lua")

function damage_about_to_be_received( damage, x, y, entity_thats_responsible, critical_hit_chance )
    local box = GetUpdatedEntityID()

    local box_x, box_y = EntityGetTransform(box)

    local destroyed_boxes = json.parse(GlobalsGetValue("bomberguy_destroyed_boxes", "[]"))

    table.insert(destroyed_boxes, {x = box_x, y = box_y})

    GlobalsSetValue("bomberguy_destroyed_boxes", json.stringify(destroyed_boxes))

    EntityKill(box)

    return 0, 0
end