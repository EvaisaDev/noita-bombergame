local post_final = ModTextFileGetContent("data/shaders/post_final.frag")

post_final = string.gsub(post_final, "const bool ENABLE_LIGHTING	    		= 1>0;", "const bool ENABLE_LIGHTING	    		= 1<0;")

ModTextFileSetContent("data/shaders/post_final.frag", post_final)

if(ModIsEnabled("evaisa.mp"))then
    ModLuaFileAppend("mods/evaisa.mp/data/gamemodes.lua", "mods/evaisa.bombergame/files/gamemode.lua")
end

ModMagicNumbersFileAdd("mods/evaisa.bombergame/files/magic.xml")
ModMaterialsFileAdd("mods/evaisa.bombergame/files/materials.xml")

function OnPlayerSpawned(player)
    --GlobalsSetValue("bomberguy_bomb_collision", "0")
    --GlobalsSetValue("bomberguy_bomb_power", "3")
    EntityKill(player)
end