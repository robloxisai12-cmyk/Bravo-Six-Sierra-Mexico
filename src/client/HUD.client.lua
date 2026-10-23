local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild(Config.RemotesFolderName)
local territoryRemote = remotes:WaitForChild(Config.TerritoryUpdateRemoteName)
local teamRequestRemote = remotes:WaitForChild(Config.TeamRequestRemoteName)

local gui = Instance.new("ScreenGui")
gui.Name = "BravoSixHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false

local panel = Instance.new("Frame")
panel.Name = "TerritoryPanel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -12, 0, 12)
panel.Size = UDim2.new(0, 250, 0, 88)
panel.BackgroundColor3 = Color3.fromRGB(18, 24, 32)
panel.BackgroundTransparency = 0.12
panel.BorderSizePixel = 0
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(12, 8)
title.Size = UDim2.new(1, -24, 0, 24)
title.Font = Enum.Font.GothamBold
title.Text = "BRAVO SIX  •  TERRITORIO"
title.TextColor3 = Color3.fromRGB(240, 244, 248)
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local status = Instance.new("TextLabel")
status.Name = "Status"
status.BackgroundTransparency = 1
status.Position = UDim2.fromOffset(12, 34)
status.Size = UDim2.new(1, -24, 0, 20)
status.Font = Enum.Font.Gotham
status.Text = "Sin zonas configuradas"
status.TextColor3 = Color3.fromRGB(190, 202, 215)
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextTruncate = Enum.TextTruncate.AtEnd
status.Parent = panel

local barBack = Instance.new("Frame")
barBack.Position = UDim2.fromOffset(12, 62)
barBack.Size = UDim2.new(1, -24, 0, 10)
barBack.BackgroundColor3 = Color3.fromRGB(54, 65, 78)
barBack.BorderSizePixel = 0
barBack.Parent = panel

local barFill = Instance.new("Frame")
barFill.Size = UDim2.fromScale(0, 1)
barFill.BackgroundColor3 = Color3.fromRGB(61, 155, 255)
barFill.BorderSizePixel = 0
barFill.Parent = barBack

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1, 0)
barCorner.Parent = barBack
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = barFill

local function fitForScreen()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    if viewport.X < 600 then
        panel.Size = UDim2.new(0, 210, 0, 82)
        panel.Position = UDim2.new(1, -8, 0, 8)
        title.TextSize = 11
        status.TextSize = 11
    else
        panel.Size = UDim2.new(0, 250, 0, 88)
        panel.Position = UDim2.new(1, -12, 0, 12)
        title.TextSize = 13
        status.TextSize = 12
    end
end

local teamPanel = Instance.new("Frame")
teamPanel.Name = "TeamSelector"
teamPanel.AnchorPoint = Vector2.new(0, 1)
teamPanel.Position = UDim2.new(0, 12, 1, -12)
teamPanel.Size = UDim2.new(0, 236, 0, 94)
teamPanel.BackgroundColor3 = Color3.fromRGB(18, 24, 32)
teamPanel.BackgroundTransparency = 0.12
teamPanel.BorderSizePixel = 0
teamPanel.Parent = gui

local teamPanelCorner = Instance.new("UICorner")
teamPanelCorner.CornerRadius = UDim.new(0, 10)
teamPanelCorner.Parent = teamPanel

local teamTitle = Instance.new("TextLabel")
teamTitle.BackgroundTransparency = 1
teamTitle.Position = UDim2.fromOffset(10, 5)
teamTitle.Size = UDim2.new(1, -20, 0, 22)
teamTitle.Font = Enum.Font.GothamBold
teamTitle.Text = "SELECCIONA TU FUERZA"
teamTitle.TextColor3 = Color3.fromRGB(240, 244, 248)
teamTitle.TextSize = 12
teamTitle.TextXAlignment = Enum.TextXAlignment.Left
teamTitle.Parent = teamPanel

local function makeTeamButton(text, color, position, teamKey)
    local button = Instance.new("TextButton")
    button.Name = teamKey .. "Button"
    button.Position = position
    button.Size = UDim2.new(0.5, -14, 0, 48)
    button.BackgroundColor3 = color
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    button.Font = Enum.Font.GothamBold
    button.Text = text
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 12
    button.TextWrapped = true
    button.Parent = teamPanel
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 7)
    buttonCorner.Parent = button
    button.Activated:Connect(function()
        teamRequestRemote:FireServer(teamKey)
    end)
end

makeTeamButton("FUERZA FEDERAL", Color3.fromRGB(38, 105, 185), UDim2.fromOffset(8, 34), "Government")
makeTeamButton("FUERZA SIERRA", Color3.fromRGB(177, 48, 48), UDim2.new(0.5, 6, 0, 34), "Sierra")

gui.Parent = player:WaitForChild("PlayerGui")
fitForScreen()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitForScreen)
end

territoryRemote.OnClientEvent:Connect(function(state)
    if typeof(state) ~= "table" then
        return
    end
    local owner = state.owner ~= "" and state.owner or "Sin control"
    local progressTeam = state.progressTeam
    if progressTeam ~= "" then
        status.Text = string.format("%s: %s capturando", state.territory, progressTeam)
    else
        status.Text = string.format("%s: %s", state.territory, owner)
    end
    barFill.Size = UDim2.fromScale(math.clamp(tonumber(state.progress) or 0, 0, 1), 1)
    if progressTeam == Config.Teams.Sierra.Name then
        barFill.BackgroundColor3 = Color3.fromRGB(230, 73, 73)
    else
        barFill.BackgroundColor3 = Color3.fromRGB(61, 155, 255)
    end
end)

player:GetPropertyChangedSignal("Team"):Connect(function()
    local team = player.Team
    if team then
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Bravo Six",
                Text = "Equipo: " .. team.Name,
                Duration = 3,
            })
        end)
    end
end)
