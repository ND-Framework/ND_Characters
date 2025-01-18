-- For support join my discord: https://discord.gg/Z9Mxu72zZ6

local currentResourceName = GetCurrentResourceName()
local changeAppearence = false
local started = false
local firstSpawn = true
local characters = {}
local lastSource = GetResourceKvpInt("ND_Characters:source")
local lastCharacter = GetResourceKvpInt("ND_Characters:character")
local config = {
    spawns = lib.load("data.spawns") or {},
    configuration = lib.load("data.configuration") or {
        changeCharacterCommand = "changecharacter",
        characterLimit = 5,
        logo = "https://i.imgur.com/02A5Cgl.png",
        backgrounds = {
            "https://i.imgur.com/E51ckFx.png",
            "https://i.imgur.com/SeZD7TP.png",
            "https://i.imgur.com/ZWKfYD9.png"
        }
    }    
}

local function getAop()
    local resources = {
        "SimpleHUD",
        "ModernHUD"
    }
    for i=1, #resources do
        local resource = resources[i]
        if GetResourceState(resource) == "started" then
            return exports[resource]:getAOP()
        end
    end
end

local function startChangeAppearence(dontReturn)
    exports["fivem-appearance"]:startPlayerCustomization(function(appearance)
        if not appearance then
            return not dontReturn and start(true)
        end
        
        Wait(4000)
        TriggerServerEvent("ND_Characters:updateClothing", appearance)
    end, {
        ped = true,
        headBlend = true,
        faceFeatures = true,
        headOverlays = true,
        components = true,
        props = true,
        tattoos = false
    })
end

-- Set the player to creating the ped if they haven't already.
local function setCharacterClothes(character)
    if GetResourceState("fivem-appearance") ~= "started" then return end
    local clothing = character.metadata.clothing

    if not clothing or not next(clothing) then
        Wait(3000)
        return startChangeAppearence()
    end

    exports["fivem-appearance"]:setPlayerModel(clothing.model or clothing.appearance.model)

    local ped = PlayerPedId()
    exports["fivem-appearance"]:setPedAppearance(ped, clothing.appearance or clothing)
end

local function tablelength(table)
    local count = 0
    for _ in pairs(table) do
        count += 1
    end
    return count
end

function SetDisplay(bool, typeName, bg, chars)
    local characterAmount = chars or characters
    if not characterAmount then
        characterAmount = {}
    end
    if not bg then
        background = config.configuration.backgrounds[math.random(1, #config.configuration.backgrounds)]
    end
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        type = typeName,
        background = background,
        status = bool,
        serverName = NDCore.getConfig("serverName"),
        characterAmount = ("%d/%d"):format(tablelength(characterAmount), config.configuration.characterLimit)
    })
    Wait(500)
    local aop = getAop()
    if not aop then return end
    SendNUIMessage({
        type = "aop",
        aop = aop
    })
end

function start(switch)
    characters, perms = lib.callback.await("ND_Characters:fetchCharacters")
    if switch then
        local ped = PlayerPedId()
        SwitchOutPlayer(ped, 0, 1)
        FreezeEntityPosition(ped, true)
        SetEntityVisible(ped, false, 0)
    end
    SendNUIMessage({
        type = "givePerms",
        deptRoles = json.encode(perms)
    })
    SendNUIMessage({
        type = "refresh",
        characters = json.encode(characters)
    })
    SendNUIMessage({
        type = "logo",
        logo = config.configuration.logo or "https://i.imgur.com/02A5Cgl.png"
    })
    SetDisplay(true, "ui", background, characters)
    local aop = getAop()
    if not aop then return end
    SendNUIMessage({
        type = "aop",
        aop = aop
    })
end

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName ~= currentResourceName then return end
    Wait(500)
    if lastSource == cache.serverId and lastCharacter then
        TriggerServerEvent("ND_Characters:select", lastCharacter)
        return
    end
    Wait(1500)
    start(false)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= currentResourceName then return end
    local player = NDCore.getPlayer()
    if not player then return end
    SetResourceKvpInt("ND_Characters:source", cache.serverId)
    SetResourceKvpInt("ND_Characters:character", player.id)
end)

AddEventHandler("playerSpawned", function()
    start(true)
end)

local function sortSpawns(chars, id)
    local player = chars[id]
    if not player then return end
    
    local defaultSpawns = config.spawns["default"] or config.spawns["DEFAULT"]
    local spawns = {}
    for _, spawn in pairs(defaultSpawns) do
        spawns[#spawns+1] = spawn
    end
    
    local job = player.job
    if not job then return spawns end
    
    local jobSpawns = {}
    for k, v in pairs(config.spawns) do
        if k:lower() == job:lower() then
            jobSpawns = v
            break
        end
    end
    
    for _, newSpawn in pairs(jobSpawns) do
        spawns[#spawns+1] = newSpawn
    end

    return spawns
end

-- Selecting a player from the iu.
RegisterNUICallback("setMainCharacter", function(data)
    local id = tonumber(data.id)
    local spawns = sortSpawns(characters, id)

    if not spawns then return end
    SendNUIMessage({
        type = "setSpawns",
        spawns = json.encode(spawns),
        id = id
    })
end)

-- Creating a character from the ui.
RegisterNUICallback("newCharacter", function(data)
    if tablelength(characters) > config.configuration.characterLimit then return end
    lib.callback("ND_Characters:new", false, function(player)
        if not player then
            return lib.print.warn("creating character unsuccessful")
        end
        characters[player.id] = player
        SendNUIMessage({
            type = "refresh",
            characters = json.encode(characters),
            characterAmount = ("%d/%d"):format(tablelength(characters), config.configuration.characterLimit)
        })
    end, {
        firstName = data.firstName,
        lastName = data.lastName,
        dob = data.dateOfBirth,
        gender = data.gender,
        ethnicity = data.ethnicity,
        job = data.department
    })
end)

-- editing a character from the ui.
RegisterNUICallback("editCharacter", function(data)
    lib.callback("ND_Characters:edit", false, function(player)
        if not player then
            return lib.print.warn("editing character unsuccessful")
        end
        characters[player.id] = player
        SendNUIMessage({
            type = "refresh",
            characters = json.encode(characters),
            characterAmount = ("%d/%d"):format(tablelength(characters), config.configuration.characterLimit)
        })
    end, {
        id = data.id,
        firstName = data.firstName,
        lastName = data.lastName,
        dob = data.dateOfBirth,
        gender = data.gender,
        ethnicity = data.ethnicity,
        job = data.department
    })
end)

-- deleting a character from the ui.
RegisterNUICallback("delCharacter", function(data)
    lib.callback("ND_Characters:delete", false, function(success)
        if not success then return end
        characters[data.character] = nil
        SendNUIMessage({
            type = "refresh",
            characters = json.encode(characters),
            characterAmount = ("%d/%d"):format(tablelength(characters), config.configuration.characterLimit)
        })
    end, data.character)
end)

-- Quit button from ui.
RegisterNUICallback("exitGame", function()
    TriggerServerEvent("ND_Characters:exitGame")
end)

-- Teleporting using ui.
RegisterNUICallback("tpToLocation", function(data)
    local ped = PlayerPedId()
    local character = characters[data.id]
    FreezeEntityPosition(ped, true)
    SetEntityCoords(ped, tonumber(data.x), tonumber(data.y), tonumber(data.z), false, false, false, false)
    SwitchInPlayer(ped)
    Wait(500)
    SetDisplay(false, "ui")
    Wait(500)
    while not HasCollisionLoadedAroundEntity(ped) do
        Wait(100)
    end
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, 0)
    setCharacterClothes(character)
    TriggerServerEvent("ND_Characters:select", data.id)
    SetTimeout(1000, function()
        if firstSpawn then
            firstSpawn = false
            SendNUIMessage({
                type = "firstSpawn"
            })
        end
    end)
end)

-- Choosing the do not tp button.
RegisterNUICallback("tpDoNot", function(data)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    local character = characters[data.id]
    if firstSpawn then
        local data = character and character.metadata
        if data and data.location then
            SetEntityCoords(ped, data.location.x, data.location.y, data.location.z)
            if data.location.w then
                SetEntityHeading(ped, data.location.w)
            end
        end
        SetTimeout(1000, function()
            firstSpawn = false
            SendNUIMessage({
                type = "firstSpawn"
            })
        end)
    end
    SwitchInPlayer(ped)
    Wait(500)
    SetDisplay(false, "ui")
    Wait(500)
    while not HasCollisionLoadedAroundEntity(ped) do
        Wait(100)
    end
    SetEntityVisible(ped, true, 0)
    FreezeEntityPosition(ped, false)
    Wait(100)
    setCharacterClothes(character)
    TriggerServerEvent("ND_Characters:select", data.id)
end)

RegisterNetEvent("ND:clothingMenu", function()
    startChangeAppearence(true)
end)

RegisterNetEvent("ND:characterMenu", function()
    start(true)
end)

if config.configuration.changeCharacterCommand then
    -- Change character command
    RegisterCommand(config.configuration.changeCharacterCommand, function()
        start(true)
    end, false)
    
    -- chat suggestions
    TriggerEvent("chat:addSuggestion", "/" .. config.configuration.changeCharacterCommand, "Change your character.")
end
