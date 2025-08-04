local QBCore = exports['qb-core']:GetCoreObject()

local rims = {
    {label = "Forgi Rims", value = "forgi_rims"},
    {label = "BB Rims", value = "bb_rims"},
    {label = "Steel Rims", value = "steel_rims"},
}

local selectedRim = nil
local collectedMetal = 0
local collectedSteel = 0
local isCollecting = false
local isCrafting = false

local EarlzBench = vector3(-225.3638, -1182.9503, 23.0546)          -- rim select menu spot
local MetalLocation = vector3(-235.6996, -1181.3897, 23.0546)        -- metal crafting spot
local SteelLocation = vector3(-240.3827, -1178.7924, 23.0546)        -- steel crafting spot
local PolishingBench = vector3(-240.2086, -1175.1843, 23.0546)       -- polishing bench spot

local function DrawText3D(coords, text)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z + 0.2)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(_x, _y)
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 75)
    end
end

local function doProgress(animScenario, text, duration, cb)
    local ped = PlayerPedId()
    TaskStartScenarioInPlace(ped, animScenario, 0, true)
    QBCore.Functions.Progressbar("action", text, duration, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        ClearPedTasks(ped)
        if cb then cb(true) end
    end, function()
        ClearPedTasks(ped)
        QBCore.Functions.Notify("Cancelled", "error")
        if cb then cb(false) end
    end)
end

-- Open rim select menu using qb-menu
local function OpenRimSelectMenu()
    local menu = {
        {
            header = "Earlz Rim Shop - Select Rim",
            isMenuHeader = true
        }
    }

    for _, rim in ipairs(rims) do
        table.insert(menu, {
            header = rim.label,
            txt = "Select to craft this rim",
            params = {
                event = "rimsystem:setSelectedRim",
                args = rim.value
            }
        })
    end

    exports['qb-menu']:openMenu(menu)
end

local function ResetMaterials()
    collectedMetal = 0
    collectedSteel = 0
end

-- Event to set selected rim from menu
RegisterNetEvent('rimsystem:setSelectedRim', function(rimValue)
    selectedRim = rimValue
    ResetMaterials()
    QBCore.Functions.Notify("Selected rim to craft: " .. rimValue, "success")
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        -- Earlz Bench (rim select menu)
        if #(coords - EarlzBench) < 2.0 then
            sleep = 0
            DrawText3D(EarlzBench, "[E] Select Rim to Craft")
            if IsControlJustPressed(0, 38) then
                OpenRimSelectMenu()
            end
        end

        -- Metal crafting spot
        if selectedRim and #(coords - MetalLocation) < 2.0 and not isCollecting and collectedMetal < 12 then
            sleep = 0
            DrawText3D(MetalLocation, "[E] Collect Metal (" .. collectedMetal .. "/12)")
            if IsControlJustPressed(0, 38) then
                isCollecting = true
                doProgress("WORLD_HUMAN_WELDING", "Collecting Metal...", 5000, function(success)
                    if success then
                        collectedMetal = collectedMetal + 4
                        TriggerServerEvent('rimsystem:giveMetal')
                    end
                    isCollecting = false
                end)
            end
        end

        -- Steel crafting spot
        if selectedRim and collectedMetal >= 12 and #(coords - SteelLocation) < 2.0 and not isCollecting and collectedSteel < 12 then
            sleep = 0
            DrawText3D(SteelLocation, "[E] Collect Steel (" .. collectedSteel .. "/12)")
            if IsControlJustPressed(0, 38) then
                isCollecting = true
                doProgress("WORLD_HUMAN_WELDING", "Collecting Steel...", 5000, function(success)
                    if success then
                        collectedSteel = collectedSteel + 4
                        TriggerServerEvent('rimsystem:giveSteel')
                    end
                    isCollecting = false
                end)
            end
        end

        -- Polishing bench (final craft)
if selectedRim and collectedMetal >= 12 and collectedSteel >= 12 and #(coords - PolishingBench) < 2.0 and not isCrafting then
    sleep = 0
    DrawText3D(PolishingBench, "[E] Polish & Craft " .. selectedRim)
    if IsControlJustPressed(0, 38) then
        isCrafting = true
        local ped = PlayerPedId()
        TaskStartScenarioInPlace(ped, "world_human_maid_clean", 0, true)

        QBCore.Functions.Progressbar("polishrim", "Polishing Rim...", 10000, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function()
            ClearPedTasks(ped)
            TriggerServerEvent('rimsystem:craftRim', selectedRim)
            selectedRim = nil
            ResetMaterials()
            isCrafting = false
        end, function()
            ClearPedTasks(ped)
            QBCore.Functions.Notify("Cancelled", "error")
            isCrafting = false
        end)
    end
end

Wait(sleep)
    end
end)

local selling = false
local currentBuyer = nil
local pedModel = "a_m_y_business_01"
local pedSpawnDistance = 15.0

local buyers = {}

local function DeleteBuyer(ped)
    if ped and DoesEntityExist(ped) then
        DeletePed(ped)
    end
end

local function ClearAllBuyers()
    for _, ped in pairs(buyers) do
        DeleteBuyer(ped)
    end
    buyers = {}
    currentBuyer = nil
end

local function PlayHandToHandExchange(playerPed, buyerPed)
    local animDict = "mp_common"
    local animName = "givetake1_a"
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do Wait(10) end

    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, 2000, 0, 0, false, false, false)
    TaskPlayAnim(buyerPed, animDict, animName, 8.0, -8.0, 2000, 0, 0, false, false, false)
    Wait(2000)
end

local function SpawnBuyer()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local forward = GetEntityForwardVector(playerPed)
    local spawnPos = playerCoords + forward * pedSpawnDistance
    spawnPos = vector3(spawnPos.x + math.random(-2,2), spawnPos.y + math.random(-2,2), spawnPos.z)

    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do Wait(10) end

    local ped = CreatePed(4, pedModel, spawnPos.x, spawnPos.y, spawnPos.z, 0.0, true, false)
    SetEntityAsMissionEntity(ped, true, true)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_STAND_MOBILE", 0, true)

    table.insert(buyers, ped)
    currentBuyer = ped

    TaskGoToEntity(ped, playerPed, -1, 1.5, 2.0, 1073741824, 0)
end

local interactionCooldown = false

local function SellingLoop()
    local playerPed = PlayerPedId()

    -- Start phone animation once
    TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_STAND_MOBILE", 0, true)

    -- Cancel phone animation after 7 seconds
    CreateThread(function()
        Wait(7000)
        ClearPedTasks(playerPed)
    end)

    -- Wait 5 seconds before first buyer spawns
    Wait(5000)

    while selling do
        Wait(0)

        if not currentBuyer or not DoesEntityExist(currentBuyer) then
            SpawnBuyer()
        else
            local dist = #(GetEntityCoords(currentBuyer) - GetEntityCoords(playerPed))
            if dist < 2.0 then
                DrawText3D(GetEntityCoords(currentBuyer), "[E] Sell Rim")

                if IsControlJustReleased(0, 38) and not interactionCooldown then
                    interactionCooldown = true

                    ClearPedTasks(playerPed)
                    ClearPedTasks(currentBuyer)
                    PlayHandToHandExchange(playerPed, currentBuyer)
                    TriggerServerEvent("rimsystem:attemptSale")
                    DeleteBuyer(currentBuyer)
                    currentBuyer = nil

                    -- cooldown to prevent spam
                    CreateThread(function()
                        Wait(1500)
                        interactionCooldown = false
                    end)
                end
            end
        end
    end

    ClearPedTasks(playerPed)
end

RegisterCommand("sellrims", function()
    if selling then
        QBCore.Functions.Notify("You are already selling rims!", "error")
        return
    end

    selling = true
    QBCore.Functions.Notify("Starting to sell rims...", "primary")
    CreateThread(SellingLoop)
end)

RegisterCommand("stoprimsell", function()
    if not selling then
        QBCore.Functions.Notify("You are not selling rims.", "error")
        return
    end

    selling = false
    ClearAllBuyers()
    QBCore.Functions.Notify("Stopped selling rims.", "success")
end)

