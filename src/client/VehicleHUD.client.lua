-- Client UI only sends requests; all permission checks happen on the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local VehicleConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VehicleConfig"))
local remotes = ReplicatedStorage:WaitForChild(VehicleConfig.RemotesFolderName)
local requestRemote = remotes:WaitForChild(VehicleConfig.RequestRemoteName)
local stateRemote = remotes:WaitForChild(VehicleConfig.StateRemoteName)

local gui = Instance.new("ScreenGui")
gui.Name = "BravoVehicleHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false

local panel = Instance.new("Frame")
panel.Name = "VehiclePanel"
panel.AnchorPoint = Vector2.new(0, 0.5)
panel.Position = UDim2.new(0, 10, 0.5, 0)
panel.Size = UDim2.new(0, 214, 0, 228)
panel.BackgroundColor3 = Color3.fromRGB(17, 23, 29)
panel.BackgroundTransparency = 0.12
panel.BorderSizePixel = 0
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(10, 7)
title.Size = UDim2.new(1, -20, 0, 25)
title.Font = Enum.Font.GothamBold
title.Text = "VEHÍCULOS"
title.TextColor3 = Color3.fromRGB(239, 243, 247)
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local status = Instance.new("TextLabel")
status.Name = "Status"
status.BackgroundTransparency = 1
status.Position = UDim2.fromOffset(10, 31)
status.Size = UDim2.new(1, -20, 0, 30)
status.Font = Enum.Font.Gotham
status.Text = "Solicita un vehículo de tu equipo"
status.TextColor3 = Color3.fromRGB(192, 202, 212)
status.TextSize = 10
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = panel

local function addButton(name, label, vehicleType, y, color)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Position = UDim2.fromOffset(9, y)
    button.Size = UDim2.new(1, -18, 0, 36)
    button.BackgroundColor3 = color
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    button.Font = Enum.Font.GothamBold
    button.Text = label
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 11
    button.TextWrapped = true
    button.Parent = panel
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 7)
    buttonCorner.Parent = button

    button.Activated:Connect(function()
        status.Text = "Solicitando " .. label .. "..."
        requestRemote:FireServer("Spawn", vehicleType)
    end)
    return button
end

local government = player.Team and player.Team.Name == VehicleConfig.Teams.Government
local sierra = player.Team and player.Team.Name == VehicleConfig.Teams.Sierra
local federalButton = addButton("FederalPickup", "Camioneta táctica federal", "GovernmentTactical", 65, Color3.fromRGB(42, 91, 69))
local sierraButton = addButton("SierraPickup", "Camioneta Sierra", "CartelPickup", 105, Color3.fromRGB(91, 75, 60))
local truckButton = addButton("LogisticsTruck", "Camión logístico (Federal)", "LogisticsTruck", 145, Color3.fromRGB(70, 83, 68))
local boatButton = addButton("PatrolBoat", "Lancha de patrulla (Federal)", "PatrolBoat", 185, Color3.fromRGB(35, 78, 100))

local function updateTeamVisibility()
    local team = player.Team
    local isGovernment = team and team.Name == VehicleConfig.Teams.Government
    local isSierra = team and team.Name == VehicleConfig.Teams.Sierra
    federalButton.Visible = isGovernment
    truckButton.Visible = isGovernment
    boatButton.Visible = isGovernment
    sierraButton.Visible = isSierra
    if not isGovernment and not isSierra then
        status.Text = "Elige un equipo para solicitar vehículos."
    end
end

player:GetPropertyChangedSignal("Team"):Connect(updateTeamVisibility)
updateTeamVisibility()

stateRemote.OnClientEvent:Connect(function(state)
    if typeof(state) ~= "table" then
        return
    end
    if typeof(state.message) == "string" then
        status.Text = state.message
    end
    if typeof(state.active) == "number" and typeof(state.maximum) == "number" then
        title.Text = string.format("VEHÍCULOS  %d/%d", state.active, state.maximum)
    end
end)

local function fitForScreen()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    if viewport.X < 600 then
        panel.Size = UDim2.new(0, 190, 0, 220)
        panel.Position = UDim2.new(0, 7, 0.5, 0)
        title.TextSize = 12
    else
        panel.Size = UDim2.new(0, 214, 0, 228)
        panel.Position = UDim2.new(0, 10, 0.5, 0)
        title.TextSize = 14
    end
end

if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitForScreen)
end
fitForScreen()
gui.Parent = player:WaitForChild("PlayerGui")
