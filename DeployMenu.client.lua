-- Menú de selección de bando/unidad y despliegue (táctil). El servidor valida todo.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild(Config.RemotesFolderName)
local teamUpdate = remotes:WaitForChild(Config.TeamUpdateRemoteName)
local teamRequest = remotes:WaitForChild(Config.TeamRequestRemoteName)

local gui = Instance.new("ScreenGui")
gui.Name = "BravoSixDeploy"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Enabled = false

local background = Instance.new("Frame")
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(12, 16, 22)
background.BackgroundTransparency = 0.1
background.BorderSizePixel = 0
background.Parent = gui

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromScale(0.05, 0.03)
title.Size = UDim2.fromScale(0.9, 0.09)
title.Font = Enum.Font.GothamBold
title.Text = "ELIGE TU FUERZA"
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(240, 244, 248)
title.Parent = background

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromScale(0.05, 0.14)
list.Size = UDim2.fromScale(0.9, 0.72)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.ScrollBarThickness = 6
list.Parent = background

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.Parent = list

local message = Instance.new("TextLabel")
message.BackgroundTransparency = 1
message.Position = UDim2.fromScale(0.05, 0.88)
message.Size = UDim2.fromScale(0.9, 0.07)
message.Font = Enum.Font.Gotham
message.Text = ""
message.TextScaled = true
message.TextColor3 = Color3.fromRGB(255, 130, 130)
message.Parent = background

local teamColors = {
    Government = Color3.fromRGB(38, 105, 90),
    Cartels = Color3.fromRGB(150, 45, 45),
}

for _, unit in ipairs(Config.Units) do
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -12, 0, 56)
    button.BackgroundColor3 = teamColors[unit.Team]
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamBold
    button.Text = Config.Teams[unit.Team].Name .. "  —  " .. unit.Name
    button.TextScaled = true
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Parent = list

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.Parent = button

    button.Activated:Connect(function()
        message.Text = ""
        teamRequest:FireServer(unit.Id)
    end)
end

teamUpdate.OnClientEvent:Connect(function(payload)
    if typeof(payload) ~= "table" then
        return
    end
    if payload.action == "ShowDeploy" then
        message.Text = ""
        gui.Enabled = true
    elseif payload.action == "Result" then
        if payload.ok then
            gui.Enabled = false
        else
            message.Text = typeof(payload.msg) == "string" and payload.msg or "No se pudo desplegar"
        end
    end
end)

gui.Parent = player:WaitForChild("PlayerGui")
teamRequest:FireServer("Ready")
