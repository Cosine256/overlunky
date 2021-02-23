meta.name = "Hemophobia"
meta.version = "WIP"
meta.description = "One could call this a true pacifist mode."
meta.author = "Dregu"

health = {4, 4, 4, 4}

set_callback(function()
    set_interval(function()
        for i,player in ipairs(players) do
            if (player.inventory.kills_total > 0 or player.health < health[i]) and player.health > 0 then
                kill_entity(player.uid)
            end
            x, y, l = get_position(player.uid)
            blood = get_entities_at(ENT_TYPE.ITEM_BLOOD, 0, x, y, l, 2.0)
            if #blood > 0 then
                kill_entity(player.uid)
            end
            health[i] = player.health
        end
    end, 5)
end, ON.LEVEL)
