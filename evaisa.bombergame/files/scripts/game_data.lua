grid_types = {
    air = 1,
    wall = 2,
    open = 3,
    spawn = 4,
    crate = 5,
    explosive_crate = 6,
}

spawn_list = {
    {
        weight = 1,
        type = grid_types.crate,
        entity = "mods/evaisa.bombergame/files/entities/crate.xml",
        can_contain_powerups = true,
    },
    {
        weight = function() return tonumber(GlobalsGetValue("bomberguy_explosive_percentage", "0.1")) end,
        type = grid_types.explosive_crate,
        entity = "mods/evaisa.bombergame/files/entities/explosive_crate.xml"
    },
}

spawn_colors = {
    [grid_types.crate] = {0xbf, 0x7a, 0x49},
    [grid_types.explosive_crate] = {0xff, 0, 0},
    [grid_types.wall] = {0,0,0},
    [grid_types.air] = {0xff, 0xff, 0xff},
    [grid_types.spawn] = {0x7a, 0x49, 0xbf},
}

powerup_types = {
    none = 0,
    throw_strength = 1,
    speed_multipier = 2,
    max_active_bombs = 3,
    bomb_collision = 4,
    box_penetration = 5,
    bomb_power = 6,
    kick_bombs = 7,
}

-- keep order in sync with powerup_types
powerup_list = {
    {
        name = "Throw Strength",
        description = "Increases how hard you throw a bomb",
        weight = 1,
        type = powerup_types.throw_strength,
        sprite = "mods/evaisa.bombergame/files/gfx/powerups/throw_strength.png",
        reset = function()
            GlobalsSetValue("bomberguy_throw_strength", "1")
        end,
        pickup = function(player, x, y)
            local throw_strenght = tonumber(GlobalsGetValue("bomberguy_throw_strength", "1"))
            throw_strenght = throw_strenght + 50
            GlobalsSetValue("bomberguy_throw_strength", tostring(throw_strenght))
        end,
    },
    {
        name = "Accelerator",
        description = "Increases your speed",
        weight = 1,
        type = powerup_types.speed_multipier,
        sprite = "mods/evaisa.bombergame/files/gfx/powerups/speed.png",
        reset = function()
            GlobalsSetValue("bomberguy_speed", "60")
        end,
        pickup = function(player, x, y)
            local speed = tonumber(GlobalsGetValue("bomberguy_speed", "60"))
            speed = speed + 10
            GlobalsSetValue("bomberguy_speed", tostring(speed))
        end,
    },
    {
        name = "Extra Bomb",
        description = "Increases the amount of bombs you can have active at once",
        weight = 1,
        type = powerup_types.max_active_bombs,
        sprite = "mods/evaisa.bombergame/files/gfx/powerups/max_active_bombs.png",
        reset = function()
            GlobalsSetValue("bomberguy_max_active_bombs", "1")
        end,
        pickup = function(player, x, y)
            local active_bombs = tonumber(GlobalsGetValue("bomberguy_max_active_bombs", "1"))
            active_bombs = active_bombs + 1
            GlobalsSetValue("bomberguy_max_active_bombs", tostring(active_bombs))
        end,
    },
    {
        name = "Bomb Passer",
        description = "Allows you to pass through bombs",
        weight = 1,
        type = powerup_types.bomb_collision,
        sprite = "mods/evaisa.bombergame/files/gfx/powerups/bomb_collision.png",
        reset = function()
            GlobalsSetValue("bomberguy_bomb_collision", "1")
        end,
        pickup = function(player, x, y)
            GlobalsSetValue("bomberguy_bomb_collision", "0")
        end,
    },
    {
        name = "Pierce Strength",
        description = "Increases how many crates your explosions can pierce through",
        weight = 1,
        type = powerup_types.box_penetration,
        sprite = "mods/evaisa.bombergame/files/gfx/powerups/box_penetration.png",
        reset = function()
            GlobalsSetValue("bomberguy_box_penetration", "0")
        end,
        pickup = function(player, x, y)
            local penetration = tonumber(GlobalsGetValue("bomberguy_box_penetration", "0"))
            penetration = penetration + 1
            GlobalsSetValue("bomberguy_box_penetration", tostring(penetration))
        end,
    },
    {
        name = "Explosion Expander",
        description = "Increases the power of your bombs",
        weight = 1,
        type = powerup_types.bomb_power,
        sprite = "mods/evaisa.bombergame/files/gfx/powerups/bomb_power.png",
        reset = function()
            GlobalsSetValue("bomberguy_bomb_power", "1")
        end,
        pickup = function(player, x, y)
            local power = tonumber(GlobalsGetValue("bomberguy_bomb_power", "1"))
            power = power + 1
            GlobalsSetValue("bomberguy_bomb_power", tostring(power))
        end,
    },
    {
        name = "Kick",
        description = "Allows the ability to kick bombs",
        weight = 1,
        type = powerup_types.kick_bombs,
        sprite = "mods/evaisa.bombergame/files/gfx/powerups/kick.png",
        reset = function()
            GlobalsSetValue("bomberguy_kick_stacks", "0")
        end,
        pickup = function(player, x, y)
            local power = tonumber(GlobalsGetValue("bomberguy_kick_stacks", "0"))
            power = power + 1
            GlobalsSetValue("bomberguy_kick_stacks", tostring(power))
        end,
    },
}

powerup_colors = {
    [powerup_types.throw_strength] = {0xff, 0x00, 0x00},
    [powerup_types.speed_multipier] = {0x00, 0xff, 0x00},
    --[powerup_types.bomb_cooldown] = {0x00, 0x00, 0xff},
    [powerup_types.max_active_bombs] = {0xff, 0xff, 0x00},
    [powerup_types.bomb_collision] = {0x00, 0xff, 0xff},
    [powerup_types.box_penetration] = {0xff, 0x00, 0xff},
    [powerup_types.bomb_power] = {0xff, 0xff, 0xff},
    [powerup_types.kick_bombs] = {0x7a, 0x49, 0xbf},
}