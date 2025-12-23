local BotToken = "" -- put your bot token here

local function postToWebhook(webhookURL, payload)
    PerformHttpRequest(webhookURL, function(httpStatus, responseData)
        if httpStatus ~= 204 and httpStatus ~= 200 then
            print("Failed to post webhook: " .. tostring(httpStatus) .. " - " .. tostring(responseData))
        end
    end, "POST", json.encode(payload), { ["Content-Type"] = "application/json" })
end

local function postToChannel(channelId, payload)
    PerformHttpRequest("https://discord.com/api/v10/channels/" .. channelId .. "/messages", function(httpStatus, responseData)
        if httpStatus ~= 200 then
            print("Failed to send log: " .. tostring(httpStatus) .. " - " .. tostring(responseData))
        end
    end, "POST", json.encode(payload), {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bot " .. BotToken
    })
end

local function sendLog(status, playerName, discordName, discordId, playerIP, license, license2)
    local title = status == "Accepted" and "Player Connected" or "Connection Rejected"
    local color = status == "Accepted" and 3066993 or 15158332
    local description = string.format("**%s** attempted to connect to the server.", playerName)

    local fields = {
        { name = "Player Name", value = playerName, inline = true },
        { name = "Discord Name", value = discordName or "Not Found", inline = true },
        { name = "Discord ID", value = discordId or "Not Found", inline = true },
    }

    table.insert(fields, { name = "License", value = "||" .. (license or "Not Found") .. "||", inline = false })
    table.insert(fields, { name = "License2", value = "||" .. (license2 or "Not Found") .. "||", inline = false })

    if Config.LogIP and playerIP then
        table.insert(fields, { name = "IP Address", value = "||" .. playerIP .. "||", inline = false })
    end

    local embed = {
        title = title,
        description = description,
        fields = fields,
        color = color,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    }

    local payload = { embeds = { embed } }

    if Config.UseWebhook and Config.WebhookURL and Config.WebhookURL ~= "" then
        postToWebhook(Config.WebhookURL, payload)
    else
        local channelId = (status == "Accepted") and Config.Accepted or Config.Rejected
        if channelId and channelId ~= "" then
            postToChannel(channelId, payload)
        else
            print("No logging method configured (no webhook and no channel ID).")
        end
    end
end

local function isDiscordIdAllowed(discordId)
    if not Config.AllowedDiscordIds then return false end
    for _, id in ipairs(Config.AllowedDiscordIds) do
        if tostring(id) == tostring(discordId) then
            return true
        end
    end
    return false
end

local function hasAllowedRole(memberData)
    if not Config.AllowedRoleIds or not memberData or not memberData.roles then return false end
    for _, r in ipairs(memberData.roles) do
        for _, allowed in ipairs(Config.AllowedRoleIds) do
            if tostring(r) == tostring(allowed) then
                return true
            end
        end
    end
    return false
end

AddEventHandler("playerConnecting", function(playerName, setKickReason, deferrals)
    local source = source
    local playerIdentifiers = GetPlayerIdentifiers(source)
    local discordId = nil
    local playerIP = GetPlayerEndpoint(source)
    local license = nil
    local license2 = nil

    for _, id in ipairs(playerIdentifiers) do
        if string.sub(id, 1, 7) == "license" then
            if not license then
                license = string.sub(id, 9)
            elseif not license2 then
                license2 = string.sub(id, 9)
            end
        end
    end

    deferrals.defer()
    deferrals.update("Checking your Discord nickname...")

    for _, id in ipairs(playerIdentifiers) do
        if string.sub(id, 1, 8) == "discord:" then
            discordId = string.sub(id, 9)
            break
        end
    end

    if not discordId then
        sendLog("Rejected", playerName, nil, nil, playerIP, license, license2)
        deferrals.done(Config.RejectMessage3)
        return
    end

    PerformHttpRequest("https://discord.com/api/v10/guilds/" .. Config.GuildId .. "/members/" .. discordId, function(status, response, headers)
        if status == 200 then
            local data = json.decode(response)
            local discordName = data.nick or (data.user and data.user.username) or nil

            if isDiscordIdAllowed(discordId) or hasAllowedRole(data) then
                sendLog("Accepted", playerName, discordName, discordId, playerIP, license, license2)
                deferrals.done()
                return
            end

            if discordName == playerName then
                sendLog("Accepted", playerName, discordName, discordId, playerIP, license, license2)
                deferrals.done()
            else
                sendLog("Rejected", playerName, discordName, discordId, playerIP, license, license2)
                deferrals.done(string.format(Config.RejectMessage1, discordName or "unknown"))
            end
        else
            print("Error fetching Discord data: " .. tostring(status))
            sendLog("Rejected", playerName, nil, discordId, playerIP, license, license2)
            deferrals.done(Config.RejectMessage2)
        end
    end, "GET", "", { ["Authorization"] = "Bot " .. BotToken })
end)
