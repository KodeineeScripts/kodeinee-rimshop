local QBCore = exports['qb-core']:GetCoreObject()

-- Give 4x Metal
RegisterNetEvent('rimsystem:giveMetal', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        Player.Functions.AddItem("metal", 4)
        TriggerClientEvent('QBCore:Notify', src, "You received 4x Metal.", "success")
    end
end)

-- Give 4x Steel
RegisterNetEvent('rimsystem:giveSteel', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        Player.Functions.AddItem("steel", 4)
        TriggerClientEvent('QBCore:Notify', src, "You received 4x Steel.", "success")
    end
end)

-- Craft Rim from 12 Metal + 12 Steel
RegisterNetEvent('rimsystem:craftRim', function(rimName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player and rimName then
        local metal = Player.Functions.GetItemByName("metal")
        local steel = Player.Functions.GetItemByName("steel")

        if metal and metal.amount >= 12 and steel and steel.amount >= 12 then
            Player.Functions.RemoveItem("metal", 12)
            Player.Functions.RemoveItem("steel", 12)
            Player.Functions.AddItem(rimName, 1)
            TriggerClientEvent('QBCore:Notify', src, "You crafted a " .. rimName .. "!", "success")
        else
            TriggerClientEvent('QBCore:Notify', src, "You need 12x Metal and 12x Steel to craft a rim.", "error")
        end
    else
        TriggerClientEvent('QBCore:Notify', src, "Crafting failed.", "error")
    end
end)

-- Rim Selling Logic (Random payout between $600 - $1200)
local RimItems = {
    "forgi_rims",
    "bb_rims",
    "steel_rims"
}

RegisterNetEvent("rimsystem:attemptSale", function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    for _, rimItem in ipairs(RimItems) do
        local item = Player.Functions.GetItemByName(rimItem)
        if item and item.amount > 0 then
            Player.Functions.RemoveItem(rimItem, 1)
            local payout = math.random(600, 1200)
            Player.Functions.AddMoney("cash", payout, "sold-" .. rimItem)
            TriggerClientEvent('QBCore:Notify', src, "Sold 1x " .. rimItem .. " for $" .. payout, "success")
            return
        end
    end

    TriggerClientEvent('QBCore:Notify', src, "You don’t have any rims to sell.", "error")
end)
