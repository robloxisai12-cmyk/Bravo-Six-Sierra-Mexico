local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local TerritoryService = {}
local progressByPart = {}
local lastSentState = {}

local function getTeamName(player)
    return player.Team and player.Team.Name or nil
end

local function getTerritoryParts()
    local folder = Workspace:FindFirstChild(Config.Territories.FolderName)
    if not folder then
        return {}
    end

    local parts = {}
    for _, descendant in ipairs(folder:GetDescendants()) do
        if descendant:IsA("BasePart") then
            table.insert(parts, descendant)
        end
    end
    return parts
end

local function isPlayerInside(player, zone)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return false
    end

    local localPosition = zone.CFrame:PointToObjectSpace(root.Position)
    local halfSize = zone.Size * 0.5
    local padding = Config.Territories.ContestRadiusPadding
    return math.abs(localPosition.X) <= halfSize.X + padding
        and math.abs(localPosition.Y) <= halfSize.Y + padding
        and math.abs(localPosition.Z) <= halfSize.Z + padding
end

local function getPresence(zone)
    local counts = {}
    for _, team in ipairs(Teams:GetTeams()) do
        counts[team.Name] = 0
    end

    for _, player in ipairs(Players:GetPlayers()) do
        local teamName = getTeamName(player)
        if teamName and counts[teamName] ~= nil and isPlayerInside(player, zone) then
            counts[teamName] += 1
        end
    end
    return counts
end

local function publish(zone, owner, progressTeam, progress)
    local state = {
        territory = zone.Name,
        owner = owner or "",
        progressTeam = progressTeam or "",
        progress = progress or 0,
    }
    local key = table.concat({
        state.owner,
        state.progressTeam,
        tostring(math.floor(state.progress * 10) / 10),
    }, "|")

    if lastSentState[zone] == key then
        return
    end
    lastSentState[zone] = key
    zone:SetAttribute("OwnerTeam", state.owner)
    zone:SetAttribute("CaptureTeam", state.progressTeam)
    zone:SetAttribute("CaptureProgress", state.progress)

    local remotes = ReplicatedStorage:FindFirstChild(Config.RemotesFolderName)
    local remote = remotes and remotes:FindFirstChild(Config.TerritoryUpdateRemoteName)
    if remote then
        remote:FireAllClients(state)
    end
end

function TerritoryService.Start()
    Players.PlayerAdded:Connect(function(player)
        task.delay(2, function()
            if not player.Parent then
                return
            end
            local remotes = ReplicatedStorage:FindFirstChild(Config.RemotesFolderName)
            local remote = remotes and remotes:FindFirstChild(Config.TerritoryUpdateRemoteName)
            if not remote then
                return
            end
            for _, zone in ipairs(getTerritoryParts()) do
                remote:FireClient(player, {
                    territory = zone.Name,
                    owner = zone:GetAttribute("OwnerTeam") or "",
                    progressTeam = zone:GetAttribute("CaptureTeam") or "",
                    progress = tonumber(zone:GetAttribute("CaptureProgress")) or 0,
                })
            end
        end)
    end)

    task.spawn(function()
        while true do
            for _, zone in ipairs(getTerritoryParts()) do
                local owner = zone:GetAttribute("OwnerTeam")
                local captureTime = zone:GetAttribute("CaptureTime")
                if typeof(captureTime) ~= "number" or captureTime <= 0 then
                    captureTime = Config.Territories.DefaultCaptureTime
                end

                local counts = getPresence(zone)
                local activeTeam = nil
                local activeCount = 0
                local tied = false
                for teamName, count in pairs(counts) do
                    if count > activeCount then
                        activeTeam = teamName
                        activeCount = count
                        tied = false
                    elseif count > 0 and count == activeCount then
                        tied = true
                    end
                end

                local state = progressByPart[zone] or { team = nil, elapsed = 0 }
                if activeCount == 0 or tied or activeTeam == owner then
                    state.team = nil
                    state.elapsed = 0
                elseif state.team ~= activeTeam then
                    state.team = activeTeam
                    state.elapsed = 0
                else
                    state.elapsed += Config.Territories.ScanInterval
                end

                if state.team and state.elapsed >= captureTime then
                    owner = state.team
                    state.team = nil
                    state.elapsed = 0
                end

                progressByPart[zone] = state
                publish(zone, owner, state.team, math.clamp(state.elapsed / captureTime, 0, 1))
            end
            task.wait(Config.Territories.ScanInterval)
        end
    end)
end

return TerritoryService
