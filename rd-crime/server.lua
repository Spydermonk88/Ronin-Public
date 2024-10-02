local QBCore = exports['qb-core']:GetCoreObject()

-- Server event for using the headbag
RegisterNetEvent('rd-crime:server:UseHeadbag', function(targetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(targetId)

    -- Check if both players exist
    if not Player or not Target then return end

    -- Check if the target already has a headbag on
    if Target.Functions.GetMetaData('headbag') then
        -- Remove the headbag
        Target.Functions.SetMetaData('headbag', false)
        Player.Functions.AddItem('headbag', 1)
        TriggerClientEvent('rd-crime:client:TakeOffHeadbag', targetId)
        TriggerClientEvent('QBCore:Notify', src, 'You removed the headbag from the player', 'success')
        TriggerClientEvent('QBCore:Notify', targetId, 'The headbag was removed', 'success')
    else
        -- Put on the headbag
        if Player.Functions.RemoveItem('headbag', 1) then
            Target.Functions.SetMetaData('headbag', true)
            TriggerClientEvent('rd-crime:client:PutOnHeadbag', targetId)
            TriggerClientEvent('QBCore:Notify', src, 'You put a headbag on the player', 'success')
            TriggerClientEvent('QBCore:Notify', targetId, 'A headbag was put on you', 'error')
        else
            TriggerClientEvent('QBCore:Notify', src, 'You don\'t have a headbag', 'error')
        end
    end
end)

-- Server event for using the ziptie
RegisterNetEvent('rd-crime:server:UseZipTie', function(targetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(targetId)

    -- Check if both players exist
    if not Player or not Target then return end

    -- Check if the target is already zip-tied
    if Target.Functions.GetMetaData('ziptied') then
        -- Remove the zip tie
        Target.Functions.SetMetaData('ziptied', false)
        Player.Functions.AddItem('ziptie', 1)
        TriggerClientEvent('rd-crime:client:ToggleZipTie', targetId)
        TriggerClientEvent('QBCore:Notify', src, 'You removed the zip tie from the player', 'success')
        TriggerClientEvent('QBCore:Notify', targetId, 'The zip tie was removed', 'success')
    else
        -- Apply the zip tie
        if Player.Functions.RemoveItem('ziptie', 1) then
            Target.Functions.SetMetaData('ziptied', true)
            TriggerClientEvent('rd-crime:client:ToggleZipTie', targetId)
            TriggerClientEvent('QBCore:Notify', src, 'You restrained the player with a zip tie', 'success')
            TriggerClientEvent('QBCore:Notify', targetId, 'You were restrained with a zip tie', 'error')
        else
            TriggerClientEvent('QBCore:Notify', src, 'You don\'t have a zip tie', 'error')
        end
    end
end)

-- You can add more server-side events or functions here if needed
-- For example, you might want to add events for syncing the headbag and ziptie states across all clients

-- Example of a server-side function to check if a player is zip-tied or has a headbag on
QBCore.Functions.CreateCallback('rd-crime:server:CheckPlayerState', function(source, cb, targetId)
    local Target = QBCore.Functions.GetPlayer(targetId)
    if Target then
        local isZipTied = Target.Functions.GetMetaData('ziptied') or false
        local hasHeadbag = Target.Functions.GetMetaData('headbag') or false
        cb(isZipTied, hasHeadbag)
    else
        cb(false, false)
    end
end)

-- You can also add more server-side logic here, such as:
-- - Logging events to a database
-- - Integrating with other server resources
-- - Adding additional checks or permissions for using headbags and zipties