Config = {}

Config.GuildId = "" -- Discord Server Id

Config.UseWebhook = true
Config.WebhookURL = "" -- Webhook URL (e.g. https://discord.com/api/webhooks/... )

Config.Accepted = "" -- Accept Log Channel Id (fallback)
Config.Rejected = "" -- Reject Log Channel Id (fallback)

Config.LogIP = true

-- Messages
Config.RejectMessage1 = "Your Fivem name must match your Discord nickname (%s)." -- Don't change the (%s) if you want the discord name inserted
Config.RejectMessage2 = "Could not verify your Discord account. Please try again later."
Config.RejectMessage3 = "You need to link your Discord account to connect."


-- Config.AllowedDiscordIds = { "123456789012345678", "987654321098765432" }
-- Config.AllowedRoleIds = { "111111111111111111", "222222222222222222" }
Config.AllowedDiscordIds = {}
Config.AllowedRoleIds = {}
