local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local TerritoryService = require(script:WaitForChild("Services"):WaitForChild("TerritoryService"))

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

TerritoryService.Start()
print("[Bravo Six] Server systems initialized.")
