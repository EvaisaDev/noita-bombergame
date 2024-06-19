package.path = package.path .. ";./mods/evaisa.bombergame/lib/?.lua"
package.path = package.path .. ";./mods/evaisa.bombergame/lib/?/init.lua"

local json = dofile("mods/evaisa.mp/lib/json.lua")
local vector = dofile("mods/evaisa.bombergame/lib/vector.lua")
local rng = dofile("mods/evaisa.bombergame/lib/rng.lua")
local delay = dofile("mods/evaisa.bombergame/lib/delay.lua")

game_funcs = dofile("mods/evaisa.mp/files/scripts/game_functions.lua")


local load_scene = false
local load_world = false
local player_entity = nil
local dead = false
local world_loaded = false
local world_start = false
local game_finished = false
local randomized_seed = true

local player_powerups = {}
PlayerHasPowerup = function(user, id)
    for k, v in ipairs(player_powerups[tostring(user)] or {})do
        if(v == id)then
            return true
        end
    end
    return false
end
PlayerGetPowerupStacks = function(user, id)
    local count = 0
    for k, v in ipairs(player_powerups[tostring(user)] or {})do
        if(v == id)then
            count = count + 1
        end
    end
    return count
end

local self_powerups = {}
SelfHasPowerup = function(id)
    for k, v in ipairs(self_powerups)do
        if(v == id)then
            return true
        end
    end
    return false
end
SelfGetPowerupStacks = function(id)
    local count = 0
    for k, v in ipairs(self_powerups)do
        if(v == id)then
            count = count + 1
        end
    end
    return count
end

random = rng.new(0)

debugging = false

dofile("mods/evaisa.bombergame/files/scripts/game_data.lua")

LoadPowerupEntity = function(id, type, x, y)
    local position = vector.new(math.floor(x * 16) + 8, math.floor(y * 16) + 8)
    local powerup = EntityLoad("mods/evaisa.bombergame/files/entities/powerup.xml", position.x, position.y)
    local sprite_comp = EntityGetFirstComponentIncludingDisabled(powerup, "SpriteComponent", "powerup_sprite")

    local powerup_data = powerup_list[type]
    local powerup_sprite = powerup_data.sprite

    ComponentSetValue2(sprite_comp, "image_file", powerup_sprite) 

    EntitySetName(powerup, "powerup_" .. tostring(id))
end

local world_gen = dofile("mods/evaisa.bombergame/files/scripts/world_gen.lua")

GetDestroyedBoxes = function(lobby)
    local destroyed_boxes = steam.matchmaking.getLobbyData(lobby, "bomberguy_box_destroyed")
    if(destroyed_boxes == nil or destroyed_boxes == "")then
        destroyed_boxes = "{}"
    end
    return json.parse(destroyed_boxes)
end

AddDestroyedBox = function(lobby, x, y)
    local destroyed_boxes = GetDestroyedBoxes(lobby)
    if(destroyed_boxes[tostring(x)] == nil )then
        destroyed_boxes[tostring(x)] = {}
    end
    print("destroyed box at " .. tostring(x) .. ", " .. tostring(y))
    destroyed_boxes[tostring(x)][tostring(y)] = true
    steam.matchmaking.setLobbyData(lobby, "bomberguy_box_destroyed", json.stringify(destroyed_boxes))
end

GetBoxDestroyed = function(destroyed_boxes, x, y)
    if(destroyed_boxes[tostring(x)] ~= nil)then
        return destroyed_boxes[tostring(x)][tostring(y)] == true
    end
    return false
end

ClearDestroyedBoxes = function(lobby)
    steam.matchmaking.setLobbyData(lobby, "bomberguy_box_destroyed", "{}")
end

GetTakenPowerups = function(lobby)
    local taken_powerups = steam.matchmaking.getLobbyData(lobby, "bomberguy_taken_powerups")
    if(taken_powerups == nil or taken_powerups == "")then
        taken_powerups = "{}"
    end
    return json.parse(taken_powerups)
end

AddTakenPowerup = function(lobby, x, y)
    local taken_powerups = GetTakenPowerups(lobby)
    if(taken_powerups[tostring(x)] == nil )then
        taken_powerups[tostring(x)] = {}
    end
    print("taken powerup at " .. tostring(x) .. ", " .. tostring(y))
    taken_powerups[tostring(x)][tostring(y)] = true
    steam.matchmaking.setLobbyData(lobby, "bomberguy_taken_powerups", json.stringify(taken_powerups))
end

GetPowerupTaken = function(taken_powerups, x, y)
    if(taken_powerups[tostring(x)] ~= nil)then
        return taken_powerups[tostring(x)][tostring(y)] == true
    end
    return false
end

GetPowerup = function(taken_powerups, x, y)
    if(world_gen.powerup_positions[x] ~= nil)then
        if(world_gen.powerup_positions[x][y] ~= nil and world_gen.powerup_positions[x][y] ~= powerup_types.none)then
            print("powerup at " .. tostring(x) .. ", " .. tostring(y) .. " type: " .. tostring(world_gen.powerup_positions[x][y]))
            
            if(not GetPowerupTaken(taken_powerups, x, y))then
                return world_gen.powerup_positions[x][y]
            end
        end
    end
    return nil
end

ClearTakenPowerups = function(lobby)
    steam.matchmaking.setLobbyData(lobby, "bomberguy_taken_powerups", "{}")
end

GetSpawnedPowerups = function(lobby)
    local spawned_powerups = steam.matchmaking.getLobbyData(lobby, "bomberguy_spawned_powerups")
    if(spawned_powerups == nil or spawned_powerups == "")then
        spawned_powerups = "{}"
    end
    return json.parse(spawned_powerups)
end

AddSpawnedPowerup = function(lobby, x, y, id)
    local spawned_powerups = GetSpawnedPowerups(lobby)
    if(spawned_powerups[tostring(x)] == nil )then
        spawned_powerups[tostring(x)] = {}
    end
    print("spawned powerup at " .. tostring(x) .. ", " .. tostring(y))
    spawned_powerups[tostring(x)][tostring(y)] = id
    steam.matchmaking.setLobbyData(lobby, "bomberguy_spawned_powerups", json.stringify(spawned_powerups))
end

GetSpawnedPowerup = function(spawned_powerups, x, y)
    if(spawned_powerups[tostring(x)] ~= nil)then
        return spawned_powerups[tostring(x)][tostring(y)]
    end
    return nil
end

ClearSpawnedPowerups = function(lobby)
    steam.matchmaking.setLobbyData(lobby, "bomberguy_spawned_powerups", "{}")
end

TakePowerup = function(lobby, x, y)
    local taken_powerups = GetTakenPowerups(lobby)
    local powerup = GetPowerup(taken_powerups, x, y)
    local id = nil
    if(powerup ~= nil)then
        if(steamutils.IsOwner(MP_VERSION <= 302 and lobby or nil))then
            AddTakenPowerup(lobby, x, y)
        end
        local powerup_id = GetSpawnedPowerup(GetSpawnedPowerups(lobby), x, y)
        if(powerup_id ~= nil)then
            id = powerup_id
            local powerup_entity = EntityGetWithName("powerup_" .. tostring(powerup_id))
            if(powerup_entity ~= nil)then
                EntityKill(powerup_entity)
                local powerup_data = powerup_list[powerup]
                if(powerup_data ~= nil)then
                    local players = EntityGetWithTag("player_unit")
                    if(players ~= nil and players[1] ~= nil)then
                        local player = players[1]
                        powerup_data.pickup(player, x * 16 + 8, y * 16 + 8)
                        table.insert(self_powerups, powerup)
                    end
                end
            end
        end
        steamutils.send("powerup_taken", {x = x, y = y, id = id}, steamutils.messageTypes.OtherPlayers, lobby, true, true)
        return powerup
    end
    return nil
end

GetPlayerIndex = function(lobby)
    local player_ids = {}
    local members = steamutils.getLobbyMembers(lobby)
    for i, member in ipairs(members) do
        table.insert(player_ids, tostring(member.id))
    end
    table.sort(player_ids, function(a, b) return a < b end)
    local local_player = tostring(steam.user.getSteamID())
    for i, player_id in ipairs(player_ids) do
        --print(player_id)
        if(player_id == local_player)then
            --GamePrint("player index: "..tostring(i))
            return i
        end
    end
    return 1
end

ResetPowerupData = function()
    for k, v in ipairs(powerup_list)do
        v.reset()
    end
end

Bombergame = {
    id = "bombergame",
    name = "Bombergame",
    version = 0.32,
    version_flavor_text = "Release",
    allow_in_progress_joining = false,
    settings = {
        {
            id = "random_seed",
            name = "Random Seed",
            description = "Randomized seed every restart.",
            type = "bool",
            default = true
        },  
        {
			id = "map_size_x",
            require = function(setting_self)
                return true
            end,
			name = "Arena Size Horizontal",
			description = "How many squares should the Arena be horizontally",
			type = "slider",
			min = 5,
			max = 61,
			default = 11;
			display_multiplier = 1,
			formatting_string = " $0",
			width = 100,
            modifier = function(value)
                value = math.floor(value)
                -- turn the value odd if it is not
                if(value % 2 == 0)then
                    value = value + 1
                end
                return value
            end,
		},
        {
			id = "map_size_y",
            require = function(setting_self)
                return true
            end,
			name = "Arena Size Vertical",
			description = "How many squares should the Arena be vertically",
			type = "slider",
			min = 5,
			max = 61,
			default = 11;
			display_multiplier = 1,
			formatting_string = " $0",
			width = 100,
            modifier = function(value)
                value = math.floor(value)
                -- turn the value odd if it is not
                if(value % 2 == 0)then
                    value = value + 1
                end
                return value
            end,
		},
        {
			id = "crate_percentage",
            require = function(setting_self)
                return true
            end,
			name = "Crate Percentage",
			description = "What percentage of the map should be filled with crates",
			type = "slider",
			min = 0,
			max = 1,
			default = 0.85;
			display_multiplier = 1,
            display_fractions = true,
			formatting_string = " $0",
			width = 100,
            modifier = function(value)
                -- round to 2 decimals
                value = math.floor(value * 100) / 100
                return value
            end,
		},
        {
			id = "powerup_percentage",
            require = function(setting_self)
                return true
            end,
			name = "Powerup Percentage",
			description = "What percentage of crates should hide powerups",
			type = "slider",
			min = 0,
			max = 1,
			default = 0.1;
			display_multiplier = 1,
            display_fractions = true,
			formatting_string = " $0",
			width = 100,
            modifier = function(value)
                -- round to 2 decimals
                value = math.floor(value * 100) / 100
                return value
            end,
		},
        {
			id = "explosive_percentage",
            require = function(setting_self)
                return true
            end,
			name = "Explosive Probability",
			description = "The spawn probability of explosive crates",
			type = "slider",
			min = 0,
			max = 2,
			default = 0.1;
			display_multiplier = 1,
            display_fractions = true,
			formatting_string = " $0",
			width = 100,
            modifier = function(value)
                -- round to 2 decimals
                value = math.floor(value * 100) / 100
                return value
            end,
		},
        {
            id = "player_collisions",
            name = "Player Collisions",
            description = "Players block eachother from moving past",
            type = "bool",
            default = true
        },  
    },
    default_data = {
    },
    refresh = function(lobby)
        local random_seeds = steam.matchmaking.getLobbyData(lobby, "setting_random_seed")
        if (random_seeds == nil) then
            random_seeds = "true"
        end
        randomized_seed = random_seeds == "true"


        
        local map_size_x = steam.matchmaking.getLobbyData(lobby, "setting_map_size_x")
        if (map_size_x == nil) then
            map_size_x = 11
        end
        GlobalsSetValue("bomberguy_arena_size_x", tostring(math.floor(map_size_x)))

        local map_size_y = steam.matchmaking.getLobbyData(lobby, "setting_map_size_y")
        if (map_size_y == nil) then
            map_size_y = 11
        end
        GlobalsSetValue("bomberguy_arena_size_y", tostring(math.floor(map_size_y)))

        local crate_percentage = steam.matchmaking.getLobbyData(lobby, "setting_crate_percentage")
        if (crate_percentage == nil) then
            crate_percentage = 0.85
        end
        GlobalsSetValue("bomberguy_crate_percentage", tostring(crate_percentage))

        local powerup_percentage = steam.matchmaking.getLobbyData(lobby, "setting_powerup_percentage")
        if (powerup_percentage == nil) then
            powerup_percentage = 0.1
        end
        GlobalsSetValue("bomberguy_powerup_percentage", tostring(powerup_percentage))

        local explosive_percentage = steam.matchmaking.getLobbyData(lobby, "setting_explosive_percentage")
        if (explosive_percentage == nil) then
            explosive_percentage = 0.1
        end
        GlobalsSetValue("bomberguy_explosive_percentage", tostring(explosive_percentage))

        local player_collisions = steam.matchmaking.getLobbyData(lobby, "setting_player_collisions")
        if (player_collisions == nil) then
            player_collisions = "true"
        end
        if(player_collisions == "true")then
            GameAddFlagRun("player_collisions")
        else
            GameRemoveFlagRun("player_collisions")
        end
    end,
    enter = function(lobby)
        Bombergame.refresh(lobby)
        world_gen:clear_scene()
    end,
    start = function(lobby)
        delay.new(60, function()
            GlobalsSetValue("bomberguy_destroyed_boxes", "[]")
            GlobalsSetValue("bombergame_current_bombs", "[]")
            ResetPowerupData()
            
            load_scene = false
            load_world = false
            dead = false
            world_loaded = false
            world_start = false
            game_finished = false
            GameAddFlagRun("DisableExplosions")
            GameRemoveFlagRun("local_user_kicked_bomb")
            delay.reset()

            GameSetCameraFree( false )



            if(steamutils.IsOwner(MP_VERSION <= 302 and lobby or nil))then
                ClearDestroyedBoxes(lobby)
                ClearTakenPowerups(lobby)
                ClearSpawnedPowerups(lobby)
                steam.matchmaking.setLobbyData(lobby, "dead_players", "{}")
                print("cleared deadplayer data")
            end

            local dead_players_data = steam.matchmaking.getLobbyData(lobby, "dead_players")
            if(dead_players_data == nil or dead_players_data == "")then
                dead_players_data = "{}"
            end

            local dead_players = json.parse(dead_players_data)

            local local_player = steam.user.getSteamID()

            print(dead_players_data)

            if(dead_players[tostring(local_player)])then
                dead = true
                GameSetCameraFree( true )
            end
            
            seed = tonumber(steam.matchmaking.getLobbyData(lobby, "seed") or 1)

            if(randomized_seed and steamutils.IsOwner(MP_VERSION <= 302 and lobby or nil))then
                print("randomizing seed")
                local a, b, c, d, e, f = GameGetDateAndTimeLocal()
                SetRandomSeed(GameGetFrameNum() + a + b + c + d + e + f+ 235123, GameGetFrameNum() + a + b + c + d + e + f + 325325)
                --steam.matchmaking.setLobbyData(lobby, "seed", tostring(Random(1, 1000000000)))
                seed = Random(1, 1000000000)
                steam.matchmaking.setLobbyData(lobby, "rng_seed", tostring(seed))
                print("randomized seed")
                
                steam.matchmaking.setLobbyData(lobby, "spawnpoint_count", tostring(steamutils.getPlayerCount(lobby, false, true)))
            end


            if(randomized_seed)then
                seed = tonumber(steam.matchmaking.getLobbyData(lobby, "rng_seed") or 1)
            end
        -- SetWorldSeed( seed )

            random = rng.new(seed)
            print("seed: "..tostring(seed))

            --SetRandomSeed(0, 0)

            -- kill player entity
            local players = EntityGetWithTag("player_unit")
            for _, player in ipairs(players) do
                EntityKill(player)
            end

            -- spawn player entity
            if(not dead)then
                player_entity = EntityLoad("mods/evaisa.bombergame/files/entities/bomberguy.xml", 0, 0)
                game_funcs.SetPlayerEntity(player_entity)
                np.RegisterPlayerEntityId(player_entity)
            end

            --BiomeMapLoad_KeepPlayer("mods/evaisa.bombergame/files/scripts/biomes/map_arena.lua", "mods/evaisa.bombergame/files/biome/scenes.xml")


            for k, v in ipairs(EntityGetWithTag("cleanup_mark") or {})do
                local lua_components = EntityGetComponent(v, "LuaComponent") or {}
                for k2, v2 in ipairs(lua_components)do
                    ComponentSetValue2(v2, "execute_on_removed", false)
                    EntityRemoveComponent(v, v2)
                end
                EntityKill(v)
            end
            

            load_world = true
            
        end)
    end,
    update = function(lobby)
        delay.update()
        if(load_world)then
            GamePrint("loading world with seed: "..tostring(seed))
            print("loading world with seed: "..tostring(seed))
            local arena_size_x = tonumber(GlobalsGetValue("bomberguy_arena_size_x", "11"))
            local arena_size_y = tonumber(GlobalsGetValue("bomberguy_arena_size_y", "11"))
            world_gen:generate(lobby, vector.new(arena_size_x, arena_size_y), tonumber(GlobalsGetValue("bomberguy_crate_percentage", "0.85")), tonumber(GlobalsGetValue("bomberguy_powerup_percentage", "0.1")), tonumber(steam.matchmaking.getLobbyData(lobby, "spawnpoint_count") or 32))

            local spawn_pos = world_gen:GetSpawnPoint(GetPlayerIndex(lobby))
    
            if(not dead)then
                EntitySetTransform(player_entity, spawn_pos.x, spawn_pos.y)
                EntityApplyTransform(player_entity, spawn_pos.x, spawn_pos.y)
            elseif(not world_loaded)then
                GameSetCameraPos(spawn_pos.x, spawn_pos.y)
            end
            load_world = false
            world_loaded = true
        elseif(world_loaded and not world_start)then
            world_start = true
            GameRemoveFlagRun("DisableExplosions")
            print("explosions are allowed!")
        end

        --if(world_loaded)then
        dofile("mods/evaisa.bombergame/files/scripts/player_controller.lua")
        --end

        local world_state = GameGetWorldStateEntity()
        local world_state_component = EntityGetFirstComponentIncludingDisabled(world_state, "WorldStateComponent")
        ComponentSetValue2(world_state_component, "time", 0.2)
        ComponentSetValue2(world_state_component, "time_dt", 0)
        ComponentSetValue2(world_state_component, "fog", 0)
        ComponentSetValue2(world_state_component, "intro_weather", true)
    end,
    late_update = function(lobby)
        local taken_powerups = GetTakenPowerups(lobby)

        local camera_x, camera_y = GameGetCameraPos()

        local powerups = EntityGetInRadiusWithTag(camera_x, camera_y, 500, "powerup") or {}

        for k, v in ipairs(powerups)do
            local pos_x, pos_y = EntityGetTransform(v)
            local cell_x, cell_y = math.floor(pos_x / 16), math.floor(pos_y / 16)

            local taken = GetPowerupTaken(taken_powerups, cell_x, cell_y)

            if(taken)then
                EntityKill(v)
            end
        end


        if(world_loaded)then

            local destroyed_boxes = json.parse(GlobalsGetValue("bomberguy_destroyed_boxes", "[]"))
            for k, v in ipairs(destroyed_boxes)do
                local box_cell = {math.floor(v.x / 16), math.floor(v.y / 16)}
                steamutils.send("box_destroyed", box_cell, steamutils.messageTypes.OtherPlayers, lobby, true, true)
                -- check if box contains powerup
                if(steamutils.IsOwner(MP_VERSION <= 302 and lobby or nil))then
                    AddDestroyedBox(lobby, box_cell[1], box_cell[2])
                    
                    local powerup = GetPowerup(taken_powerups, box_cell[1], box_cell[2])

                    if(powerup)then
                        local id = random.range(1, 100000000)
                        LoadPowerupEntity(id, powerup, box_cell[1], box_cell[2])
                        AddSpawnedPowerup(lobby, box_cell[1], box_cell[2], id)
                        steamutils.send("powerup_spawned", {id, powerup, box_cell[1], box_cell[2]}, steamutils.messageTypes.OtherPlayers, lobby, true, true)
                    end
                end
            end
            GlobalsSetValue("bomberguy_destroyed_boxes", "[]")

            local current_bombs = json.parse(GlobalsGetValue("bombergame_current_bombs", "[]"))
            for k, v in ipairs(current_bombs)do
               -- print(json.stringify(v))
                steamutils.send("bomb_placed", v, steamutils.messageTypes.OtherPlayers, lobby, true, true)
            end
            GlobalsSetValue("bombergame_current_bombs", "[]")

            local player_bombs = EntityGetWithTag("player_bomb") or {}

            for k, v in ipairs(player_bombs)do
                local physbodyComp = EntityGetFirstComponentIncludingDisabled(v, "PhysicsBodyComponent")

                if physbodyComp then
                    
                    local x, y, r, vx, vy, av = PhysicsComponentGetTransform(physbodyComp)

                    --print("bomb update: "..x..", "..y..", "..r..", "..vx..", "..vy..", "..av)

                    steamutils.send("bomb_update", {
                        x = x,
                        y = y,
                        r = r,
                        vx = vx,
                        vy = vy,
                        av = av,
                        name = EntityGetName(v)
                    }, steamutils.messageTypes.OtherPlayers, lobby, false, true)
                    
                end
            end

            local function DeathHandler()
                steamutils.send("player_died", {}, steamutils.messageTypes.OtherPlayers, lobby, true, true)
                GameSetCameraFree( true )
                if(steamutils.IsOwner(MP_VERSION <= 302 and lobby or nil))then
                    local dead_players_data = steam.matchmaking.getLobbyData(lobby, "dead_players")
                    if(dead_players_data == nil or dead_players_data == "")then
                        dead_players_data = "{}"
                    end

                    local dead_players = json.parse(dead_players_data)

                    dead_players[tostring(steam.user.getSteamID())] = true

                    steam.matchmaking.setLobbyData(lobby, "dead_players", json.stringify(dead_players))
                end
            end

            local players = EntityGetWithTag("player_unit")
            if(players ~= nil)then
                if(players[1] and EntityGetIsAlive(players[1]))then
                    local player = players[1]
                    local x, y, r, w, h = EntityGetTransform(player)
                    local character_data_component = EntityGetFirstComponentIncludingDisabled( player, "CharacterDataComponent" )

                    local vel_x, vel_y = 0, 0
                    if(character_data_component ~= nil)then
                        vel_x, vel_y = ComponentGetValue2(character_data_component, "mVelocity")
                    end

                    local sprite_comp = EntityGetFirstComponentIncludingDisabled( player, "SpriteComponent", "body_top" )

                    animation = ComponentGetValue2(sprite_comp, "rect_animation")

                    if(animation == nil or animation == "")then
                        animation = "stand_down"
                    end

                    steamutils.send("player_update", {
                        x = x,
                        y = y,
                        r = r,
                        w = w,
                        h = h,
                        vel_x = vel_x,
                        vel_y = vel_y,
                        animation = animation
                    }, steamutils.messageTypes.OtherPlayers, lobby, false, true)


                    if(GameHasFlagRun("local_user_kicked_bomb"))then
                        local direction_x = tonumber(GlobalsGetValue("bomberguy_last_direction_x", "0"))
                        local direction_y = tonumber(GlobalsGetValue("bomberguy_last_direction_y", "1"))
                        steamutils.send("player_kick", {x = x, y = y, direction_x = direction_x, direction_y = direction_y}, steamutils.messageTypes.OtherPlayers, lobby, true, true)
                        GameRemoveFlagRun("local_user_kicked_bomb")
                    end


                    if(GameHasFlagRun("took_damage"))then
                        local info = GlobalsGetValue("last_damage_details", "")
                        if(info ~= nil and info ~= "")then
                            steamutils.send("player_took_damage", json.parse(info), steamutils.messageTypes.OtherPlayers, lobby, true, true)
                        end
                        GameRemoveFlagRun("took_damage")
                        GlobalsSetValue("last_damage_details", "")
                    end

                    --local cell_x = math.floor(x / 16)
                    --local cell_y = math.floor(y / 16)

                    --[[
                    local taken_powerups = GetTakenPowerups(lobby)
                    local powerup = GetPowerup(taken_powerups, cell_x, cell_y)

                    if(powerup ~= nil and powerup ~= powerup_types.none)then
                        TakePowerup(lobby, cell_x, cell_y)
                    end
                    ]]

                    local current_pickups = GlobalsGetValue("current_pickups", "[]")
                    local current_pickups_table = json.parse(current_pickups)

                    for k, v in ipairs(current_pickups_table)do
                        TakePowerup(lobby, math.floor(v.x / 16), math.floor(v.y / 16))
                    end

                    GlobalsSetValue("current_pickups", "[]")
                elseif(dead == false)then
                    DeathHandler()
                    dead = true
                end
            elseif(dead == false)then
                DeathHandler()
                dead = true
            end

            local GetAlivePlayers = function()
                local members_alive = {}
                local members = steamutils.getLobbyMembers(lobby)
                local no_members = true
                for k, member in pairs(members) do
                    no_members = false
                    local dead_players_data = steam.matchmaking.getLobbyData(lobby, "dead_players")
                    if(dead_players_data == nil or dead_players_data == "")then
                        dead_players_data = "{}"
                    end
    
                    local dead_players = json.parse(dead_players_data)
                    
                    if(not dead_players[tostring(member.id)])then
                        --print("member is alive")
                        table.insert(members_alive, member.id)
                    end
                end

                if(no_members)then
                    return {steam.user.getSteamID()}
                end

                return members_alive
            end

            local client_entities = EntityGetWithTag("client") or {}

            game_funcs.RenderOffScreenMarkers(client_entities)
            --game_funcs.RenderAboveHeadMarkers(client_entities, 0, 34)

            local alive_players = GetAlivePlayers()
            local members = steam.matchmaking.getNumLobbyMembers(lobby)

            --print("alivecount: "..tostring(#alive_players))
            --print("membercount: "..tostring(members))

            if(not game_finished)then
                if(#alive_players == 0)then
                    GamePrintImportant("Everyone died!", "It is a tie!")
                    game_finished = true
                    --world_loaded = false
                    if(steamutils.IsOwner(MP_VERSION <= 302 and lobby or nil))then
                        steam.matchmaking.setLobbyData(lobby, "in_progress", "false")
                    end
                    GameAddFlagRun("DisableExplosions")

                    delay.new(10 * 60, function()
                        GameAddFlagRun("DisableExplosions")
                        StopGame()
                        local players = EntityGetWithTag("player_unit") or {}
                        for _, player in ipairs(players) do
                            EntityKill(player)
                        end
                        local backgrounds = EntityGetWithTag("background") or {}
                        for _, v in ipairs(backgrounds) do
                            EntityKill(v)
                        end
                        for _, client in ipairs(client_entities)do
                            EntityKill(client)
                        end
                        for _, powerup in ipairs(EntityGetWithTag("powerup") or {})do
                            EntityKill(powerup)
                        end
                        world_gen:clear_scene()
                    end, function(frames)
                        if (frames % 60 == 0) then
                            GamePrint(string.format("Returning to lobby menu in %s seconds.", tostring(math.floor(frames / 60))))
                        end
                    end)
                elseif(#alive_players == 1 and members > 1)then
                    --print(tostring(alive_players[1]))
                    local player_name = steamutils.getTranslatedPersonaName(alive_players[1])
                    GamePrintImportant(player_name.." won!", "Congratulations!")
                    game_finished = true
                    if(steamutils.IsOwner(MP_VERSION <= 302 and lobby or nil))then
                        steam.matchmaking.setLobbyData(lobby, "in_progress", "false")
                    end
                    GameAddFlagRun("DisableExplosions")

                    delay.new(10 * 60, function()
                        GameAddFlagRun("DisableExplosions")
                        StopGame()
                        local players = EntityGetWithTag("player_unit") or {}
                        for _, player in ipairs(players) do
                            EntityKill(player)
                        end
                        local backgrounds = EntityGetWithTag("background") or {}
                        for _, v in ipairs(backgrounds) do
                            EntityKill(v)
                        end
                        for _, client in ipairs(client_entities)do
                            EntityKill(client)
                        end
                        for _, powerup in ipairs(EntityGetWithTag("powerup") or {})do
                            EntityKill(powerup)
                        end
                        world_gen:clear_scene()
                    end, function(frames)
                        if (frames % 60 == 0) then
                            GamePrint(string.format("Returning to lobby menu in %s seconds.", tostring(math.floor(frames / 60))))
                        end
                    end)
                    --world_loaded = false
                end
            end
        end
    end,
    leave = function(lobby)
    end,
    disconnected = function(lobby, user)
        local player_name = steamutils.getTranslatedPersonaName(user)

        if(player_name ~= nil)then
            GamePrint(player_name.." left this realm!")
            print(player_name.." left this realm!")
        end

        if(steamutils.IsOwner(MP_VERSION <= 302 and lobby or nil))then
            local dead_players_data = steam.matchmaking.getLobbyData(lobby, "dead_players")
            if(dead_players_data == nil or dead_players_data == "")then
                dead_players_data = "{}"
            end

            local dead_players = json.parse(dead_players_data)

            dead_players[tostring(user)] = true

            --print(json.stringify(dead_players))

            steam.matchmaking.setLobbyData(lobby, "dead_players", json.stringify(dead_players))
        end

        local client = EntityGetWithName("player_"..tostring(user))
        if(client ~= nil)then
            EntityInflictDamage(client, 10, "DAMAGE_EXPLOSION", "bomb_hit", "BLOOD_EXPLOSION", 0, 0, GameGetWorldStateEntity())
        end
    end,
    received = function(lobby, event, message, user)
        local events = {
            box_destroyed = function(lobby, event, message, user)
                if(steamutils.IsOwner(MP_VERSION <= 302 and lobby or nil))then
                    AddDestroyedBox(lobby, message[1], message[2])

                    local taken_powerups = GetTakenPowerups(lobby)
                    local powerup = GetPowerup(taken_powerups, message[1], message[2])
    
                    if(powerup)then
                        local id = random.range(1, 100000000)
                        LoadPowerupEntity(id, powerup, message[1], message[2])
                        AddSpawnedPowerup(lobby, message[1], message[2], id)
                        steamutils.send("powerup_spawned", {id, powerup, message[1], message[2]}, steamutils.messageTypes.OtherPlayers, lobby, true, true)
                    end
                end


                local real_position = vector.new(message[1] * 16, message[2] * 16)
                -- check if there is a bomb_hittable entity
                local hittables = EntityGetInRadiusWithTag(real_position.x + 8, real_position.y + 8, 4, "bomb_hittable") or {}
                for k, v in ipairs(hittables)do
                    if(debugging)then
                        GameCreateSpriteForXFrames("data/ui_gfx/debug_marker.png", real_position.x + 8, real_position.y + 8, true, 0, 0, 240, true)
                    end
                    --EntityInflictDamage(v, 5, "DAMAGE_EXPLOSION", "bomb_hit", "NORMAL", 0, 0)
                    local lua_components = EntityGetComponent(v, "LuaComponent") or {}
                    for k2, v2 in ipairs(lua_components)do
                        ComponentSetValue2(v2, "execute_on_removed", false)
                        EntityRemoveComponent(v, v2)
                    end
                    EntityKill(v)
                end
            end,
            powerup_spawned = function(lobby, event, message, user)
                local id = message[1]
                local powerup = message[2]
                local x = message[3]
                local y = message[4]

                LoadPowerupEntity(id, powerup, x, y)
            end,
            player_kick = function(lobby, event, message, user)
                if(PlayerHasPowerup(user, powerup_types.kick_bombs))then
                    local client = EntityGetWithName("player_"..tostring(user))
                    if(client ~= 0 and client ~= nil)then
                        local direction_x = message.direction_x
                        local direction_y = message.direction_y
                        local x = message.x
                        local y = message.y
                        local stacks = PlayerGetPowerupStacks(user, powerup_types.kick_bombs)
                        local kick_radius = 10
                        local kick_power = 20 * stacks
                        local bombs_nearby = EntityGetInRadiusWithTag(x, y, kick_radius, "local_bomb")
                        for k, v in ipairs(bombs_nearby)do
                            local ids = PhysicsBodyIDGetFromEntity(v)
                            for k2, v2 in ipairs(ids) do
                                PhysicsBodyIDApplyForce(v2, (direction_x * kick_power), (direction_y * kick_power), x, y)
                                if(PhysicsBodyIDGetGravityScale(v2) ~= 0)then
                                    PhysicsBodyIDSetGravityScale(v2, 0)
                                end
                            end
                        end
                    end
                end
            end,
            bomb_placed = function(lobby, event, message, user)
                --[[
                    {
                        id = custom_id,
                        x = bomb_location_x,
                        y = bomb_location_y,
                        throw_target_x = throw_target_x,
                        throw_target_y = throw_target_y,
                        box_penetration = box_penetration,
                        bomb_power = bomb_power,
                    }
                ]]

                local bomb_collision = tonumber(GlobalsGetValue("bomberguy_bomb_collision", "1"))
                local bomb_projectile = "mods/evaisa.bombergame/files/entities/bomb.xml"
    
                if(bomb_collision == 0)then
                    bomb_projectile = "mods/evaisa.bombergame/files/entities/bomb_nocollide.xml"
                end

                local bomb = EntityLoad(bomb_projectile, message.x, message.y)

                -- set penetration and power variablestoragecomponents
                local penetration = EntityGetFirstComponentIncludingDisabled(bomb, "VariableStorageComponent", "penetration")
                if(penetration ~= nil)then
                    ComponentSetValue2(penetration, "value_int", message.box_penetration)
                end

                local power = EntityGetFirstComponentIncludingDisabled(bomb, "VariableStorageComponent", "power")
                if(power ~= nil)then
                    ComponentSetValue2(power, "value_int", message.bomb_power)
                end
            
                EntitySetName(bomb, "bomb_"..tostring(message.id))

                local bomb_bodies = PhysicsBodyIDGetFromEntity(bomb)
                for k, v in ipairs(bomb_bodies) do
                    PhysicsBodyIDSetGravityScale(v, 0)
                end
            end,
            bomb_update = function(lobby, event, message, user)
                local bomb = EntityGetWithName(message.name)
                if(bomb)then
                    local physbodyComp = EntityGetFirstComponentIncludingDisabled(bomb, "PhysicsBodyComponent")

                    if physbodyComp then
                        PhysicsComponentSetTransform(physbodyComp, message.x, message.y, message.r, message.vx, message.vy, message.av)
                    end
                end
            end,
            player_update = function(lobby, event, message, user)
                local client = EntityGetWithName("player_"..tostring(user))
                if(client == 0 or client == nil)then
                    local gui = GuiCreate()
                    GuiStartFrame(gui)

                    client = EntityLoad("mods/evaisa.bombergame/files/entities/bomberguy_client.xml", message.x, message.y)
                    EntitySetName(client, "player_"..tostring(user))
                    local usernameSprite = EntityGetFirstComponentIncludingDisabled(client, "SpriteComponent", "username")
                    local name = steamutils.getTranslatedPersonaName(user)
                    local offset = GuiGetTextDimensions( gui, name, 0.7 ) * 1.4
                    GuiDestroy(gui)
                    ComponentSetValue2(usernameSprite, "text", name)
                    ComponentSetValue2(usernameSprite, "offset_x", offset / 2)
                end

                EntityApplyTransform(client, message.x, message.y, message.r, message.w, message.h)

                --[[local physics_body_ids = PhysicsBodyIDGetFromEntity(client)
                if(physics_body_ids ~= nil and physics_body_ids[1] ~= nil)then
                    local body_x, body_y = GamePosToPhysicsPos(message.x - 3, message.y - 3)
                    PhysicsBodyIDSetTransform(physics_body_ids[1], body_x, body_y, 0, 0, 0)
                    PhysicsBodyIDSetDamping(physics_body_ids[1], 100000, 100000)
                    PhysicsBodyIDSetGravityScale(physics_body_ids[1], 0)
                end]]

                local character_data_component = EntityGetFirstComponentIncludingDisabled( client, "CharacterDataComponent" )

                if(character_data_component ~= nil)then
                    ComponentSetValue2(character_data_component, "mVelocity", message.vel_x, message.vel_y)
                end

                local current_animation = ""
                local sprite_comp = EntityGetFirstComponentIncludingDisabled( client, "SpriteComponent", "body_top" )

                if(sprite_comp ~= nil)then
                    current_animation = ComponentGetValue2(sprite_comp, "rect_animation")
                end

                if(current_animation ~= message.animation)then
                    GamePlayAnimation(client, message.animation, 0)
                end
            end,
            player_died = function(lobby, event, message, user)
                local client = EntityGetWithName("player_"..tostring(user))
                if(client ~= nil)then
                    EntityInflictDamage(client, 10, "DAMAGE_EXPLOSION", "bomb_hit", "BLOOD_EXPLOSION", 0, 0, GameGetWorldStateEntity())
                end

                local player_name = steamutils.getTranslatedPersonaName(user)

                if(player_name ~= nil)then
                    GamePrint(player_name.." blew up!")
                    print(player_name.." blew up!")
                end

                if(steamutils.IsOwner(MP_VERSION <= 302 and lobby or nil))then
                    local dead_players_data = steam.matchmaking.getLobbyData(lobby, "dead_players")
                    if(dead_players_data == nil or dead_players_data == "")then
                        dead_players_data = "{}"
                    end

                    local dead_players = json.parse(dead_players_data)

                    dead_players[tostring(user)] = true

                    steam.matchmaking.setLobbyData(lobby, "dead_players", json.stringify(dead_players))
                end
            end,
            player_took_damage = function(lobby, event, message, user)
                local client = EntityGetWithName("player_"..tostring(user))
                if(client ~= nil)then
                    --[[
                        damage_details = {
                            ragdoll_fx = 1 
                            damage_types = 16 -- bitflag
                            knockback_force = 0    
                            impulse = {0, 0},
                            world_pos = {216.21, 12.583},
                        }
                        local details = {
                            damage = damage,
                            message = message,
                            details = damage_details,
                        }
                    ]]

                    print("player took damage")
                    EntityInflictDamage(client, message.damage, "DAMAGE_EXPLOSION", "bomb_hit", "BLOOD_EXPLOSION", message.details.impulse[1], message.details.impulse[2], nil, message.details.world_pos[1], message.details.world_pos[2], message.details.knockback_force)
                end
            end,
            powerup_taken = function(lobby, event, message, user)
                print("powerup taken")
                if(player_powerups[tostring(user)] == nil)then
                    player_powerups[tostring(user)] = {}
                end

                table.insert(player_powerups[tostring(user)], message.id)
                if(message.id)then
                    local powerup = EntityGetWithName("powerup_"..tostring(message.id))
                    if(powerup ~= nil)then
                        EntityKill(powerup)
                    end
                else
                    -- try to find entity at position
                    local powerup = EntityGetInRadiusWithTag((message.x * 16) + 8, (message.y * 16) + 8, 8, "powerup")
                    if(powerup ~= nil)then
                        EntityKill(powerup[1])
                    end
                end
                if(steamutils.IsOwner(MP_VERSION <= 302 and lobby or nil))then
                    AddTakenPowerup(lobby, message.x, message.y)
                end
            end,
        }
        if(events[event])then
            events[event](lobby, event, message, user)
        end
    end,
    on_projectile_fired = function(lobby, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message)
    end,
    on_projectile_fired_post = function(lobby, shooter_id, projectile_id, rng, position_x, position_y, target_x, target_y, send_message)
    end
}

table.insert(gamemodes, Bombergame)