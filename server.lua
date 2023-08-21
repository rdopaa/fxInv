ESX = exports['es_extended']:getSharedObject()

local isDeadly = {}  -- Almacenar un estado de jugador si está muerto
local deathCoords = {}  -- Almacenar las coordenadas de muerte

RegisterServerEvent('esx:onPlayerDeath')
AddEventHandler('esx:onPlayerDeath', function(data)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    deathCoords[source] = xPlayer.getCoords(true)
    isDeadly[source] = true
end)

RegisterServerEvent('playerSpawned')
AddEventHandler('playerSpawned', function()
    local source = source

    isDeadly[source] = false
    deathCoords[source] = nil
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    local rawInventory = exports.ox_inventory:Inventory(source).items
    local inventory = {}

    if (isDeadly[source] and deathCoords[source]) then
        if Config.OnlyWeapon then
            for _,v in pairs(rawInventory) do
                if v.name:sub(0, 7) == 'WEAPON_' then
                    inventory[#inventory + 1] = {
                        v.name,
                        v.count,
                        v.metadata
                    }
                    exports.ox_inventory:RemoveItem(source, v.name, v.count, v.metadata)
                end
            end
        else
            for _, v in pairs(rawInventory) do
                inventory[#inventory + 1] = {
                    v.name,
                    v.count,
                    v.metadata
                }
            end
        end
        if #inventory > 0 then
            exports.ox_inventory:CustomDrop(Config.NameLoot, inventory, deathCoords[source])
            if Config.Debug then
                print("Created Loot Dead"..deathCoords[source])
            end
        end
        if not Config.OnlyWeapon then
            exports.ox_inventory:ClearInventory(source, false)
        end
            
        isDeadly[source] = false
        deathCoords[source] = nil
    end
end)

