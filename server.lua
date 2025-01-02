local BotToken = "" --put your bot token here
local function sendLogToDiscord(channelId, playerName, discordName, discordId, playerIP, license, license2, status)
    PerformHttpRequest("https://discord.com/api/v10/channels/" .. channelId .. "/messages", function(httpStatus, responseData)
        if httpStatus ~= 200 then
            print("Failed to send log: " .. tostring(httpStatus) .. " - " .. tostring(responseData))
        end
    end, "POST", json.encode({
        embeds = {{
            title = status == "Accepted" and "Player Connected" or "Connection Rejected",
            description = string.format("**%s** attempted to connect to the server.", playerName),
            fields = {
                { name = "Player Name", value = playerName, inline = true },
                { name = "Discord Name", value = discordName or "Not Found", inline = true },
                { name = "Discord ID", value = discordId or "Not Found", inline = true },
                { name = "IP Address", value = "||" .. playerIP .. "||", inline = false },
                { name = "License", value = "||" .. (license or "Not Found") .. "||", inline = false },
                { name = "License2", value = "||" .. (license2 or "Not Found") .. "||", inline = false },
            },
            color = status == "Accepted" and 3066993 or 15158332,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }}
    }), {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bot " .. BotToken
    })
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
        sendLogToDiscord(Config.Rejected, playerName, nil, nil, playerIP, license, license2, "Rejected")
        deferrals.done(Config.RejectMessage3)
        return
    end


    PerformHttpRequest("https://discord.com/api/guilds/" .. Config.GuildId .. "/members/" .. discordId, function(status, response, headers)
        if status == 200 then
            local data = json.decode(response)
            local discordName = data.nick or data.user.username

            if discordName == playerName then
                sendLogToDiscord(Config.Accepted, playerName, discordName, discordId, playerIP, license, license2, "Accepted")
                deferrals.done()
            else
                sendLogToDiscord(Config.Rejected, playerName, discordName, discordId, playerIP, license, license2, "Rejected")
                deferrals.done(string.format(Config.RejectMessage1, discordName))
            end
        else
            print("Error fetching Discord data: " .. tostring(status))
            sendLogToDiscord(Config.Rejected, playerName, nil, discordId, playerIP, license, license2, "Rejected")
            deferrals.done(Config.RejectMessage2)
        end
    end, "GET", "", { ["Authorization"] = "Bot " .. BotToken })
end)
