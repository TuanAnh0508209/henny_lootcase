-- Henny Lootcase Client Script
-- NUI Callbacks and Network Events for Lootcase Spinning Animation

-- Stores the current lootcase data
local lootcaseData = {}
local isAnimating = false

-- RegisterNetEvent for useBox - when player uses a lootcase
RegisterNetEvent('henny_lootcase:useBox', function(boxData)
    if isAnimating then return end
    
    lootcaseData = boxData
    isAnimating = true
    
    -- Send data to NUI to start spinning animation
    SendNUIMessage({
        action = 'startAnimation',
        items = boxData.items,
        duration = boxData.duration or 5000
    })
end)

-- RegisterNetEvent for showResult - display the result from server
RegisterNetEvent('henny_lootcase:showResult', function(resultData)
    -- Send result to NUI
    SendNUIMessage({
        action = 'showResult',
        item = resultData.item,
        label = resultData.label,
        quantity = resultData.quantity,
        rarity = resultData.rarity
    })
end)

-- NUI Callback for when animation finishes
RegisterNUICallback('animationFinished', function(data, cb)
    isAnimating = false
    
    -- Trigger server event to process the lootcase result
    TriggerServerEvent('henny_lootcase:processResult', {
        boxId = lootcaseData.boxId,
        selectedIndex = data.selectedIndex
    })
    
    cb('ok')
end)

-- NUI Callback for close event - when player closes the lootcase UI
RegisterNUICallback('close', function(data, cb)
    isAnimating = false
    lootcaseData = {}
    
    -- Send message to NUI to close the UI
    SendNUIMessage({
        action = 'closeUI'
    })
    
    -- Set NUI focus to false
    SetNuiFocus(false, false)
    
    cb('ok')
end)

-- Export function to open lootcase from external scripts
exports('openLootcase', function(boxData)
    if not boxData or not boxData.items then
        print('^1Error: Invalid lootcase data provided^7')
        return false
    end
    
    -- Store the lootcase data
    lootcaseData = boxData
    isAnimating = true
    
    -- Enable NUI focus
    SetNuiFocus(true, true)
    
    -- Send data to NUI
    SendNUIMessage({
        action = 'openUI',
        items = boxData.items,
        title = boxData.title or 'Lootcase',
        duration = boxData.duration or 5000
    })
    
    return true
end)

-- Helper function to check if animation is currently running
local function isLootcaseAnimating()
    return isAnimating
end

-- Export helper function
exports('isLootcaseAnimating', isLootcaseAnimating)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        SetNuiFocus(false, false)
        isAnimating = false
        lootcaseData = {}
    end
end)
