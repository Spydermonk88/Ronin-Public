local QBCore = exports['qb-core']:GetCoreObject()
local headbagOn = false

-- Helper function to check player status
local function IsZipTied()
    return QBCore.Functions.GetPlayerData().metadata['ziptied'] or false
end

local function HasHandsUp(targetPed)
    return IsEntityPlayingAnim(targetPed, "missminuteman_1ig_2", "handsup_base", 3)
end

-- Function to apply the headbag effect
local function ApplyHeadbagEffect()
    Citizen.CreateThread(function()
        while headbagOn do
            -- Draw black rectangle covering the entire screen
            DrawRect(0.5, 0.5, 1.0, 1.0, 0, 0, 0, 255)
            
            -- Hide radar/minimap
            DisplayRadar(false)
            
            -- Disable GPS
            SetGpsActive(false)
            
            -- Hide HUD based on config
            if Config.HudSystem == 'crm-hud' then
                exports['crm-hud']:crm_toggle_hud(false)
            elseif Config.HudSystem == 'qb-hud' then
                TriggerEvent("qb-hud:client:SetHud", false)
            end
            
            Wait(0)
        end
    end)
end

-- Event handler for putting on the headbag
RegisterNetEvent('rd-crime:client:PutOnHeadbag', function()
    headbagOn = true
    ApplyHeadbagEffect()
end)

-- Event handler for taking off the headbag
RegisterNetEvent('rd-crime:client:TakeOffHeadbag', function()
    headbagOn = false
    DisplayRadar(true) -- Show radar/minimap again
    SetGpsActive(true)
    
    -- Show HUD based on config
    if Config.HudSystem == 'crm-hud' then
        exports['crm-hud']:crm_toggle_hud(true)
    elseif Config.HudSystem == 'qb-hud' then
        TriggerEvent("qb-hud:client:SetHud", true)
    end
end)

-- Event handler for ziptie
RegisterNetEvent('rd-crime:client:ToggleZipTie', function()
    local ped = PlayerPedId()
    local ziptied = IsZipTied()
    
    if ziptied then
        -- Disable inventory based on config
        if Config.InventorySystem == 'qs-inventory' then
            exports['qs-inventory']:setInventoryDisabled(true)
        elseif Config.InventorySystem == 'qb-inventory' then
            TriggerEvent("inventory:client:CloseInventory")
        elseif Config.InventorySystem == 'ox_inventory' then
            exports.ox_inventory:disableInventory(true)
        end
        
        -- Disable voice and phone
        exports["pma-voice"]:setVoiceProperty("radioEnabled", false)
        exports['qs-smartphone-pro']:SetCanOpenPhone(false)
        
        -- Apply additional restrictions
        SetEnableHandcuffs(ped, true)
        SetPedCanPlayGestureAnims(ped, false)
        TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 3.0, "handcuff", 0.4)
    else
        -- Enable inventory based on config
        if Config.InventorySystem == 'qs-inventory' then
            exports['qs-inventory']:setInventoryDisabled(false)
        elseif Config.InventorySystem == 'qb-inventory' then
            -- No action needed for qb-inventory
        elseif Config.InventorySystem == 'ox_inventory' then
            exports.ox_inventory:disableInventory(false)
        end
        
        -- Enable voice and phone
        exports["pma-voice"]:setVoiceProperty("radioEnabled", true)
        exports['qs-smartphone-pro']:SetCanOpenPhone(true)
        
        -- Remove additional restrictions
        SetEnableHandcuffs(ped, false)
        SetPedCanPlayGestureAnims(ped, true)
        ClearPedTasks(ped)
        TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 3.0, "uncuff", 0.4)
    end
end)

-- Target system integration
local function SetupTargetSystem()
    local options = {
        {
            type = "client",
            event = "rd-crime:client:UseHeadbag",
            icon = "fas fa-bag-shopping",
            label = "Use Headbag",
            item = "headbag",
            canInteract = function(entity)
                return not Config.BlacklistedJobs[QBCore.Functions.GetPlayerData().job.name] and HasHandsUp(entity)
            end
        },
        {
            type = "client",
            event = "rd-crime:client:UseZipTie",
            icon = "fas fa-zip-tie",
            label = "Use Zip Tie",
            item = "ziptie",
            canInteract = function(entity)
                return not Config.BlacklistedJobs[QBCore.Functions.GetPlayerData().job.name] and HasHandsUp(entity)
            end
        }
    }

    if Config.TargetSystem == 'qb-target' then
        exports['qb-target']:AddGlobalPlayer({
            options = options,
            distance = 2.5,
        })
    elseif Config.TargetSystem == 'ox_target' then
        exports.ox_target:addGlobalPlayer({
            {
                name = 'rd-crime:headbag',
                icon = 'fas fa-bag-shopping',
                label = 'Use Headbag',
                items = 'headbag',
                canInteract = function(entity, distance, coords, name)
                    return not Config.BlacklistedJobs[QBCore.Functions.GetPlayerData().job.name] and HasHandsUp(entity)
                end,
                onSelect = function(data)
                    TriggerEvent('rd-crime:client:UseHeadbag')
                end
            },
            {
                name = 'rd-crime:ziptie',
                icon = 'fas fa-zip-tie',
                label = 'Use Zip Tie',
                items = 'ziptie',
                canInteract = function(entity, distance, coords, name)
                    return not Config.BlacklistedJobs[QBCore.Functions.GetPlayerData().job.name] and HasHandsUp(entity)
                end,
                onSelect = function(data)
                    TriggerEvent('rd-crime:client:UseZipTie')
                end
            }
        })
    end
end

-- Call the setup function when the resource starts
Citizen.CreateThread(function()
    SetupTargetSystem()
end)

-- Event handler for using the headbag
RegisterNetEvent('rd-crime:client:UseHeadbag', function()
    local player, distance = QBCore.Functions.GetClosestPlayer()
    if player ~= -1 and distance < 2.5 then
        local targetPed = GetPlayerPed(player)
        if HasHandsUp(targetPed) then
            TriggerServerEvent('rd-crime:server:UseHeadbag', GetPlayerServerId(player))
        else
            QBCore.Functions.Notify('Target must have their hands up', 'error')
        end
    else
        QBCore.Functions.Notify('No player nearby', 'error')
    end
end)

-- Event handler for using the ziptie
RegisterNetEvent('rd-crime:client:UseZipTie', function()
    local player, distance = QBCore.Functions.GetClosestPlayer()
    if player ~= -1 and distance < 2.5 then
        local targetPed = GetPlayerPed(player)
        if HasHandsUp(targetPed) then
            TriggerServerEvent('rd-crime:server:UseZipTie', GetPlayerServerId(player))
        else
            QBCore.Functions.Notify('Target must have their hands up', 'error')
        end
    else
        QBCore.Functions.Notify('No player nearby', 'error')
    end
end)

-- Continuous check for zip-tied state
Citizen.CreateThread(function()
    while true do
        if IsZipTied() then
            local ped = PlayerPedId()
            DisablePlayerFiring(ped, true)
            SetCurrentPedWeapon(ped, GetHashKey('WEAPON_UNARMED'), true)
            
            -- Disable all movement and interaction keys
            DisableControlAction(0, 30, true) -- disable left/right
            DisableControlAction(0, 31, true) -- disable forward/back
            DisableControlAction(0, 36, true) -- INPUT_DUCK
            DisableControlAction(0, 21, true) -- disable sprint
            DisableControlAction(0, 24, true) -- disable attack
            DisableControlAction(0, 25, true) -- disable aim
            DisableControlAction(0, 47, true) -- disable weapon
            DisableControlAction(0, 58, true) -- disable weapon
            DisableControlAction(0, 263, true) -- disable melee
            DisableControlAction(0, 264, true) -- disable melee
            DisableControlAction(0, 257, true) -- disable melee
            DisableControlAction(0, 140, true) -- disable melee
            DisableControlAction(0, 141, true) -- disable melee
            DisableControlAction(0, 142, true) -- disable melee
            DisableControlAction(0, 143, true) -- disable melee
            DisableControlAction(0, 75, true) -- disable exit vehicle
            DisableControlAction(27, 75, true) -- disable exit vehicle
            DisableControlAction(0, 22, true) -- disable jump
            DisableControlAction(0, 23, true) -- disable enter vehicle
            DisableControlAction(0, 288, true) -- disable phone
            DisableControlAction(0, 289, true) -- disable inventory
            DisableControlAction(0, 170, true) -- disable animations
            DisableControlAction(0, 167, true) -- disable F6 menu
            DisableControlAction(0, 318, true) -- disable animation menu
            DisableControlAction(0, 106, true) -- disable vehicle mouse control override

            -- Disable hotkeys (1-5)
            for i = 157, 161 do
                DisableControlAction(0, i, true)
            end

            -- Disable inventory based on config
            if Config.InventorySystem == 'qs-inventory' then
                exports['qs-inventory']:setInventoryDisabled(true)
            elseif Config.InventorySystem == 'qb-inventory' then
                TriggerEvent("inventory:client:CloseInventory")
            elseif Config.InventorySystem == 'ox_inventory' then
                exports.ox_inventory:disableInventory(true)
            end
            
            -- Disable voice and phone
            exports["pma-voice"]:setVoiceProperty("radioEnabled", false)
            exports['qs-smartphone-pro']:SetCanOpenPhone(false)

            -- Apply cuffed animation if not already playing
            if not IsEntityPlayingAnim(ped, "mp_arresting", "idle", 3) then
                TaskPlayAnim(ped, "mp_arresting", "idle", 8.0, -8, -1, 49, 0, 0, 0, 0)
            end
        else
            -- Re-enable inventory and phone when not zip-tied
            if Config.InventorySystem == 'qs-inventory' then
                exports['qs-inventory']:setInventoryDisabled(false)
            elseif Config.InventorySystem == 'qb-inventory' then
                -- No action needed for qb-inventory
            elseif Config.InventorySystem == 'ox_inventory' then
                exports.ox_inventory:disableInventory(false)
            end
            exports['qs-smartphone-pro']:SetCanOpenPhone(true)
        end
        Citizen.Wait(0)
    end
end)

-- Load animation dictionary
Citizen.CreateThread(function()
    RequestAnimDict("mp_arresting")
    while not HasAnimDictLoaded("mp_arresting") do
        Citizen.Wait(100)
    end
end)