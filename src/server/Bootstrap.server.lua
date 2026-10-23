local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local TerritoryService = require(script.Parent:WaitForChild("Services"):WaitForChild("TerritoryService"))
local VehicleService = require(script.Parent:WaitForChild("Services"):WaitForChild("VehicleService"))

local Deploy = Config.Deploy

-- Los jugadores eligen bando antes de aparecer.
Players.CharacterAutoLoads = false

local teamObjects = {}
local function getOrCreateTeam(key, config)
    local team = Teams:FindFirstChild(config.Name)
    if not team then
        team = Instance.new("Team")
        team.Name = config.Name
        team.Parent = Teams
    end
    team.TeamColor = BrickColor.new(config.BrickColor)
    team.AutoAssignable = config.AutoAssignable
    teamObjects[key] = team
    return team
end

getOrCreateTeam("Government", Config.Teams.Government)
getOrCreateTeam("Cartels", Config.Teams.Cartels)

local unitsById = {}
for _, unit in ipairs(Config.Units) do
    unitsById[unit.Id] = unit
end

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
local teamUpdate = getOrCreateRemote(Config.TeamUpdateRemoteName)
local teamRequest = getOrCreateRemote(Config.TeamRequestRemoteName)

-- Spawns: cada SpawnLocation etiquetado pertenece a un solo bando, así Roblox
-- impide aparecer en el spawn del bando contrario.
local function prepareSpawn(spawn)
    if not spawn:IsA("SpawnLocation") then
        return
    end
    local team = teamObjects[spawn:GetAttribute("Team")]
    if team then
        spawn.Neutral = false
        spawn.TeamColor = team.TeamColor
    end
end
for _, spawn in ipairs(CollectionService:GetTagged(Deploy.SpawnTag)) do
    prepareSpawn(spawn)
end
CollectionService:GetInstanceAddedSignal(Deploy.SpawnTag):Connect(prepareSpawn)

local function pickSpawn(teamKey)
    local options = {}
    for _, spawn in ipairs(CollectionService:GetTagged(Deploy.SpawnTag)) do
        if spawn:IsA("SpawnLocation") and spawn.Enabled and spawn:GetAttribute("Team") == teamKey then
            table.insert(options, spawn)
        end
    end
    if #options == 0 then
        return nil
    end
    return options[math.random(1, #options)]
end

local function isAlive(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid ~= nil and humanoid.Health > 0
end

local function reply(player, ok, msg)
    teamUpdate:FireClient(player, { action = "Result", ok = ok, msg = msg })
end

local lastRequest = {}
local lastSwitch = {}

local function tryDeploy(player, unitId)
    local unit = unitsById[unitId]
    if not unit then
        return reply(player, false, "Unidad inexistente")
    end
    -- Solo se puede desplegar sin personaje vivo: evita cambiar de bando para
    -- escapar de un combate o recuperar vida.
    if isAlive(player) then
        return reply(player, false, "Ya estás desplegado")
    end

    local newTeam = teamObjects[unit.Team]
    local oldTeam = player.Team
    local now = os.clock()

    if oldTeam ~= nil and oldTeam ~= newTeam then
        if now - (lastSwitch[player] or -math.huge) < Deploy.SwitchCooldown then
            return reply(player, false, "Espera antes de cambiar de bando")
        end
        -- El sistema de combate debe actualizar este atributo al dañar/recibir daño.
        if now - (player:GetAttribute("LastCombat") or -math.huge) < Deploy.CombatLock then
            return reply(player, false, "No puedes cambiar de bando tras un combate")
        end
    end

    if oldTeam ~= newTeam then
        local otherTeam = (unit.Team == "Government") and teamObjects.Cartels or teamObjects.Government
        local newCount = #newTeam:GetPlayers() + 1
        local otherCount = #otherTeam:GetPlayers() - (oldTeam == otherTeam and 1 or 0)
        if newCount - otherCount > Deploy.MaxImbalance then
            return reply(player, false, "Ese bando está lleno, prueba el otro")
        end
        lastSwitch[player] = now
    end

    player.Neutral = false
    player.Team = newTeam
    player:SetAttribute("Unit", unit.Id)
    -- Si aún no hay spawns etiquetados para el bando, se usa el spawn por defecto del mapa.
    player.RespawnLocation = pickSpawn(unit.Team)
    if player.Parent then
        player:LoadCharacter()
    end
    reply(player, true, "")
end

teamRequest.OnServerEvent:Connect(function(player, request)
    if typeof(request) ~= "string" then
        return
    end

    if request == "Ready" then
        if not player.Character then
            teamUpdate:FireClient(player, { action = "ShowDeploy" })
        end
        return
    end

    local now = os.clock()
    if lastRequest[player] and now - lastRequest[player] < Deploy.RequestInterval then
        return reply(player, false, "Espera un momento")
    end
    lastRequest[player] = now

    tryDeploy(player, request)
end)

local function watchPlayer(player)
    player.CharacterAdded:Connect(function(character)
        -- The map template's MapAccessService marks characters Neutral on spawn.
        -- Re-assert the chosen Bravo Six faction after template CharacterAdded handlers run.
        task.defer(function()
            if player.Parent and player.Team then
                local teamName = player.Team.Name
                if teamName == "Government" or teamName == "Cartels" then
                    player.Neutral = false
                end
            end
        end)

        local humanoid = character:WaitForChild("Humanoid", 10)
        if not humanoid then
            return
        end
        humanoid.Died:Connect(function()
            task.wait(Deploy.RespawnDelay)
            if player.Parent then
                teamUpdate:FireClient(player, { action = "ShowDeploy" })
            end
        end)
    end)
end

Players.PlayerAdded:Connect(watchPlayer)
for _, player in ipairs(Players:GetPlayers()) do
    watchPlayer(player)
end

Players.PlayerRemoving:Connect(function(player)
    lastRequest[player] = nil
    lastSwitch[player] = nil
end)

TerritoryService.Start()
VehicleService.Start()
print("[Bravo Six] Server systems initialized.")
