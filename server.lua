ESX = exports['es_extended']:getSharedObject()

local isDeadly = false
local deathCoords = {}

RegisterServerEvent('esx:onPlayerDeath')
AddEventHandler('esx:onPlayerDeath', function(data)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer then
        deathCoords[source] = xPlayer.getCoords(true)
        isDeadly = true
        --print(deathCoords[source])
    end
end)

RegisterServerEvent('playerSpawned')
AddEventHandler('playerSpawned', function(spawn)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer then
        deathCoords[source] = nil
        isDeadly = false
    end
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    local rawInventory = exports.ox_inventory:Inventory(source).items
    local inventory = {}

    if deathCoords[source] and isDeadly then
        for _,v in pairs(rawInventory) do
            inventory[#inventory + 1] = {
                v.name,
                v.count,
                v.metadata
            }
        end

        if #inventory > 0 then
            exports.ox_inventory:CustomDrop('Loot Drop', inventory, deathCoords[source])
        end
            
        exports.ox_inventory:ClearInventory(source, false)
        --print("Created Drop Loot"..deathCoords[source])
        deathCoords[source] = nil
    end
end)
