game_funcs = dofile("mods/evaisa.mp/files/scripts/game_functions.lua")

local Bombergame = {
    id = "bombergame",
    name = "Bombergame",
    version = 0.1,
    settings = {
    },
    default_data = {
    },
    refresh = function(lobby)

    end,
    enter = function(lobby)
        local game_in_progress = steam.matchmaking.getLobbyData(lobby, "in_progress") == "true"
        if(game_in_progress)then
            ArenaMode.start(lobby)
        end

    end,
    start = function(lobby)

        
        -- kill player entity
        local players = EntityGetWithTag("player_unit")
        for _, player in ipairs(players) do
            EntityKill(player)
        end

        -- spawn player entity
        local new_player = EntityLoad("mods/evaisa.bombergame/files/entities/bomberguy.xml", 0, 0)
        game_funcs.SetPlayerEntity(new_player)
        np.RegisterPlayerEntityId(new_player)

        BiomeMapLoad_KeepPlayer("mods/evaisa.bombergame/files/scripts/biomes/map_arena.lua", "mods/evaisa.bombergame/files/biome/scenes.xml")

    end,
    update = function(lobby)
        local world_state = GameGetWorldStateEntity()
        local world_state_component = EntityGetFirstComponentIncludingDisabled(world_state, "WorldStateComponent")
        ComponentSetValue2(world_state_component, "time", 0.2)
        ComponentSetValue2(world_state_component, "time_dt", 0)
        ComponentSetValue2(world_state_component, "fog", 0)
        ComponentSetValue2(world_state_component, "intro_weather", true)
    end,
    late_update = function(lobby)
    end,
    leave = function(lobby)
    end,
    received = function(lobby, event, message, user)
    end,
    on_projectile_fired = function(lobby, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message)
    end,
    on_projectile_fired_post = function(lobby, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message)
    end
}

table.insert(gamemodes, Bombergame)