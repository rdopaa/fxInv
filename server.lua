ESX = exports['es_extended']:getSharedObject()

local playerStates = {}

RegisterServerEvent('esx:onPlayerDeath')
AddEventHandler('esx:onPlayerDeath', function(data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if xPlayer then
        playerStates[_source] = {
            is_dead = true,
            coords = xPlayer.getCoords(true)
        }
    end
end)

RegisterServerEvent('playerDropped')
AddEventHandler('playerDropped', function(data, reason)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local state = playerStates[_source]

    if state and state.is_dead == true then
        if Config.Debug then
            print("Player is dead, processing inventory drop.")
        end

        local rawInventory = exports.ox_inventory:Inventory(_source).items
        local inventory = {}

        for _, v in pairs(rawInventory) do
            if Config.OnlyWeapon and v.name:sub(1, 7) == 'WEAPON_' then
                table.insert(inventory, { v.name, v.count, v.metadata })
                exports.ox_inventory:RemoveItem(_source, v.name, v.count, v.metadata)
            elseif not Config.OnlyWeapon then
                table.insert(inventory, { v.name, v.count, v.metadata })
            end
        end

        -- Crear el drop si hay ítems en el inventario
        if #inventory > 0 then
            exports.ox_inventory:CustomDrop('Dead Loot', inventory, state.coords)
            if Config.Debug then
                print("Quit drop loot created in: " .. state.coords)
            end
        end

        -- Limpiar el inventario si no es solo armas
        if not Config.OnlyWeapon then
            exports.ox_inventory:ClearInventory(_source, false)
        end
    end

    -- Limpiar estado del jugador
    playerStates[_source] = nil
end)
