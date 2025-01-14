AddEventHandler('esx:onPlayerSpawn', function()
    TriggerServerEvent('fxinv:playerSpawned')
end)

AddEventHandler('onPlayerSpawned', function()
    TriggerServerEvent('fxinv:playerSpawned')
end)