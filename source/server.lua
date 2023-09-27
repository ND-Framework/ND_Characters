-- For support join my discord: https://discord.gg/Z9Mxu72zZ6

local function validateJob(source, job)
    if not job then return end

    local jobExists
    for k, v in pairs(Config.jobs) do
        if k:lower() == job:lower() then
            jobExists = v
        end
    end

    if not jobExists then return end
    local info = NDCore.getPlayerServerInfo(source)
    local roles = info and info.discord and info.discord.roles or {}

    for i=1, #jobExists do
        local roleId = tostring(jobExists[i])
        if roleId == "0" or lib.table.contains(roles, roleId) then
            return true
        end
    end
end

-- Creating a new character.
lib.callback.register("ND_Characters:new", function(src, newCharacter)
    local player = NDCore.newCharacter(src, {
        firstname = newCharacter.firstName,
        lastname = newCharacter.lastName,
        dob = newCharacter.dob,
        gender = newCharacter.gender,
        cash = Config.startingMoney.cash,
        bank = Config.startingMoney.bank,
        metadata = {
            ethnicity = newCharacter.ethnicity
        }
    })

    if validateJob(player.source, newCharacter.job) then
        player.setJob(newCharacter.job)
    end
    return player
end)

-- Update the character info when edited.
lib.callback.register("ND_Characters:edit", function(src, newCharacter)
    local player = NDCore.fetchCharacter(newCharacter.id, src)
    player.setData({
        source = src,
        firstname = newCharacter.firstName,
        lastname = newCharacter.lastName,
        dob = newCharacter.dob,
        gender = newCharacter.gender
    })
    player.setMetadata("ethnicity", newCharacter.ethnicity)

    if validateJob(player.source, newCharacter.job) then
        player.setJob(newCharacter.job)
    end
    return player
end)

lib.callback.register("ND_Characters:delete", function(src, characterId)
    local player = NDCore.fetchCharacter(characterId, src)
    return player and player.delete()
end)

local function paySalary(player)
    local salary
    for k, v in pairs(Config.salaries) do
        if k:lower() == v:lower() then
            salary = v
        end
    end
    if not salary then return end

    player.addMoney("bank", salary, "Salary")
    player.notify({
        title = "Salary",
        description = ("Received $%d."):format(salary),
        type = "success",
        icon = "sack-dollar"
    })
end

CreateThread(function()
    local interval = Config.paycheckInterval*60000
    while Config.paychecks do
        Wait(interval)
        for _, player in pairs(NDCore.getPlayers()) do
            paySalary(player)
        end
    end
end)

lib.callback.register("ND_Characters:fetchCharacters", function(source)
    local characters = NDCore.fetchAllCharacters(source)
    local perms = {}

    for job, _ in pairs(Config.jobs) do
        if validateJob(source, job) then
            perms[#perms+1] = job:lower()
        end
    end

    return characters, perms
end)

RegisterNetEvent("ND_Characters:select", function(id)
    local src = source
    NDCore.setActiveCharacter(src, tonumber(id))
end)

RegisterNetEvent("ND_Characters:exitGame", function()
    local src = source
    DropPlayer(src, "Quit from main menu")
end)

RegisterNetEvent("ND_Characters:updateClothing", function(clothing)
    local src = source
    local player = NDCore.getPlayer(src)
    if not player or not clothing or type(clothing) ~= "table" then return end
    player.setMetadata("clothing", clothing)
end)
