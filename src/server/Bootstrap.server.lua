local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local TerritoryService = require(script.Parent:WaitForChild("Services"):WaitForChild("TerritoryService"))
local VehicleService = require(script.Parent:WaitForChild("Services"):WaitForChild("VehicleService"))

local function getOrCreateTeam(config)
    local team = Teams:FindFirstChild(config.Name)
    if not team then
        team = Instance.new("Team")
        team.Name = config.Name
        team.Parent = Teams
    end
    team.TeamColor = BrickColor.new(config.BrickColor)
    team.AutoAssignable = config.AutoAssignable
    return team
end

getOrCreateTeam(Config.Teams.Government)
getOrCreateTeam(Config.Teams.Sierra)

local remotes = ReplicatedStorage:FindFirstChild(Config.RemotesFolderName)
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = Config.RemotesFolderName
    remotes.Parent = ReplicatedStorage
end

local function getOrCreateRemote(name)
    local remote = remotes:FindFirstChild(name)
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = remotes
    end
    return remote
end

getOrCreateRemote(Config.TerritoryUpdateRemoteName)
getOrCreateRemote(Config.TeamUpdateRemoteName)
local teamRequest = getOrCreateRemote(Config.TeamRequestRemoteName)

local lastTeamRequest = {}
teamRequest.OnServerEvent:Connect(function(player, requestedKey)
    if typeof(requestedKey) ~= "string" then
        return
    end

    local now = os.clock()
    if lastTeamRequest[player] and now - lastTeamRequest[player] < 2 then
        return
    end
    lastTeamRequest[player] = now

    local teamConfig = Config.Teams[requestedKey]
    if not teamConfig then
        return
    end

    local team = Teams:FindFirstChild(teamConfig.Name)
    if not team then
        return
    end

    player.Team = team
    player.Neutral = false
    player:LoadCharacter()
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
    lastTeamRequest[player] = nil
end)

TerritoryService.Start()
VehicleService.Start()
print("[Bravo Six] Server systems initialized.")
