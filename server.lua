-- Henny Lootcase Server Script
-- ESX Framework Integration with Discord Logging
-- Created: 2025-12-15 15:21:05 UTC

local ESX = exports["es_extended"]:getSharedObject()

-- Configuration
local Config = {
    Discord = {
        WebhookURL = "YOUR_WEBHOOK_URL_HERE",
        ServerName = "Your Server Name",
        EmbedColor = 3447003 -- Blue
    },
    Rewards = {
        Money = { min = 500, max = 5000 },
        Items = {
            { name = "water", label = "Water", chance = 0.30 },
            { name = "bread", label = "Bread", chance = 0.25 },
            { name = "laptop", label = "Laptop", chance = 0.10 },
            { name = "phone", label = "Phone", chance = 0.20 },
            { name = "goldbar", label = "Gold Bar", chance = 0.15 }
        }
    }
}

-- ====================================
-- Discord Logging Functions
-- ====================================

--- Log general information to Discord
--- @param title string The title of the embed
--- @param description string The description of the embed
--- @param color number The color of the embed (optional)
function LogDiscordInfo(title, description, color)
    color = color or Config.Discord.EmbedColor
    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["color"] = color,
            ["footer"] = {
                ["text"] = Config.Discord.ServerName .. " - Info Log",
                ["icon_url"] = "https://media.discordapp.net/attachments/1234567890/1234567890/info_icon.png"
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    SendToDiscord(embed)
end

--- Log errors to Discord
--- @param title string The title of the error embed
--- @param description string The error description
--- @param playerIdentifier string Player identifier (optional)
function LogDiscordError(title, description, playerIdentifier)
    playerIdentifier = playerIdentifier or "Unknown"
    local embed = {
        {
            ["title"] = "⚠️ " .. title,
            ["description"] = description,
            ["color"] = 16711680, -- Red
            ["fields"] = {
                {
                    ["name"] = "Player Identifier",
                    ["value"] = playerIdentifier,
                    ["inline"] = false
                }
            },
            ["footer"] = {
                ["text"] = Config.Discord.ServerName .. " - Error Log",
                ["icon_url"] = "https://media.discordapp.net/attachments/1234567890/1234567890/error_icon.png"
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    SendToDiscord(embed)
end

--- Send embed to Discord webhook
--- @param embeds table Array of embed objects
function SendToDiscord(embeds)
    if not Config.Discord.WebhookURL or Config.Discord.WebhookURL == "YOUR_WEBHOOK_URL_HERE" then
        print("^3[WARNING]^7 Discord webhook URL not configured!")
        return
    end

    local payload = {
        embeds = embeds,
        username = Config.Discord.ServerName .. " - Lootcase Logger",
        avatar_url = "https://media.discordapp.net/attachments/1234567890/1234567890/lootcase_icon.png"
    }

    PerformHttpRequest(Config.Discord.WebhookURL, function(err, text, headers)
        if err == 204 then
            print("^2[SUCCESS]^7 Message sent to Discord")
        else
            print("^1[ERROR]^7 Failed to send message to Discord. Error: " .. tostring(err))
        end
    end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

-- ====================================
-- Reward System Functions
-- ====================================

--- Calculate random reward from lootcase
--- @return table reward Reward object with type, amount, and item info
function CalculateReward()
    local totalChance = 0
    local rewardType = math.random()
    
    -- 60% chance for money, 40% chance for items
    if rewardType <= 0.6 then
        local amount = math.random(Config.Rewards.Money.min, Config.Rewards.Money.max)
        return {
            type = "money",
            amount = amount,
            label = "$" .. amount
        }
    else
        -- Calculate item based on chances
        local cumulativeChance = 0
        local randomChance = math.random()
        
        for _, item in ipairs(Config.Rewards.Items) do
            cumulativeChance = cumulativeChance + item.chance
            if randomChance <= cumulativeChance then
                return {
                    type = "item",
                    name = item.name,
                    label = item.label,
                    amount = 1
                }
            end
        end
        
        -- Fallback to first item if no match
        local fallbackItem = Config.Rewards.Items[1]
        return {
            type = "item",
            name = fallbackItem.name,
            label = fallbackItem.label,
            amount = 1
        }
    end
end

--- Give reward to player
--- @param source number The player's server ID
--- @param reward table The reward object from CalculateReward
--- @return boolean success Whether the reward was successfully given
function GiveReward(source, reward)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        LogDiscordError("Player Not Found", "Failed to give reward - player not found. Source: " .. source)
        return false
    end

    local playerName = xPlayer.getName()
    local playerIdentifier = xPlayer.identifier

    if reward.type == "money" then
        xPlayer.addMoney(reward.amount)
        
        LogDiscordInfo(
            "💰 Money Reward Given",
            "**Player:** " .. playerName .. "\n" ..
            "**Identifier:** " .. playerIdentifier .. "\n" ..
            "**Amount:** $" .. reward.amount,
            65280 -- Green
        )
        
        TriggerClientEvent('chat:addMessage', source, {
            args = { "Lootcase", "You received $" .. reward.amount },
            color = { 0, 255, 0 }
        })
        
        return true
        
    elseif reward.type == "item" then
        if xPlayer.canCarryItem(reward.name, reward.amount) then
            xPlayer.addInventoryItem(reward.name, reward.amount)
            
            LogDiscordInfo(
                "📦 Item Reward Given",
                "**Player:** " .. playerName .. "\n" ..
                "**Identifier:** " .. playerIdentifier .. "\n" ..
                "**Item:** " .. reward.label .. "\n" ..
                "**Amount:** " .. reward.amount,
                3447003 -- Blue
            )
            
            TriggerClientEvent('chat:addMessage', source, {
                args = { "Lootcase", "You received " .. reward.amount .. "x " .. reward.label },
                color = { 0, 255, 255 }
            })
            
            return true
        else
            LogDiscordError(
                "Inventory Full",
                "Player inventory is full. Could not give " .. reward.label,
                playerIdentifier
            )
            
            TriggerClientEvent('chat:addMessage', source, {
                args = { "Lootcase", "Your inventory is full!" },
                color = { 255, 0, 0 }
            })
            
            return false
        end
    end

    return false
end

-- ====================================
-- Network Events
-- ====================================

--- Handle lootcase opening
RegisterNetEvent('henny_lootcase:openBox')
AddEventHandler('henny_lootcase:openBox', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then
        LogDiscordError("Invalid Player", "Player tried to open lootcase but not found. Source: " .. source)
        return
    end

    -- Check if player has lootcase item
    local hasLootcase = false
    for _, item in ipairs(xPlayer.getInventory()) do
        if item.name == "lootcase" and item.count > 0 then
            hasLootcase = true
            break
        end
    end

    if not hasLootcase then
        LogDiscordError(
            "No Lootcase",
            "Player attempted to open lootcase without having one",
            xPlayer.identifier
        )
        TriggerClientEvent('chat:addMessage', source, {
            args = { "Lootcase", "You don't have a lootcase!" },
            color = { 255, 0, 0 }
        })
        return
    end

    -- Remove lootcase from inventory
    xPlayer.removeInventoryItem("lootcase", 1)

    -- Calculate reward
    local reward = CalculateReward()

    -- Trigger client event to show animation
    TriggerClientEvent('henny_lootcase:showAnimation', source, reward)

    -- Schedule reward distribution after animation completes (adjust time as needed)
    SetTimeout(3000, function()
        TriggerEvent('henny_lootcase:finalizeReward', source, reward)
    end)
end)

--- Handle finalize reward
RegisterNetEvent('henny_lootcase:finalizeReward')
AddEventHandler('henny_lootcase:finalizeReward', function(source, reward)
    source = source or source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then
        LogDiscordError("Invalid Player", "Failed to finalize reward - player not found")
        return
    end

    local success = GiveReward(source, reward)

    if success then
        LogDiscordInfo(
            "✅ Reward Finalized",
            "**Player:** " .. xPlayer.getName() .. "\n" ..
            "**Reward Type:** " .. reward.type .. "\n" ..
            "**Reward:** " .. reward.label,
            65280 -- Green
        )
    else
        LogDiscordError(
            "Reward Failed",
            "Failed to finalize reward for player",
            xPlayer.identifier
        )
    end

    -- Notify client
    TriggerClientEvent('henny_lootcase:rewardFinalized', source, success, reward)
end)

-- ====================================
-- Admin Commands
-- ====================================

--- Give lootcase to player (Admin Command)
TriggerEvent('chat:addSuggestion', '/givecase', 'Give a lootcase to a player', {
    { name = 'Player ID', help = 'The ID of the player to give the case to' },
    { name = 'Amount', help = 'Number of lootcases to give (default: 1)' }
})

ESX.RegisterCommand('givecase', 'admin', function(xPlayer, args, showError)
    local targetPlayerId = tonumber(args[1])
    local amount = tonumber(args[2]) or 1

    if not targetPlayerId or targetPlayerId < 1 then
        return showError('Invalid player ID')
    end

    if amount < 1 then
        return showError('Amount must be at least 1')
    end

    local targetPlayer = ESX.GetPlayerFromId(targetPlayerId)

    if not targetPlayer then
        return showError('Player not found')
    end

    -- Give lootcase
    targetPlayer.addInventoryItem('lootcase', amount)

    -- Log to Discord
    LogDiscordInfo(
        "🎁 Lootcase Given by Admin",
        "**Admin:** " .. xPlayer.getName() .. "\n" ..
        "**Target Player:** " .. targetPlayer.getName() .. "\n" ..
        "**Target ID:** " .. targetPlayerId .. "\n" ..
        "**Amount:** " .. amount,
        16776960 -- Yellow
    )

    -- Notify both players
    TriggerClientEvent('chat:addMessage', targetPlayerId, {
        args = { "Admin", "Admin " .. xPlayer.getName() .. " gave you " .. amount .. "x Lootcase!" },
        color = { 255, 255, 0 }
    })

    TriggerClientEvent('chat:addMessage', xPlayer.source, {
        args = { "Admin", "You gave " .. amount .. "x Lootcase to " .. targetPlayer.getName() },
        color = { 0, 255, 0 }
    })
end, false, { help = 'Give a lootcase to a player', validate = false, arguments = { 
    { name = 'id', help = 'Player ID' },
    { name = 'amount', help = 'Amount (optional)' }
}})

-- ====================================
-- Server Start Events
-- ====================================

AddEventHandler('onServerResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print("^2[SUCCESS]^7 Henny Lootcase Server script loaded successfully")
        LogDiscordInfo(
            "🚀 Server Started",
            "Henny Lootcase system is now active",
            3447003
        )
    end
end)

AddEventHandler('onServerResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print("^1[STOPPED]^7 Henny Lootcase Server script stopped")
        LogDiscordInfo(
            "⛔ Server Stopped",
            "Henny Lootcase system has been stopped",
            16711680
        )
    end
end)

-- ====================================
-- Exported Functions
-- ====================================

--- Exported function to give lootcase programmatically
exports('giveLootcase', function(playerId, amount)
    amount = amount or 1
    local xPlayer = ESX.GetPlayerFromId(playerId)
    
    if xPlayer then
        xPlayer.addInventoryItem('lootcase', amount)
        return true
    end
    return false
end)

--- Exported function to manually trigger a reward
exports('manualReward', function(playerId)
    if playerId then
        local reward = CalculateReward()
        TriggerEvent('henny_lootcase:finalizeReward', playerId, reward)
        return true
    end
    return false
end)

print("^3[INFO]^7 Henny Lootcase Server - All systems initialized")