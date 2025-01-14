ESX = exports['es_extended']:getSharedObject()

local playerCoords = {}

MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS fxinv (
            identifier VARCHAR(50) PRIMARY KEY,
            dead BOOLEAN DEFAULT 0
        )
    ]], {}, function(affectedRows)
        if Config.Debug then
            print("FX-INV: SQL Updated")
        end
    end)
end)

local function ensurePlayerInDatabase(identifier)
    MySQL.Async.fetchScalar("SELECT identifier FROM fxinv WHERE identifier = @identifier", {
        ['@identifier'] = identifier
    }, function(result)
        if not result then
            MySQL.Async.execute("INSERT INTO fxinv (identifier, dead) VALUES (@identifier, 1)", {
                ['@identifier'] = identifier
            })
        end
    end)
end

RegisterServerEvent('esx:onPlayerDeath')
AddEventHandler('esx:onPlayerDeath', function(data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local identifier = GetPlayerIdentifier(_source, 0) -- STEAM

    if xPlayer then
        ensurePlayerInDatabase(identifier)
        MySQL.Async.execute("UPDATE fxinv SET dead = 1 WHERE identifier = @identifier", {
            ['@identifier'] = identifier
        })

        playerCoords[_source] = xPlayer.getCoords(true)
    end
end)

RegisterServerEvent('fxinv:playerSpawned')
AddEventHandler('fxinv:playerSpawned', function()
    local _source = source
    local identifier = GetPlayerIdentifier(_source, 0)

    if identifier then
        MySQL.Async.execute("UPDATE fxinv SET dead = 0 WHERE identifier = @identifier", {
            ['@identifier'] = identifier
        })
    end
end)

AddEventHandler('playerDropped', function(data, reason)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if not xPlayer then return end

    local identifier = GetPlayerIdentifier(_source, 0) -- STEAM
    local coords = playerCoords[_source]
    local inventoryData = exports.ox_inventory:Inventory(_source)
    MySQL.Async.fetchScalar("SELECT dead FROM fxinv WHERE identifier = @identifier", {
        ['@identifier'] = identifier
    }, function(isDead)
        if isDead == true then
            local rawInventory = inventoryData.items
            local inventory = {}

            for _, v in pairs(rawInventory) do
                if Config.OnlyWeapon and v.name:sub(1, 7) == 'WEAPON_' then
                    inventory[#inventory + 1] = { v.name, v.count, v.metadata }
                    exports.ox_inventory:RemoveItem(_source, v.name, v.count, v.metadata)
                elseif not Config.OnlyWeapon then
                    inventory[#inventory + 1] = { v.name, v.count, v.metadata }
                end
            end

            if #inventory > 0 then
                exports.ox_inventory:CustomDrop(_source, inventory, coords)
                if Config.Debug then
                    print("FX-INV: Drop Created in " .. json.encode(coords))
                end
            end

        end
    end)
    if not Config.OnlyWeapon then
        exports.ox_inventory:ClearInventory(_source, false)
    end
    playerCoords[_source] = nil

end)


-- TXAdmin Listening
local function changeState(identifier)
    MySQL.Async.execute("UPDATE fxinv SET dead = 0 WHERE identifier = @identifier", {
        ['@identifier'] = identifier
    })
end
AddEventHandler('txAdmin:events:scheduledRestart', function(source, eventData)
    if eventData.secondsRemaining == 15 then
        local _source = source
        local identifier = GetPlayerIdentifier(_source, 0) -- STEAM

        changeState(identifier)
        playerCoords[_source] = nil
    end
end)

AddEventHandler('txAdmin:events:healedPlayer', function(source)
    if source then
        local _source = source
        local identifier = GetPlayerIdentifier(_source, 0) -- STEAM

        changeState(identifier)
        playerCoords[_source] = nil
    end
end)

