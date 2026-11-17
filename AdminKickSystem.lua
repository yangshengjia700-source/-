--[[
    Script: AdminKickSystem (ServerScriptService)
    Purpose: Allows whitelisted admins in YOUR OWN game to kick players by name.
    Setup: Place this as a Script inside ServerScriptService.
]]

-- ===== Configuration =====
local CONFIG = {
    AdminUserIds = {
        -- Add your admin UserIds here, e.g. 123456789
    },
    KickMessage = "You have been removed by an administrator.",
    ChatCommandPrefix = "!kick",
    LogEnabled = true,
}

-- ===== Services =====
local Players = game:GetService("Players")

-- ===== Logging =====
local function log(level, message)
    if CONFIG.LogEnabled then
        print(string.format("[AdminKick][%s] %s", level, message))
    end
end

-- ===== Validation =====
local adminSet = {}
for _, userId in ipairs(CONFIG.AdminUserIds) do
    adminSet[userId] = true
end

local function isAdmin(player)
    return player ~= nil and adminSet[player.UserId] == true
end

-- ===== Core Logic =====
-- Finds players whose name partially matches the query (case-insensitive)
local function findPlayers(query)
    local matches = {}
    local lowerQuery = string.lower(query)
    for _, player in ipairs(Players:GetPlayers()) do
        if string.find(string.lower(player.Name), lowerQuery, 1, true) then
            table.insert(matches, player)
        end
    end
    return matches
end

local function kickPlayer(admin, target)
    if target == admin then
        return false, "You cannot kick yourself."
    end
    if not target.Parent then
        return false, "Target is no longer in the game."
    end
    local ok, err = pcall(function()
        target:Kick(CONFIG.KickMessage)
    end)
    if ok then
        log("INFO", string.format("%s kicked %s", admin.Name, target.Name))
        return true
    end
    log("ERROR", "Kick failed: " .. tostring(err))
    return false, "Kick failed."
end

-- ===== Command Handling =====
local function handleCommand(admin, message)
    local prefix = CONFIG.ChatCommandPrefix
    if string.sub(message, 1, #prefix) ~= prefix then
        return
    end

    local query = string.match(message, "^" .. prefix .. "%s+(%S+)")
    if not query then
        log("WARN", admin.Name .. " sent an invalid kick command.")
        return
    end

    local matches = findPlayers(query)
    if #matches == 0 then
        log("WARN", "No player matched '" .. query .. "'.")
        return
    end
    if #matches > 1 then
        log("WARN", "Multiple players matched '" .. query .. "'; be more specific.")
        return
    end

    kickPlayer(admin, matches[1])
end

-- ===== Connections =====
local function onPlayerAdded(player)
    if not isAdmin(player) then
        return
    end
    player.Chatted:Connect(function(message)
        handleCommand(player, message)
    end)
    log("INFO", "Admin connected: " .. player.Name)
end

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(onPlayerAdded, player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
