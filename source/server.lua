-- For support join my discord: https://discord.gg/Z9Mxu72zZ6

local config = {
    permissions = lib.load("data.permissions") or {},
    salaries = lib.load("data.salaries") or {},
    configuration = lib.load("data.configuration") or {
        characterLimit = 5,
        startingMoney = {
            cash = 2500,
            bank = 8000
        }
    }
}

NDCore.enableMultiCharacter(true)

local function validateJob(source, job)
    if not job then return end

    local jobExists
    for k, v in pairs(config.permissions) do
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
    local count = 0
    local characters = NDCore.fetchAllCharacters(src)

    for _, __ in pairs(characters) do
        count += 1
    end

    if count >= config.configuration.characterLimit then return end

    local player = NDCore.newCharacter(src, {
        firstname = newCharacter.firstName,
        lastname = newCharacter.lastName,
        dob = newCharacter.dob,
        gender = newCharacter.gender,
        cash = config.configuration.startingMoney.cash,
        bank = config.configuration.startingMoney.bank,
        metadata = {
            ethnicity = newCharacter.ethnicity
        }
    })

    if validateJob(player.source, newCharacter.job) then
        player.jobInfo = player.setJob(newCharacter.job)
        if player.jobInfo then
            player.job = newCharacter.job
        end
    end

    player.save()
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
        player.jobInfo = player.setJob(newCharacter.job)
    end

    player.save()
    return player
end)

lib.callback.register("ND_Characters:delete", function(src, characterId)
    local player = NDCore.fetchCharacter(characterId, src)
    return player and player.delete()
end)

local function getSalary(player)
    if not player or not player.job then return end
    
    local job = player.job:lower()
    for name, info in pairs(config.salaries) do
        if info.enabled and name:lower() == job then
            return info
        end
    end
end

CreateThread(function()
    local payChecks = false
    for _, salary in pairs(config.salaries) do
        if salary.enabled then
            payChecks = true
            break
        end
    end
    local lastSalaryPayouts = {}
    while payChecks do
        Wait(60000)
        local time = os.time()
        for _, player in pairs(NDCore.getPlayers()) do
            local salaryInfo = getSalary(player) or config.salaries["default"] or config.salaries["DEFAULT"]
            local src = player.source
            local lastPayout = lastSalaryPayouts[src]
            if not lastPayout then
                lastSalaryPayouts[src] = time -- this will make it to where it won't pay the player until next interval which will prevent pay if switching characters everytime.
            end
            if salaryInfo and (not lastPayout or time-lastPayout > salaryInfo.interval*60) then
                local salary = salaryInfo.rank[player.jobInfo.rank] or 100
                player.addMoney("bank", salary, player.jobInfo.label.." Salary")
                TriggerClientEvent('ox_lib:notify', player.source, {description = ("Recieved $%s from %s"):format(salary, player.jobInfo.label)})
                lastSalaryPayouts[src] = time
            end
            if not salaryInfo and (not lastPayout or time-lastPayout > salaryInfo.interval*60) then
                local salary = 50
                player.addMoney("bank", salary, "Citizen Salary")
                TriggerClientEvent('ox_lib:notify', player.source, {description = ("Welfare Check - $%s"):format(salary, player.jobInfo.label)})
                lastSalaryPayouts[src] = time
            end
        end
    end
end)

lib.callback.register("ND_Characters:fetchCharacters", function(source)
    local characters = NDCore.fetchAllCharacters(source)
    local perms = {}
    local groups = NDCore.getConfig("groups") or {}

    for job, _ in pairs(config.permissions) do
        if validateJob(source, job) then
            perms[#perms+1] = {
                name = job,
                label = groups[job]?.label or job
            }
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
